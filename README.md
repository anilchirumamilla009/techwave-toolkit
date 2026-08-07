# TechWave Toolkit

A plugin marketplace for **Claude Code** and **GitHub Copilot CLI** that packages the TechWave SDLC into installable skills — from business analysis, through requirements, design, coding, and QA, to compliance — plus optional Jira/Confluence integration. Install the plugins once and drive a feature from a business objective (or a Jira ticket) to reviewed, tested, compliance-checked code with slash commands.

All commands below are shown for both CLIs — use the one you work in. Skills behave the same in both; where behavior differs (e.g. subagent support), the skills adapt automatically.

## What's in the marketplace

| Plugin | Version | What it does |
|---|---|---|
| **tw-ba** | 0.1.0 | Business analysis. `/ba` turns a business objective into development-ready BA deliverables in `docs/ba/<feature>/` — stakeholder analysis, domain & process models, UX wireframes, data dictionary & API spec, compliance requirements, and a functional spec (FRD + traceability matrix). Domain-agnostic; industry specifics (e.g. healthcare/FHIR) load from optional domain references. |
| **tw-dev** | 0.10.0 | Development phases. `/orchestrator` drives the dev flow taking the tw-ba package (`docs/ba/<feature>/`) — or a ticket/pasted text — as its requirements **input**; individual skills: `/design` (HLD/LLD/ADRs with version history), `/coding` (multi-agent code + ALL unit/integration tests + validation for any project type), `/compliance` (code-level HIPAA/PCI/GDPR/SOC 2 review). Stack- and project-type agnostic. |
| **tw-qa** | 0.1.0 | Manual QA planning. `/qa` drafts the manual testing plan for a change set — typically what `/coding` just built — into `docs/test/TEST_PLAN-*.md` (+ importable CSV): full step-by-step instructions, concrete test data creation steps with cleanup, boundary/negative/authorization cases, regression checklist, sign-off. Documents only — all automated tests (unit + integration) are written by tw-dev `/coding`'s test agents. Standalone or as Phase 4 of the tw-dev orchestrator. |
| **tw-hooks** | 0.1.0 | Shared guardrails for all TechWave plugins (moved out of tw-dev). PreToolUse sensitive-data guard **blocks** reading or exfiltrating secret files (`.env`, private keys, cloud credentials, tfstate) so secrets never enter the conversation; PostToolUse compliance scan warns on hardcoded credentials, PII in log statements, and cloud access keys in written files. No skills — install alongside any other plugin. |
| **tw-atlassian** | 1.0.0 | Atlassian integration. Connects Jira and Confluence through the official Atlassian remote MCP server (browser OAuth — no API tokens) so `/ba` and `/orchestrator` can fetch tickets and pages directly. Install only if you use Atlassian. |

### How they fit together

```
Business objective / Jira ticket / Confluence page
        │
        ▼
  /ba (tw-ba) ──────────► docs/ba/<feature>/   FRD, stories, api-spec,
        │                                      compliance requirements, RTM
        ▼
  /orchestrator (tw-dev) ► [BA package as input] → design → coding → qa* → compliance
        │                  docs/HLD.md, docs/LLD.md, ADRs, code + all unit/integration tests,
        ▼                  docs/test/TEST_PLAN-*.md (+.csv), control report
  Ready to ship            (* qa phase provided by the tw-qa plugin)
```

