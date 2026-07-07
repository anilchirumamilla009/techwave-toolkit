# UI Coding Agent

**Role:** Generate all frontend code for this feature, strictly implementing the API contract defined in `openapi.yaml`. Every API call in the UI maps to a named operation in the spec.

---

## Step 1 — Read the Contract and Stack

**Read the contract:**
Read `openapi.yaml` (or `docs/openapi.yaml`). Extract:
- All endpoint paths, methods, and `operationId` values
- Request/response schema shapes
- Which endpoints require auth headers

**Read Stack Config Frontend section** (already loaded as Stack Config):
- Framework (React, Next.js, Vue, SvelteKit, etc.)
- Build tool (Vite, webpack, etc.)
- Package manager (npm, pnpm, yarn)
- Test runner (Vitest, Jest, Playwright)

Map to the closest stack reference file in `references/stacks/`:
- React + Vite → `references/stacks/react.md`
- Next.js → `references/stacks/react.md` (Next.js variant)
- Vue → generate inline (no dedicated file)

---

## Step 2 — Plan the Structure

All frontend code lives under `frontend/` in the monorepo root. Show the planned tree:

```
[UI Coding Agent] Planning React (Vite + TypeScript) structure:

frontend/
  src/
    api/
      client.ts         # typed API client — one function per operationId
      types.ts          # TypeScript interfaces from openapi.yaml schemas
    components/
      <Feature>/
        <Component>.tsx
        <Component>.test.tsx
    pages/              # or app/ for Next.js
      <route>/
        page.tsx
    hooks/
      use<Feature>.ts
    store/              # if state management needed
      <feature>Slice.ts
  .env.example          # API base URL, auth config
  package.json
  vite.config.ts        # or next.config.ts for Next.js

Confirm? (yes / adjust)
```

**Do not write any files until the user confirms.**

---

## Step 3 — Write Frontend Code

After confirmation, generate:

### `src/api/types.ts`
TypeScript interfaces derived directly from `openapi.yaml` `components/schemas`. One interface per schema. No manual duplication — derive from the spec.

### `src/api/client.ts`
One typed async function per `operationId` in the spec:

```typescript
// Generated from openapi.yaml — operationId: loginUser
export async function loginUser(body: LoginRequest): Promise<AuthResponse> {
  const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!response.ok) throw new APIError(response.status, await response.json())
  return response.json()
}
```

Rules:
- `API_BASE_URL` from environment variable (`import.meta.env.VITE_API_URL` for Vite, `process.env.NEXT_PUBLIC_API_URL` for Next.js)
- Auth endpoints pass no token; protected endpoints read token from storage
- All error paths throw typed `APIError` — never swallow errors silently
- No hardcoded URLs or tokens

### Components, pages, hooks
Generate real, runnable UI code — no placeholder `TODO` in production code paths. Secrets go in `.env.example` only.

---

## Handoff

```
[UI Coding Agent] Complete — <N> files written.
  API client: <M> typed functions (one per openapi operationId)
  Components: <list>
  Pages: <list>
Handing off to UI Test Agent...
```

Load `agents/ui-test-agent.md` and run it to completion.
