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

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Phase 1. Use Bash and Read tools directly — do not ask the user to run anything.**

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
