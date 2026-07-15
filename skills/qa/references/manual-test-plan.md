# Manual Test Plan — Template & Derivation Rules

The manual test plan is a standalone document a human tester executes to verify the change — no code required. Save to `docs/TEST_PLAN-<kebab-feature>.md`. Every case must be executable by someone who did not write the code.

---

## Document Template

```markdown
# Test Plan: <Feature / Change Name>

| | |
|---|---|
| **Change under test** | <one line — what was built or changed> |
| **References** | <ticket ID, PR link, requirement doc> |
| **Build / version** | <commit SHA, build number, or environment URL> |
| **Author / Date** | <who wrote this plan, when> |

## 1. Scope

**In scope:** <the changed behavior this plan verifies — bullet list>
**Out of scope:** <adjacent features NOT covered, and why>

## 2. Environment & Prerequisites

| Item | Value |
|---|---|
| Environment | <URL / device / build> |
| Test accounts | <role: credentials source — never hardcode real credentials> |
| Test data | <seed script to run, fixtures needed, starting state> |
| Tools | <browser + version, API client, device> |

## 3. Entry / Exit Criteria

**Entry:** build deployed to test env · unit/integration suites green · test data seeded
**Exit:** all P1 cases Pass · no open Critical/High defects · P2 failures triaged with owner

## 4. Test Cases

### <Functional area 1>

| ID | Pri | Title | Precondition | Steps | Expected Result | AC Ref | Status |
|---|---|---|---|---|---|---|---|
| TC-001 | P1 | <observable outcome> | <starting state> | 1. <concrete action with real value><br>2. <next action> | <what the tester sees> | AC-1 | ☐ |
| TC-002 | P1 | ... | ... | ... | ... | AC-2 | ☐ |

*(repeat table per functional area; Status: Pass / Fail / Blocked / Skipped)*

## 5. Regression Checklist

| ID | Area touched by this change | Quick check | Status |
|---|---|---|---|
| RG-001 | <adjacent feature> | <one-line smoke check> | ☐ |

## 6. Defects Found

| ID | Test case | Severity | Description | Status |
|---|---|---|---|---|

## 7. Sign-off

| Role | Name | Verdict (Ship / Block) | Date |
|---|---|---|---|
```

---

## Test-Case Derivation Checklist

Derive cases in this order — each acceptance criterion must map to at least one case (traceability via the **AC Ref** column):

1. **Happy path** — one case per acceptance criterion, using realistic data
2. **Boundary values** — for every input: min, min−1, max, max+1, empty, whitespace-only, very long, unicode/emoji
3. **Equivalence classes** — one case per class for enums, ranges, roles, states (not every value)
4. **Negative authorization** — logged out, wrong role, and another user's resource ID (IDOR check) on every changed endpoint/screen
5. **Error handling** — invalid input shows a helpful message near the field; server/network failure shows recovery path, not a blank screen
6. **State transitions** — for workflows: every legal transition once, plus one illegal transition (e.g., cancel an already-shipped order)
7. **Idempotency / double-submit** — double-click submit, browser back + resubmit, refresh on confirmation page
8. **Regression** — one smoke check per adjacent feature the diff touched (derive from KG Context / changed files)

## Rules for Writing Cases

- **Concrete values, not placeholders**: "enter `test-042@example.com`", never "enter a valid email"
- **Expected result is observable**: what the tester *sees* — never "record is saved to DB" (a tester can't see that; say "the item appears in the list")
- **One purpose per case** — if a case verifies two behaviors, split it
- **Priorities**: P1 = blocks release (acceptance criteria, auth, data loss) · P2 = should run (boundaries, errors) · P3 = time-permitting (cosmetic, rare paths)
- **Steps a stranger can follow** — no tribal knowledge; name the exact button, field label, and menu path
- 10–25 cases per feature is the normal range; more means the feature should be split, fewer means boundaries/negatives are missing
