# UI Test Agent

**Role:** Generate tests for the frontend code — component tests, API client tests (mocking the OpenAPI contract), and critical user-journey E2E stubs.

---

## Step 1 — Read Stack and Generated Code

**Read the `Test runner:` line from Stack Config Frontend section** (loaded in Step 0.0). Use exactly what is declared there. If not declared, use the idiomatic default for the declared framework:
- React + Vite → Vitest + React Testing Library (`import { describe, it, expect } from 'vitest'`)
- Next.js → Jest + React Testing Library (`import { describe, it, expect } from '@jest/globals'`)
- Vue + Vite → Vitest + Vue Test Utils
- SvelteKit → Vitest + Svelte Testing Library

Read all files written by the UI Coding Agent:
- `src/api/client.ts` — identifies API client functions to test
- `src/api/types.ts` — interfaces for typed mocks
- `src/components/` — components to render and assert
- `src/hooks/` — hooks to test in isolation

---

## Step 2 — Generate Component Tests

For each component, write tests that assert on visible behavior — not implementation details:

```typescript
describe('LoginForm', () => {
  it('should submit credentials when form is filled and submitted', async () => {
    // TODO: implement
    render(<LoginForm onSuccess={vi.fn()} />)
    await userEvent.type(screen.getByLabelText('Email'), 'test@example.com')
    await userEvent.type(screen.getByLabelText('Password'), 'password123')
    await userEvent.click(screen.getByRole('button', { name: /login/i }))
    // assert API was called with correct args
  })

  it('should display error message when login fails', async () => {
    // TODO: implement
    expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument()
  })
})
```

---

## Step 3 — Generate API Client Tests

For each function in `src/api/client.ts`, write tests that mock `fetch` (or `axios`) and assert the request shape matches the OpenAPI spec:

```typescript
describe('loginUser', () => {
  it('should POST to /api/auth/login with credentials', async () => {
    // TODO: implement
    const mockFetch = vi.fn().mockResolvedValue({ ok: true, json: () => ({ token: 'abc', user: {} }) })
    global.fetch = mockFetch
    await loginUser({ email: 'a@b.com', password: 'pw' })
    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining('/api/auth/login'),
      expect.objectContaining({ method: 'POST' })
    )
  })

  it('should throw APIError when response is not ok', async () => {
    // TODO: implement
    await expect(loginUser({ email: '', password: '' })).rejects.toThrow(APIError)
  })
})
```

---

## Step 4 — Coverage Targets

| Layer | Target |
|---|---|
| API client functions | 100% — every function has a success + error test |
| Components (auth, payments) | 90%+ |
| Components (UI, utilities) | 60%+ |
| E2E stubs | 3–5 critical journeys (login, main action, error path) |

---

## Handoff

```
[UI Test Agent] Complete — <N> test files written.
  Component tests: <list>
  API client tests: <list>
```

After this handoff, the Backend Test Agent will complete, and then the Validator Agent will review both layers.
