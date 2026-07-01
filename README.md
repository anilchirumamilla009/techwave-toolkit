# techwave-toolkit

A Claude Code plugin providing AI-assisted skills for the development phases of the SDLC. Tech-stack agnostic — works with Node.js, Python, Go, Java, Rust, React, and more.

**Version:** 0.2.0 · **License:** MIT · **Author:** Venkata Anil Kumar Chirumamilla

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Plugin Management](#plugin-management)
- [Skills Reference](#skills-reference)
- [Orchestrator — Start Here](#orchestrator--start-here)
- [Requirements](#requirements)
- [Design](#design)
- [Coding](#coding)
- [Test Plan](#test-plan)
- [Compliance](#compliance)
- [Hooks and Compliance Scanning](#hooks-and-compliance-scanning)
- [MCP Server Configuration](#mcp-server-configuration)
- [Plugin Structure](#plugin-structure)
- [How Skills Work](#how-skills-work)
- [Contributing](#contributing)

---

## Overview

techwave-toolkit wraps the development phases of the SDLC into a Claude Code plugin. Instead of juggling separate tools, you drive the full dev workflow — from raw requirements through compliance — from a single Claude Code session.

**What it does:**

- Converts Jira tickets, Confluence pages, GitHub issues, or plain text into structured requirements
- Generates architecture diagrams (Mermaid), ADRs, and tech-stack evaluations saved to `docs/`
- Generates runnable code via a sequential Coding → Unit Test → Validator agent flow
- Produces test-plan documents plus runnable test stubs for the detected framework
- Reviews code against HIPAA, PCI DSS v4.0, GDPR, and SOC 2 controls
- Scans every file write for hardcoded credentials and PII in logs via a background hook

**Skill map:**

| Command | Phase | Description |
|---|---|---|
| `/orchestrator` | **Entry point** | Accepts a Jira ticket, Confluence page, GitHub issue, or plain text — drives all dev phases in sequence |
| `/requirements` | Requirements | User stories, acceptance criteria, BDD scenarios, epic breakdown |
| `/design` | Architecture | Mermaid diagrams saved to `docs/HLD.md` + `docs/LLD.md`, ADRs, tech-stack evaluation |
| `/coding [stack]` | Development | Coding Agent → Unit Test Agent → Validator Agent sequential flow |
| `/test-plan` | Testing | Test strategy document + runnable test stubs |
| `/compliance [domain]` | Compliance | HIPAA, PCI DSS, GDPR, SOC 2 code-level review |

---

## Prerequisites

- **Claude Code** CLI installed and authenticated (`claude --version` must succeed)
- **bash** available in `PATH` — required by the compliance-scan hook
- **jq** (optional but recommended) — used by the hook to parse file paths from tool events
- An active Claude Code session (the plugin is loaded per-session or permanently via symlink)

---

## Installation

### Option 1 — Load for the current session only

No installation step. Pass the plugin directory when starting Claude Code:

```bash
claude --plugin-dir /path/to/techwave-toolkit
```

The plugin is active for that session only. Skills are not available in future sessions.

### Option 2 — Permanent install via local directory

```bash
claude plugin install --plugin-dir /path/to/techwave-toolkit
```

### Option 3 — Permanent install via symlink

Symlink the plugin into the Claude Code skills directory so it loads automatically every session:

```bash
ln -s /path/to/techwave-toolkit ~/.claude/skills/techwave-toolkit
```

Verify it loaded:

```bash
claude plugin list
```

### Option 4 — Install from the remote marketplace

Once published to the Claude Code marketplace:

```bash
# Install from the default marketplace
claude plugin install techwave-toolkit

# Install from a named marketplace (e.g., the techwave org marketplace)
claude plugin install techwave-toolkit@techwave
```

---

## Knowledge Graph

Every skill runs a **Step 0** before its main logic: it checks for `graphify-out/graph.json` in the project root. If it does not exist, `scripts/setup-kg.sh` installs [graphify](https://graphify.net) (official PyPI package) and builds the graph. The skill then queries it for context before generating any output.

### How it works

```
Skill invoked
  └─ Step 0: graphify-out/graph.json exists?
       NO  → bash scripts/setup-kg.sh
               installs graphify (pip install graphifyy && graphify claude install)
               runs: graphify .
               installs post-commit hook: graphify hook install
       YES → bash scripts/query-kg.sh "<context>"
               searches graph.json (NetworkX JSON) for matching nodes
               surfaces GRAPH_REPORT.md for broader context
               results injected as KG Context into skill execution
```

### What graphify produces

| File | Contents |
|---|---|
| `graphify-out/graph.json` | NetworkX JSON — functions, classes, imports, call edges (EXTRACTED/INFERRED confidence tags) |
| `graphify-out/GRAPH_REPORT.md` | Core nodes, surprises, suggested questions |
| `graphify-out/graph.html` | Interactive visualization |
| `graphify-out/cache/` | Incremental AST cache (tree-sitter, rebuilt on each commit) |

### Manual build / rebuild

```bash
# First build (or full rebuild after major restructuring)
bash scripts/setup-kg.sh

# Query the graph directly
bash scripts/query-kg.sh "UserService"
bash scripts/query-kg.sh "payment hipaa"
```

### When to rebuild

The post-commit hook (`graphify hook install`) handles AST-level rebuilds automatically after each commit. For doc or image changes, run `bash scripts/setup-kg.sh` manually. You can also delete `graphify-out/` and let the next skill invocation rebuild it from scratch.

---

## Plugin Management

```bash
# List all installed plugins and their versions
claude plugin list

# Show skill details, trigger phrases, and estimated token cost
claude plugin details techwave-toolkit

# Pull the latest version (if installed from marketplace)
claude plugin update techwave-toolkit

# Disable without uninstalling (skills stop loading)
claude plugin disable techwave-toolkit

# Re-enable a disabled plugin
claude plugin enable techwave-toolkit

# Completely remove the plugin and its hooks
claude plugin uninstall techwave-toolkit

# Validate plugin.json and all SKILL.md frontmatter (run from the plugin root)
claude plugin validate .
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
| Jira ticket ID | `PROJ-123`, `DEV-456` (pattern: `[A-Z]+-\d+`) |
| Confluence URL | `https://*/wiki/spaces/*/pages/*` |
| Confluence page title (quoted) | `"User Authentication Design"` |
| GitHub issue URL | `https://github.com/org/repo/issues/42` |
| GitHub issue shorthand | `#42` (when inside a GitHub-linked project) |
| Linear ticket | `ENG-123` (requires Linear MCP) |
| Plain text description | Any feature brief, PRD excerpt, or requirement |
| Pasted content | Raw Jira/Confluence/GitHub body pasted into chat |

### What happens step by step

**Step 1 — Parse the input.**
The orchestrator detects the input type and either fetches content via MCP (if a matching MCP server is configured) or asks you to paste the content. It normalises the input into a structured requirement:

```
Title:                <one-line summary>
Type:                 feature | bug | spike | epic | task
Domain:               health | finance | eu | general | unknown
Stack signals:        <any tech mentions — Java, Node.js, React, etc.>
Acceptance criteria:  <extracted or inferred>
Out of scope:         <explicitly excluded items>
```

It then shows you this struct and asks for confirmation before proceeding. A wrong parse wastes all subsequent phases, so this step is never skipped.

**Step 2 — Detect what already exists.**
The orchestrator scans the project for existing artefacts (source directories, test files, design docs) and skips phases whose outputs are already present.

**Step 3 — Propose the sequence.**
Based on what exists, it proposes only the missing phases and asks for your approval. Type `go` to start, or adjust before proceeding.

Full sequence when nothing exists:

```
Phase 1: /requirements  — user stories + acceptance criteria
Phase 2: /design        — HLD, LLD, ADR saved to docs/
Phase 3: /coding        — code, tests, validation (3-agent flow)
Phase 4: /test-plan     — test strategy + stubs
Phase 5: /compliance    — domain compliance check
```

Example partial sequences:

```
New feature:           /requirements → /design → /coding → /test-plan → /compliance
Code exists, no tests: /test-plan → /compliance
Bug ticket:            /requirements (bug story) → /coding → /test-plan
```

**Step 4 — Drive each phase.**
For each phase the orchestrator:
1. Announces `Starting Phase N: <skill>`
2. Invokes the skill with full requirement context (title, type, domain, stack signals)
3. Shows a brief summary of what was produced
4. Asks `Continue to Phase N+1? (yes / skip / stop)`

Responding `yes` proceeds, `skip` skips that phase and moves to the next, `stop` ends orchestration.

**Step 5 — Final summary.**
After all phases complete (or you type `stop`), the orchestrator prints a completion table:

```
SDLC Orchestration Complete
===========================
Source: <input type + ID/title>
Requirement: <one-line title>

Completed phases:
  ✓ Requirements — X user stories, Y acceptance criteria
  ✓ Design — C4 diagram, 1 ADR
  ✓ Scaffold — Java/Spring Boot structure
  ✓ Test Plan — JUnit5 stubs, coverage targets
  ✓ Compliance — HIPAA: 3 controls applied
  ✓ CI/CD — GitHub Actions pipeline
  ✓ Deploy — Helm chart + values.yaml

Skipped: [list any skipped phases]

Next steps:
  - Review generated files
  - Re-invoke any skill individually: /requirements, /design, etc.
```

### Key rules

- The orchestrator never generates artefacts itself — it coordinates skills; they produce outputs.
- It always confirms the parsed requirement before starting any phase.
- It always asks `Continue?` between phases — it never skips silently.
- If an MCP fetch fails (network error, auth, missing field), it falls back to "paste it here" — it never aborts.
- Context is carried forward: every skill receives the requirement title, domain, and stack signals so output is coherent across phases.

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
/requirements create a product backlog item for two-factor authentication
/requirements document requirements for the reporting dashboard
```

### What it produces

1. **Epic statement** (if applicable)
2. **User stories** in As a / I want / So that format
3. **Acceptance criteria** — testable Given/When/Then bullets for each story
4. **BDD scenarios** (optional — included when requested or when the feature has complex branching)
5. **Technical Notes** — constraints the dev team needs (never implementation choices)
6. **Out of Scope** — explicit list of what this story does NOT cover

### Output template

```
## Epic: [Epic Name]
As a [type of user], I want [goal] so that [benefit].

---

### Story 1: [Story Name] [Size: S/M/L/XS]

**As a** [persona]
**I want** [action or capability]
**So that** [benefit or outcome]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [outcome]
- [ ] [Edge case or alternate path]
- [ ] [Non-happy path: what happens on error]

**Out of Scope:**
- [What this story does NOT cover]

**Technical Notes:** *(optional)*
- [Constraint, not solution — e.g., "must respond in < 200ms" not "use Redis"]
```

### Story sizing

| Size | Effort |
|---|---|
| XS | Less than 1 day |
| S | 1–2 days |
| M | 3–5 days |
| L | 1–2 weeks — flag as candidate for further breakdown |

### Key rules

- Stories describe observable outcomes, not database tables or API calls.
- Acceptance criteria must be verifiable true/false by a QA engineer.
- Never write "the system should" — write "the user can" or "the user sees".
- Implementation details (tech stack, database, framework) are stripped from stories and placed in Technical Notes only.
- When input is incomplete, the skill drafts requirements immediately using inferences tagged `[Assumed]`, then asks one consolidating question — never a questionnaire upfront.
- For Jira/Linear format output, the skill maps fields using `references/story-templates.md`.

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
/design create a high-level architecture diagram for a microservices platform
/design create a low-level design for the authentication service
```

### Artifact type routing and output location

| User says | Artifact | Saved to |
|---|---|---|
| "HLD", "high-level design", "system design" | C4 Context + Container diagrams + narrative | `docs/HLD.md` |
| "LLD", "low-level design", "component diagram" | Component / class / sequence + API contracts | `docs/LLD.md` |
| "sequence diagram", "flow" | Mermaid `sequenceDiagram` | `docs/LLD.md` |
| "ER diagram", "data model" | Mermaid `erDiagram` | `docs/LLD.md` |
| "ADR", "architecture decision" | Nygard ADR | `docs/ADR-NNN-<title>.md` |
| "tech stack", "which technology" | Evaluation matrix + recommendation | inline only |
| "design the system" (generic) | HLD first, then asks if LLD is needed | `docs/HLD.md` |

All diagrams are text-based Mermaid — renders on GitHub, GitLab, Notion, and most editors.

### Docs folder behavior

The skill confirms the planned document paths with you before writing, then creates `docs/` in the project root if it does not exist and writes each document there. ADR filenames are auto-incremented (`ADR-001`, `ADR-002`, ...).

### ADR format (Nygard)

- **Title** — short imperative phrase
- **Status** — one of: Proposed, Accepted, Deprecated, Superseded by [ADR-NNN]
- **Context** — the forces and constraints that led to this decision
- **Decision** — what was decided
- **Consequences** — trade-offs and follow-on work (never skipped)

### Tech stack evaluation

Collects team expertise, deployment target, scale requirements, and integration constraints before producing a scoring matrix. Recommendation always follows the matrix — never precedes it.

### Key rules

- Always write HLD and LLD to `docs/` — never leave design artifacts only in chat.
- Confirm planned files with the user before writing anything.
- Diagrams are Mermaid text only — no SVG, no image URLs.
- "Quick diagram" request → produce diagram inline only, skip the doc write.

---

## Coding

Drives a three-agent sequential flow: Coding Agent → Unit Test Agent → Validator Agent. Each agent runs to completion before the next begins.

### How to invoke

```
/coding nodejs          # Node.js + TypeScript + Express
/coding python          # Python + FastAPI + Poetry
/coding go              # Go + Gin
/coding java            # Java + Spring Boot
/coding react           # React + Vite + TypeScript
/coding rust            # Rust + Axum
/coding                 # Auto-detects stack from existing marker files
```

### Supported stacks and recognized aliases

| Stack | Aliases |
|---|---|
| Node.js (TypeScript) | `nodejs`, `node`, `express`, `fastify`, `hapi`, `typescript` |
| Python | `python`, `fastapi`, `django`, `flask`, `uvicorn` |
| Java | `java`, `spring`, `springboot`, `quarkus`, `micronaut`, `maven`, `gradle` |
| Go | `go`, `golang`, `gin`, `echo`, `chi`, `fiber` |
| React | `react`, `nextjs`, `next`, `vite`, `cra`, `frontend` |
| Rust | `rust`, `axum`, `actix`, `warp`, `tokio` |

### Agent 1 — Coding Agent

Detects or accepts the stack, shows the planned directory tree, and waits for confirmation before writing any files. Generates real, runnable code — no placeholders. Secrets go in `.env.example` only; `.env` is gitignored.

```
[Coding Agent] Planning [Stack] structure:
<directory tree>
Confirm? (yes / adjust)
```

### Agent 2 — Unit Test Agent

Reads the generated code, selects the idiomatic test framework for the stack, and writes test files alongside source files. Every test has a failing assertion + `// TODO: implement`. Sets coverage targets by risk level (90%+ for auth/payments, 80%+ for APIs, 60%+ for utilities).

### Agent 3 — Validator Agent

Reviews code and tests across three dimensions and produces a single verdict:

```
[Validator Agent] Review Complete
==================================
Correctness : PASS | FAIL
Security    : PASS | FAIL
Test Quality: PASS | FAIL

Overall: PASS ✓  |  NEEDS REVISION ✗

Issues (if NEEDS REVISION):
- [file:line] [HIGH|MED|LOW] <description> — <fix>
```

### Key rules

- No agent writes files until Coding Agent receives user confirmation.
- Generated code is immediately runnable — no `TODO` in production code.
- Hardcoded secrets are always HIGH severity in the Validator report.
- Each agent announces its start and handoff so you can follow the flow.

---

## Test Plan

Generates a written test-plan document and runnable test stubs for the detected tech stack and framework.

### How to invoke

```
/test-plan write a test plan for the user authentication module
/test-plan generate test stubs for the OrderService class
/test-plan create a testing strategy for the payments API
/test-plan what should we test for the notification service
/test-plan plan e2e tests for the checkout flow
/test-plan generate integration tests for the database layer
/test-plan QA plan for the user registration feature
```

### Stack and framework detection

The skill detects the tech stack from marker files (same logic as `/coding`) and selects the idiomatic test framework:

| Stack | Default framework |
|---|---|
| Node.js / TypeScript | Jest |
| Go | `testing` + `testify` |
| Java | JUnit 5 + Mockito |
| Python | pytest |
| Rust | built-in `#[test]` + `tokio::test` |
| React | Vitest + React Testing Library |

### Test plan document structure

```
## Test Plan: [Feature/Service Name]

### Scope
[What is included in testing]

### Out of Scope
[What is explicitly excluded and why]

### Test Types

#### Unit Tests
- [Component/function]: [what is being verified]
- Coverage target: [X]% for this module

#### Integration Tests
- [Integration point]: [what is being verified]
- Dependencies: [list real vs mocked]

#### End-to-End Tests
- [User flow]: [steps and expected outcomes]

#### Performance Considerations
- [Any latency or throughput targets]

### CI Integration
[Which CI stage should run which test type]
```

### Coverage targets by risk level

| Risk level | Unit | Integration | E2E |
|---|---|---|---|
| High (auth, payments, data mutations) | 90%+ | 80%+ | 3–5 critical journeys |
| Medium (business logic, APIs) | 80%+ | 60%+ | 3–5 critical journeys |
| Low (UI, utilities) | 60%+ | — | 3–5 critical journeys |

### Test stub example

```javascript
describe('UserService.createUser', () => {
  it('should return created user with assigned ID', async () => {
    // TODO: implement
    expect(result.id).toBeDefined()
    expect(result.email).toBe(input.email)
  })

  it('should throw validation error when email is missing', async () => {
    // TODO: implement
    await expect(service.createUser({})).rejects.toThrow('email is required')
  })
})
```

### Key rules

- Test stubs always have a failing assertion and a `// TODO: implement` comment — empty test bodies are never generated.
- Test names describe behavior, not implementation: `should return 404 when user not found` not `test getUserById error`.
- Integration tests clearly state which dependencies are real (real database, real HTTP) vs mocked.
- If no existing code is found, tests are generated first (TDD approach) — this is noted in the output.

---

## Compliance


Reviews a codebase or design against domain-specific regulatory requirements and produces a structured pass/fail checklist with concrete code-level remediation guidance.

### How to invoke

```
/compliance health        # HIPAA technical safeguards review
/compliance hipaa         # alias for health
/compliance healthcare    # alias for health
/compliance finance       # PCI DSS v4.0 code controls
/compliance pci           # alias for finance
/compliance payment       # alias for finance
/compliance eu            # GDPR (consent, erasure, portability)
/compliance gdpr          # alias for eu
/compliance privacy       # alias for eu
/compliance soc2          # SOC 2 CC6/7/8 controls
/compliance soc           # alias for soc2
/compliance               # Auto-detects domain from codebase signals
```

### Domain routing

| Arguments | Standard | Reference loaded |
|---|---|---|
| `health`, `hipaa`, `healthcare`, `phi`, `medical` | HIPAA | `references/hipaa.md` |
| `finance`, `pci`, `pci-dss`, `payment`, `fintech`, `card` | PCI DSS v4.0 | `references/pci-dss.md` |
| `eu`, `gdpr`, `privacy`, `europe`, `personal-data` | GDPR | `references/gdpr.md` |
| `general`, `soc2`, `soc`, `cloud`, `startup`, `saas` | SOC 2 | `references/soc2.md` |

### Auto-detection (when no argument is given)

The skill greps the codebase for domain signals in `.py`, `.ts`, `.js`, `.java`, and `.go` files:

| Signals found | Suggested domain |
|---|---|
| `hl7`, `fhir`, `patient`, `phi`, `hipaa`, `dicom`, `medical`, `clinical` | `health` |
| `card`, `pan`, `cvv`, `pci`, `stripe`, `braintree`, `payment`, `transaction`, `billing` | `finance` |
| `gdpr`, `consent`, `personal_data`, `erasure`, `right_to`, `data_subject`, `lawful_basis` | `eu` |
| No signals found | `soc2` (most general, applies to any SaaS) |

If signals from multiple domains are found, you are asked which to prioritize.

### Compliance report structure

```
## Compliance Review: [Domain] ([Standard])

### Summary
- Total controls reviewed: N
- Passing: N ✓
- Failing: N ✗
- Not Applicable: N —
- Requires Manual Verification: N ⚠

### Control Checklist

#### [Control Category]

| Control | Status | Evidence / Location |
|---|---|---|
| [Control name] | ✓ Pass   | [file:line or "config"] |
| [Control name] | ✗ Fail   | [what was found] |
| [Control name] | — N/A    | [why not applicable] |
| [Control name] | ⚠ Manual | [needs human verification] |

### Remediation Guidance

#### [Failing Control 1]
**Issue:** [What is wrong and why it violates the regulation]
**Fix:** [Specific code pattern — actual before/after code, not just description]
**Effort:** Low / Medium / High

### Non-Technical Controls Required
[Controls that require policies, training, or physical security — cannot be satisfied by code alone]

### Remaining Gaps
[Controls that are partially addressed or unclear — need further investigation]
```

### What the skill reads in the codebase

- Authentication and authorization implementation
- Data storage and encryption patterns
- Logging statements (looks for PII exposure)
- API endpoints that handle sensitive data
- Configuration files for secrets management
- Data retention or deletion mechanisms

For large codebases it focuses on the highest-risk areas first: authentication, data storage, logging, and external API calls.

### Key rules

- A control is only marked Pass when specific code evidence (file and approximate line) is cited.
- Controls requiring runtime or infrastructure verification are marked Manual, not Pass.
- All findings are framed as engineering recommendations — never legal advice.

---

## Hooks and Compliance Scanning

The plugin registers a `PostToolUse` hook that runs automatically after every `Write`, `Edit`, or `MultiEdit` tool call. The hook scans the modified file for security and compliance issues before Claude Code proceeds.

### What the hook scans for

**Pattern 1 — Hardcoded credentials in assignments:**

Matches patterns such as:
```
password = "mysecret"
api_key: "abc123xyz"
secret = 'my-token-value'
access_token = "Bearer abc..."
```

The pattern matches any credential variable name followed by a quoted string of 4 or more characters.

**Pattern 2 — PII passed directly to logging calls:**

Matches patterns such as:
```javascript
console.log(user.ssn)
logger.info(`Patient ID: ${patient_id}`)
print(f"Card: {credit_card}")
logging.debug(f"DOB: {date_of_birth}")
```

PII field names checked: `ssn`, `social_security`, `credit_card`, `password`, `phone_number`, `date_of_birth`, `patient_id`.

**Pattern 3 — Embedded cloud access keys:**

AWS access key IDs in the format `AKIA` followed by 16 uppercase alphanumeric characters.

### Hook behavior

| Condition | Behavior |
|---|---|
| File is clean | Exits silently (exit 0) — no output |
| Issue detected | Emits a warning to stderr, exits with code 1 — warning surfaces in Claude Code output |
| Binary file | Skipped automatically |
| File larger than 500 KB | Skipped to stay within the 5-second hook timeout |
| `jq` not installed | Falls back to reading file path from `CLAUDE_TOOL_FILE_PATH` environment variable |

### Example warning output

```
[techwave-toolkit] WARNING: Possible hardcoded credential detected in src/config.ts. Use environment variables or a secrets manager instead.
[techwave-toolkit] WARNING: Possible PII in log statement detected in src/service/user.ts. Remove PII from logs or use pseudonymization.
[techwave-toolkit] WARNING: Possible AWS Access Key ID detected in scripts/deploy.sh. Revoke and rotate this key immediately.
```

---

## MCP Server Configuration

The `/orchestrator` skill auto-fetches ticket and page content when a matching MCP server is connected. Without an MCP server, it falls back to asking you to paste the content.

### Jira

```bash
claude mcp add --transport http jira https://your-jira-mcp-url
```

The orchestrator looks for any of: `mcp__jira__getIssue`, `mcp__jira__get_issue`, `mcp__jira__fetchTicket`, `mcp__jira__getTicket`.

### Confluence

```bash
claude mcp add --transport http confluence https://your-confluence-mcp-url
```

The orchestrator looks for any of: `mcp__confluence__getPage`, `mcp__confluence__get_page`, `mcp__confluence__fetchPage`.

- Input is a Confluence URL → page ID is extracted from the URL.
- Input is a quoted page title → search runs and the top result is used.

### GitHub

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/v1
```

The orchestrator looks for any of: `mcp__github__getIssue`, `mcp__github__get_issue`.

### Linear

```bash
claude mcp add --transport http linear https://your-linear-mcp-url
```

The orchestrator looks for any of: `mcp__linear__getIssue`, `mcp__linear__get_issue`.

### Fallback when no MCP server is found

```
No Jira MCP detected. Either:
  1. Paste the ticket content here, or
  2. Add a Jira MCP server: claude mcp add --transport http jira https://your-jira-mcp-url
```

The orchestrator never aborts — it always provides a paste fallback.

---

## Plugin Structure

```
techwave-toolkit/
├── .claude-plugin/
│   └── plugin.json                   # Plugin manifest (name, version, author, license)
├── skills/                            # One directory per skill
│   ├── shared/
│   │   └── knowledge-graph.md        # Step 0 KG protocol shared by all skills
│   ├── orchestrator/
│   │   ├── SKILL.md                   # Entry point — coordinates all dev skills
│   │   └── references/
│   │       └── mcp-sources.md         # Full list of known MCP tool signatures
│   ├── requirements/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── story-templates.md     # User story and Jira/Linear field templates
│   │       └── bdd-patterns.md        # Idiomatic Given/When/Then patterns
│   ├── design/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── adr-template.md        # Nygard ADR format
│   │       ├── diagram-formats.md     # Mermaid syntax starters per diagram type
│   │       └── tech-stack-evaluation.md  # Scoring matrix and evaluation criteria
│   ├── coding/
│   │   ├── SKILL.md                   # Thin orchestrator: Coding → Test → Validator
│   │   ├── agents/
│   │   │   ├── coding-agent.md        # Stack detection, structure confirm, code generation
│   │   │   ├── test-agent.md          # Test framework selection, stub generation
│   │   │   └── validator-agent.md     # Correctness / Security / Test Quality verdict
│   │   └── references/
│   │       ├── detection.md           # Stack detection logic
│   │       └── stacks/
│   │           ├── nodejs.md          # Node.js + TypeScript + Express boilerplate
│   │           ├── python.md          # Python + FastAPI + Poetry boilerplate
│   │           ├── go.md              # Go + Gin boilerplate
│   │           ├── java.md            # Java + Spring Boot boilerplate
│   │           ├── react.md           # React + Vite + TypeScript boilerplate
│   │           └── rust.md            # Rust + Axum boilerplate
│   ├── test-plan/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── frameworks.md          # Test framework selection per stack
│   │       └── test-types.md          # Unit / integration / E2E patterns
│   └── compliance/
│       ├── SKILL.md
│       └── references/
│           ├── hipaa.md               # HIPAA technical safeguards checklist
│           ├── pci-dss.md             # PCI DSS v4.0 code controls
│           ├── gdpr.md                # GDPR consent, erasure, portability controls
│           └── soc2.md                # SOC 2 CC6/7/8 controls
├── scripts/
│   ├── setup-kg.sh                   # Install graphify (pip install graphifyy) + build graph
│   ├── query-kg.sh                   # Query graphify-out/graph.json for context
│   └── build-graph.py                # Fallback builder (used only when pip is unavailable)
└── hooks/
    ├── hooks.json                     # Registers PostToolUse compliance-scan hook
    └── compliance-scan.sh             # Scans file writes for hardcoded secrets and PII in logs
```

---

## How Skills Work

Each skill is a `SKILL.md` file with a YAML frontmatter block:

```yaml
---
name: <skill-name>
description: <trigger phrases — what the user must say to invoke this skill>
version: 0.1.0
disable-model-invocation: true   # present on file-writing skills only
---
```

Claude Code loads all skills at session start. When you type a `/command` or a phrase matching the `description` field, Claude Code invokes the corresponding skill.

### Progressive disclosure

Skills use a two-layer pattern to keep context cost low:

1. **`SKILL.md`** — core instructions (~1,000–2,000 words), always loaded when the skill is invoked.
2. **`references/*.md`** — dense domain knowledge (templates, code patterns, checklists), loaded on-demand only when needed by the core skill.

### `disable-model-invocation: true`

The `/coding` skill carries this flag. It prevents Claude Code from auto-invoking it without an explicit user command. The skill always confirms the planned directory structure with you before writing any files.

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
- [ ] Parameterized skills have a complete routing table for all valid `$ARGUMENTS` values
- [ ] Reference files contain concrete examples (templates, full code blocks, patterns) — not prose summaries
- [ ] The skill asks the user rather than guessing when context is ambiguous
- [ ] `claude plugin validate .` passes before submitting

---

## License

MIT — free to use, modify, and distribute within your team.
