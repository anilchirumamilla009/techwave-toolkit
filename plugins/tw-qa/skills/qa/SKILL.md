---
name: qa
description: 'Use when the user asks for a "manual test plan", "manual testing", "QA plan", "test plan to verify changes", "testing instructions", "test data creation steps", "acceptance checks", or a testing document for a feature — or right after /coding completes and the change needs its manual QA package. Drafts a manual testing plan document into docs/test/ with full step-by-step instructions and test data creation steps. Documentation only — automated tests (unit + integration) are written by the tw-dev /coding agents.'
version: 0.13.0
user-invocable: true
---

# QA Skill — Manual Testing Plan for a Change Set

## Overview

This skill has one responsibility: **drafting the manual testing plan for a change** — typically the changes the `/coding` skill (or a developer) just made — as a detailed document in `docs/test/`:

- **`docs/test/TEST_PLAN-<kebab-feature>.md`** — the manual testing plan: environment setup, **test data creation steps** (numbered, concrete, runnable by a stranger), test cases with full step-by-step instructions and observable expected results, regression checklist, sign-off.
- **`docs/test/TEST_PLAN-<kebab-feature>.csv`** — the same cases as a flat, importable sheet for tracking.

**It writes documents only — never test code.** All automated tests are `/coding`'s job: its test agents cover **all unit and integration test cases** for the change. This skill drafts what a human tester does on top of that, and flags any automated-coverage gaps back to `/coding`. Works for any project type: web, API, mobile, CLI, library, desktop, data pipeline, ML.

---

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation (the orchestrator or a prior skill ran Step 0), reuse them and skip 0.0–0.3 — do not re-read or re-run anything.

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config**.

**0.1 Ensure graphify (consent-gated)**
```bash
command -v graphify
```
Missing → ask the user once: install `graphifyy==0.9.16` (pinned) and wire it into this project (`.gitignore` entry, `graphify claude install`)? If yes: `pip install graphifyy==0.9.16 || pip3 install graphifyy==0.9.16`. If declined: skip 0.2–0.3, use Stack Config + marker files, do not ask again this conversation.

**0.2 Build or refresh the graph**
```bash
if [ -f graphify-out/GRAPH_REPORT.md ]; then graphify .; else graphify . && graphify claude install && { grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore; }; fi
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing test files, risk-flagged modules, user-facing flows, primary entities. Hold as **KG Context**.

Full protocol: `../shared/knowledge-graph.md`

---

## Step 1 — Detect the Change Set

The unit of work is **the change**, not the whole application:

1. **Coding context** — if `/coding` ran in this conversation (or the orchestrator passed a coding summary), use its file list and test list directly.
2. **Git evidence** — otherwise reconstruct:
```bash
git status --short                     # uncommitted work
git diff --stat                        # unstaged scope
git diff --cached --stat               # staged scope
git log --oneline -10                  # recent feature commits if the tree is clean
```
3. **`$ARGUMENTS`** — the feature name scopes which changes belong to this plan. No arguments and a clean tree → ask the user which feature/commit range to cover.

Hold the result as the **Change Inventory**: changed files grouped by module/component, plus the requirement or acceptance criteria they implement (from orchestrator context, `docs/ba/`, or `$ARGUMENTS`).

---

## Step 2 — Check Automated Coverage

The manual plan complements automation — it must not duplicate it, and gaps in automation are not silently absorbed:

```bash
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "test_*.py" -o -name "*_test.go" -o -name "*Test.java" 2>/dev/null | grep -v node_modules | head -20
```

- Changed module **with** unit/integration tests → the manual plan verifies the user-observable behavior, not what the automated suite already asserts.
- Changed module **without** tests → flag as an automated-coverage gap: report it in chat as a `/coding` follow-up (its test agents must cover all unit and integration cases). The manual plan still covers the behavior, but the gap is named, not compensated for silently.

---

## Step 3 — Derive the Manual Test Cases and Test Data Steps

Load `references/manual-test-plan.md` (template + derivation checklist) — only now, not earlier. Then:

1. **Test data creation steps** — for every entity the cases need, write numbered creation steps a stranger can execute: exact seed script commands, or exact UI/API steps ("POST /api/users with body {…}", "Admin → Users → New, fill Name=`Test Tester 042`"), with concrete values and the expected confirmation after each step. Include cleanup/reset steps so the plan is repeatable.
2. **Test cases** — derive with the reference's checklist: happy path per acceptance criterion, boundary values, equivalence classes, negative authorization (wrong role, other user's data), error handling, state transitions, double-submit, cross-role and visual checks automation can't reach, and — when the change touches a UI — the manual accessibility checks from the reference.
3. **Regression checklist** — one smoke check per adjacent area the change touched (from KG Context / changed files).
4. Every case: full step-by-step instructions (exact button, field label, menu path, URL), concrete data values referencing the data created in (1), an observable expected result, a priority (P1/P2/P3), and an **AC Ref** — every acceptance criterion maps to at least one case.

Present the case list summary (areas, counts, priorities) to the user for confirmation before writing.

---

## Step 4 — Write the Plan to docs/test/

1. Ensure the folder exists: `mkdir -p docs/test`
2. Write `docs/test/TEST_PLAN-<kebab-feature>.md` from the template — scope, environment & prerequisites, test data creation steps, entry/exit criteria, test cases, regression checklist, defects table, sign-off.
3. Write `docs/test/TEST_PLAN-<kebab-feature>.csv` — the same cases as a flat sheet (CSV Export spec in the reference: one row per case, RFC 4180 quoting, Status column blank).
4. Re-running the skill for the same feature updates both files in place.
5. Report both paths, case count, and priority breakdown — do not paste the plan into chat.

---

## Output Format

1. **Manual test plan** — `docs/test/TEST_PLAN-<feature>.md` + `.csv` (paths, case count, priority breakdown — never pasted)
2. **Automated-coverage gaps** — one short list in chat of changed modules missing unit/integration tests, to hand back to `/coding`

If the user asks this skill to write test code, decline: automated tests belong to `/coding`'s test agents.

---

## Key Rules

- **Documents only, never test code** — no unit, integration, or E2E files, no stubs, no fixtures, no framework config
- Scope is **the change set**, never the whole application — every case traces back to the Change Inventory
- Automated testing (all unit and integration cases) is `/coding`'s responsibility — gaps are reported, never compensated for silently
- Both files live in `docs/test/` — create the folder if missing; re-runs update in place
- **Test data creation steps are part of the plan** — numbered, concrete, repeatable, with cleanup; cases reference the data they create
- Full instructions, concrete values: "enter `test-042@example.com`", never "enter a valid email" — a stranger must be able to execute the plan without asking questions
- Expected results are observable — what the tester *sees*, never internal state
- Load `references/manual-test-plan.md` only at Step 3, once per invocation
