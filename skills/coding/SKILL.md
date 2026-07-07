---
name: coding
description: This skill should be used when the user asks to "scaffold a project", "generate boilerplate", "bootstrap a new service", "initialize a codebase", "create project structure", "build a new app", "set up project skeleton", "generate a new app", "write the code for", "implement this feature", "create the folder structure", or "start a new project". Drives a sequential multi-agent flow — single-stack or fullstack with an OpenAPI contract.
version: 0.3.0
disable-model-invocation: true
user-invocable: true
---

# Coding Skill — Multi-Agent Flow

**Single-stack:**
```
[Coding Agent] → [Unit Test Agent] → [Validator Agent]
```

**Fullstack** (when `tech-stack.md` has both Frontend and Backend sections):
```
[Contract Agent] → [UI Coding Agent] → [UI Test Agent]
                ↘                                      ↘
                  [Backend Coding Agent] → [Backend Test Agent] → [Validator Agent]
```

Each agent runs to completion before the next begins. Load each agent file when its phase starts.

---

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Phase 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — this is authoritative for stack and test runner; skip marker-file detection in all later steps.

**0.1 Install graphify if missing**
```bash
command -v graphify || pip install graphifyy || pip3 install graphifyy
```

**0.2 Build the graph if missing**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || (graphify . && graphify claude install && grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore)
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing modules and their patterns, imports used by related code, dominant stack and framework, any existing code related to `$ARGUMENTS`. Pass as **KG Context** to the Coding Agent — Unit Test and Validator agents inherit it automatically.

Full protocol: `../shared/knowledge-graph.md`

---

## Mode Detection

Determined from Stack Config only — check immediately after Step 0.0 loads the Stack Config:

| Stack Config content | Mode |
|---|---|
| Has both `## Frontend` and `## Backend` sections | **Fullstack** |
| Has only one section (`## Frontend` or `## Backend`) | **Single-stack** (use declared stack) |
| No `tech-stack.md` found | **Single-stack** (fall back to `$ARGUMENTS` / marker files) |

---

## Agent Definitions

| Agent | File | Mode | Responsibility |
|---|---|---|---|
| Coding Agent | `agents/coding-agent.md` | Single-stack | Detect stack, confirm structure, write all code |
| Unit Test Agent | `agents/test-agent.md` | Single-stack | Write idiomatic test files |
| Contract Agent | `agents/contract-agent.md` | Fullstack | Write `openapi.yaml` — user confirms before writing |
| UI Coding Agent | `agents/ui-coding-agent.md` | Fullstack | Generate frontend code from the OpenAPI spec |
| Backend Coding Agent | `agents/backend-coding-agent.md` | Fullstack | Generate backend handlers implementing the spec |
| UI Test Agent | `agents/ui-test-agent.md` | Fullstack | Component tests + API client tests for frontend |
| Backend Test Agent | `agents/backend-test-agent.md` | Fullstack | Route integration + service unit tests for backend |
| Validator Agent | `agents/validator-agent.md` | Both | Pass/fail verdict across all dimensions |

---

## Single-Stack Execution Order

### Phase 1
Load `agents/coding-agent.md` and run it to completion.
Do not proceed to Phase 2 until the Coding Agent announces handoff.

### Phase 2
Load `agents/test-agent.md` and run it to completion.
Do not proceed to Phase 3 until the Unit Test Agent announces handoff.

### Phase 3
Load `agents/validator-agent.md` and run it to completion.
The Validator Agent's verdict is the final output.

---

## Fullstack Execution Order

### Phase 0 — Contract
Load `agents/contract-agent.md` and run it to completion.
Do not proceed until Contract Agent writes `openapi.yaml` and announces handoff.

### Phase 1A — UI Coding
Load `agents/ui-coding-agent.md` and run it to completion.
UI Coding Agent reads `openapi.yaml` and generates all frontend code.
Do not proceed to Phase 1B until UI Coding Agent announces handoff.

### Phase 1B — Backend Coding
Load `agents/backend-coding-agent.md` and run it to completion.
Backend Coding Agent reads `openapi.yaml` and implements every route handler.
Do not proceed to Phase 2A until Backend Coding Agent announces handoff.

### Phase 2A — UI Tests
Load `agents/ui-test-agent.md` and run it to completion.

### Phase 2B — Backend Tests
Load `agents/backend-test-agent.md` and run it to completion.
Do not proceed to Phase 3 until Backend Test Agent announces handoff.

### Phase 3 — Validation
Load `agents/validator-agent.md` and run it to completion.
Validator checks both layers + contract conformance.
The Validator Agent's verdict is the final output.

---

## Key Rules

- No agent writes any file until it receives explicit user confirmation for its own layer
- Each agent announces its start and handoff — the user can follow the flow
- Contract Agent confirmation is separate from coding agent confirmations — three gates total in fullstack mode
- Context (KG, Stack Config, openapi.yaml location) passes forward to all agents automatically
- Validator must never downgrade a hardcoded secret to MED or LOW severity
