# Test Framework Reference

## Stack → Framework Mapping

| Stack | Unit Tests | Integration Tests | E2E Tests | Install Command |
|---|---|---|---|---|
| **Node.js / TypeScript** | Jest + ts-jest | Jest + supertest | Playwright | `npm i -D jest ts-jest @types/jest supertest` |
| **Node.js / JavaScript** | Jest | Jest + supertest | Playwright | `npm i -D jest supertest` |
| **React / Next.js** | Vitest + React Testing Library | Vitest + MSW | Playwright / Cypress | `npm i -D vitest @testing-library/react @testing-library/jest-dom msw` |
| **Python (FastAPI)** | pytest + pytest-asyncio | pytest + httpx | Playwright | `pip install pytest pytest-asyncio httpx` |
| **Python (Django)** | pytest-django | pytest-django + factory_boy | Playwright / Selenium | `pip install pytest-django factory_boy` |
| **Go** | testing (stdlib) + testify | testify + httptest | Playwright | `go get github.com/stretchr/testify` |
| **Java (Spring Boot)** | JUnit 5 + Mockito | Spring Test + Testcontainers | Selenium / Playwright | `testImplementation 'org.springframework.boot:spring-boot-starter-test'` |
| **Rust** | cargo test (stdlib) | tokio-test + reqwest | - | Built-in to Cargo |

---

## Jest (Node.js / TypeScript)

### Config: `jest.config.ts`
```typescript
import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts', '**/*.spec.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 }
  }
}
export default config
```

### Run commands
```bash
npx jest                    # all tests
npx jest --coverage         # with coverage report
npx jest --testPathPattern=user  # filter by name
npx jest --watch            # watch mode
```

### Unit test stub
```typescript
import { UserService } from '../user.service'

describe('UserService', () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService(/* mock dependencies */)
  })

  describe('createUser', () => {
    it('should return created user with assigned ID', async () => {
      // TODO: implement
      const result = await service.createUser({ email: 'test@example.com', password: 'pass' })
      expect(result.id).toBeDefined()
      expect(result.email).toBe('test@example.com')
    })

    it('should throw when email already exists', async () => {
      // TODO: implement
      await expect(service.createUser({ email: 'existing@example.com', password: 'pass' }))
        .rejects.toThrow('Email already registered')
    })
  })
})
```

---

## pytest (Python / FastAPI)

### Config: `pyproject.toml`
```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"
```

### Run commands
```bash
pytest                      # all tests
pytest -v                   # verbose
pytest tests/unit/          # specific directory
pytest -k "test_create"     # filter by name
pytest --cov                # with coverage
```

### Unit test stub
```python
import pytest
from unittest.mock import AsyncMock, MagicMock
from src.services.user_service import UserService

@pytest.fixture
def user_service():
    repo = MagicMock()
    return UserService(repo=repo)

class TestUserServiceCreateUser:
    async def test_returns_created_user_with_id(self, user_service):
        # TODO: implement
        result = await user_service.create_user(email="test@example.com", password="pass")
        assert result.id is not None
        assert result.email == "test@example.com"

    async def test_raises_when_email_exists(self, user_service):
        # TODO: implement
        with pytest.raises(ValueError, match="Email already registered"):
            await user_service.create_user(email="existing@example.com", password="pass")
```

---

## Go (testing + testify)

### Run commands
```bash
go test ./...               # all tests
go test -v ./...            # verbose
go test -run TestCreateUser # filter
go test -cover ./...        # with coverage
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out
```

### Unit test stub
```go
package user_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "yourmodule/internal/user"
)

func TestUserService_CreateUser(t *testing.T) {
    t.Run("returns created user with assigned ID", func(t *testing.T) {
        // TODO: implement — set up service with mock repo
        svc := user.NewService(nil) // replace nil with mock
        result, err := svc.CreateUser(t.Name(), "test@example.com", "pass")
        require.NoError(t, err)
        assert.NotEmpty(t, result.ID)
        assert.Equal(t, "test@example.com", result.Email)
    })

    t.Run("returns error when email already exists", func(t *testing.T) {
        // TODO: implement
        svc := user.NewService(nil)
        _, err := svc.CreateUser(t.Name(), "existing@example.com", "pass")
        assert.ErrorIs(t, err, user.ErrEmailExists)
    })
}
```

---

## JUnit 5 + Mockito (Java / Spring Boot)

### Run commands
```bash
./mvnw test                 # Maven
./gradlew test              # Gradle
./gradlew test --tests "*.UserServiceTest"  # filter
```

### Unit test stub
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("should return created user with assigned ID")
    void createUser_withValidInput_returnsUserWithId() {
        // TODO: implement
        when(userRepository.save(any())).thenReturn(new User("uuid-123", "test@example.com"));

        User result = userService.createUser("test@example.com", "password");

        assertThat(result.getId()).isNotNull();
        assertThat(result.getEmail()).isEqualTo("test@example.com");
    }

    @Test
    @DisplayName("should throw when email already exists")
    void createUser_withDuplicateEmail_throwsException() {
        // TODO: implement
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.createUser("existing@example.com", "pass"))
            .isInstanceOf(EmailAlreadyExistsException.class);
    }
}
```

---

## Playwright (E2E — any stack)

### Install
```bash
npm i -D @playwright/test
npx playwright install
```

### Config: `playwright.config.ts`
```typescript
import { defineConfig } from '@playwright/test'
export default defineConfig({
  testDir: './e2e',
  use: { baseURL: 'http://localhost:3000', screenshot: 'only-on-failure' },
  webServer: { command: 'npm start', url: 'http://localhost:3000' }
})
```

### E2E test stub
```typescript
import { test, expect } from '@playwright/test'

test.describe('Login flow', () => {
  test('user can log in with valid credentials', async ({ page }) => {
    // TODO: implement
    await page.goto('/login')
    await page.fill('[data-testid="email"]', 'user@example.com')
    await page.fill('[data-testid="password"]', 'validpassword')
    await page.click('[data-testid="submit"]')
    await expect(page).toHaveURL('/dashboard')
  })

  test('shows error on invalid credentials', async ({ page }) => {
    // TODO: implement
    await page.goto('/login')
    await page.fill('[data-testid="email"]', 'wrong@example.com')
    await page.fill('[data-testid="password"]', 'wrongpass')
    await page.click('[data-testid="submit"]')
    await expect(page.getByText('Incorrect email or password')).toBeVisible()
  })
})
```
