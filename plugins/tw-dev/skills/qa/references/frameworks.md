# E2E & QA Framework Reference

## E2E Framework Selection (by project type)

| Project type | E2E Framework | Install |
|---|---|---|
| Web frontend (React, Next.js, Vue, SvelteKit, any) | Playwright | `npm i -D @playwright/test && npx playwright install` |
| Web frontend (team prefers Cypress) | Cypress | `npm i -D cypress` |
| API only — Node.js | Supertest | `npm i -D supertest` |
| API only — Python | httpx + pytest | `pip install httpx pytest` |
| Mobile (cross-platform) | Maestro | `curl -Ls https://get.maestro.mobile.dev \| bash` |
| Mobile (React Native) | Detox | `npm i -D detox` |
| Mobile (native iOS / Android) | XCUITest / Espresso | ships with Xcode / Android Studio |
| CLI tool | bats, or pytest + `subprocess` / Go `os/exec` | `npm i -g bats` or per stack |
| Desktop (Electron / Tauri) | Playwright | as above |
| Library / SDK | example project importing the published API | per stack |
| Data pipeline | Great Expectations / dbt tests / pytest full-run | `pip install great_expectations` |
| ML project | evaluation harness (pytest + metrics thresholds) | per stack |

Unit and integration test frameworks are handled by the `/coding` skill's test agents. This reference focuses on E2E and QA-layer tooling.

---

## Playwright (E2E — any web stack)

### Config: `playwright.config.ts`
```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

### Run commands
```bash
npx playwright test               # all E2E tests
npx playwright test --ui          # interactive mode
npx playwright test e2e/login     # specific file
npx playwright show-report        # view last report
```

### Journey stub pattern
```typescript
import { test, expect } from '@playwright/test'

test.describe('Login flow', () => {
  test.beforeEach(async ({ page }) => {
    // TODO: seed test user via API or DB script
  })

  test('user sees dashboard after valid login', async ({ page }) => {
    // TODO: implement
    await page.goto('/login')
    await page.getByLabel('Email').fill('user@example.com')
    await page.getByLabel('Password').fill('validpassword')
    await page.getByRole('button', { name: /sign in/i }).click()
    await expect(page).toHaveURL('/dashboard')
    await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible()
  })

  test('user sees error message on invalid credentials', async ({ page }) => {
    // TODO: implement
    await page.goto('/login')
    await page.getByLabel('Email').fill('wrong@example.com')
    await page.getByLabel('Password').fill('wrongpass')
    await page.getByRole('button', { name: /sign in/i }).click()
    await expect(page.getByText('Incorrect email or password')).toBeVisible()
    await expect(page).toHaveURL('/login')
  })
})
```

### Accessibility snapshot (axe-core integration)
```typescript
import { test, expect } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

test('login page has no critical accessibility violations', async ({ page }) => {
  await page.goto('/login')
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze()
  expect(results.violations).toEqual([])
})
```

---

## Maestro (E2E — mobile, cross-platform)

### Journey stub: `e2e/flows/login.yaml`
```yaml
appId: com.example.app
---
- launchApp
- tapOn: "Email"
- inputText: "user@example.com"
- tapOn: "Password"
- inputText: "validpassword"
- tapOn: "Sign In"
- assertVisible: "Welcome"
```

### Run commands
```bash
maestro test e2e/flows/login.yaml    # single flow
maestro test e2e/flows/              # all flows
```

---

## CLI Testing (bats / subprocess)

### bats stub: `tests/e2e/cli.bats`
```bash
#!/usr/bin/env bats

@test "prints version with --version" {
  run mycli --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^mycli\ [0-9]+\.[0-9]+ ]]
}

@test "fails with exit 2 and usage on missing input file" {
  run mycli process ./does-not-exist.csv
  [ "$status" -eq 2 ]
  [[ "$output" =~ "No such file" ]]
}
```

### pytest + subprocess stub (any stack)
```python
# tests/e2e/test_cli.py
import subprocess

def test_happy_path_writes_output(tmp_path):
    out = tmp_path / "result.json"
    r = subprocess.run(["mycli", "process", "fixtures/sample.csv", "-o", str(out)],
                       capture_output=True, text=True)
    assert r.returncode == 0
    assert out.exists()

def test_bad_args_exit_nonzero():
    r = subprocess.run(["mycli", "--bogus"], capture_output=True, text=True)
    assert r.returncode != 0
    assert "usage" in r.stderr.lower()
```

Assert on the CLI's public surface only: exit codes, stdout/stderr, files produced — never internals.

---

## Data Pipeline Testing

### Full-run test on fixture data
```python
# tests/e2e/test_pipeline_run.py
from pipeline import run

def test_full_run_on_fixture(tmp_path):
    result = run(input_path="fixtures/sample_events.jsonl", output_dir=tmp_path)
    assert result.rows_out > 0
    assert result.rows_rejected == 0          # fixture is known-clean
    # output schema invariants
    df = result.load_output()
    assert set(df.columns) >= {"id", "timestamp", "amount"}
    assert df["id"].is_unique
    assert df["amount"].ge(0).all()
```

Data-quality suites (Great Expectations, dbt tests) belong in CI on every run, not only in E2E: uniqueness, nullability, referential integrity, value ranges, row-count deltas vs. previous run.

---

## k6 (Performance / Load Testing)

### Install
```bash
# macOS
brew install k6

# Linux
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/k6.list && sudo apt-get update && sudo apt-get install k6
```

### Steady-state load test stub
```javascript
// e2e/performance/load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
  vus: 50,           // 50 virtual users
  duration: '5m',    // sustained for 5 minutes
  thresholds: {
    http_req_duration: ['p(99)<500'],  // 99% of requests < 500ms
    http_req_failed: ['rate<0.01'],    // error rate < 1%
  },
}

export default function () {
  const res = http.post('http://localhost:3000/api/auth/login', JSON.stringify({
    email: 'loadtest@example.com',
    password: 'loadtestpass',
  }), { headers: { 'Content-Type': 'application/json' } })

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response has token': (r) => JSON.parse(r.body).token !== undefined,
  })

  sleep(1)
}
```

### Run commands
```bash
k6 run e2e/performance/load-test.js
k6 run --vus 100 --duration 10m e2e/performance/load-test.js
```

---

## Test Data Factory Pattern

```typescript
// e2e/factories/user.factory.ts
import { randomUUID } from 'crypto'

export function createTestUser(overrides: Partial<UserInput> = {}): UserInput {
  const id = randomUUID().slice(0, 8)
  return {
    email: `test-${id}@example.com`,
    password: 'TestPass123!',
    name: `Test User ${id}`,
    ...overrides,
  }
}
```

---

## Locust (Python load testing alternative)

```python
# e2e/performance/locustfile.py
from locust import HttpUser, task, between

class AppUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        # TODO: authenticate and store token
        pass

    @task
    def login(self):
        self.client.post('/api/auth/login', json={
            'email': 'loadtest@example.com',
            'password': 'loadtestpass',
        })
```

```bash
locust -f e2e/performance/locustfile.py --headless -u 50 -r 5 --run-time 5m --host http://localhost:3000
```
