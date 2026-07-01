# Knowledge Graph Protocol

Shared by all skills. Load this file as Step 0 before any skill's Step 1.

Graphify reference: https://graphify.net  |  Install: `pip install graphifyy`

---

## Check → Build → Query

```
graphify-out/graph.json exists?
  YES → query it
  NO  → run bash scripts/setup-kg.sh, then query
```

### Step-by-step

1. **Check** — does `graphify-out/graph.json` exist in the project root?
   - YES → skip to step 2
   - NO  → run `bash scripts/setup-kg.sh`
     - Installs graphify via `pip install graphifyy && graphify claude install`
       (official source: https://graphify.net)
     - Runs `graphify .` in the project root
     - Installs a post-commit hook (`graphify hook install`) for automatic AST rebuilds

2. **Query** — run `bash scripts/query-kg.sh "<context>"` using the per-skill context from the table below
   - Returns matching nodes from `graphify-out/graph.json` (NetworkX JSON: functions, classes, imports, call relationships, confidence-tagged edges)
   - Also surfaces the top of `graphify-out/GRAPH_REPORT.md` (core nodes, surprises, suggested questions)

3. **Inject** — treat query output as **KG Context** for this skill's execution:
   - Existing artifact found (ADR, test file, Dockerfile, pipeline) → offer to extend/update it, not regenerate
   - Related module or entity found → reference it in imports, dependencies, design decisions
   - Nothing returned → proceed with normal skill flow unchanged

## Output files graphify produces

| File | Contents |
|---|---|
| `graphify-out/graph.json` | NetworkX JSON graph — nodes (functions, classes, files) + edges (imports, calls, inheritance) with EXTRACTED/INFERRED confidence tags |
| `graphify-out/GRAPH_REPORT.md` | Human-readable summary — core nodes, surprises, suggested questions |
| `graphify-out/graph.html` | Interactive visualization (open in browser) |
| `graphify-out/cache/` | Incremental AST cache (tree-sitter, rebuilt on commit) |

## Per-Skill Query Context

| Skill | Query string to pass |
|---|---|
| orchestrator | Feature title + type from the parsed requirement struct |
| requirements | Feature name or epic title from `$ARGUMENTS` |
| design | System/service name + artifact type (HLD, LLD, ADR) |
| coding | Stack name + feature/module name from `$ARGUMENTS` |
| test-plan | Module or service name being tested |
| compliance | Domain keyword (hipaa / pci / gdpr / soc2) + service name |
| cicd | Platform name + stack + repo name |
| deploy | Deployment target + service name |

## Rules

- KG Context is advisory — it informs output, never blocks it
- If query returns nothing, continue with normal skill flow unchanged
- Never rebuild mid-skill; if `graph.json` is missing at Step 0, build once and proceed
- The post-commit hook keeps the graph current automatically after `graphify hook install`
