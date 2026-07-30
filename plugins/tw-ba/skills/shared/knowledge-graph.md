# Knowledge Graph Protocol (tw-ba)

The `/ba` skill runs this protocol as Step 0 before any analysis, and each phase agent invoked standalone runs it first.
The goal: understand the existing project from its knowledge graph — refreshed to the latest code — before analyzing anything, so BA deliverables build on what exists instead of re-inventing it.

Official graphify: https://graphify.net | PyPI package: `pip install graphifyy==0.9.16` (pinned — bump deliberately, never install unpinned)

---

## Session Cache Rule (check before anything else)

If **Stack Config** and **KG Context** are already loaded in this conversation — because the `/ba` skill or a previously invoked skill completed Step 0 — **reuse them and skip Steps 0.0–0.3 entirely.** Do not re-read `tech-stack.md`, re-check the graphify install, or re-read `GRAPH_REPORT.md`. Re-run Step 0 only if files were written since the context was loaded and the task depends on seeing them (then re-read only `GRAPH_REPORT.md`, not the install/build steps).

**Greenfield skip:** if the target project has no source files yet (empty repo, docs-only, or brand-new product), skip Steps 0.1–0.3 — there is nothing to graph. BA work often precedes code entirely; Stack Config (0.0) and the stated objective are then the only inputs, and that is normal.

**Consent rule:** never install packages, modify `.gitignore`, or run `graphify claude install` without the user's one-time confirmation (Step 0.1). A declined install is remembered for the rest of the conversation — fall back to Stack Config alone and never re-ask.

---

## Full Protocol (run in order, do not skip steps)

### Step 0.0 — Read Stack Config (do this first)

Use the Read tool to check for a team-maintained stack declaration in the target project:

1. Try **`.github/tech-stack.md`** first
2. If not found, try **`.claude/tech-stack.md`**

**If found:** Hold the full file content as **Stack Config**. This is the authoritative source for stack, framework, and any declared `Domain:` or compliance domain (used by Step 0.5 domain detection in the `/ba` skill).

**If not found:** Stack Config = none. Continue with Step 0.1.

Stack Config and KG are complementary: Stack Config declares what the team *chose*, KG shows what is *actually in the codebase*. Both are used together.

---

### Step 0.1 — Ensure graphify is installed (consent-gated)

Use the Bash tool to check:

```bash
command -v graphify
```

If graphify is NOT found, **ask the user first** (one-time):

> graphify (knowledge-graph builder) is not installed. Install `graphifyy==0.9.16` (pinned) and wire it into this project? This also adds `graphify-out/` to `.gitignore` and runs `graphify claude install`. (yes / no)

If **yes**:

```bash
pip install graphifyy==0.9.16 || pip3 install graphifyy==0.9.16
```

Confirm installation succeeded before continuing.

If **no**: skip Steps 0.2–0.3, rely on Stack Config, and do not ask again this conversation.

---

### Step 0.2 — Build or refresh the knowledge graph

Use the Bash tool to check whether the graph exists:

```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || echo "MISSING"
```

If EXISTS — **refresh it before reading** so the report reflects the latest code changes (incremental via the AST cache, typically sub-second):

```bash
graphify .
```

If MISSING (first build — consent-gated by Step 0.1):

```bash
graphify .
graphify claude install
```

Also add `graphify-out/` to `.gitignore` if not already there:

```bash
grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify knowledge graph\ngraphify-out/\n" >> .gitignore
```

---

### Step 0.3 — Read the knowledge graph

Use the Read tool to read `graphify-out/GRAPH_REPORT.md` — **selectively, not exhaustively**. Read the summary/module sections first; if the report is long (> ~300 lines), read only the sections matching the Per-Phase Focus table below rather than the whole file.

Extract and hold as **KG Context** (the extract, not the raw report, is what later steps use):
- Core modules and their stated purpose
- Key entities, flows, and integrations relevant to the objective
- Dominant stack and framework
- Existing artifacts related to what this phase will produce (including prior `docs/ba/` outputs)

Do NOT scan source files to build this understanding. The report is the source of truth.
Only read specific source files if you need detail not present in the report.

---

### Step 0.4 — Apply KG Context and Stack Config

| Signal | Action |
|---|---|
| Stack Config found | Use declared stack/domain directly — no further detection |
| Stack Config has `Domain:` | Feed Step 0.5 domain detection (`/ba` skill) — check `references/domains/` for a match |
| KG shows an existing related feature | Analyze the delta against it — do not re-specify what exists |
| KG shows existing entities/schemas/APIs | Reuse their names and shapes in domain/data deliverables |
| Existing `docs/ba/<feature>/` artifacts | Offer to update them — do not regenerate from scratch |
| No Stack Config, no code | Proceed from the stated objective alone (greenfield BA) |

---

## Per-Phase Focus when reading GRAPH_REPORT.md

| Phase | What to extract |
|---|---|
| ba (skill / orchestration) | Existing `docs/ba/` artifacts, completed phases, dominant stack |
| discovery | Features or modules related to the objective; existing user-facing capabilities |
| domain | Entities, models, and relationships already in the code; naming conventions |
| process | User-facing flows, service boundaries, integrations between modules |
| ux-wireframe | Existing screens/pages/components and navigation structure |
| data | Existing schemas, models, API endpoints, storage layers |
| compliance | Sensitive data flows, auth patterns, logging, existing consent/audit handling |
| functional-spec | Everything the earlier phases held (assembles, does not re-read) |
| knowledge | Artifact inventory across `docs/ba/` |
