#!/usr/bin/env python3
"""
build-graph.py — Lightweight knowledge graph builder.
Walks a project directory, extracts functions/classes/imports from source files,
and writes graphify-out/graph.json (NetworkX-compatible) + graphify-out/GRAPH_REPORT.md.

Supported: Python, TypeScript/JavaScript, Java, Go, Rust
Usage: python3 scripts/build-graph.py <project-root>
"""
import ast
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# ── helpers ──────────────────────────────────────────────────────────────────

def rel(path, root):
    return str(Path(path).relative_to(root))

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist",
             "build", "target", ".gradle", "graphify-out", ".kg"}

# ── language extractors ───────────────────────────────────────────────────────

def extract_python(src, filepath, root, nodes, edges):
    """Use the stdlib ast module — zero dependencies."""
    rel_path = rel(filepath, root)
    try:
        tree = ast.parse(src, filename=filepath)
    except SyntaxError:
        return

    module_id = f"{rel_path}:module"
    nodes.append({"id": module_id, "type": "module", "label": Path(filepath).stem, "file": rel_path})

    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            cid = f"{rel_path}:{node.name}"
            nodes.append({"id": cid, "type": "class", "label": node.name, "file": rel_path})
            edges.append({"source": module_id, "target": cid, "type": "contains", "confidence": "EXTRACTED"})
            for base in node.bases:
                if isinstance(base, ast.Name):
                    edges.append({"source": cid, "target": base.id, "type": "inherits", "confidence": "EXTRACTED"})

        elif isinstance(node, ast.FunctionDef) or isinstance(node, ast.AsyncFunctionDef):
            fid = f"{rel_path}:{node.name}"
            nodes.append({"id": fid, "type": "function", "label": node.name, "file": rel_path})

        elif isinstance(node, ast.Import):
            for alias in node.names:
                edges.append({"source": module_id, "target": alias.name, "type": "imports", "confidence": "EXTRACTED"})

        elif isinstance(node, ast.ImportFrom):
            mod = node.module or ""
            edges.append({"source": module_id, "target": mod, "type": "imports", "confidence": "EXTRACTED"})


def extract_regex(src, filepath, root, nodes, edges, lang):
    """Regex-based extraction for TS/JS/Java/Go/Rust."""
    rel_path = rel(filepath, root)
    module_id = f"{rel_path}:module"
    nodes.append({"id": module_id, "type": "module", "label": Path(filepath).stem, "file": rel_path})

    patterns = {
        "ts_js": {
            "class":    r"\bclass\s+(\w+)",
            "function": r"(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\(?[^)]*\)?\s*=>)",
            "import":   r'(?:import|require)\s*\(?["\']([^"\']+)["\']',
        },
        "java": {
            "class":    r"\b(?:class|interface|enum)\s+(\w+)",
            "function": r"(?:public|private|protected|static|void|[\w<>\[\]]+)\s+(\w+)\s*\([^)]*\)\s*(?:throws\s+\w+\s*)?\{",
            "import":   r"import\s+([\w.]+);",
        },
        "go": {
            "class":    r"\btype\s+(\w+)\s+struct",
            "function": r"\bfunc\s+(?:\(\w+\s+\*?\w+\)\s+)?(\w+)\s*\(",
            "import":   r'"([^"]+)"',
        },
        "rust": {
            "class":    r"\b(?:struct|enum|trait|impl)\s+(\w+)",
            "function": r"\bfn\s+(\w+)\s*[(<]",
            "import":   r"\buse\s+([\w:]+)",
        },
    }

    p = patterns.get(lang, patterns["ts_js"])

    for m in re.finditer(p["class"], src):
        name = next(g for g in m.groups() if g)
        cid = f"{rel_path}:{name}"
        nodes.append({"id": cid, "type": "class", "label": name, "file": rel_path})
        edges.append({"source": module_id, "target": cid, "type": "contains", "confidence": "EXTRACTED"})

    for m in re.finditer(p["function"], src):
        name = next((g for g in m.groups() if g), None)
        if name and not name[0].isupper():
            fid = f"{rel_path}:{name}"
            nodes.append({"id": fid, "type": "function", "label": name, "file": rel_path})

    for m in re.finditer(p["import"], src):
        target = next(g for g in m.groups() if g)
        edges.append({"source": module_id, "target": target, "type": "imports", "confidence": "EXTRACTED"})


LANG_MAP = {
    ".py":   "python",
    ".ts":   "ts_js", ".tsx": "ts_js", ".js": "ts_js", ".jsx": "ts_js",
    ".java": "java",
    ".go":   "go",
    ".rs":   "rust",
}

# ── walk and build ─────────────────────────────────────────────────────────────

def build(root_dir):
    root = Path(root_dir).resolve()
    nodes, edges = [], []

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fname in filenames:
            ext = Path(fname).suffix.lower()
            lang = LANG_MAP.get(ext)
            if not lang:
                continue
            fpath = os.path.join(dirpath, fname)
            try:
                src = Path(fpath).read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            if lang == "python":
                extract_python(src, fpath, root, nodes, edges)
            else:
                extract_regex(src, fpath, root, nodes, edges, lang)

    return nodes, edges


def write_graph(nodes, edges, out_dir):
    graph = {
        "directed": True,
        "multigraph": False,
        "graph": {},
        "nodes": nodes,
        "edges": edges,
    }
    graph_path = out_dir / "graph.json"
    graph_path.write_text(json.dumps(graph, indent=2))
    return graph_path


def write_report(nodes, edges, out_dir):
    type_counts = defaultdict(int)
    file_counts = defaultdict(int)
    for n in nodes:
        type_counts[n.get("type", "unknown")] += 1
        file_counts[n.get("file", "")] += 1

    # Top files by node density
    top_files = sorted(file_counts.items(), key=lambda x: x[1], reverse=True)[:10]

    lines = [
        "# Knowledge Graph Report",
        "",
        "## Summary",
        f"- Nodes: {len(nodes)}",
        f"- Edges: {len(edges)}",
        "",
        "### Node Types",
    ]
    for t, c in sorted(type_counts.items()):
        lines.append(f"- {t}: {c}")

    lines += ["", "## Core Files (highest node density)"]
    for f, c in top_files:
        lines.append(f"- `{f}` — {c} nodes")

    lines += [
        "",
        "## Suggested Questions",
        "- Which modules have the most dependencies?",
        "- What classes exist in the auth or payment domain?",
        "- Which functions are called most frequently?",
        "- Are there any orphaned modules with no imports?",
    ]

    report_path = out_dir / "GRAPH_REPORT.md"
    report_path.write_text("\n".join(lines))
    return report_path


# ── main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    root_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    out_dir = Path("graphify-out")
    out_dir.mkdir(exist_ok=True)

    print(f"[kg] Scanning {Path(root_dir).resolve()} ...")
    nodes, edges = build(root_dir)
    # Deduplicate nodes by id
    seen = set()
    nodes = [n for n in nodes if not (n["id"] in seen or seen.add(n["id"]))]

    graph_path = write_graph(nodes, edges, out_dir)
    report_path = write_report(nodes, edges, out_dir)

    print(f"[kg] {len(nodes)} nodes, {len(edges)} edges")
    print(f"[kg] Written: {graph_path}")
    print(f"[kg] Written: {report_path}")
