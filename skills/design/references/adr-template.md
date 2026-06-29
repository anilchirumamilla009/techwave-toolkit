# ADR Template Reference

## Standard Nygard ADR Format

```markdown
# ADR-[NNN]: [Short Title — present tense, e.g., "Use PostgreSQL for primary data store"]

**Date:** [YYYY-MM-DD]
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-NNN]
**Deciders:** [List of people involved in the decision]

---

## Context

[Describe the situation, problem, or requirement that forces this decision. Include relevant constraints: team size, performance targets, existing infrastructure, budget. Do NOT include the decision here — just the forces at play.]

## Decision

[State the decision in active voice: "We will use X" not "X was chosen". One paragraph maximum. Be specific about what is decided, not just the category (e.g., "We will use PostgreSQL 16 with read replicas" not just "We will use a relational database").]

## Consequences

### Positive
- [Benefit 1 — be specific, not generic ("Enables JSONB queries for our config schema" vs "Flexible schema")]
- [Benefit 2]

### Negative
- [Trade-off 1 — be honest about real costs ("Requires team to learn query planner tuning")]
- [Trade-off 2]

### Neutral / Risks
- [Assumption that, if wrong, would invalidate this decision]
- [Dependency: this decision is coupled to ADR-NNN]

## Alternatives Considered

| Option | Why Rejected |
|---|---|
| [Option A] | [Specific reason — not "too complex" but "requires X which we don't have"] |
| [Option B] | [Specific reason] |

## References
- [Link to relevant documentation, RFC, blog post, or prior art]
```

---

## Worked Example: Technology Choice ADR

```markdown
# ADR-001: Use PostgreSQL for Primary Data Store

**Date:** 2026-06-29
**Status:** Accepted
**Deciders:** Engineering Lead, Backend Team

---

## Context

We need a primary data store for the user and transaction data in our payments platform. Requirements:
- ACID transactions across multiple tables (user account + transaction records must be atomic)
- ~50k writes/day initially, scaling to ~500k/day in 12 months
- Team has strong SQL expertise; no prior NoSQL experience
- Compliance: must support row-level audit logging for SOC 2

## Decision

We will use PostgreSQL 16 as our primary relational database, hosted on RDS (managed AWS service) with one read replica for reporting queries.

## Consequences

### Positive
- JSONB column support allows flexible metadata fields on transactions without schema migrations
- Row-level security (RLS) satisfies our SOC 2 audit isolation requirement without application-layer changes
- RDS automated backups and point-in-time recovery reduces operational burden for the team

### Negative
- RDS licensing cost (~$300/month for db.t3.medium + replica) vs. self-managed (~$80/month compute)
- Connection pooling (PgBouncer) required at scale; adds operational complexity that the team hasn't managed before

### Neutral / Risks
- Assumes query complexity stays within PostgreSQL's optimizer capabilities — if we later need graph traversals, this decision may be revisited
- Coupled to AWS region choice (ADR-002); migrating to another cloud provider would require RDS migration

## Alternatives Considered

| Option | Why Rejected |
|---|---|
| MySQL 8 | No native row-level security — would require application-layer enforcement, increasing audit surface |
| MongoDB | Team has no MongoDB expertise; document model provides no benefit for our normalized transaction data |
| CockroachDB | Distributed consistency overhead unnecessary at our scale; higher operational complexity |

## References
- [PostgreSQL 16 RLS documentation](https://www.postgresql.org/docs/16/ddl-rowsecurity.html)
- SOC 2 CC6.3: Logical access controls requirement
```

---

## Worked Example: Architectural Pattern ADR

```markdown
# ADR-007: Use Event Sourcing for Inventory Updates

**Date:** 2026-06-29
**Status:** Proposed
**Deciders:** Architecture Review Board

---

## Context

Our current inventory service updates a `current_stock` integer directly. We have had three production incidents where concurrent updates caused stock to go negative, resulting in overselling. We need an approach that:
- Prevents negative inventory from concurrent writes
- Provides a complete audit trail of every stock change
- Allows replaying the inventory history for debugging

## Decision

We will implement event sourcing for the inventory domain. Stock levels will be derived by replaying events (StockAdded, StockReserved, StockReleased, StockAdjusted) from an append-only event log, rather than storing current state directly.

## Consequences

### Positive
- Concurrency handled at the event store level (optimistic concurrency via version numbers) — eliminates the race condition
- Full audit trail of all inventory changes is a built-in outcome, not an add-on
- Temporal queries (what was the stock level at 3pm yesterday?) become trivial

### Negative
- Requires a projection layer to answer "what is the current stock?" — adds a read model that must be kept in sync
- Team has no prior event sourcing experience; estimated 2-sprint learning curve
- Event schema changes are permanent — incorrect event definitions are very costly to fix

### Neutral / Risks
- Event store tooling choice (EventStoreDB vs. Kafka + Postgres) is a follow-on decision (ADR-008)
- If the projection rebuild time becomes unacceptable at scale, snapshotting will be required (not in scope for initial implementation)

## Alternatives Considered

| Option | Why Rejected |
|---|---|
| Pessimistic locking (SELECT FOR UPDATE) | Solves concurrency but kills throughput; unacceptable for our peak-hour write volume |
| Optimistic locking on current_stock | Still results in negative stock during concurrent reservations if multiple clients read same version |

## References
- Martin Fowler: Event Sourcing pattern
- Greg Young: CQRS and Event Sourcing
```

---

## Worked Example: Integration Approach ADR

```markdown
# ADR-012: Use Webhooks (not Polling) for Third-Party Order Updates

**Date:** 2026-06-29
**Status:** Accepted
**Deciders:** Integration Team Lead

---

## Context

Our fulfillment partner updates order statuses asynchronously. Currently we poll their API every 60 seconds, which results in: 86,400 API calls/day (near our rate limit), 60-second average delay in status updates, and $200/month in API call overage charges.

## Decision

We will migrate from polling to receiving webhooks from the fulfillment partner. We will expose a `POST /webhooks/fulfillment` endpoint that validates the partner's HMAC signature and enqueues the status update for processing.

## Consequences

### Positive
- Eliminates 86,400 unnecessary API calls per day
- Status updates will be received within seconds of the partner sending them (vs. 60s average)
- Removes rate limit risk entirely

### Negative
- We now depend on the partner's reliability for delivery — if their webhook delivery fails, we need a retry mechanism
- Requires implementing HMAC signature validation (security requirement) and idempotency (duplicate webhook handling)

### Neutral / Risks
- The partner guarantees "at least once" delivery — our handler must be idempotent
- If the partner's webhook service goes down, we will fall back to polling the `/status` endpoint for orders updated in the last 5 minutes (emergency fallback, not the happy path)

## Alternatives Considered

| Option | Why Rejected |
|---|---|
| Increase poll frequency to 10s | Increases API calls 6x; pushes us over the rate limit |
| Partner-provided SDK | SDK only supports polling; no webhook support |
```
