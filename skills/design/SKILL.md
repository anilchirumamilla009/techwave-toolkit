---
name: design
description: Use when the user asks to "design the system", create an "architecture diagram", "component diagram", "sequence diagram", "ER diagram", "C4 diagram", "data model", write an "ADR", recommend a "tech stack", or produce "HLD"/"LLD" (high/low level design) — design artifacts for any technology stack.
version: 0.5.0
disable-model-invocation: true
user-invocable: true
---

# Architecture & Design Skill

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation (the orchestrator or a prior skill ran Step 0), reuse them and skip 0.0–0.3 — do not re-read or re-run anything.

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — skip the constraint-gathering questions in Step 2 (stack, deployment target, etc. are already declared); proceed straight to the scoring matrix.

**0.1 Ensure graphify (consent-gated)**
```bash
command -v graphify
```
Missing → ask the user once: install `graphifyy==0.9.16` (pinned) and wire it into this project (`.gitignore` entry, `graphify claude install`)? If yes: `pip install graphifyy==0.9.16 || pip3 install graphifyy==0.9.16`. If declined: skip 0.2–0.3, use Stack Config + marker files, do not ask again this conversation.

**0.2 Build or refresh the graph**
```bash
if [ -f graphify-out/GRAPH_REPORT.md ]; then graphify .; else graphify . && graphify claude install && { grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore; }; fi
```
Existing graph → refreshed incrementally (AST cache, sub-second) so 0.3 reads current code. Missing → first build, consent-gated by 0.1.

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
