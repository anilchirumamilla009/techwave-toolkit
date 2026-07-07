# Knowledge Graph Protocol

Every skill runs this protocol as Step 0 before any other work.
The goal: understand the project from its knowledge graph before generating anything.

Official graphify: https://graphify.net | PyPI package: `pip install graphifyy`

---

## Full Protocol (run in order, do not skip steps)

### Step 0.0 — Read Stack Config (do this first)

Use the Read tool to check for a team-maintained stack declaration in the target project:

1. Try **`.github/tech-stack.md`** first
2. If not found, try **`.claude/tech-stack.md`**

**If found:** Hold the full file content as **Stack Config**. This is the authoritative source for stack, framework, test runner, package manager, and any declared compliance domain. No marker-file detection is needed in any later step — Stack Config wins.

**If not found:** Stack Config = none. Continue with Step 0.1 and rely on graphify KG + marker-file inference as before.

Stack Config and KG are complementary: Stack Config declares what the team *chose*, KG shows what is *actually in the codebase*. Both are used together.

---

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

### Step 0.4 — Apply KG Context and Stack Config

Use both KG Context and Stack Config throughout the skill execution:

| Signal | Action |
|---|---|
| Stack Config found | Use declared stack/framework/test-runner directly — no further detection needed |
| Stack Config has compliance domain | Pass that domain to `/compliance` — no auto-detection needed |
| KG shows existing artifact (design doc, test file) | Offer to extend/update it — do not regenerate from scratch |
| KG shows related module or pattern | Reference it in imports, dependencies, design decisions |
| No Stack Config found | Ask the user what stack to use — do not scan marker files |

---

## Per-Skill Focus when reading GRAPH_REPORT.md

| Skill | What to extract |
|---|---|
| orchestrator | Completed phases, existing artifacts, dominant stack |
| requirements | Features or modules related to the requested epic/feature |
| design | Existing design docs (`docs/HLD.md`, `docs/LLD.md`, ADRs), known components |
| coding | Existing modules, patterns, imports used by related code |
| qa | Existing test files, untested modules, risky areas in the report |
| compliance | Sensitive data flows, auth patterns, logging, existing compliance controls |
