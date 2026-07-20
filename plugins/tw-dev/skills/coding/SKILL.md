---
name: coding
description: Use when the user asks to "scaffold a project", "generate boilerplate", "create project structure", "write the code for", "implement this feature", "build a CLI tool", "create a library", "scaffold a mobile app", or "start a new project". Multi-agent flow for any project type (web, API, CLI, library, mobile, desktop, data/ML, infra) — single or multi-component with an interface contract.
version: 0.5.0
disable-model-invocation: true
user-invocable: true
---

# Coding Skill — Multi-Agent Flow

Works for **any project type**: web app, API service, CLI tool, library/SDK, mobile app, desktop app, data pipeline, ML project, infrastructure-as-code, embedded. The flow adapts to how many components the project has, not to what kind of software it is.

**Single-component** (one deliverable — a service, a CLI, a library, a pipeline, ...):
```
[Coding Agent] → [Unit Test Agent] → [Validator Agent]
```

**Fullstack web** (when `tech-stack.md` has exactly `## Frontend` and `## Backend` sections):
```
[Contract Agent] → [UI Coding Agent] → [UI Test Agent]
                ↘                                      ↘
                  [Backend Coding Agent] → [Backend Test Agent] → [Validator Agent]
```

**Multi-component** (any other combination of 2+ sections — e.g. Mobile + Backend, CLI + Library, Pipeline + API):
```
[Contract Agent] → for each component: [Coding Agent] → [Unit Test Agent]
                                                              ↘
                                                        [Validator Agent]
```

Each agent runs to completion before the next begins. Load each agent file when its phase starts.

---

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Phase 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation (the orchestrator or a prior skill ran Step 0), reuse them and skip 0.0–0.3 — do not re-read or re-run anything.

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — this is authoritative for stack and test runner; skip marker-file detection in all later steps.

**0.1 Ensure graphify (consent-gated)**
```bash
command -v graphify
```
Missing → ask the user once: install `graphifyy==0.9.16` (pinned) and wire it into this project (`.gitignore` entry, `graphify claude install`)? If yes: `pip install graphifyy==0.9.16 || pip3 install graphifyy==0.9.16`. If declined: skip 0.2–0.3, use Stack Config + marker files, do not ask again this conversation.

**0.2 Build or refresh the graph**
```bash
if [ -f graphify-out/GRAPH_REPORT.md ]; then graphify .; else graphify . && graphify claude install && { grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore; }; fi
```
Existing graph → refreshed incrementally (AST cache, sub-second) so 0.3 reads current code. Missing → first build, consent-gated by 0.1.

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing modules and their patterns, imports used by related code, dominant stack and framework, any existing code related to `$ARGUMENTS`. Pass as **KG Context** to the Coding Agent — Unit Test and Validator agents inherit it automatically.

Full protocol: `../shared/knowledge-graph.md`

---

## Mode Detection

Determined from Stack Config only — check immediately after Step 0.0 loads the Stack Config. Any `## <Section>` heading in `tech-stack.md` (other than `## Notes`) counts as a **component** — `## Frontend`, `## Backend`, `## Mobile`, `## CLI`, `## Library`, `## Data Pipeline`, `## ML`, `## Desktop`, `## Infrastructure`, or anything else the team declares.

| Stack Config content | Mode |
|---|---|
| Exactly `## Frontend` + `## Backend` | **Fullstack web** (specialized UI/Backend agents) |
| Any other combination of 2+ component sections | **Multi-component** (generic contract + per-component agents) |
| Exactly one component section | **Single-component** (use declared stack) |
| No `tech-stack.md` found | **Single-component** (fall back to `$ARGUMENTS` / marker files / one question) |

---

## Agent Definitions

