---
name: design
description: This skill should be used when the user asks to "design the system", "create an architecture diagram", "draw a component diagram", "write an ADR", "architecture decision record", "tech stack recommendation", "system design for", "design the components of", "create a sequence diagram", "draw an ER diagram", "C4 diagram", "design the data model", "propose a solution architecture", "create HLD", "create LLD", "high level design", "low level design", or needs any form of system design or architectural documentation. Use this skill for technical design artifacts across any technology stack.
version: 0.2.0
disable-model-invocation: true
---

# Architecture & Design Skill

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**0.1 Install graphify if missing**
```bash
command -v graphify || pip install graphifyy || pip3 install graphifyy
```

**0.2 Build the graph if missing**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || (graphify . && graphify claude install && grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore)
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing design docs (`docs/HLD.md`, `docs/LLD.md`, `docs/ADR-*.md`), known components and relationships, dominant stack. If a design doc already exists, read it — offer to update rather than regenerate. Hold as **KG Context**.

Full protocol: `../shared/knowledge-graph.md`

---

## Step-by-Step Process

### 1. Identify the Artifact Type

| User says | Artifact | Saved to |
|---|---|---|
| "HLD", "high-level design", "system design", "architecture diagram" | C4 Context + Container diagrams + narrative | `docs/HLD.md` |
| "LLD", "low-level design", "component diagram", "class diagram" | Component / class / sequence diagrams + API contracts | `docs/LLD.md` |
| "sequence diagram", "flow" | Mermaid `sequenceDiagram` | `docs/LLD.md` |
| "ER diagram", "data model" | Mermaid `erDiagram` | `docs/LLD.md` |
| "ADR", "architecture decision" | Nygard ADR | `docs/ADR-NNN-<kebab-title>.md` |
| "tech stack", "which technology" | Evaluation matrix + recommendation | inline only |
| "design the system" (generic) | HLD first, then ask if LLD is also needed | `docs/HLD.md` |

All diagrams are Mermaid text-based (renders on GitHub, GitLab, Notion). Load `references/diagram-formats.md` for syntax starters.

### 2. Tech Stack Decisions — Collect Constraints First

Before recommending a tech stack, ask:
1. Team's language preference or existing expertise
2. Deployment target (cloud, on-prem, serverless)
3. Performance/scale requirements
4. Existing systems this must integrate with

Apply scoring matrix from `references/tech-stack-evaluation.md`. Present matrix first, recommendation second — never the reverse.

### 3. Confirm Before Writing

Show planned documents and destination paths. Wait for confirmation.

```
[Design Skill] I'll create:

  docs/HLD.md — C4 context + container diagrams, design decisions
  docs/LLD.md — component diagram, sequence diagrams, data model, API contracts

I'll create docs/ if it doesn't exist. Proceed?
```

### 4. Write to docs/

After confirmation:
1. Create `docs/` in the project root if it does not exist
2. Write each document using the templates below
3. ADRs: filename `docs/ADR-<NNN>-<kebab-title>.md`; increment NNN by reading existing ADR files

---

## Document Templates

### HLD (`docs/HLD.md`)

````markdown
# High-Level Design: [System / Feature Name]

## Overview
[2–3 sentences: what this system does and why]

## System Context

```mermaid
C4Context
  [actors, external systems, boundaries]
```

## Container View

```mermaid
C4Container
  [major deployable units and interactions]
```

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| [e.g., Messaging] | [e.g., Kafka] | [e.g., ordered delivery, replay] |

## Non-Functional Requirements

| Attribute | Target |
|---|---|
| Availability | [e.g., 99.9%] |
| Latency (p99) | [e.g., < 200ms] |
| Data retention | [e.g., 90 days] |
````

### LLD (`docs/LLD.md`)

````markdown
# Low-Level Design: [Service / Module Name]

## Component Diagram

```mermaid
[class or component diagram]
```

## Sequence: [Primary Use Case]

```mermaid
sequenceDiagram
  [critical request flow]
```

## Data Model

```mermaid
erDiagram
  [entities and relationships]
```

## API Contracts

| Method | Path | Request | Response |
|---|---|---|---|
| POST | /resource | {field: type} | {id: uuid} |

## Error Handling

| Scenario | Behavior |
|---|---|
| [e.g., upstream timeout] | [e.g., retry x3, then return 503] |
````

### ADR (`docs/ADR-NNN-title.md`)

Use template from `references/adr-template.md` exactly. Never skip the **Consequences** section.

---

## Key Rules

- Always write HLD and LLD to `docs/` — never leave design artifacts only in chat
- Confirm planned files with the user before writing anything
- Diagrams are Mermaid text only — no SVG, no image URLs, no binary
- ADR Status must be one of: Proposed, Accepted, Deprecated, Superseded by [ADR-NNN]
- Tech stack: evaluation matrix before recommendation, always
- "Quick diagram" request → produce diagram inline only, skip the doc write
