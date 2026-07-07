# QA Test Types Reference

## The Testing Pyramid — Who Owns Each Layer

```
         /\
        /E2E\         /qa skill — Playwright journey stubs, acceptance scenarios
       /------\
      / Integ  \      /coding skill — Backend Test Agent (route integration tests)
     /----------\
    / Unit Tests \    /coding skill — UI Test Agent + Backend Test Agent
   /--------------\
```

The `/qa` skill owns the top of the pyramid. The `/coding` skill owns unit and integration. This file covers only what `/qa` generates.

---

## E2E Tests

- **Scope**: Full user journeys through the running application (real browser, real backend, real DB)
- **Dependencies**: Real running application + seeded test database
- **Speed**: 1s–30s per test — keep the suite small
- **Quantity**: 3–7 journeys per feature — cover what must never break
- **When**: After `/coding` has produced code and unit/integration tests

### Journey selection criteria

Always include:
1. Authentication (login, logout, expired session)
2. Primary value action (the core thing the app does)
3. Payment or subscription flow (if applicable)

Include when relevant:
4. Data creation / deletion that cannot be undone
5. Critical admin or privileged actions
6. Data export / import

### E2E test data rules

- Each test creates its own data using factories → never depends on pre-existing rows
- `afterEach` deletes or rolls back data created during the test
- Never share mutable state between tests — tests must run in any order

---

## Acceptance Scenarios (Given/When/Then)

Acceptance scenarios describe behavior in domain language. They bridge requirements and E2E tests.

### Format

```
Feature: <Feature name>

  Background:
    Given <shared precondition for all scenarios in this feature>

  Scenario: <Happy path — user observable outcome>
    Given <specific precondition>
    When  <user action>
    Then  <observable outcome>
    And   <secondary observable outcome>

  Scenario: <Error path — what the user sees when something goes wrong>
    Given <precondition>
    When  <invalid or boundary action>
    Then  <error is shown / action is rejected>
```

### Rules for good acceptance scenarios

- Use domain language — no class names, no HTTP status codes, no database tables
- `Then` describes what the user **sees** — not what the database contains
- One `When` per scenario — if you need two `When` clauses, split into two scenarios
- `And` is fine for chaining related assertions in `Then`

---

## Performance Tests

### Risk tiers for performance coverage

| Tier | Examples | Load target | Latency target |
|---|---|---|---|
| **Critical** | Login, checkout, payment | 500 RPS, 5 min steady | p99 < 300ms |
| **High** | Search, profile, order history | 200 RPS, 5 min steady | p99 < 500ms |
| **Medium** | Preferences, notifications | 50 RPS | p99 < 1s |
| **Low** | Admin, static | Skip | — |

### Three required scenario types

1. **Steady-state**: target RPS for 5 minutes — baseline conformance
2. **Spike**: ramp from 0 to 2× target in 30s, hold 2 minutes — elasticity check
3. **Soak**: target RPS for 30 minutes — memory leak and connection pool exhaustion detection

### Acceptance thresholds (always define before running)

```
- http_req_failed rate < 1%
- p99 latency < <Xms>
- No memory growth > 20% over soak duration
- DB connection pool never exhausted (monitor pool wait time)
```

---

## Accessibility Testing

### Automated (axe-core via Playwright)

Run on every new page/component. Catches ~40% of WCAG issues automatically.

```typescript
import AxeBuilder from '@axe-core/playwright'
const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).analyze()
expect(results.violations).toEqual([])
```

Focus on `critical` and `serious` violations — `moderate` and `minor` are advisory.

### Manual checklist (WCAG 2.1 AA)

**Keyboard navigation**
- [ ] All interactive elements reachable by Tab (no focus traps except modals)
- [ ] Tab order is logical (matches visual reading order)
- [ ] All actions possible with keyboard alone (no mouse-only interactions)
- [ ] Escape closes modals and dropdowns

**Visual**
- [ ] Color contrast ≥ 4.5:1 for normal text, ≥ 3:1 for large text (18px+ or 14px+ bold)
- [ ] No information conveyed by color alone (use icon or text alongside)
- [ ] No content flashes > 3 times per second

**Screen reader**
- [ ] All images have meaningful `alt` text (`alt=""` for decorative images)
- [ ] All form inputs have associated `<label>` elements (not just placeholder)
- [ ] Dynamic content updates announced via `aria-live` regions
- [ ] Error messages associated with their input via `aria-describedby`

**Forms**
- [ ] Required fields marked with `aria-required="true"` or `required`
- [ ] Validation errors appear near the relevant field, not only at the top
- [ ] Submit button clearly labeled (not just an icon)

---

## CI Stage Assignment

| Test Type | CI Trigger | Blocks merge? | Typical runtime |
|---|---|---|---|
| Unit tests (`/coding`) | Every push | Yes | < 60s |
| Integration tests (`/coding`) | Every push / PR | Yes | 1–5 min |
| **E2E tests (`/qa`)** | **PR merge to main** | **Yes — blocks deployment** | 5–15 min |
| **Performance tests (`/qa`)** | **Nightly or pre-release** | **No — alert only** | 30+ min |
| **Accessibility (`/qa`)** | **Every push (automated axe only)** | **Yes for critical violations** | < 2 min |
