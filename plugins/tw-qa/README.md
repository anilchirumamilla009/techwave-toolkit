# tw-qa

Manual QA planning plugin for **Claude Code** and **GitHub Copilot CLI**. `/qa` has one job: **drafting the manual testing plan for a change** — typically the changes the tw-dev coding agent just made — as a detailed document in `docs/test/`:

| File | Content |
|---|---|
| `docs/test/TEST_PLAN-<feature>.md` | Scope · environment & prerequisites · **test data creation steps** (numbered, concrete, with cleanup) · entry/exit criteria · test cases with full step-by-step instructions and observable expected results · regression checklist · defects table · sign-off |
| `docs/test/TEST_PLAN-<feature>.csv` | The same cases as a flat sheet — importable into Excel, Jira/Zephyr, or TestRail |

**It writes documents only — never test code.** All automated testing is tw-dev `/coding`'s responsibility: its test agents cover **all unit and integration test cases** for the change. `/qa` drafts what a human tester does on top of that, and hands automated-coverage gaps back to `/coding`.

Works standalone on any codebase, or as Phase 4 of the tw-dev `/orchestrator` pipeline, for any project type: web, API, mobile, CLI, library, desktop, data pipeline, ML.

## Installation

```bash
# Claude Code
claude plugin marketplace add anilchirumamilla009/techwave-toolkit   # once per machine
claude plugin install tw-qa@techwave

# Copilot CLI
copilot plugin marketplace add anilchirumamilla009/techwave-toolkit
copilot plugin install tw-qa@techwave
```

Restart the CLI to load the skill.

## How to invoke

```
/qa checkout flow            # manual test plan for the checkout changes
/qa login feature
/qa payments API
/qa                          # scopes from git (uncommitted work / recent commits)
```

## How it works

1. **Detect the change set** — from the `/coding` summary in the conversation, or reconstructed from git (`status`, `diff --stat`, recent commits), scoped by the feature you name.
2. **Check automated coverage** — changed modules with unit/integration tests get manual cases that verify observable behavior without duplicating the suite; changed modules **without** tests are reported as gaps for `/coding` to fill (never silently absorbed into the manual plan).
3. **Derive the plan** — test data creation steps first (exact commands, UI paths, or API calls with concrete values and cleanup), then cases from a systematic checklist: happy path per acceptance criterion, boundaries, equivalence classes, negative authorization, error handling, state transitions, double-submit, cross-role and visual checks, manual accessibility checks when a UI changed, and a regression smoke check per adjacent area.
4. **Write both files to `docs/test/`** — confirmed with you first; re-runs update them in place.

## What makes the plan executable

- **Test data creation is spelled out** — numbered TD-* steps with concrete values ("create user `test-042@example.com` / `Passw0rd!x`, role `member`"), an observable confirmation per step, and cleanup steps so the plan is repeatable.
- **Instructions a stranger can follow** — exact button names, field labels, menu paths, URLs; never "enter a valid email".
- **Observable expected results** — what the tester *sees*, never internal state.
- **Traceability** — every acceptance criterion maps to at least one case (AC Ref column); priorities P1–P3 drive the exit criteria.

## Division of labour with tw-dev `/coding`

| Responsibility | Owner |
|---|---|
| Unit tests — all cases (happy, boundary, error per public function) | tw-dev `/coding` test agents |
| Integration tests — all route/module interactions | tw-dev `/coding` test agents |
| Manual testing plan (+ test data creation steps, CSV export) | **tw-qa `/qa`** |
| Reporting automated-coverage gaps back to `/coding` | **tw-qa `/qa`** |

## Knowledge-graph context

Before drafting, `/qa` builds/refreshes a project knowledge graph with graphify and reads its report, so cases target the code you actually have (risk-flagged modules become exploratory checks, adjacent areas become regression checks). The install is consent-gated (`graphifyy==0.9.16`, pinned); declining falls back to the tech-stack file plus marker-file detection. See `skills/shared/knowledge-graph.md`.

## Structure

```
tw-qa/
├── plugin.json
└── skills/
    ├── qa/
    │   ├── SKILL.md
    │   └── references/
    │       └── manual-test-plan.md    # plan template + test-data section + derivation checklist + CSV spec
    └── shared/
        └── knowledge-graph.md         # graphify context protocol
```

## License

MIT
