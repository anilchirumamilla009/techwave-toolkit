# tw-dev

A Claude Code plugin providing AI-assisted skills for the development phases of the SDLC. Tech-stack agnostic — works with Node.js, Python, Go, Java, Rust, .NET, React, and more.

**Version:** 0.6.0 · **License:** MIT · **Author:** Venkata Anil Kumar Chirumamilla

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Tech Stack Config](#tech-stack-config)
- [Knowledge Graph](#knowledge-graph)
- [Plugin Management](#plugin-management)
- [Skills Reference](#skills-reference)
  - [Orchestrator](#orchestrator--start-here)
  - [Requirements](#requirements)
  - [Design](#design)
  - [Coding](#coding)
  - [QA Strategy](#qa-strategy)
  - [Compliance](#compliance)
- [Hooks and Compliance Scanning](#hooks-and-compliance-scanning)
- [MCP Server Configuration](#mcp-server-configuration)
- [Plugin Structure](#plugin-structure)
- [How Skills Work](#how-skills-work)
- [Contributing](#contributing)

---

## Overview

**tw-dev** wraps the development phases of the SDLC into a Claude Code plugin. Instead of juggling separate tools, you drive the full dev workflow — from raw requirements through compliance — from a single Claude Code session.

### What it does

- Converts Jira tickets, Confluence pages, GitHub issues, or plain text into structured requirements
- Generates architecture diagrams (Mermaid), ADRs, and tech-stack evaluations saved to `docs/`
- Scaffolds fullstack monorepos (frontend + backend) from an OpenAPI contract using a multi-agent flow
- Generates E2E scenarios, acceptance mapping, test data strategy, and performance plans
- Reviews code against HIPAA, PCI DSS v4.0, GDPR, and SOC 2 controls
- Scans every file write for hardcoded credentials and PII in logs via a background hook

### Skill map

| Command | Phase | Description |
|---|---|---|
| `/orchestrator` | Entry point | Accepts a ticket, page, issue, or plain text — drives all dev phases in sequence |
| `/requirements` | Requirements | User stories, acceptance criteria, BDD scenarios, epic breakdown |
| `/design` | Architecture | Mermaid diagrams saved to `docs/`, ADRs, tech-stack evaluation |
| `/coding` | Development | Single-stack or fullstack (Contract → UI + Backend → Tests → Validator) |
| `/qa` | QA Strategy | E2E scenarios (Playwright), acceptance mapping, test data, performance plan |
| `/compliance [domain]` | Compliance | HIPAA, PCI DSS, GDPR, SOC 2 code-level review |

---

## Prerequisites

- **bash** available in `PATH` — required by the compliance-scan hook
- **Python + pip** — required by Step 0 to install graphify (`pip install graphifyy`)
- **jq** (optional but recommended) — used by the hook to parse file paths from tool events
- Either **Claude Code CLI** or **GitHub Copilot CLI** (or both)

---

## Installation

This plugin works with both **Claude Code CLI** and **GitHub Copilot CLI**. The skill content is identical — only the install command differs.

### Claude Code CLI

```bash
# Step 1 — register the GitHub repo as a marketplace
claude plugin marketplace add anilchirumamilla009/techwave-toolkit

# Step 2 — install the plugin
claude plugin install tw-dev@techwave
```

To update:

```bash
claude plugin marketplace update techwave
claude plugin update tw-dev
```

### GitHub Copilot CLI

```bash
# Step 1 — register the GitHub repo as a marketplace
copilot plugin marketplace add anilchirumamilla009/techwave-toolkit

# Step 2 — install the plugin
copilot plugin install tw-dev@techwave
```

To update:

```bash
copilot plugin marketplace update techwave
copilot plugin update tw-dev
```

---

## Tech Stack Config

Create a single `tech-stack.md` file in your target project's `.github/` folder (or `.claude/`). Every skill reads it automatically at Step 0 — no repeated stack detection, no questions about your framework.

```
your-project/
└── .github/
    └── tech-stack.md    ← checked first
```

### Format

```markdown
# Tech Stack

## Frontend
- Framework: React 18 + TypeScript
- Build tool: Vite
- Test runner: Vitest + React Testing Library
- Package manager: pnpm

## Backend
- Language: Node.js (TypeScript)
- Framework: Express 4
- Test runner: Jest + Supertest
- Package manager: pnpm

## Notes
- Monorepo tool: pnpm workspaces
- CI: GitHub Actions
- Compliance domain: hipaa
```

Plain markdown — no YAML or strict schema required. Add any sections your team needs (Database, Infrastructure, etc.).

### Mode detection for `/coding`

| `tech-stack.md` content | Mode |
|---|---|
| Has both `## Frontend` and `## Backend` sections | **Fullstack** — Contract Agent → UI + Backend Agents |
| Has only one section | **Single-stack** — uses declared stack directly |
| File not present | Skills ask one plain-English question before proceeding |

### What each skill uses it for

| Skill | How it uses Stack Config |
|---|---|
| `/coding` | Reads stack and test runner directly — no file scanning |
| `/qa` | Picks the right E2E framework and test runner per layer |
| `/orchestrator` | Populates stack signals and compliance domain in the requirement struct |
| `/design` | Skips tech-stack-gathering questions — uses declared stack directly |
| `/compliance` | Reads `Compliance domain:` from Notes — no auto-detection needed |

The `Compliance domain:` note in the `Notes` section (e.g. `hipaa`, `pci`, `gdpr`, `soc2`) tells `/compliance` which standard to check against automatically.

---

## Knowledge Graph

Every skill runs a fully automatic **Step 0** before its main logic. No manual setup is needed — invoking any skill for the first time in a project handles everything automatically.

### What happens on first invocation

```
/coding  (or any skill)
  │
  ├─ 0.0  Read .github/tech-stack.md (or .claude/tech-stack.md)
  │         Found → hold as Stack Config; skip all detection
  │         Not found → ask user when stack is needed
  │
  ├─ 0.1  Is graphify installed?
  │         NO  → pip install graphifyy
  │         YES → continue
  │
  ├─ 0.2  Does graphify-out/GRAPH_REPORT.md exist?
  │         NO  → graphify .  (builds knowledge graph)
  │              graphify claude install
  │              adds graphify-out/ to .gitignore
  │         YES → continue
  │
  └─ 0.3  Read graphify-out/GRAPH_REPORT.md
            extracts: modules, stack, existing artifacts relevant to this skill
            proceeds with full project context
```

From the second invocation onwards, graphify is already installed and the graph already exists — Step 0 completes in under a second.

### What graphify produces

| File | Contents |
|---|---|
| `graphify-out/GRAPH_REPORT.md` | Human-readable summary — core modules, key entities. Read by every skill. |
| `graphify-out/graph.json` | Full NetworkX graph — functions, classes, imports, call edges |
| `graphify-out/graph.html` | Interactive visualization (open in browser) |
| `graphify-out/cache/` | Incremental AST cache — rebuilt automatically after each commit |

To force a full rebuild at any time: `graphify .`

---

## Plugin Management

Commands are identical between the two CLIs — just swap `claude` for `copilot`.

### Claude Code CLI

```bash
claude plugin list                          # list installed plugins
claude plugin details tw-dev               # show skill details
claude plugin marketplace update techwave  # fetch latest from GitHub
claude plugin update tw-dev                # apply the update
claude plugin disable tw-dev               # disable without uninstalling
claude plugin enable tw-dev                # re-enable
claude plugin uninstall tw-dev             # remove completely
claude plugin validate .                   # validate from plugin root
```

### GitHub Copilot CLI

```bash
copilot plugin list
copilot plugin details tw-dev
copilot plugin marketplace update techwave
copilot plugin update tw-dev
copilot plugin disable tw-dev
copilot plugin enable tw-dev
copilot plugin uninstall tw-dev
copilot plugin validate .
```

---

## Skills Reference

---

## Orchestrator — Start Here

The orchestrator is the single entry point for the full SDLC workflow. Give it any form of requirement and it drives each phase in sequence, asking for your approval at each boundary.

### How to invoke

```
/orchestrator PROJ-123
/orchestrator DEV-456
/orchestrator https://github.com/org/repo/issues/42
/orchestrator https://wiki.company.com/wiki/spaces/ENG/pages/123456/Feature+Design
/orchestrator "User Authentication Design"
/orchestrator Build a JWT authentication module with refresh token support
/orchestrator <paste full Jira ticket body here>
```

### Accepted input formats

| Format | Example |
|---|---|
| Jira ticket ID | `PROJ-123`, `DEV-456` |
| Confluence URL | `https://*/wiki/spaces/*/pages/*` |
| Confluence page title (quoted) | `"User Authentication Design"` |
| GitHub issue URL | `https://github.com/org/repo/issues/42` |
| Linear ticket | `ENG-123` (requires Linear MCP) |
| Plain text | Any feature brief, PRD excerpt, or requirement |
| Pasted content | Raw Jira/Confluence/GitHub body pasted into chat |

### What happens step by step

**Step 1 — Parse the input.**
The orchestrator detects the input type and either fetches content via MCP (if a matching MCP server is configured) or asks you to paste the content. It normalises the input into a structured requirement struct and asks for your confirmation before proceeding.

**Step 2 — Detect what already exists.**
The orchestrator scans the project for existing artefacts (source directories, test files, design docs) and skips phases whose outputs are already present.

**Step 3 — Propose the sequence.**
Based on what exists, it proposes only the missing phases:

```
New feature:           /requirements → /design → /coding → /qa → /compliance
Code exists, no tests: /qa → /compliance
Bug ticket:            /requirements (bug story) → /coding → /qa
```

**Step 4 — Drive each phase.**
For each phase: announces start → invokes the skill with full requirement context → shows a brief summary → asks `Continue to Phase N+1? (yes / skip / stop)`.

**Step 5 — Final summary.**
Prints a completion table listing completed phases, what was produced, and suggested next steps.

### Key rules

- The orchestrator never generates artefacts itself — it coordinates skills; they produce outputs.
- It always confirms the parsed requirement before starting any phase.
- It always asks `Continue?` between phases — it never skips silently.
- Context (title, domain, stack signals) is carried forward to every skill so output is coherent across phases.

---

## Requirements

Transforms raw ideas, features, or epics into structured, behavior-first requirements artefacts.

### How to invoke

```
/requirements write user stories for a user login feature
/requirements break down the epic: "User Profile Management"
/requirements define acceptance criteria for the checkout flow
/requirements write BDD scenarios for password reset
/requirements capture requirements for real-time notifications
```

### What it produces

1. **Epic statement** (if applicable)
2. **User stories** in As a / I want / So that format
3. **Acceptance criteria** — testable Given/When/Then bullets for each story
4. **BDD scenarios** (when the feature has complex branching)
5. **Technical Notes** — constraints the dev team needs (never implementation choices)
6. **Out of Scope** — explicit list of what this story does NOT cover

### Story sizing

| Size | Effort |
|---|---|
| XS | Less than 1 day |
| S | 1–2 days |
| M | 3–5 days |
| L | 1–2 weeks — flag for breakdown |

### Key rules

- Stories describe observable outcomes, not database tables or API calls.
- Acceptance criteria must be verifiable true/false by a QA engineer.
- Implementation details go in Technical Notes only — never in story body.
- When input is incomplete, drafts requirements using `[Assumed]` tags, then asks one consolidating question.

---

## Design

Produces text-based system design artefacts: architecture diagrams, ADRs, tech-stack evaluations, and component designs.

### How to invoke

```
/design create a C4 container diagram for a payments service
/design write an ADR for choosing PostgreSQL over MongoDB
/design recommend a tech stack for a real-time chat app
/design draw a sequence diagram for the order checkout flow
/design create an ER diagram for the user management module
/design design the system for a healthcare data ingestion pipeline
```

### Artifact type routing and output location

| User says | Artifact | Saved to |
|---|---|---|
| "HLD", "high-level design", "system design" | C4 Context + Container + narrative | `docs/HLD.md` |
| "LLD", "low-level design", "component diagram" | Component / class / sequence + API contracts | `docs/LLD.md` |
| "sequence diagram", "flow" | Mermaid `sequenceDiagram` | `docs/LLD.md` |
| "ER diagram", "data model" | Mermaid `erDiagram` | `docs/LLD.md` |
| "ADR", "architecture decision" | Nygard ADR | `docs/ADR-NNN-<title>.md` |
| "tech stack", "which technology" | Evaluation matrix + recommendation | inline only |

### Key rules

- Always write HLD and LLD to `docs/` — never leave design artifacts in chat only.
- Confirm planned file paths with the user before writing anything.
- Diagrams are Mermaid text only — renders on GitHub, Notion, and most editors.
- ADR filenames are auto-incremented (`ADR-001`, `ADR-002`, ...).

---

## Coding

Drives a multi-agent sequential flow from stack detection through validation. The mode is determined automatically from `tech-stack.md`.

### How to invoke

```
/coding        # reads tech-stack.md — fullstack or single-stack depending on content
```

If no `tech-stack.md` is present, the skill asks one question: what stack to scaffold.

### Supported stacks

Node.js + TypeScript · Python + FastAPI · Go + Gin · Java + Spring Boot · Rust + Axum · .NET 8 + ASP.NET Core · React + Vite · Next.js · Vue · SvelteKit

### Single-stack mode

Triggered when `tech-stack.md` has only one section (Frontend or Backend).

```
[Coding Agent] → [Unit Test Agent] → [Validator Agent]
```

1. **Coding Agent** — reads Stack Config, confirms the planned directory tree, then writes all application code
2. **Unit Test Agent** — reads the generated code, selects the idiomatic test framework from Stack Config, writes test stubs with coverage targets (90%+ auth/payments, 80%+ APIs)
3. **Validator Agent** — pass/fail verdict across Correctness, Security, and Test Quality

### Fullstack mode

Triggered when `tech-stack.md` has both `## Frontend` and `## Backend` sections. Both frontend and backend code are placed under the **same parent repository** as a monorepo.

```
[Contract Agent]
       │
       ├─ establishes monorepo structure (frontend/ + backend/ + docs/ + docker-compose.yml)
       └─ writes docs/openapi.yaml after user confirms the contract
              │
   ┌──────────┴──────────┐
   │                     │
[UI Coding Agent]   [Backend Coding Agent]
frontend/           backend/
       │                     │
[UI Test Agent]     [Backend Test Agent]
       └──────────┬──────────┘
                  │
          [Validator Agent]
          (checks both layers + contract conformance)
```

**Contract Agent** — proposes the monorepo directory layout, then drafts `openapi.yaml`. Waits for explicit user confirmation before writing any file.

**UI Coding Agent** — reads `openapi.yaml`, writes all frontend code under `frontend/`. Generates a typed API client (one function per `operationId`), components, pages, and routing.

**Backend Coding Agent** — reads `openapi.yaml`, writes all backend code under `backend/`. Generates route handlers for every path in the spec, middleware, and a service layer.

**UI / Backend Test Agents** — each reads their layer's generated code and the Stack Config `Test runner:` line. Generates component tests + API client tests (UI) and route integration tests + service unit tests (Backend).

**Validator Agent** — reviews both layers and checks contract conformance (every `operationId` in the spec must have a backend handler and a frontend client function).

### Key rules

- No agent writes any file until it receives explicit user confirmation for its own planning step
- Three confirmation gates in fullstack mode: monorepo structure → openapi spec → code structure per layer
- Hardcoded secrets are always HIGH severity in the Validator report
- Generated code is immediately runnable — no `TODO` in production code paths

---

## QA Strategy

Generates the testing layers that sit above unit and integration stubs. If `/coding` has already run, `/qa` detects existing test files and focuses only on what is missing.

### How to invoke

```
/qa checkout flow       # E2E scenarios for a specific feature
/qa login feature       # acceptance scenarios + Playwright stubs
/qa payments API        # E2E + performance plan for a critical path
/qa                     # full QA strategy for the current codebase
```

### What it produces

| Output | Description |
|---|---|
| E2E stubs | Playwright `.ts` files — one file per journey group |
| Acceptance scenarios | Given/When/Then in domain language, mapped from requirements |
| Test data strategy | Fixtures, factory stubs, seed script outline |
| Performance plan | k6/Locust/Artillery scenarios + latency/throughput targets |
| Accessibility checklist | WCAG 2.1 AA automated (axe-core) + manual checks |
| QA strategy document | Full test pyramid for this feature, CI stage assignment |

### Division of labour with `/coding`

| Layer | Generated by |
|---|---|
| Unit test stubs | `/coding` — Unit Test Agent or Backend Test Agent |
| Route integration stubs | `/coding` — Backend Test Agent |
| Component + API client tests | `/coding` — UI Test Agent |
| **E2E scenarios (Playwright)** | **`/qa`** |
| **Acceptance mapping (Given/When/Then)** | **`/qa`** |
| **Test data strategy** | **`/qa`** |
| **Performance plan** | **`/qa`** |
| **Accessibility checklist** | **`/qa`** |

### E2E journey selection

Always included: authentication, primary value action, payment/subscription flow (if applicable).
Included when relevant: data creation/deletion, admin or privileged actions, data export/import.

### Key rules

- Never regenerates unit or integration stubs when `/coding` already produced them
- E2E test names describe the user's observable outcome — no implementation references
- Acceptance scenarios are in domain language — no code, no class names
- Test data factories generate unique data per test run — no shared mutable state

---

## Compliance

Reviews a codebase against domain-specific regulatory requirements and produces a structured pass/fail checklist with code-level remediation guidance.

### How to invoke

```
/compliance health      # HIPAA technical safeguards review
/compliance finance     # PCI DSS v4.0 code controls
/compliance eu          # GDPR consent, erasure, portability
/compliance soc2        # SOC 2 CC6/7/8 controls
/compliance             # auto-detects domain from codebase signals
```

### Domain routing

| Arguments | Standard | Reference |
|---|---|---|
| `health`, `hipaa`, `healthcare`, `phi`, `medical` | HIPAA 45 CFR 164.312 | `references/hipaa.md` |
| `finance`, `pci`, `pci-dss`, `payment`, `fintech`, `card` | PCI DSS v4.0 | `references/pci-dss.md` |
| `eu`, `gdpr`, `privacy`, `europe`, `personal-data` | GDPR | `references/gdpr.md` |
| `general`, `soc2`, `soc`, `cloud`, `startup`, `saas` | SOC 2 | `references/soc2.md` |

If `Compliance domain:` is declared in `tech-stack.md` Notes, that domain is used directly — no auto-detection needed.

### Compliance report structure

```
## Compliance Review: [Domain] ([Standard])

### Summary
  Total controls reviewed: N  |  Passing: N ✓  |  Failing: N ✗

### Control Checklist

| Control | Status | Evidence / Location |
|---|---|---|
| Encrypt data at rest | ✓ Pass   | src/db/config.ts:42 |
| No hardcoded credentials | ✗ Fail   | src/auth/service.ts:17 |
| MFA for admin access | ⚠ Manual | needs runtime verification |

### Remediation Guidance

#### [Failing Control]
Issue: [what is wrong and why it violates the standard]
Fix:   [specific before/after code pattern]
Effort: Low / Medium / High
```

### Key rules

- A control is only marked Pass when specific code evidence (file and line) is cited.
- Controls requiring runtime or infrastructure verification are marked Manual — not Pass.
- All findings are engineering recommendations — never legal advice.

---

## Hooks and Compliance Scanning

The plugin registers a `PostToolUse` hook that runs automatically after every file write. The hook scans the modified file for security and compliance issues.

### What the hook scans for

| Pattern | Example |
|---|---|
| Hardcoded credentials | `password = "mysecret"`, `api_key: "abc123"` |
| PII passed to logging | `console.log(user.ssn)`, `print(f"DOB: {date_of_birth}")` |
| Embedded cloud access keys | AWS `AKIA...` format key IDs |

### Hook behavior

| Condition | Behavior |
|---|---|
| File is clean | Exits silently (exit 0) |
| Issue detected | Emits a warning to stderr, exits with code 1 |
| Binary file | Skipped automatically |
| File larger than 500 KB | Skipped (stays within 5-second hook timeout) |
| `jq` not installed | Falls back to `CLAUDE_TOOL_FILE_PATH` env variable |

### Example warning output

```
[tw-dev] WARNING: Possible hardcoded credential detected in src/config.ts. Use environment variables or a secrets manager instead.
[tw-dev] WARNING: Possible PII in log statement detected in src/service/user.ts. Remove PII from logs or use pseudonymization.
[tw-dev] WARNING: Possible AWS Access Key ID detected in scripts/deploy.sh. Revoke and rotate this key immediately.
```

---

## MCP Server Configuration

The `/orchestrator` skill auto-fetches ticket and page content when a matching MCP server is connected. Without an MCP server, it falls back to asking you to paste the content.

### Jira

```bash
claude mcp add --transport http jira https://your-jira-mcp-url
```

### Confluence

```bash
claude mcp add --transport http confluence https://your-confluence-mcp-url
```

### GitHub

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/v1
```

### Linear

```bash
claude mcp add --transport http linear https://your-linear-mcp-url
```

The orchestrator tries multiple tool name variants for each source (e.g. `mcp__jira__getIssue`, `mcp__jira__get_issue`). If no MCP is detected, it always provides a paste fallback — it never aborts.

---

## Plugin Structure

```
techwave-toolkit/
├── .claude-plugin/
│   ├── plugin.json                     # Plugin manifest (name: tw-dev, version, author)
│   └── marketplace.json                # Marketplace listing
├── .github/
│   └── copilot-instructions.md         # GitHub Copilot CLI context
├── skills/
│   ├── shared/
│   │   └── knowledge-graph.md          # Step 0 protocol shared by all skills
│   ├── orchestrator/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── mcp-sources.md          # Known MCP tool name variants per source
│   ├── requirements/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── story-templates.md      # User story + Jira/Linear field templates
│   │       └── bdd-patterns.md         # Idiomatic Given/When/Then patterns by domain
│   ├── design/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── adr-template.md         # Nygard ADR format with worked examples
│   │       ├── diagram-formats.md      # Mermaid syntax starters per diagram type
│   │       └── tech-stack-evaluation.md # Scoring matrix — backend, DB, frontend, deploy
│   ├── coding/
│   │   ├── SKILL.md                    # Mode detection + agent execution order
│   │   ├── agents/
│   │   │   ├── coding-agent.md         # Single-stack: reads Stack Config, writes code
│   │   │   ├── test-agent.md           # Single-stack: writes unit test stubs
│   │   │   ├── contract-agent.md       # Fullstack: proposes monorepo structure + openapi.yaml
│   │   │   ├── ui-coding-agent.md      # Fullstack: generates frontend/ from openapi.yaml
│   │   │   ├── backend-coding-agent.md # Fullstack: generates backend/ from openapi.yaml
│   │   │   ├── ui-test-agent.md        # Fullstack: component + API client tests
│   │   │   ├── backend-test-agent.md   # Fullstack: route integration + service unit tests
│   │   │   └── validator-agent.md      # Both modes: correctness / security / test quality verdict
│   │   └── references/
│   │       └── stacks/
│   │           ├── nodejs.md           # Node.js + TypeScript + Express scaffold
│   │           ├── python.md           # Python + FastAPI + Poetry scaffold
│   │           ├── go.md               # Go + Gin scaffold
│   │           ├── java.md             # Java + Spring Boot scaffold
│   │           ├── react.md            # React + Vite + TypeScript scaffold
│   │           ├── rust.md             # Rust + Axum scaffold
│   │           └── dotnet.md           # .NET 8 + ASP.NET Core Web API scaffold
│   ├── qa/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── frameworks.md           # Playwright config, k6 stubs, axe-core integration
│   │       └── test-types.md           # Testing pyramid ownership, E2E patterns, CI assignment
│   └── compliance/
│       ├── SKILL.md
│       └── references/
│           ├── hipaa.md                # HIPAA 45 CFR 164.312 code controls
│           ├── pci-dss.md              # PCI DSS v4.0 code controls
│           ├── gdpr.md                 # GDPR consent, erasure, portability controls
│           └── soc2.md                 # SOC 2 CC6/7/8 controls
├── hooks/
│   ├── hooks.json                      # Registers PostToolUse compliance-scan hook
│   └── compliance-scan.sh              # Scans file writes for hardcoded secrets + PII in logs
└── scripts/
    ├── setup-kg.sh
    ├── query-kg.sh
    └── build-graph.py
```

---

## How Skills Work

Each skill is a `SKILL.md` file with a YAML frontmatter block. The same file works for both CLIs:

```yaml
---
name: coding
description: <trigger phrases>
version: 0.3.0
disable-model-invocation: true   # Claude Code: prevents auto-invocation
user-invocable: true             # Copilot CLI: enables /coding slash command
---
```

| Frontmatter field | Claude Code | Copilot CLI |
|---|---|---|
| `name` | skill identifier | skill identifier |
| `description` | trigger phrase matching | trigger phrase matching |
| `version` | update detection | update detection |
| `disable-model-invocation: true` | blocks auto-invocation | ignored |
| `user-invocable: true` | ignored | enables `/skill-name` command |

### Execution order

Every skill follows this order regardless of which CLI is used:

1. **Step 0** — read `tech-stack.md` (if present), install graphify, build graph, read `GRAPH_REPORT.md`
2. **Skill logic** — generates output informed by real project knowledge

### Progressive disclosure

1. **`SKILL.md`** — core instructions, always loaded on invocation
2. **`references/*.md`** — dense domain knowledge (templates, code patterns, checklists), loaded on-demand

### Hooks

Both CLIs fire the compliance-scan hook after every file write:

| File | Used by |
|---|---|
| `hooks/hooks.json` | Claude Code |
| `hooks/copilot-hooks.json` | GitHub Copilot CLI |

---

## Contributing

1. Fork this repository.
2. Add or update a skill in `skills/<skill-name>/SKILL.md`.
3. Validate: `claude plugin validate .` (run from the plugin root).
4. Test: `claude plugin install --plugin-dir .` then invoke the skill.
5. Submit a pull request.

### Skill quality checklist

- [ ] `description` field has 8+ distinct trigger phrases covering common user phrasings
- [ ] `SKILL.md` has a clear, numbered step-by-step process section
- [ ] File-writing skills have `disable-model-invocation: true` in frontmatter
- [ ] Reference files contain concrete examples — not prose summaries
- [ ] The skill asks the user rather than guessing when context is ambiguous
- [ ] `claude plugin validate .` passes before submitting

---

## License

MIT — free to use, modify, and distribute within your team.
