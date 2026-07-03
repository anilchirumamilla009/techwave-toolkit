# techwave-dev

This project has the **techwave-dev** plugin installed. It provides AI-assisted skills for every development phase of the SDLC.

## Available skills

Invoke any skill with `/skill-name`:

| Skill | Invoke | What it does |
|---|---|---|
| Orchestrator | `/orchestrator` | Entry point — drives the full dev workflow from a ticket, GitHub issue, or plain text |
| Requirements | `/requirements` | Writes user stories, acceptance criteria, BDD scenarios |
| Design | `/design` | Creates HLD and LLD saved to `docs/`, ADRs, tech-stack evaluations |
| Coding | `/coding [stack]` | Coding Agent → Unit Test Agent → Validator Agent sequential flow |
| Test Plan | `/test-plan` | Test strategy document + runnable test stubs |
| Compliance | `/compliance [domain]` | HIPAA, PCI DSS, GDPR, SOC 2 code-level review |

## Knowledge graph (Step 0)

Every skill automatically builds and reads a project knowledge graph before starting work:
- Installs graphify if not present (`pip install graphifyy`)
- Builds `graphify-out/GRAPH_REPORT.md` if missing (`graphify .`)
- Reads the report for project context before generating any output

This means skills understand your existing codebase — modules, stack, patterns — without scanning every file.

## Typical workflow

```
/orchestrator PROJ-123         — full workflow from a Jira ticket
/requirements login feature    — write stories only
/design create HLD for auth    — design only
/coding nodejs                 — generate code + tests + validation
/test-plan UserService         — test plan + stubs
/compliance health             — HIPAA review
```