Each plugin also works standalone — you can run `/qa` (tw-qa) on any existing codebase, or `/ba` without ever installing tw-dev. tw-atlassian is optional for all of them: skills detect its MCP tools when present and fall back to pasted text when absent. If tw-qa is not installed, the orchestrator skips the QA phase and tells you how to add it.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) (CLI ≥ 2.x, desktop app, or IDE extension) **or** [GitHub Copilot CLI](https://docs.github.com/en/copilot) with plugin support
- Git
- Optional, for the knowledge-graph context step: Python + `pip` (skills offer to install [graphify](https://graphify.net) on first run — consent-gated, never automatic)

## Installation

**1. Register the marketplace (once per machine):**

```bash
# Claude Code
claude plugin marketplace add anilchirumamilla009/techwave-toolkit

# Copilot CLI
copilot plugin marketplace add anilchirumamilla009/techwave-toolkit
```

**2. Install the plugins you need:**

```bash
# Claude Code
claude plugin install tw-hooks@techwave       # shared guardrails — recommended for every install
claude plugin install tw-ba@techwave
claude plugin install tw-dev@techwave
claude plugin install tw-qa@techwave
claude plugin install tw-atlassian@techwave   # only if you use Jira/Confluence

# Copilot CLI
copilot plugin install tw-hooks@techwave      # shared guardrails — recommended for every install
copilot plugin install tw-ba@techwave
copilot plugin install tw-dev@techwave
copilot plugin install tw-qa@techwave
copilot plugin install tw-atlassian@techwave  # only if you use Jira/Confluence
```

**3. Restart the CLI** to load the new skills.

> tw-atlassian: on first use of `/orchestrator PROJ-123` (or `/ba PROJ-123`), your browser opens for Atlassian OAuth login — no API token needed.

You can also manage plugins interactively via the `/plugin` command inside Claude Code.

## Verify

```bash
# Claude Code
claude plugin list
claude plugin details tw-dev          # version + skills
claude plugin details tw-ba

# Copilot CLI
copilot plugin list
copilot plugin details tw-dev
copilot plugin details tw-ba
```

## Updating

Plugin updates are compared against your **local marketplace clone**, so always refresh the marketplace first — otherwise updates report "already up to date" against stale data.

**Claude Code:**

```bash
claude plugin marketplace update techwave     # refresh the marketplace clone first
claude plugin update tw-hooks@techwave
claude plugin update tw-ba@techwave
claude plugin update tw-dev@techwave
claude plugin update tw-qa@techwave
claude plugin update tw-atlassian@techwave
```

**Copilot CLI** — ⚠️ do **not** use `copilot plugin update` (it fails with a permissions error). Use uninstall → refresh → reinstall:

```bash
copilot plugin uninstall tw-dev
copilot plugin marketplace update techwave
copilot plugin install tw-dev@techwave
# repeat for tw-hooks / tw-ba / tw-qa / tw-atlassian
```

Restart the CLI after updating.

## Uninstall

```bash
# Claude Code                          # Copilot CLI
claude plugin uninstall tw-hooks       # copilot plugin uninstall tw-hooks
claude plugin uninstall tw-ba          # copilot plugin uninstall tw-ba
claude plugin uninstall tw-dev         # copilot plugin uninstall tw-dev
claude plugin uninstall tw-qa          # copilot plugin uninstall tw-qa
claude plugin uninstall tw-atlassian   # copilot plugin uninstall tw-atlassian
claude plugin marketplace remove techwave   # copilot plugin marketplace remove techwave
```

(The last line removes the marketplace registration itself — only if you're removing everything.)

## Using the skills

### Start from a business objective

```
/ba member self-scheduling for the customer portal
```

`/ba` proposes only the phases the request needs (discovery → domain & process → UX & data → compliance → functional spec → optional knowledge index), gates each phase with `Continue? (yes / skip / stop)`, and writes every artifact to `docs/ba/<feature>/`. Re-running updates artifacts in place and snapshots prior versions to `docs/ba/ba-history/`.

### Start from a ticket

```
/orchestrator PROJ-123
```

With tw-atlassian installed, the orchestrator fetches the Jira ticket (or a Confluence page URL), confirms its parse with you, detects what already exists in the repo, and proposes only the missing phases. Without Atlassian, paste the requirement as text.

### Run any skill standalone

```
/ba write the requirements for CSV export       # tw-ba plugin — output feeds tw-dev
/design create the HLD for the notification service
/coding implement the export endpoint
/qa manual test plan for the changes on this branch   # tw-qa plugin
/compliance health
```

### Where artifacts go

| Artifact | Path | Produced by |
|---|---|---|
| BA package (discovery, domain, process, UX, data, compliance, FRD, RTM + RTM.csv) | `docs/ba/<feature>/` | tw-ba `/ba` |
| High/low-level design, ADRs (version-logged, history snapshots) | `docs/HLD.md`, `docs/LLD.md`, `docs/ADR-NNN-*.md`, `docs/design-history/` | tw-dev `/design` |
| Manual test plan — instructions + test data creation steps (+ importable CSV) | `docs/test/TEST_PLAN-<feature>.md` / `.csv` | tw-qa `/qa` |
| Code + all unit/integration tests | project source tree (edited in place — never duplicate files) | tw-dev `/coding` |

## Project configuration (optional but recommended)

**Tech-stack declaration** — create `.github/tech-stack.md` (or `.claude/tech-stack.md`) in your project so skills skip stack detection:

```markdown
# Tech Stack
## Backend
Language: Python 3.12
Framework: FastAPI
Test runner: pytest

Domain: healthcare        # lets /ba and /compliance pick the right domain reference
```

**Knowledge graph (context first)** — before analyzing or generating, skills build/refresh a project knowledge graph with graphify and read its report, so output builds on the code you already have instead of re-inventing it. The install is consent-gated (`graphifyy==0.9.16`, pinned); declining falls back to the tech-stack file, and empty/greenfield projects skip the graph automatically.

**Domain references (tw-ba)** — `/ba` is industry-neutral. To teach it your domain, add a file under `plugins/tw-ba/skills/ba/references/domains/<domain>.md` (entity mappings, regulation checklists, value sets). `healthcare-fhir.md` ships as the example. A missing domain file is never a blocker.

## Compliance: two complementary layers

- **tw-ba `/ba` Phase 4** specifies *requirement-level* controls — what must exist (access matrix, consent, audit requirements) — before code is written.
- **tw-dev `/compliance <health|finance|eu|soc2>`** verifies the *implemented code* against the regulation with `file:line` evidence, after code exists.

Run the first before development, the second after.

## Repository structure

```
techwave-toolkit/
├── .claude-plugin/marketplace.json      # marketplace manifest (plugin index)
├── plugins/
│   ├── tw-ba/                           # business-analysis plugin  → plugins/tw-ba/README.md
│   ├── tw-dev/                          # development plugin        → plugins/tw-dev/README.md
│   ├── tw-qa/                           # manual QA planning plugin → plugins/tw-qa/README.md
│   ├── tw-hooks/                        # shared guardrail hooks    → plugins/tw-hooks/README.md
│   └── tw-atlassian/                    # Atlassian MCP plugin      → plugins/tw-atlassian/README.md
└── README.md
```

Full per-plugin references (every skill's steps, rules, and outputs) live in each plugin's own README.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `plugin update` says up to date but skills are old | Stale marketplace clone — run `claude plugin marketplace update techwave` (or the `copilot` equivalent) first, then update the plugin. |
| Install/update fails with "source type your version does not support" | Your marketplace clone predates the source-path fix — refresh the marketplace (command above). Sources in `marketplace.json` must start with `./`. |
| `copilot plugin update` fails with a permissions error | Known Copilot CLI issue — use uninstall → `marketplace update` → reinstall (see Updating). |
| New skills don't appear after install/update | Restart the CLI — plugins load at startup. |
| `/orchestrator` or `/ba` can't fetch a Jira ticket | tw-atlassian not installed or not authenticated — install it, then approve the browser OAuth prompt on first use; or paste the ticket text. |
| Skills ask to install graphify every run | The consent answer is per-conversation; add the pinned install to your environment (`pip install graphifyy==0.9.16`) to stop the prompt. |

## Contributing

1. Branch from `main`; edit the plugin under `plugins/<name>/`.
2. Bump the plugin `version` in **both** `plugins/<name>/plugin.json` and `.claude-plugin/marketplace.json` — installs and updates key off the marketplace version.
3. Keep skills project-type- and domain-agnostic; put stack/industry specifics in `references/` files that load on demand.
4. PR to `main`. After merge, users pick the change up via the update commands above.

## License

MIT — see individual `plugin.json` files.
