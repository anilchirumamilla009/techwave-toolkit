# Tech Stack Evaluation Matrix

## Scoring Criteria

Score each option 1–5 per dimension (5 = best for this project). Adapt the weights to your project's priorities.

| Dimension | Weight | What to consider |
|---|---|---|
| **Performance** | varies | Throughput, latency at target scale |
| **Developer Experience** | varies | Learning curve, tooling, debugging |
| **Ecosystem** | varies | Libraries, community, long-term support |
| **Ops Burden** | varies | Deployment, monitoring, incident response |
| **Cost** | varies | Licensing, hosting, developer time |
| **Team Familiarity** | always high | Existing expertise on the team |

---

## Backend Language Comparison

| Language | Performance | Dev Exp | Ecosystem | Ops Burden | Cost | Notes |
|---|---|---|---|---|---|---|
| **Node.js / TypeScript** | 3 | 5 | 5 | 3 | 4 | Best for I/O-heavy APIs; single-threaded limits CPU tasks |
| **Python** | 2 | 5 | 5 | 3 | 4 | Dominant in ML/data; FastAPI is production-grade for APIs |
| **Go** | 5 | 3 | 4 | 5 | 5 | Excellent for microservices; compiled binaries, tiny containers |
| **Java / Kotlin** | 4 | 3 | 5 | 3 | 3 | Strong for enterprise; JVM startup time is a consideration |
| **Rust** | 5 | 2 | 3 | 4 | 4 | Best performance; steep learning curve; worth it for systems software |
| **Ruby** | 2 | 5 | 4 | 3 | 4 | Rails is highly productive; performance limits at high scale |
| **C# / .NET** | 4 | 4 | 4 | 3 | 3 | Strong Windows/Azure ecosystem; .NET 8 is cross-platform |

---

## Database Comparison

| Database | Consistency | Scale | Query Flexibility | Ops | Cost | Best For |
|---|---|---|---|---|---|---|
| **PostgreSQL** | ACID | Vertical + read replicas | SQL + JSONB + full-text | Medium | Low | General-purpose, financial data, audit trails |
| **MySQL / MariaDB** | ACID | Vertical + read replicas | SQL | Low | Low | Web apps, proven ops story |
| **MongoDB** | Eventual (default) | Horizontal | Document queries | Medium | Medium | Variable schemas, content, hierarchical data |
| **DynamoDB** | Configurable | Infinite | Key/range, limited scan | Low (managed) | Pay-per-use | Serverless, high-traffic KV access patterns |
| **Redis** | In-memory | Horizontal | KV, sorted sets, pub/sub | Low | Low | Cache, session store, rate limiting, queues |
| **Elasticsearch** | Eventually | Horizontal | Full-text, aggregations | High | High | Search, log analytics — not a primary store |
| **ClickHouse** | Eventual | Horizontal | OLAP queries | Medium | Medium | Analytics, time-series, large aggregations |
| **CockroachDB** | Distributed ACID | Horizontal | SQL | Medium | High | Geo-distributed ACID; Postgres-compatible |

---

## API Style Comparison

| Style | When to use | Drawbacks |
|---|---|---|
| **REST** | Standard CRUD, public APIs, widely understood | Over-fetching/under-fetching; multiple round trips |
| **GraphQL** | Complex queries, mobile apps, aggregating multiple services | N+1 query problem; complex caching; not ideal for simple CRUD |
| **gRPC** | Internal service-to-service (high throughput); streaming | Binary protocol — hard to debug; browser support requires grpc-web |
| **WebSockets** | Real-time bidirectional (chat, live updates, gaming) | Stateful connections; scaling is harder |
| **Webhooks** | Push-based event notification from third parties | Reliability requires retry logic; security requires HMAC validation |

---

## Frontend Framework Comparison

| Framework | Learning Curve | Performance | Ecosystem | Best For |
|---|---|---|---|---|
| **React + Vite** | Medium | Excellent | Largest | SPAs, highly interactive UIs, large teams |
| **Next.js** | Medium | Excellent | Large | SSR/SSG, SEO-critical apps, full-stack JS |
| **Vue 3 + Vite** | Low | Excellent | Medium | Approachable, progressive enhancement |
| **Angular** | High | Good | Large | Enterprise, opinionated structure, large teams |
| **SvelteKit** | Low | Best | Smaller | Performance-critical, minimal bundle size |
| **HTMX + server templates** | Low | Good | Small | Simpler interactivity, server-rendered apps, no build step |

---

## Infrastructure & Deployment Comparison

| Approach | Scale | Complexity | Cost | Best For |
|---|---|---|---|---|
| **Docker Compose** | Single host | Low | Lowest | Local dev, simple production for small apps |
| **Kubernetes (self-managed)** | High | Very High | High | Large teams with K8s expertise |
| **AWS ECS / GCP Cloud Run** | High | Medium | Pay-per-use | Managed containers without K8s overhead |
| **AWS Lambda / Cloud Functions** | Infinite | Low (per function) | Pay-per-request | Event-driven, sporadic traffic, no warm state |
| **Heroku / Railway / Render** | Medium | Lowest | Medium | Fastest time-to-production, small teams |
| **Bare metal / VMs** | Medium | High | Lowest (if owned) | Legacy, compliance constraints, GPU workloads |

---

## Decision Template (fill in for each evaluation)

```markdown
## Tech Stack Evaluation: [Decision Name]

**Context:** [What are we choosing between, and why now?]

**Constraints:**
- Team expertise: [languages/tools the team knows well]
- Scale target: [requests/day, data volume, users]
- Compliance: [any regulatory constraints on tech choice]
- Timeline: [how long until this needs to be production-ready]

**Evaluation:**

| Option | Performance | Dev Exp | Ecosystem | Ops | Cost | Team Fit | Total |
|---|---|---|---|---|---|---|---|
| [Option A] | [1-5] | [1-5] | [1-5] | [1-5] | [1-5] | [1-5] | [sum] |
| [Option B] | [1-5] | [1-5] | [1-5] | [1-5] | [1-5] | [1-5] | [sum] |

**Recommendation:** [Winner] — [one paragraph explaining why the score translates to a recommendation, including any non-obvious factors]

**Risk:** [What assumption, if wrong, would change this recommendation?]
```
