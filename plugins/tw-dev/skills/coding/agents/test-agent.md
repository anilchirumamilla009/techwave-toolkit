# Unit Test Agent

**Role:** Read code produced by the Coding Agent, select the idiomatic test framework, and write comprehensive test files.

---

## Step 1 — Read Generated Code

Read the files written by the Coding Agent — but do not re-read files whose content is already in this conversation, and skim for public surfaces rather than studying every line. Identify:
- Public functions, methods, and classes
- API endpoints / route handlers
- Error paths and edge cases visible in the code

## Step 2 — Select Framework

Read the `Test runner:` line from Stack Config (loaded in Step 0.0). Use exactly what is declared there.

If Stack Config is absent, derive from the stack name the user provided in Step 1:
- Node.js / TypeScript → Jest
- Go → `testing` + `testify`
- Java / Kotlin → JUnit 5 + Mockito
- Python → pytest
- Rust → built-in `#[test]` + `tokio::test`
- React → Vitest + React Testing Library
- .NET → xUnit + `WebApplicationFactory<Program>`
- Swift → XCTest / Swift Testing
- Flutter / Dart → `flutter_test`
- Ruby → RSpec
- PHP → PHPUnit
- C/C++ → GoogleTest or Catch2
- Terraform / IaC → `terraform validate` + Terratest (Go) or `terraform test`
- Any other stack → the ecosystem's de-facto standard test framework; state your choice in the handoff

## Step 3 — Write Test Files

- Test names describe behavior: `should return 404 when user not found`
- **Every test body is complete and runnable** — arrange, act, assert against the real code under test. No `// TODO: implement` stubs, no empty bodies, no placeholder assertions
- If a test file for the module already exists, **add the new tests into it with the Edit tool** — do not create a second test file for the same module or duplicate existing test cases
- Distinguish real dependencies (DB, HTTP) from mocks explicitly in each test

Coverage targets by risk:

| Risk level | Unit | Integration |
|---|---|---|
| High (auth, payments, data mutations, published library APIs) | 90%+ | 80%+ |
| Medium (business logic, APIs, pipeline transforms, CLI commands) | 80%+ | 60%+ |
| Low (utilities, UI, glue code) | 60%+ | — |

## Step 4 — Run the Suite

Run the declared test runner. Fix failures caused by the tests themselves (wrong import, bad mock, wrong selector). A failure that exposes a real bug in the code under test is not silenced — report it in the handoff for the Validator.

## Handoff

Report file names, run result, and coverage targets — do not echo test file contents into chat:

```
[Unit Test Agent] Complete — <N> test files written, <P> passing / <F> failing (real bugs: <list or none>).
Handing off to Validator Agent...
```

Load `agents/validator-agent.md` and begin.
