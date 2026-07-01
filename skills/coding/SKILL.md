---
name: coding
description: This skill should be used when the user asks to "scaffold a project", "generate boilerplate", "bootstrap a new service", "initialize a codebase", "create project structure", "build a new app", "set up project skeleton", "generate a new app", "write the code for", "implement this feature", "create the folder structure", or "start a new project". Drives a sequential Coding Agent → Unit Test Agent → Validator Agent flow.
version: 0.2.0
disable-model-invocation: true
---

# Coding Skill — Multi-Agent Sequential Flow

```
[Coding Agent] → [Unit Test Agent] → [Validator Agent]
```

Each agent runs to completion before the next begins. Context passes forward automatically. Load each agent file when its phase starts.

---

## Step 0 — Knowledge Graph Check

Load `../shared/knowledge-graph.md` for the full protocol. Summary:

1. If `graphify-out/graph.json` exists → run `bash scripts/query-kg.sh "<stack + feature/module name from $ARGUMENTS>"`
2. If missing → run `bash scripts/setup-kg.sh` first, then query
3. Inject results as KG Context (existing modules, patterns, dependencies) before Phase 1

KG Context is passed to the Coding Agent. The Unit Test and Validator agents inherit it automatically.

---

## Agent Definitions

| Agent | File | Responsibility |
|---|---|---|
| Coding Agent | `agents/coding-agent.md` | Detect stack, confirm structure, write all code files |
| Unit Test Agent | `agents/test-agent.md` | Read generated code, write idiomatic test files |
| Validator Agent | `agents/validator-agent.md` | Review code + tests, produce pass/fail verdict |

---

## Execution Order

### Phase 1
Load `agents/coding-agent.md` and run it to completion.
Do not proceed to Phase 2 until the Coding Agent announces handoff.

### Phase 2
Load `agents/test-agent.md` and run it to completion.
Do not proceed to Phase 3 until the Unit Test Agent announces handoff.

### Phase 3
Load `agents/validator-agent.md` and run it to completion.
The Validator Agent's verdict is the final output of this skill.

---

## Key Rules

- No agent writes files until the Coding Agent receives explicit user confirmation
- Each agent announces its start and handoff — the user can follow the flow
- Context from earlier agents (stack, files written, risk level) is carried into later agents
- Validator must never downgrade a hardcoded secret to MED or LOW severity
