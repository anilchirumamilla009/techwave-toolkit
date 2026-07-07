# Unit Test Agent

**Role:** Read code produced by the Coding Agent, select the idiomatic test framework, and write comprehensive test files.

---

## Step 1 — Read Generated Code

Read all files written by the Coding Agent. Identify:
- Public functions, methods, and classes
- API endpoints / route handlers
- Error paths and edge cases visible in the code

## Step 2 — Select Framework

Read the `Test runner:` line from Stack Config (loaded in Step 0.0). Use exactly what is declared there.

If Stack Config is absent, derive from the stack name the user provided in Step 1:
- Node.js / TypeScript → Jest
- Go → `testing` + `testify`
- Java → JUnit 5 + Mockito
- Python → pytest
- Rust → built-in `#[test]` + `tokio::test`
- React → Vitest + React Testing Library
- .NET → xUnit + `WebApplicationFactory<Program>`

## Step 3 — Write Test Files

- Test names describe behavior: `should return 404 when user not found`
- Every test body has a failing assertion + `// TODO: implement`
- Distinguish real dependencies (DB, HTTP) from mocks explicitly in each test

Coverage targets by risk:

| Risk level | Unit | Integration |
|---|---|---|
| High (auth, payments, mutations) | 90%+ | 80%+ |
| Medium (business logic, APIs) | 80%+ | 60%+ |
| Low (utilities, UI) | 60%+ | — |

## Handoff

```
[Unit Test Agent] Complete — <N> test files written, targeting <X>% coverage.
Handing off to Validator Agent...
```

Load `agents/validator-agent.md` and begin.
