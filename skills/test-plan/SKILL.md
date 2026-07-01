---
name: test-plan
description: This skill should be used when the user asks to "create a test plan", "write tests for", "generate test cases", "plan unit tests", "plan e2e tests", "test strategy for", "what should we test", "generate integration tests", "create a testing strategy", "write test stubs", "generate test coverage", "QA plan", or needs any form of structured testing approach for a feature, service, or codebase. This skill generates both the written test plan document and runnable test stubs.
version: 0.1.0
---

# Testing Skill

## Overview

This skill generates two outputs: (1) a written test plan document describing scope, test types, and coverage targets, and (2) runnable test code stubs with failing assertions. It detects the tech stack to select the appropriate test framework and generates idiomatic test code for that framework.

## When to Use

Invoke when the user wants to plan, structure, or generate tests for a feature, service, endpoint, or codebase. Works at any granularity — single function, full service, or entire system.

## Step 0 — Knowledge Graph Check

Load `../shared/knowledge-graph.md` for the full protocol. Summary:

1. If `graphify-out/graph.json` exists → run `bash scripts/query-kg.sh "<module or service name being tested>"`
2. If missing → run `bash scripts/setup-kg.sh` first, then query
3. Inject results as KG Context (existing test files, coverage gaps, risky modules) before Step 1

---

## Step-by-Step Process

### 1. Identify the Scope

Ask if not clear from context:
- What is being tested? (function, module, API, user flow, full system)
- Is there existing code to read? (if yes, read it before generating tests)
- What is the risk level? (higher risk = more thorough test plan)

### 2. Detect the Tech Stack

Check for framework marker files (same logic as `/scaffold`):
- `package.json` / `tsconfig.json` → Node.js/TypeScript
- `go.mod` → Go
- `pom.xml` / `build.gradle` → Java
- `pyproject.toml` / `requirements.txt` → Python
- `Cargo.toml` → Rust

Load `references/frameworks.md` to select the idiomatic test framework for the detected stack.

### 3. Produce the Test Plan Document

Structure the test plan as follows (from `references/test-types.md`):

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
[Which stage in CI should run which test type]
```

### 4. Generate Test Stubs

Generate actual test stubs with failing assertions using the framework from `references/frameworks.md`. The stubs must:
- Use the correct import syntax for the detected framework
- Have meaningful test names (describe the behavior, not the implementation)
- Include `// TODO: implement` in the assertion body — never leave empty test bodies
- Be runnable immediately with the project's test command without modification

Example pattern for a unit test stub:
```
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

### 5. Coverage Targets

Set coverage targets based on risk level:
- **High risk** (auth, payments, data mutations): 90%+ unit, 80%+ integration
- **Medium risk** (business logic, APIs): 80%+ unit, 60%+ integration
- **Low risk** (UI, utilities): 60%+ unit
- E2E: cover the 3–5 most critical user journeys regardless of risk level

## Output Format

Produce in this order:
1. Test plan document (Markdown)
2. `---`
3. Test stubs (code blocks, grouped by test type)
4. Getting started commands (how to run the tests)

## Key Rules

- Never generate empty test bodies — always include a failing assertion and a `// TODO: implement` comment
- Always use the idiomatic assertion style for the detected framework (e.g., `expect().toBe()` for Jest, `assert.Equal()` for Go testify, `assert` for Python pytest)
- For integration tests: distinguish clearly which dependencies are real (database, real HTTP) vs mocked
- Test names must describe behavior, not implementation: prefer "should return 404 when user not found" over "test getUserById error"
- If there is no existing code, generate tests first (TDD approach) — note this in the output
