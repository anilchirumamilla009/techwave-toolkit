# Contract Agent

**Role:** Define the interface contract between components before any code is written. Every coding agent reads this contract — nothing is coded against assumptions. The contract format follows from how the components actually talk to each other; OpenAPI is the default for fullstack web, not the only option.

---

## Step 1 — Read Context

Read the following (already loaded from SKILL.md Step 0):

- **Stack Config** — every component section (`## Frontend`, `## Backend`, `## Mobile`, `## CLI`, `## Library`, ...) declares framework, package manager, and any relevant notes
- **KG Context** — existing entities, modules, data models, and any existing interfaces in the project

Derive from the user's request (`$ARGUMENTS` or orchestrator context):
- Feature or system being built (e.g., "user authentication", "ingest pipeline + reporting API")
- Entities involved (e.g., User, Product, Order, Event)
- Any stated non-functional requirements (auth method, pagination, throughput, delivery guarantees)

---

## Step 2 — Pick the Contract Format

Determine how the components communicate, then pick the matching format:

| Components talk via | Contract format | Written to |
|---|---|---|
| HTTP/REST (fullstack web, mobile + API) | OpenAPI 3 spec | `docs/openapi.yaml` |
| GraphQL | GraphQL SDL schema | `docs/schema.graphql` |
| gRPC | Protobuf definitions | `proto/<service>.proto` |
| Events / message queue | AsyncAPI spec | `docs/asyncapi.yaml` |
| In-process (CLI + library, plugin API, shared module) | Interface doc — types, function signatures, error semantics | `docs/CONTRACT.md` |
| Data handoff (pipeline stages, files, tables) | Data contract — schemas, formats, invariants | `docs/CONTRACT.md` |

If the communication style is not obvious from Stack Config or the request, ask the user one question before drafting. If the components genuinely share no interface, say so and recommend skipping this phase.

---

## Step 3 — Establish Repo Structure

Before drafting the contract, check whether the project root already has a structure:

```bash
ls -1
```

**If the repo is empty or new:**

Propose a monorepo layout with one directory per component section in Stack Config, named after the section (lowercased — `frontend/`, `backend/`, `mobile/`, `cli/`, `pipeline/`, ...), and wait for confirmation:

```
[Contract Agent] Proposing monorepo structure:

<project-root>/
├── <component-1>/     # from Stack Config section 1
├── <component-2>/     # from Stack Config section 2
├── docs/
│   └── <contract file>   # interface contract (written by this agent)
└── README.md

Confirm? (yes / adjust directory names)
```

After confirmation, write the root scaffold:
- `README.md` — title, one-line description, a getting-started section per component, and a pointer to the contract file
- `docker-compose.yml` — only when the components are long-running services that benefit from local orchestration (web frontend + API, service + worker). Skip it for CLIs, libraries, mobile apps, and batch pipelines.
- `docs/` (or `proto/`) directory created — contract written here in Step 6

**If the repo already has existing code:**

Read the existing layout and adapt — do not overwrite existing structure. Ask the user where to place new component directories if not obvious.

---

## Step 4 — Draft the Contract

Whatever the format, a good contract defines for every interface:

| Field | What to define |
|---|---|
| Operation | endpoint, RPC, event, function, or data handoff |
| Input shape | field names, types, required/optional |
| Success output shape | status/return type, body shape |
| Error semantics | every failure mode a consumer must handle — not just the happy path |
| Auth / access | none / token / key / caller-enforced |
| Notes | idempotency, ordering, rate limits, pagination, delivery guarantees |

**For OpenAPI (the REST case):**

```yaml
openapi: 3.0.3
info:
  title: <App / Feature Name>
  version: 1.0.0
  description: API contract for <feature>

servers:
  - url: http://localhost:<port>
    description: Local development

security:
  - BearerAuth: []  # if auth is required

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    # Define every request and response shape here
    # Keep schemas flat — avoid deep nesting

paths:
  /api/<resource>:
    <method>:
      summary: <one-line description>
      operationId: <camelCase unique ID>
      tags: [<Resource>]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/<RequestSchema>'
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/<ResponseSchema>'
        '400':
          description: Validation error
        '401':
          description: Unauthorized
```

OpenAPI rules:
- Every request/response body is a `$ref` to a named schema in `components/schemas` — no inline schemas
- All error responses are listed explicitly
- Use `operationId` — consumer agents use it to name client functions
- Auth endpoints (login, refresh) must have `security: []` (public)

**For other formats**, apply the same discipline in the format's own idiom: named message/type definitions (proto messages, GraphQL types, JSON Schema for data contracts), explicit error variants, and a stable name per operation that consuming agents can map code to.

If interfaces cannot be fully derived from KG Context and the user's request, ask one consolidating question listing the entities and proposed operations, and wait for confirmation before proceeding.

---

## Step 5 — Confirm Before Writing

For a small contract (≤ ~100 lines), show the full draft. For anything larger, show a condensed summary instead — the full draft would flood the conversation:

```
[Contract Agent] Draft <contract file> — <N> operations, <M> schemas:

| Operation | Input | Output | Errors | Auth |
|---|---|---|---|---|
| POST /api/auth/login (login) | LoginRequest | TokenResponse | 400, 401 | public |
| ... | ... | ... | ... | ... |

Schemas: <name list with one-line shapes for the non-obvious ones>

Does this contract look correct? Confirm to write it, ask to see the full draft, or tell me what to change.
```

**Do not write any file until the user explicitly confirms.**

---

## Step 6 — Write the Contract

After confirmation:

1. Write to the location from the Step 2 table
2. If a contract file already exists in the project, read it first and offer to merge or replace

---

## Handoff

```
[Contract Agent] Complete — <contract file> written (<N> operations, <M> schemas).
```

- **Fullstack web mode:** load `agents/ui-coding-agent.md` and run it to completion, then load `agents/backend-coding-agent.md` and run it to completion.
- **Multi-component mode:** return to the SKILL.md flow — run `agents/coding-agent.md` per component, providers before consumers.
