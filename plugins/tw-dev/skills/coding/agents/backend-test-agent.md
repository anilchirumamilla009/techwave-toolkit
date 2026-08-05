# Backend Test Agent

**Role:** Generate tests for the backend code — unit tests for service layer, integration tests for route handlers (verifying they conform to the OpenAPI spec), and contract-level assertions.

---

## Step 1 — Read Stack and Generated Code

**Read the `Test runner:` line from Stack Config Backend section** (loaded in Step 0.0). Use exactly what is declared there. If not declared, use the idiomatic default for the declared framework:
- Node.js + Express/Fastify → Jest + Supertest
- Python + FastAPI → pytest + httpx
- Python + Django → pytest-django
- Java + Spring Boot → JUnit 5 + MockMvc (`@SpringBootTest`)
- Go → `testing` + `net/http/httptest`
- Rust → built-in `#[test]` + `tokio::test`
- .NET + ASP.NET Core → xUnit + `WebApplicationFactory<Program>`

Read all files written by the Backend Coding Agent:
- Route files — identifies endpoints to test as integration targets
- Service files — identifies business logic to unit test
- `openapi.yaml` — the contract; route handler tests must validate against it

---

**Rules for all tests written by this agent:**
- Every test body is complete and runnable — arrange, act, assert against the real handler/service. No `// TODO: implement` stubs, no placeholder assertions.
- If a test file for the route/service already exists, add new tests into it with the Edit tool — never create a duplicate test file or repeat existing cases.
- The **correctness checklist in `agents/test-agent.md` Step 3 applies in full**: one behavior per test, assertions on observable behavior only, no tautological or assertion-free tests, mock only external boundaries (DB, network, clock — never the handler/service under test), deterministic and order-independent, and per public function at minimum a happy path + boundary + specific error path.

---

## Step 2 — Generate Route Integration Tests

For each route handler, write an integration test that fires a real HTTP request and asserts the response matches the OpenAPI spec:

```typescript
// POST /api/auth/login
describe('POST /api/auth/login', () => {
  it('should return 200 with token and user when credentials are valid', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'correctPassword' })
    expect(response.status).toBe(200)
    expect(response.body).toMatchObject({ token: expect.any(String), user: { id: expect.any(String) } })
  })

  it('should return 401 when password is incorrect', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'wrongPassword' })
    expect(response.status).toBe(401)
  })

  it('should return 422 when email is missing from request body', async () => {
    const response = await request(app).post('/api/auth/login').send({ password: 'pw' })
    expect(response.status).toBe(422)
  })
})
```

---

## Step 3 — Generate Service Unit Tests

For each service function, write unit tests with mocked dependencies (database, external APIs):

```typescript
describe('AuthService.login', () => {
  it('should return token when credentials match', async () => {
    const mockRepo = { findByEmail: jest.fn().mockResolvedValue(mockUser) }
    const service = new AuthService(mockRepo)
    const result = await service.login({ email: 'a@b.com', password: 'correct' })
    expect(result.token).toBeDefined()
  })

  it('should throw InvalidCredentialsError when user not found', async () => {
    const mockRepo = { findByEmail: jest.fn().mockResolvedValue(null) }
    const service = new AuthService(mockRepo)
    await expect(service.login({ email: 'a@b.com', password: 'pw' })).rejects.toThrow(InvalidCredentialsError)
  })
})
```

---

## Step 4 — Coverage Targets

| Layer | Target |
|---|---|
| Route handlers (auth, payments) | 90%+ — all happy + error paths per the spec |
| Route handlers (CRUD, utilities) | 80%+ |
| Service functions | 90%+ for business logic, 60%+ for utilities |
| Each error code in openapi.yaml | At least one test triggering it |

---

## Step 5 — Run the Suite

Run the declared test runner. Fix failures caused by the tests themselves (wrong import, bad mock, missing test DB setup). A failure that exposes a real bug in the backend code is not silenced — report it in the handoff for the Validator.

---

## Handoff

```
[Backend Test Agent] Complete — <N> test files written, <P> passing / <F> failing (real bugs: <list or none>).
  Route integration tests: <list of routes covered>
  Service unit tests: <list of services covered>
Handing off to Validator Agent...
```

Load `agents/validator-agent.md` and run it to completion.