| Agent | File | Mode | Responsibility |
|---|---|---|---|
| Coding Agent | `agents/coding-agent.md` | Single-component, Multi-component | Determine stack + project type, confirm structure, write all code |
| Unit Test Agent | `agents/test-agent.md` | Single-component, Multi-component | Write idiomatic test files |
| Contract Agent | `agents/contract-agent.md` | Fullstack web, Multi-component | Write the interface contract (OpenAPI / GraphQL / proto / AsyncAPI / interface doc) — user confirms before writing |
| UI Coding Agent | `agents/ui-coding-agent.md` | Fullstack web | Generate frontend code from the OpenAPI spec |
| Backend Coding Agent | `agents/backend-coding-agent.md` | Fullstack web | Generate backend handlers implementing the spec |
| UI Test Agent | `agents/ui-test-agent.md` | Fullstack web | Component tests + API client tests for frontend |
| Backend Test Agent | `agents/backend-test-agent.md` | Fullstack web | Route integration + service unit tests for backend |
| Validator Agent | `agents/validator-agent.md` | All | Pass/fail verdict across all dimensions |

---

## Single-Component Execution Order

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

## Fullstack Web Execution Order

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

## Multi-Component Execution Order

For any 2+ component combination other than Frontend+Backend (e.g. Mobile + Backend, CLI + Library, Data Pipeline + API).

### Phase 0 — Contract
Load `agents/contract-agent.md` and run it to completion. The agent picks the contract format that matches how the components talk to each other (OpenAPI for REST, GraphQL SDL, `.proto` for gRPC, AsyncAPI for events/queues, or a plain interface doc for in-process/library boundaries). Skip this phase only if the components genuinely share no interface — confirm that with the user first.

### Phase 1..N — Per Component
For each component section in Stack Config, in dependency order (providers before consumers):
1. Load `agents/coding-agent.md` scoped to that component's directory and declared stack. The agent reads the contract and implements this component's side of it.
2. Load `agents/test-agent.md` scoped to the same component.

Do not start the next component until the current one's test agent announces handoff.

### Final Phase — Validation
Load `agents/validator-agent.md` and run it to completion.
Validator checks every component + conformance to the contract written in Phase 0.
The Validator Agent's verdict is the final output.

---

## Token Efficiency Rules

Multi-agent flows burn tokens fast; these rules keep the cost proportional to the work:

- **Lazy-load everything.** Load exactly one agent file — the current phase's — and unload the mental model of finished phases. Never preload later agents. Load at most one stack reference per component (the matching file, or `generic.md`) — never several speculatively.
- **Never echo written files into chat.** After writing, report the directory tree, file count, and notable decisions — not file bodies. The user can open the files; repeating them doubles the cost of every generated line.
- **Confirmation gates show plans, not products.** Trees + one-line key-file purposes for structure; a condensed operation table for large contracts (see contract agent). Full content only when the user asks.
- **Delegate bulk generation to a subagent (Claude Code only).** After the user confirms a component's structure, the mechanical file-writing may run in a subagent (Agent/Task tool) carrying only: the confirmed tree, the contract, the component's Stack Config section, and the relevant KG extract. Only its summary (files written, decisions, open issues) returns to the main conversation — the generation churn never lands in the main context. Run inline instead when the flow needs mid-generation user input or the CLI has no subagent support (Copilot).
- **Pass extracts, not raw artifacts.** Agents receive the KG *extract* and the contract's operation list — not the full `GRAPH_REPORT.md` or re-pasted specs the conversation already contains.

---

## Key Rules

- No agent writes any file until it receives explicit user confirmation for its own component
- Each agent announces its start and handoff — the user can follow the flow
- Contract Agent confirmation is separate from coding agent confirmations — it is its own gate in fullstack and multi-component modes
- Context (KG, Stack Config, contract file location) passes forward to all agents automatically
- A stack with no matching file in `references/stacks/` is never a blocker — agents follow `references/stacks/generic.md` and the ecosystem's own conventions
- Validator must never downgrade a hardcoded secret to MED or LOW severity
