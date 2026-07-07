# Backend Coding Agent

**Role:** Generate all backend code implementing the API contract defined in `openapi.yaml`. Every path in the spec gets a corresponding handler. The backend is the source of truth for the contract — it must match the spec exactly.

---

## Step 1 — Read the Contract and Stack

**Read the contract:**
Read `openapi.yaml` (or `docs/openapi.yaml`). Extract:
- All endpoint paths, methods, `operationId`, request/response schemas
- Auth requirements (which routes are protected)
- Error response codes that must be implemented

**Read Stack Config Backend section** (already loaded as Stack Config):
- Language and framework (Node.js + Express, Python + FastAPI, Go + Gin, Java + Spring Boot, etc.)
- Package manager
- Test runner

Map to the stack reference file:

| Stack Config Backend | Reference |
|---|---|
| Node.js, Express, TypeScript | `references/stacks/nodejs.md` |
| Python, FastAPI, Django, Flask | `references/stacks/python.md` |
| Java, Spring Boot, Quarkus | `references/stacks/java.md` |
| Go, Gin, Echo | `references/stacks/go.md` |
| Rust, Axum, Actix | `references/stacks/rust.md` |
| C#, .NET, ASP.NET Core | `references/stacks/dotnet.md` |

---

## Step 2 — Plan the Structure

All backend code lives under `backend/` in the monorepo root. Show the planned tree:

```
[Backend Coding Agent] Planning Node.js (Express + TypeScript) structure:

backend/
  src/
    routes/
      <resource>.routes.ts    # one file per tag in openapi.yaml
    controllers/
      <resource>.controller.ts
    middleware/
      auth.middleware.ts      # JWT validation
      validation.middleware.ts
    models/
      <Entity>.ts             # data models from openapi schemas
    services/
      <resource>.service.ts   # business logic, separated from routing
  .env.example               # DB_URL, JWT_SECRET, PORT, etc.
  package.json
  tsconfig.json              # or equivalent for the declared stack

Confirm? (yes / adjust)
```

The `openapi.yaml` contract lives at `docs/openapi.yaml` in the monorepo root — read it from there; do not copy it into the backend folder.

**Do not write any files until the user confirms.**

---

## Step 3 — Write Backend Code

After confirmation, generate one handler per path+method in `openapi.yaml`:

```typescript
// POST /api/auth/login — loginUser
router.post('/auth/login', validateBody(LoginRequestSchema), async (req, res) => {
  try {
    const result = await authService.login(req.body)
    res.json(result)
  } catch (err) {
    if (err instanceof InvalidCredentialsError) return res.status(401).json({ error: 'Invalid credentials' })
    res.status(500).json({ error: 'Internal server error' })
  }
})
```

Rules:
- Every route from the spec is implemented — no missing handlers
- Input validation matches the spec's request schema (use Zod for Node.js, Pydantic for Python, etc.)
- Auth middleware is applied to every route where the spec requires `security: [BearerAuth: []]`
- Error responses match spec-declared error codes (401, 403, 404, etc.)
- No hardcoded secrets — read from environment variables; document in `.env.example`
- Business logic lives in a service layer, not in route handlers

---

## Handoff

```
[Backend Coding Agent] Complete — <N> files written.
  Routes: <M> handlers implementing all openapi.yaml paths
  Middleware: <list>
  Services: <list>
Handing off to Backend Test Agent...
```

Load `agents/backend-test-agent.md` and run it to completion.
