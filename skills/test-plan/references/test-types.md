# Test Types Reference

## The Testing Pyramid

```
         /\
        /E2E\         Few, slow, expensive — test critical user journeys
       /------\
      / Integ  \      Moderate — test service boundaries, DB, APIs
     /----------\
    / Unit Tests \    Many, fast, cheap — test business logic in isolation
   /--------------\
```

---

## Unit Test Characteristics

- **Scope**: Single function, class, or module in isolation
- **Dependencies**: All external dependencies (DB, HTTP, file system) are mocked
- **Speed**: < 1ms per test (entire suite runs in seconds)
- **Quantity**: Highest count — aim for every code path
- **When to write**: Before or alongside the implementation (TDD preferred)

### What to unit test
- Business logic (calculations, transformations, validations)
- Error handling and edge cases
- State machines / status transitions
- Input sanitization

### What NOT to unit test with mocks
- Database queries (mock the repo, not the SQL)
- HTTP request construction (let integration tests cover the full HTTP layer)
- Third-party SDK internals

### Setup/teardown pattern
```
beforeAll: set up shared expensive resources (test doubles, shared state)
beforeEach: reset state between tests (clear mocks, reset counters)
afterEach: assert no unexpected side effects
afterAll: tear down shared resources
```

---

## Integration Test Characteristics

- **Scope**: Multiple components working together — service + database, service + HTTP client
- **Dependencies**: Real database (Testcontainers or test DB), real HTTP (supertest/httpx), real filesystem
- **Speed**: 10ms–2s per test
- **Quantity**: Moderate — cover critical integration points, not every combination
- **When to write**: After unit tests; focus on boundary correctness

### What to integration test
- Database queries: schema correctness, constraint enforcement, index performance
- HTTP endpoints: request parsing, response shape, status codes, auth enforcement
- Message queue consumers: correct deserialization and processing
- External API clients: correct request construction (use WireMock or MSW)

### Integration test setup patterns

**Testcontainers (Java/Go/Node) — real database per test suite:**
```java
@Testcontainers
class UserRepositoryIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb");

    @BeforeAll
    static void runMigrations() {
        Flyway.configure().dataSource(postgres.getJdbcUrl(), ...).load().migrate();
    }
}
```

**pytest + real DB (Python):**
```python
@pytest.fixture(scope="module")
def db_session():
    # Uses TEST_DATABASE_URL env var pointing to a local/CI test database
    engine = create_engine(os.environ["TEST_DATABASE_URL"])
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    Base.metadata.drop_all(engine)
```

**supertest (Node.js) — full HTTP integration:**
```typescript
import request from 'supertest'
import { app } from '../src/app'

describe('POST /users', () => {
  it('returns 201 with created user', async () => {
    const res = await request(app)
      .post('/users')
      .send({ email: 'test@example.com', password: 'secure123' })
      .expect(201)

    expect(res.body.id).toBeDefined()
    expect(res.body.email).toBe('test@example.com')
    expect(res.body.password).toBeUndefined() // never return password hash
  })
})
```

---

## E2E Test Characteristics

- **Scope**: Full user journeys through the real application (browser or API end-to-end)
- **Dependencies**: Real running application, real (seeded) database
- **Speed**: 1s–30s per test
- **Quantity**: Fewest — cover the 3–7 most critical user journeys only
- **When to write**: After integration tests; focus on the paths that must never break

### Choosing which journeys to cover
Cover flows where breakage would immediately hurt users:
1. Authentication (login, logout, session expiry)
2. Core value creation (the main thing the app does — e.g., placing an order)
3. Payment or subscription flows (if applicable)
4. Critical admin actions (if applicable)
5. Data export/import (if applicable)

### E2E test data management
- Use a dedicated test database seeded before the test run
- Each test run resets state (truncate tables or use transactions that roll back)
- Never share state between E2E tests — tests must be independent and runnable in any order

---

## Coverage Target Table

| Risk Level | Examples | Unit | Integration | E2E journeys |
|---|---|---|---|---|
| **Critical** | Auth, payments, PII handling | 95% | 85% | All happy paths + main error paths |
| **High** | Order processing, core business logic | 85% | 70% | Happy paths |
| **Medium** | User preferences, search, notifications | 75% | 50% | Happy path only |
| **Low** | UI formatting, static content, utilities | 60% | — | — |

---

## CI Test Stage Assignment

| Test Type | CI Trigger | Allowed to fail? | Typical runtime |
|---|---|---|---|
| Unit tests | Every push | No — blocks merge | < 60s |
| Integration tests | Every push (or PR only) | No — blocks merge | 1–5 min |
| E2E tests | PR merge to main | No — blocks deployment | 5–15 min |
| Performance/load tests | Nightly or pre-release | Yes (alert only) | 30+ min |
| Security scans | Every push | Yes (alert) or No (policy) | 2–10 min |

---

## Test Plan Document Template

```markdown
## Test Plan: [Feature / Service Name]
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Risk Level:** [Critical / High / Medium / Low]

### Scope
[What is included in testing for this feature/service]

### Out of Scope
[What is explicitly not tested and why]

### Unit Tests
| Component / Function | Test Cases | Coverage Target |
|---|---|---|
| [UserService.createUser] | Valid input, duplicate email, invalid email format | 90% |

### Integration Tests
| Integration Point | What is Verified | Real vs Mocked |
|---|---|---|
| POST /users endpoint | 201 on success, 422 on duplicate, 400 on invalid input | Real DB (Testcontainers) |

### E2E Tests
| Journey | Steps | Expected Outcome |
|---|---|---|
| User registration | Navigate to /register → Fill form → Submit | Redirected to dashboard, welcome email sent |

### Performance Considerations
- [Target latency: POST /users must complete in < 200ms at p99 under 100 RPS]
- [Load test: run 1000 concurrent registrations, verify no data corruption]

### CI Integration
- Unit + integration tests: run on every PR push, must pass before merge
- E2E tests: run on merge to main, must pass before deployment to staging
```
