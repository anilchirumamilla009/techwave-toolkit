---
name: qa
description: 'This skill should be used when the user asks to "create a QA plan", "write E2E tests", "write acceptance tests", "plan end-to-end scenarios", "test strategy for", "what should we test beyond unit tests", "performance testing plan", "load testing strategy", "accessibility testing", "write Playwright tests", "write Cypress tests", "test data strategy", "generate fixtures", "map requirements to test scenarios", "QA acceptance criteria", or needs test coverage that goes beyond unit and integration stubs. This skill focuses on E2E, acceptance, performance, and test data — the layers the coding skill does not generate.'
version: 0.6.0
user-invocable: true
---

# QA Strategy Skill

## Overview

This skill produces the testing layers that sit above unit and integration tests:
- **E2E test stubs** (Playwright/Cypress) for critical user journeys
- **Acceptance scenarios** mapped from requirements to Given/When/Then
- **Test data strategy** — fixtures, factories, seed scripts
- **Performance and load testing plan**
- **Accessibility testing checklist** (WCAG 2.1 AA)
- **QA strategy document** describing the full test pyramid for this feature

If `/coding` already ran, this skill detects existing unit and integration test files and does not regenerate them — it focuses only on the layers above.

---

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

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
- `openapi.yaml` or `docs/openapi.yaml` → fullstack project with contract

**Triage:**

| Found | Action |
|---|---|
| Unit/integration test files exist | Skip unit/integration generation — note what already exists |
| E2E directory exists | Read existing E2E tests, extend with missing journeys only |
| No test files at all | Generate E2E stubs + note that unit/integration coverage is missing (suggest `/coding`) |
| `openapi.yaml` found | Read it — derive journey list from the API contract paths |

---

## Step 2 — Identify E2E Journeys

Identify the 3–7 critical user journeys that must never break. Derive from:
1. `openapi.yaml` paths (if present) — group endpoints into user-visible flows
2. KG Context — user-facing modules and flows the graph highlights
3. Requirements context (from orchestrator or `$ARGUMENTS`)

**Journey selection criteria:**
- Authentication (login, logout, session expiry) → always include
- The primary value action (the main thing the app does) → always include
- Payment or subscription flow (if applicable) → always include
- Data creation / deletion that is hard to undo → include
- Admin or privileged actions → include if applicable

Present the journey list to the user for confirmation before generating stubs.

---

## Step 3 — Generate E2E Stubs

Select E2E framework from Stack Config or `references/frameworks.md`:

| Stack Config Frontend | E2E Framework |
|---|---|
| React, Vue, SvelteKit, Next.js | Playwright (preferred) |
| Any web frontend | Playwright as default; Cypress if team prefers |
| No frontend (API only) | Supertest / httpx integration tests at the API boundary |

Generate Playwright stubs for each confirmed journey:

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

Include when: KG Context shows latency-sensitive modules, `openapi.yaml` has high-traffic endpoints, or Stack Config notes performance requirements.

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

Include when Stack Config declares a Frontend section.

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
2. **E2E stubs** (Playwright `.ts` files, one file per journey group)
3. **Acceptance scenarios** (Given/When/Then, plain text)
4. **Test data files** (`e2e/fixtures/`, factory stub)
5. **Performance plan** (if applicable)
6. **Accessibility checklist** (if frontend present)
7. **Getting started commands** (`npx playwright test`, seed script, etc.)

---

## Key Rules

- Never regenerate unit or integration stubs if coding skill already produced them — note what exists, focus on gaps
- E2E tests cover journeys, not implementation details — no assertions on class names or DOM structure beyond user-visible text and ARIA roles
- Test names describe the user's observable outcome: "user sees dashboard after login" not "login route returns 200"
- Acceptance scenarios are in domain language — no code references
- Test data factories must generate unique data (use random suffixes or UUIDs) — tests must never depend on pre-existing database state
