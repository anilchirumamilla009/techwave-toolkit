---
name: qa
description: 'Use when the user asks for a "QA plan", "E2E tests", "acceptance tests", "test strategy", "performance testing plan", "load testing", "accessibility testing", "test data strategy", "generate fixtures", or requirement-to-scenario mapping. Covers the test layers above unit/integration — E2E, acceptance, performance, test data — for any project type (web, API, mobile, CLI, library, data/ML).'
version: 0.7.0
user-invocable: true
---

# QA Strategy Skill

## Overview

This skill produces the testing layers that sit above unit and integration tests, for any project type — web, API, mobile, CLI, library, desktop, data pipeline, ML:
- **E2E test stubs** in the framework that fits the project type (see Step 3)
- **Acceptance scenarios** mapped from requirements to Given/When/Then
- **Test data strategy** — fixtures, factories, seed scripts
- **Performance and load testing plan**
- **Accessibility testing checklist** (WCAG 2.1 AA — when the project has a UI)
- **QA strategy document** describing the full test pyramid for this feature

If `/coding` already ran, this skill detects existing unit and integration test files and does not regenerate them — it focuses only on the layers above.

---

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation (the orchestrator or a prior skill ran Step 0), reuse them and skip 0.0–0.3 — do not re-read or re-run anything.

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — use declared stack and test runner in Step 2; skip marker-file detection.

**0.1 Install graphify if missing**
```bash
command -v graphify || pip install graphifyy || pip3 install graphifyy
```

**0.2 Build the graph if missing**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || (graphify . && graphify claude install && grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore)
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing test files, existing coverage gaps, risk-flagged modules, user-facing flows, any API contract (`openapi.yaml`). Hold as **KG Context**.

Full protocol: `../shared/knowledge-graph.md`

---

## Step 1 — Detect What Already Exists

Before generating anything, check what the coding skill may have already produced:

```bash
# Check for existing unit/integration test files
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.js" \
       -o -name "test_*.py" -o -name "*_test.go" -o -name "*Test.java" \
       2>/dev/null | grep -v node_modules | head -20
```

Also check for:
- `e2e/` or `playwright/` or `cypress/` directory → E2E tests already exist
- A contract file (`docs/openapi.yaml`, `docs/schema.graphql`, `proto/`, `docs/asyncapi.yaml`, `docs/CONTRACT.md`) → multi-component project with a contract

**Triage:**

| Found | Action |
|---|---|
| Unit/integration test files exist | Skip unit/integration generation — note what already exists |
| E2E directory exists | Read existing E2E tests, extend with missing journeys only |
| No test files at all | Generate E2E stubs + note that unit/integration coverage is missing (suggest `/coding`) |
| Contract file found (`openapi.yaml`, `schema.graphql`, `*.proto`, `CONTRACT.md`) | Read it — derive the journey list from the contract's operations |

---

## Step 2 — Identify E2E Journeys

Identify the 3–7 critical journeys that must never break. A "journey" depends on the project type: a user flow for a web/mobile/desktop app, a request sequence for an API, a command invocation for a CLI, a public-API usage path for a library, a full run for a pipeline or ML job. Derive from:
1. The interface contract if present (`openapi.yaml`, `schema.graphql`, `.proto`, `CONTRACT.md`) — group operations into consumer-visible flows
2. KG Context — user-facing modules and flows the graph highlights
3. Requirements context (from orchestrator or `$ARGUMENTS`)

**Journey selection criteria:**
- Authentication / authorization (if applicable) → always include
- The primary value action (the main thing this software does) → always include
- Payment or subscription flow (if applicable) → always include
- Data creation / deletion that is hard to undo → include
- Admin or privileged actions → include if applicable
- CLI: the documented happy-path invocation + the most likely misuse (bad args, missing input file)
- Library: the README quick-start example, verified end-to-end
- Pipeline / ML: a full run on fixture data with output-schema and quality assertions

Present the journey list to the user for confirmation before generating stubs.

---

## Step 3 — Generate E2E Stubs

Select the E2E framework by project type, from Stack Config or `references/frameworks.md`:

| Project type | E2E framework |
|---|---|
| Web frontend (React, Vue, SvelteKit, Next.js, any) | Playwright (preferred); Cypress if team prefers |
| API only (REST/GraphQL/gRPC) | Supertest (Node) / httpx + pytest (Python) / `net/http/httptest` (Go) at the API boundary |
| Mobile | Maestro (cross-platform preferred); Detox (React Native), XCUITest (iOS), Espresso (Android) |
| CLI tool | bats (shell) or the stack's subprocess testing (pytest + `subprocess`, Go `os/exec`) — assert on exit code, stdout/stderr, produced files |
| Desktop | Playwright (Electron/Tauri); platform driver (WinAppDriver, XCUITest) otherwise |
| Library / SDK | Consumer-perspective integration tests: a small example project importing the published API |
| Data pipeline | Full-run test on fixture data + data-quality assertions (Great Expectations, dbt tests, plain pytest) |
| ML project | Evaluation harness: held-out set metrics vs. thresholds + inference smoke test |

If Stack Config declares a test framework for this layer, that declaration wins.

For web frontends, generate Playwright stubs for each confirmed journey:

