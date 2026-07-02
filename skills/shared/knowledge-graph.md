# Knowledge Graph Protocol

Every skill runs this protocol as Step 0 before any other work.
The goal: understand the project from its knowledge graph before generating anything.

Official graphify: https://graphify.net | PyPI package: `pip install graphifyy`

---

## Full Protocol (run in order, do not skip steps)

### Step 0.1 — Ensure graphify is installed

Use the Bash tool to check:

```bash
command -v graphify
```

If graphify is NOT found:

```bash
pip install graphifyy || pip3 install graphifyy
```

Confirm installation succeeded before continuing.

---

### Step 0.2 — Build the knowledge graph if missing

Use the Bash tool to check whether the graph exists:

```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || echo "MISSING"
```

If MISSING:

```bash
graphify .
graphify claude install
```

`graphify .` scans the project and writes:
- `graphify-out/GRAPH_REPORT.md` — human-readable summary of core modules, key entities, suggested questions
- `graphify-out/graph.json` — full NetworkX graph (functions, classes, imports, call edges)
- `graphify-out/graph.html` — interactive visualization
- `graphify-out/cache/` — incremental AST cache

`graphify claude install` wires the graph into Claude Code so it stays current automatically.

Also add `graphify-out/` to `.gitignore` if not already there:

```bash
grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify knowledge graph\ngraphify-out/\n" >> .gitignore
```

---

### Step 0.3 — Read the knowledge graph

Use the Read tool to read `graphify-out/GRAPH_REPORT.md` in full.

Extract and hold as **KG Context**:
- Core modules and their stated purpose
- Key classes, functions, entities relevant to the current task
- Dominant stack and framework
- Existing artifacts related to what this skill will produce

Do NOT scan source files to build this understanding. The report is the source of truth.
Only read specific source files if you need detail not present in the report.

---

### Step 0.4 — Apply KG Context

Use KG Context throughout the skill execution:

| KG reveals | Action |
|---|---|
| Existing artifact (design doc, test file, migration) | Offer to extend/update it — do not regenerate from scratch |
| Related module or pattern | Reference it in imports, dependencies, design decisions |
| Stack confirmed | Skip stack detection — use what the graph shows |
| Nothing relevant | Proceed with the skill's normal flow unchanged |

---

## Per-Skill Focus when reading GRAPH_REPORT.md

| Skill | What to extract |
|---|---|
| orchestrator | Completed phases, existing artifacts, dominant stack |
| requirements | Features or modules related to the requested epic/feature |
| design | Existing design docs (`docs/HLD.md`, `docs/LLD.md`, ADRs), known components |
| coding | Existing modules, patterns, imports used by related code |
| test-plan | Existing test files, untested modules, risky areas in the report |
| compliance | Sensitive data flows, auth patterns, logging, existing compliance controls |
