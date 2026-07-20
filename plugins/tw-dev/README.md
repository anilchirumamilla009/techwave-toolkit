# tw-dev — Full Reference

SDLC skills plugin for GitHub Copilot CLI. Drives the full development lifecycle — requirements, architecture, code generation, QA strategy, and compliance — from a single Copilot session.

Works with **any project type** (web app, API, CLI, library, mobile, desktop, data pipeline, ML, infra) and **any stack** (Node.js, Python, Go, Java, Rust, .NET, React, Vue, Swift, Kotlin, Flutter, and beyond).

**Version:** 0.9.3 · **License:** MIT · **Author:** Venkata Anil Kumar Chirumamilla

> **Installation and update commands** → see the [root README](../../README.md).

---

## Table of Contents

- [Skills Reference](#skills-reference)
  - [Orchestrator](#orchestrator)
  - [Requirements](#requirements)
  - [Design](#design)
  - [Coding](#coding)
  - [QA Strategy](#qa-strategy)
  - [Compliance](#compliance)
- [Tech Stack Config](#tech-stack-config)
- [Knowledge Graph — Step 0](#knowledge-graph--step-0)
- [Atlassian MCP Integration](#atlassian-mcp-integration)
- [Hooks — Compliance Scan](#hooks--compliance-scan)
- [Plugin Structure](#plugin-structure)

---

## Skills Reference

---

### Orchestrator

**Entry point for the full SDLC workflow.** Give it any form of requirement — Jira ticket ID, GitHub issue URL, Confluence page, or plain text — and it drives requirements → design → coding → QA → compliance in sequence, asking for your approval at each phase boundary.

#### How to invoke

```
/orchestrator PROJ-123
/orchestrator DEV-456
/orchestrator https://github.com/org/repo/issues/42
/orchestrator https://wiki.company.com/wiki/spaces/ENG/pages/123456/Feature+Design
/orchestrator "User Authentication Design"
/orchestrator Build a JWT authentication module with refresh token support
/orchestrator <paste full Jira ticket body here>
```

#### Accepted input formats

| Format | Example |
|---|---|
| Jira ticket ID | `PROJ-123`, `DEV-456` |
| GitHub issue URL | `https://github.com/org/repo/issues/42` |
| Confluence URL | `https://*/wiki/spaces/*/pages/*` |
| Confluence page title (quoted) | `"User Authentication Design"` |
| Linear ticket | `ENG-123` (requires Linear MCP) |
| Plain text | Any feature brief, PRD excerpt, or requirement |
| Pasted content | Raw Jira/Confluence/GitHub body pasted into chat |

#### What happens step by step

**Step 1 — Fetch the ticket.**
If `tw-atlassian` is installed and input is a Jira ticket ID, fetches summary, description, acceptance criteria, labels, and status automatically. If not installed, asks you to paste the content — it never aborts on missing MCP.

**Step 2 — Parse and confirm.**
Normalises the input into a structured requirement struct (title, type, domain, stack signals, acceptance criteria) and shows it to you for confirmation before proceeding.

**Step 3 — Detect what already exists.**
Scans the project for existing source files, test files, and design docs. Skips phases whose outputs are already present.

**Step 4 — Propose a sequence.**
Shows only the missing phases. You type `go` to start or adjust.

```
New feature:           /requirements → /design → /coding → /qa → /compliance
Code exists, no tests: /qa → /compliance
Bug ticket:            /requirements (bug story) → /coding → /qa
```

**Step 5 — Drive each phase.**
Announces start → invokes the skill with full requirement context → shows a brief summary → asks `Continue to Phase N+1? (yes / skip / stop)`.

**Step 6 — Final summary.**
Prints a completion table listing every phase, what was produced, and next steps.

#### Key rules

- Never generates artefacts itself — it coordinates skills; they produce outputs.
- Always confirms the parsed requirement before starting any phase.
- If MCP fetch fails (network, auth, missing field), falls back to "paste it here" — never aborts.
- Context (title, domain, stack signals) is carried forward to every skill so output is coherent across phases.

---

### Requirements

Transforms raw ideas, features, or epics into structured, behavior-first requirements artefacts.

#### How to invoke

```
/requirements write user stories for a user login feature
/requirements break down the epic: "User Profile Management"
/requirements define acceptance criteria for the checkout flow
/requirements write BDD scenarios for password reset
/requirements capture requirements for real-time notifications
```

#### What it produces

1. **Epic statement** (when applicable)
2. **User stories** in As a / I want / So that format
3. **Acceptance criteria** — testable Given/When/Then bullets for each story
4. **BDD scenarios** (for features with complex branching)
5. **Technical Notes** — constraints for the dev team, never implementation choices
6. **Out of Scope** — explicit list of what this story does NOT cover

#### Story sizing

| Size | Effort |
|---|---|
| XS | Less than 1 day |
| S | 1–2 days |
| M | 3–5 days |
| L | 1–2 weeks — flag for breakdown |

#### Key rules

- Stories describe observable outcomes, not database tables or API calls.
- Acceptance criteria must be verifiable true/false by a QA engineer.
- Implementation details go in Technical Notes only — never in the story body.
- When input is incomplete, drafts with `[Assumed]` tags and asks one consolidating question.

---

### Design

Produces text-based architecture artefacts: C4 diagrams, sequence diagrams, ER diagrams, ADRs, and tech-stack evaluations. All artefacts are saved to `docs/` automatically.

#### How to invoke

```
/design create a C4 container diagram for a payments service
/design write an ADR for choosing PostgreSQL over MongoDB
/design recommend a tech stack for a real-time chat app
/design draw a sequence diagram for the order checkout flow
/design create an ER diagram for the user management module
/design design the system for a healthcare data ingestion pipeline
```

#### Artefact routing

| You say | Artefact | Saved to |
|---|---|---|
| "HLD", "high-level design", "system design" | C4 Context + Container + narrative | `docs/HLD.md` |
| "LLD", "low-level design", "component diagram" | Component / class / sequence + API contracts | `docs/LLD.md` |
| "sequence diagram", "flow" | Mermaid `sequenceDiagram` | `docs/LLD.md` |
| "ER diagram", "data model" | Mermaid `erDiagram` | `docs/LLD.md` |
| "ADR", "architecture decision" | Nygard ADR | `docs/ADR-NNN-<title>.md` |
| "tech stack", "which technology" | Evaluation matrix + recommendation | inline |

#### Key rules

- Always writes to `docs/` — never leaves artefacts in chat only.
- Confirms planned file paths with you before writing anything.
- Diagrams are Mermaid text — renders on GitHub, Notion, and most editors.
- ADR filenames are auto-incremented (`ADR-001`, `ADR-002`, ...).

---

### Coding

Multi-agent sequential flow for any project type. Mode is detected automatically from `tech-stack.md`.

#### How to invoke

```
/coding
/coding React + Node.js fullstack app
/coding Python FastAPI microservice
```

If no `tech-stack.md` is present, the skill asks one question: what to build and with what stack.

#### Supported stacks

Detailed scaffold references ship for:
`Node.js + TypeScript` · `Python + FastAPI` · `Go + Gin` · `Java + Spring Boot` · `Rust + Axum` · `.NET 8 + ASP.NET Core` · `React + Vite` · `Next.js`

Any other stack (Swift, Kotlin, Flutter, PHP, Ruby, Elixir, C++, Terraform, ...) works via the generic protocol — ecosystem canonical layout, standard build tooling, and idiomatic test framework.

#### Mode detection

| `tech-stack.md` content | Mode |
|---|---|
| Exactly `## Frontend` + `## Backend` | **Fullstack web** — Contract Agent → UI + Backend Agents |
| Any other combination of 2+ sections | **Multi-component** — Contract Agent → per-component Coding + Test Agents |
| One component section | **Single-component** — Coding Agent → Test Agent → Validator |
| File not found | Single-component — asks one question |

#### Agent flows

**Single-component:**
```
[Coding Agent] → [Unit Test Agent] → [Validator Agent]
```

**Fullstack web** (exactly `## Frontend` + `## Backend`):
```
[Contract Agent] → writes openapi.yaml after confirmation
       │
       ├── [UI Coding Agent]      → [UI Test Agent]      ↘
       └── [Backend Coding Agent] → [Backend Test Agent] → [Validator Agent]
```

**Multi-component** (any other 2+ sections):
```
[Contract Agent] → writes interface contract (OpenAPI / GraphQL / proto / AsyncAPI / doc)
       │
       for each component (providers before consumers):
       [Coding Agent] → [Unit Test Agent]
                              ↘ [Validator Agent]
```

#### UI Coding Agent — screen reference images

When generating frontend code, the UI Coding Agent checks for reference screen images (wireframes, mockups, screenshots) to drive layout decisions:

- **Conversation attachments** — images uploaded directly in the chat
- **`references/screens/` directory** — `.png`, `.jpg`, `.svg`, `.webp` files in your project

If images are found, each page/component is generated to match the visible layout, field labels, button text, and navigation structure from the corresponding image.

#### Key rules

- No agent writes any file until you explicitly confirm its planned structure.
- Generated code is immediately runnable — no `TODO` in production code paths.
- Hardcoded secrets are always HIGH severity in the Validator report.

---

### QA Strategy

Generates the testing layers above unit and integration stubs. If `/coding` has already run, `/qa` detects existing test files and focuses only on what is missing.

#### How to invoke

```
/qa checkout flow
/qa login feature
/qa payments API
/qa                    # full QA strategy for the current codebase
```

#### What it produces

| Output | Description |
|---|---|
| Manual test plan | `docs/TEST_PLAN-<feature>.md` — step-by-step test cases with real data values, expected results, AC traceability, and sign-off |
| E2E stubs | One file per journey group, in the project type's idiomatic framework |
| Acceptance scenarios | Given/When/Then in domain language, mapped from requirements |
| Test data strategy | Fixtures, factory stubs, seed script outline |
| Performance plan | k6/Locust/Artillery scenarios + latency/throughput targets |
| Accessibility checklist | WCAG 2.1 AA checks — when the project has a UI |

#### E2E framework by project type

| Project type | Framework |
|---|---|
| Web frontend | Playwright (or Cypress) |
| API only | Supertest / httpx at the API boundary |
| Mobile | Maestro · Detox · XCUITest · Espresso |
| CLI tool | bats or subprocess tests — exit codes, stdout/stderr |
| Library / SDK | Consumer-perspective example project |
| Data pipeline / ML | Full-run fixture tests + data-quality suites |

#### Division of labour with `/coding`

| Layer | Generated by |
|---|---|
| Unit test stubs | `/coding` — Unit Test or Backend Test Agent |
| Route integration stubs | `/coding` — Backend Test Agent |
| Component + API client tests | `/coding` — UI Test Agent |
| **Manual test plan** (`docs/TEST_PLAN-*.md`) | **`/qa`** |
| **E2E scenarios** | **`/qa`** |
| **Acceptance mapping** | **`/qa`** |
| **Test data strategy** | **`/qa`** |
| **Performance plan** | **`/qa`** |
| **Accessibility checklist** | **`/qa`** |

#### Key rules

- Never regenerates unit or integration stubs already produced by `/coding`.
- E2E test names describe the user's observable outcome — no implementation references.
- Test data factories generate unique data per test run — no shared mutable state.

---

### Compliance

Reviews a codebase against domain-specific regulatory requirements. Produces a structured pass/fail checklist with code-level evidence and remediation guidance.

#### How to invoke

```
/compliance health      # HIPAA technical safeguards review
/compliance finance     # PCI DSS v4.0 code controls
/compliance eu          # GDPR consent, erasure, portability
/compliance soc2        # SOC 2 CC6/7/8 controls
/compliance             # auto-detects domain from codebase signals
```

#### Domain routing

| Argument | Standard |
|---|---|
| `health`, `hipaa`, `healthcare`, `phi`, `medical` | HIPAA 45 CFR 164.312 |
| `finance`, `pci`, `pci-dss`, `payment`, `card` | PCI DSS v4.0 |
| `eu`, `gdpr`, `privacy`, `personal-data` | GDPR |
| `general`, `soc2`, `soc`, `cloud`, `saas` | SOC 2 |

If `Compliance domain:` is declared in `tech-stack.md` Notes, that domain is used directly — no auto-detection needed.

#### Compliance report structure

```
## Compliance Review: HIPAA (45 CFR 164.312)

### Summary
  Total controls reviewed: 12  |  Passing: 9 ✓  |  Failing: 2 ✗  |  Manual: 1 ⚠

### Control Checklist
| Control | Status | Evidence / Location |
|---|---|---|
| Encrypt data at rest | ✓ Pass | src/db/config.ts:42 |
| No hardcoded credentials | ✗ Fail | src/auth/service.ts:17 |
| MFA for admin access | ⚠ Manual | needs runtime verification |

### Remediation Guidance
#### No hardcoded credentials
Issue: API key literal on line 17 — violates HIPAA §164.312(a)(2)(iv)
Fix:   Move to environment variable and reference via process.env.API_KEY
Effort: Low
```

#### Key rules

- A control is only marked Pass when specific code evidence (file and line) is cited.
- Controls requiring runtime or infrastructure verification are marked Manual — not Pass.
- All findings are engineering recommendations — never legal advice.

---

## Tech Stack Config

Create a `tech-stack.md` file in your project's `.github/` folder. Every skill reads it automatically at Step 0 — no repeated stack detection, no questions about your framework.

```
your-project/
└── .github/
    └── tech-stack.md    ← checked first
```

### Format — one `##` heading per component

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

A single-component project:

```markdown
# Tech Stack

## CLI
- Language: Go 1.22
- Arg parsing: cobra
- Test runner: testing + testify
```

Any `## Section` heading (except `## Notes`) counts as a component. Use whatever names fit — `Frontend`, `Backend`, `Mobile`, `CLI`, `Library`, `Data Pipeline`, `ML`, `Desktop`, `Infrastructure`.

### What each skill uses it for

| Skill | How it uses Stack Config |
|---|---|
| `/coding` | Reads stack and test runner — no file scanning |
| `/qa` | Picks the right E2E framework and test runner per layer |
| `/orchestrator` | Populates stack signals and compliance domain in the requirement struct |
| `/design` | Skips tech-stack questions — uses declared stack directly |
| `/compliance` | Reads `Compliance domain:` from Notes — no auto-detection needed |

---

## Knowledge Graph — Step 0

Every skill runs a **Step 0** before its main logic. It builds a knowledge graph of your project so skills understand your existing codebase — modules, stack, patterns — before generating anything.

### What happens automatically on first invocation

```
Any skill invoked
  │
  ├─ 0.0  Read .github/tech-stack.md (or .claude/tech-stack.md)
  │         Found → use as Stack Config; skip all detection
  │         Not found → ask when stack is needed
  │
  ├─ 0.1  Is graphify installed?
  │         NO  → asks your permission once:
  │               "Install graphifyy==0.9.16? (yes / no)"
  │               yes → pip install graphifyy==0.9.16
  │               no  → skips graph, uses tech-stack.md only — no functionality lost
  │         YES → continue
  │
  ├─ 0.2  Does graphify-out/GRAPH_REPORT.md exist?
  │         NO  → builds the graph for the first time
  │               adds graphify-out/ to .gitignore
  │         YES → refreshes incrementally (near-instant via AST cache)
  │
  └─ 0.3  Reads graphify-out/GRAPH_REPORT.md
            extracts: modules, stack, existing artefacts relevant to this skill
            proceeds with full project context
```

### Session cache — Step 0 runs once per conversation

Within one conversation, Step 0 runs once. All later skills in the same session reuse the loaded Stack Config and KG Context. An orchestrated 5-phase run reads the graph report once, not five times.

### Files graphify produces

All added to `.gitignore` automatically:

| File | Contents |
|---|---|
| `graphify-out/GRAPH_REPORT.md` | Human-readable summary — modules, key entities. Read by every skill. |
| `graphify-out/graph.json` | Full dependency graph (functions, classes, imports, call edges) |
| `graphify-out/graph.html` | Interactive visualization — open in browser |
| `graphify-out/cache/` | Incremental AST cache — rebuilt automatically |

---

## Atlassian MCP Integration

Handled by the separate **`tw-atlassian`** plugin — install it independently if your team uses Jira.

### Install tw-atlassian

```bash
copilot plugin install tw-atlassian@techwave
```

### How authentication works

No API token or environment variable needed. On first use of `/orchestrator PROJ-123`:

1. Your browser opens automatically to the Atlassian login page
2. Log in with your Atlassian account
3. Click **Allow** to grant access
4. Return to terminal — authentication is stored for future sessions

### What data is fetched from Jira

| Field | Source |
|---|---|
| Summary | `fields.summary` |
| Description | `fields.description` (Atlassian Document Format, extracted as text) |
| Issue type | `fields.issuetype.name` — Story / Bug / Task / Epic |
| Status | `fields.status.name` |
| Priority | `fields.priority.name` |
| Labels and components | `fields.labels`, `fields.components[*].name` |
| Acceptance criteria | `fields.customfield_10016` or "Acceptance Criteria" section in description |
| Recent comments | Latest 3 comments only |

No data is stored or sent anywhere other than your local Copilot CLI session.

### Without tw-atlassian

`/orchestrator PROJ-123` still works — it prompts:
```
No Atlassian MCP detected. Paste the ticket content here and I'll proceed from that,
or install tw-atlassian for auto-fetch: copilot plugin install tw-atlassian@techwave
```

### Supported MCP sources (beyond Atlassian)

The orchestrator also detects MCP servers for:
- **GitHub** — auto-fetches issues from GitHub issue URLs
- **Confluence** — auto-fetches pages from Confluence URLs or titles
- **Linear** — auto-fetches issues by Linear ticket ID

See `skills/orchestrator/references/mcp-sources.md` for full tool name signatures and setup commands for each.

---

## Hooks — Compliance Scan

The plugin registers a `PostToolUse` hook that runs automatically after every file write and scans the modified file for security and compliance issues.

### What the hook scans for

| Pattern | Example |
|---|---|
| Hardcoded credentials | `password = "mysecret"`, `api_key: "abc123"` |
| PII passed to logging | `console.log(user.ssn)`, `print(f"DOB: {dob}")` |
| Embedded cloud access keys | AWS `AKIA...` format key IDs |

### Behavior

| Condition | Behavior |
|---|---|
| File is clean | Exits silently |
| Issue detected | Emits a warning to stderr with file name. Warning is fed back to the model so it can auto-fix. |
| Binary file | Skipped |
| File > 500 KB | Skipped (stays within 5-second hook timeout) |

### Example warning

```
[tw-dev] WARNING: Possible hardcoded credential in src/config.ts. Use environment variables.
[tw-dev] WARNING: Possible PII in log statement in src/service/user.ts. Remove PII from logs.
[tw-dev] WARNING: Possible AWS Access Key ID in scripts/deploy.sh. Rotate immediately.
```

---

## Plugin Structure

```
plugins/tw-dev/
├── plugin.json                       # Plugin manifest (name, version, skills, author)
├── README.md                         # This file
├── .github/
│   └── copilot-instructions.md       # Injected into Copilot context when plugin is active
├── skills/
│   ├── shared/
│   │   └── knowledge-graph.md        # Step 0 protocol shared by all skills
│   ├── orchestrator/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── mcp-sources.md        # Known MCP tool signatures per source system
│   ├── requirements/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── story-templates.md
│   │       └── bdd-patterns.md
│   ├── design/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── adr-template.md
│   │       ├── diagram-formats.md
│   │       └── tech-stack-evaluation.md
│   ├── coding/
│   │   ├── SKILL.md                  # Mode detection + agent execution order
│   │   ├── agents/
│   │   │   ├── coding-agent.md       # Single/multi-component: reads Stack Config, writes code
│   │   │   ├── test-agent.md         # Single/multi-component: unit test stubs
│   │   │   ├── contract-agent.md     # Fullstack/multi-component: monorepo + interface contract
│   │   │   ├── ui-coding-agent.md    # Fullstack web: frontend/ from openapi.yaml + screen images
│   │   │   ├── backend-coding-agent.md  # Fullstack web: backend/ from openapi.yaml
│   │   │   ├── ui-test-agent.md      # Fullstack web: component + API client tests
│   │   │   ├── backend-test-agent.md # Fullstack web: route integration + service unit tests
│   │   │   └── validator-agent.md    # All modes: correctness / security / test quality verdict
│   │   └── references/stacks/
│   │       ├── generic.md            # Any stack without a dedicated reference file
│   │       ├── nodejs.md             # Node.js + TypeScript + Express
│   │       ├── python.md             # Python + FastAPI
│   │       ├── go.md                 # Go + Gin
│   │       ├── java.md               # Java + Spring Boot
│   │       ├── react.md              # React + Vite + TypeScript
│   │       ├── rust.md               # Rust + Axum
│   │       └── dotnet.md             # .NET 8 + ASP.NET Core
│   ├── qa/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── frameworks.md
│   │       ├── manual-test-plan.md
│   │       └── test-types.md
│   └── compliance/
│       ├── SKILL.md
│       └── references/
│           ├── hipaa.md
│           ├── pci-dss.md
│           ├── gdpr.md
│           └── soc2.md
├── hooks/
│   ├── copilot-hooks.json            # Registers PostToolUse compliance-scan hook
│   └── compliance-scan.sh            # Scans file writes for secrets + PII
└── scripts/
    ├── setup-kg.sh
    ├── query-kg.sh
    └── build-graph.py
```