```typescript
import { test, expect } from '@playwright/test'

test.describe('<Feature>: <Journey name>', () => {
  test.beforeEach(async ({ page }) => {
    // TODO: seed test data or authenticate
  })

  test('<happy path description>', async ({ page }) => {
    // TODO: implement
    await page.goto('/<route>')
    // step-by-step actions
    await expect(page).toHaveURL('/<expected-outcome-route>')
  })

  test('<error / edge case description>', async ({ page }) => {
    // TODO: implement
    // trigger the failure condition
    await expect(page.getByText('<expected error message>')).toBeVisible()
  })
})
```

Include Playwright config (`playwright.config.ts`) if it does not already exist.

For non-web project types, generate stubs in the selected framework following the same pattern: one file per journey group, a happy-path case and an error/edge case per journey, every stub named after the observable outcome. `references/frameworks.md` has starter stubs per project type.

---

## Step 4 — Map Acceptance Scenarios

For each journey, produce Given/When/Then acceptance scenarios that a QA engineer or product owner can verify manually or automate:

```
Feature: <Feature name>

  Scenario: <Happy path>
    Given <precondition>
    When  <user action>
    Then  <observable outcome>

  Scenario: <Error path>
    Given <precondition>
    When  <invalid action>
    Then  <error is shown or rejected>
```

These map requirements → verifiable test conditions. They are distinct from code stubs — they describe behavior in domain language, not implementation.

---

## Step 5 — Test Data Strategy

Define how test data is created, isolated, and cleaned up:

| Concern | Recommended approach |
|---|---|
| Seed data | `scripts/seed-test-data.ts` (or `.py`, `.sh`) — idempotent, runnable in CI |
| Fixtures | Static JSON/YAML in `e2e/fixtures/` for stable reference data |
| Factories | `e2e/factories/<entity>.ts` — generate unique entities per test to avoid conflicts |
| DB isolation | Testcontainers (Java/Go/Node) or `pytest-django` transactions for backend; mock service workers (MSW) for frontend |
| Cleanup | Each E2E test cleans up its own data in `afterEach` — no shared mutable state |

Generate a stub `e2e/fixtures/` structure and at minimum one factory file matching the primary entity from the KG or `openapi.yaml`.

---

## Step 6 — Performance Plan (if applicable)

Include when: KG Context shows latency-sensitive modules, the contract has high-traffic operations, or Stack Config notes performance requirements. For non-service projects, adapt the targets: pipeline → throughput (rows/sec) and max wall-clock per run; CLI → startup time and large-input handling; library → hot-path benchmarks (criterion, JMH, pytest-benchmark); ML → inference latency and memory.

```
## Performance Testing Plan

### Targets
- <Endpoint>: p99 < <Xms> under <N> RPS sustained for 5 minutes
- <Endpoint>: handles <N> concurrent users without data corruption

### Tool: k6 (recommended) | Locust (Python) | Artillery (Node.js)

### Test scenarios
1. Steady-state load: <N> VUs for 5 min
2. Spike: ramp from 0 to <N> VUs in 30s, hold 2 min, ramp down
3. Soak: <N> VUs for 30 min (memory leak detection)

### Acceptance thresholds
- Error rate < 1%
- p99 response time < <Xms>
- No memory growth > 20% over soak duration
```

Skip this section if the feature is low-traffic utility code.

---

## Step 7 — Accessibility Checklist (if UI exists)

Include when the project has any user interface — a Frontend section in Stack Config, a mobile app, or a desktop app. Skip entirely for APIs, CLIs, libraries, and pipelines. For mobile, swap axe-core for the platform tooling (Accessibility Scanner on Android, Accessibility Inspector on iOS) — the manual checks below still apply.

```
## Accessibility Review (WCAG 2.1 AA)

### Automated (run with axe-core or Playwright accessibility snapshot)
- [ ] No critical axe violations on all new pages/components
- [ ] Color contrast ratio ≥ 4.5:1 for normal text, 3:1 for large text
- [ ] All images have meaningful alt text (or alt="" for decorative)
- [ ] Form inputs have associated <label> elements

### Manual checks
- [ ] Full keyboard navigation: Tab order is logical, no focus traps
- [ ] All interactive elements reachable and operable by keyboard
- [ ] Screen reader: all actions and state changes are announced
- [ ] No content flashes more than 3 times per second
```

---

## Output Format

Produce in this order:
1. **QA Strategy document** — scope, what coding already covers, what this skill adds
2. **E2E stubs** (in the Step 3 framework, one file per journey group)
3. **Acceptance scenarios** (Given/When/Then, plain text)
4. **Test data files** (`e2e/fixtures/` or equivalent, factory stub)
5. **Performance plan** (if applicable)
6. **Accessibility checklist** (if a UI exists)
7. **Getting started commands** (`npx playwright test`, `maestro test`, `bats tests/`, seed script — whatever matches the framework)

---

## Key Rules

- Never regenerate unit or integration stubs if coding skill already produced them — note what exists, focus on gaps
- Write stubs to files and report the file list plus one representative stub — never paste every generated file into chat
- Load `references/frameworks.md` only when generating stubs, and only once per invocation
- E2E tests cover journeys, not implementation details — no assertions on class names or DOM structure beyond user-visible text and ARIA roles
- Test names describe the user's observable outcome: "user sees dashboard after login" not "login route returns 200"
- Acceptance scenarios are in domain language — no code references
- Test data factories must generate unique data (use random suffixes or UUIDs) — tests must never depend on pre-existing database state
