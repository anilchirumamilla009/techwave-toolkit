---
name: design
description: This skill should be used when the user asks to "design the system", "create an architecture diagram", "draw a component diagram", "write an ADR", "architecture decision record", "tech stack recommendation", "system design for", "design the components of", "create a sequence diagram", "draw an ER diagram", "C4 diagram", "design the data model", "propose a solution architecture", or needs any form of system design or architectural documentation. Use this skill for technical design artifacts across any technology stack.
version: 0.1.0
---

# Architecture & Design Skill

## Overview

This skill produces text-based system design artifacts: architecture diagrams (Mermaid), Architecture Decision Records (ADRs), tech stack evaluations, and component designs. All output is tech-stack agnostic — this skill works by understanding the problem and constraints before recommending any technology.

## When to Use

Invoke when the user needs to design a system, document a decision, create a diagram, or evaluate technology choices. This skill explicitly avoids prescribing solutions before understanding constraints.

## Step-by-Step Process

### 1. Identify the Artifact Type

| User says | Produce |
|---|---|
| "architecture diagram", "system design" | C4 context or container diagram in Mermaid |
| "component diagram" | C4 component or class diagram in Mermaid |
| "sequence diagram", "flow" | Mermaid `sequenceDiagram` |
| "ER diagram", "data model" | Mermaid `erDiagram` |
| "ADR", "architecture decision" | Nygard ADR format from `references/adr-template.md` |
| "tech stack", "which technology" | Evaluation matrix from `references/tech-stack-evaluation.md` |
| "design the system" (generic) | Start with C4 context diagram, then ask if detail is needed |

### 2. Ask Before Recommending (for tech stack decisions)

Before producing a tech stack recommendation, always ask:
- What is the team's language preference or existing expertise?
- What is the deployment target (cloud, on-prem, serverless)?
- What are the performance/scale requirements?
- Are there existing systems this must integrate with?

Only after gathering constraints, apply the scoring matrix from `references/tech-stack-evaluation.md`.

### 3. Produce Diagrams

All diagrams must be text-based. Use Mermaid by default (renders on GitHub, GitLab, Notion, most editors). Reference `references/diagram-formats.md` for the exact syntax starters for each diagram type.

Default diagram type selection:
- **New system, high-level**: C4 Context (`C4Context`)
- **Services and their interactions**: C4 Container (`C4Container`)
- **Internal design of one service**: Class or component diagram
- **User flows or API interactions**: Sequence diagram
- **Database design**: ER diagram
- **HLD**: High-level architecture diagram (C4 context or container)
- **LLD**: Low-level architecture diagram (class, component, or sequence)

### 4. Produce ADRs

Use the Nygard ADR format from `references/adr-template.md`. Never skip the **Consequences** section — it is the most important part for future readers. The ADR captures the decision as it was made, not as it looks in hindsight.

### 5. Output Format

**For diagrams:**
````
## [Diagram Title]

```mermaid
[diagram code]
```

### Key Design Points
- [Explain a non-obvious element]
- [Explain a constraint or trade-off visible in the diagram]
````

**For ADRs:** Use the template exactly as provided in `references/adr-template.md`.

**For tech stack evaluations:** Use the scoring table from `references/tech-stack-evaluation.md` then add a prose recommendation paragraph.

## Key Rules

- All diagrams must be text-based (Mermaid, PlantUML, or ASCII). Never output binary, SVG source, or image URLs.
- Diagram titles must match what they actually represent — do not name a container diagram a "system architecture" if it's showing internal services.
- For ADRs: the Status field must be one of: Proposed, Accepted, Deprecated, Superseded by [ADR-NNN].
- For tech stack decisions: present the evaluation matrix first, then the recommendation — never lead with a recommendation before showing the evidence.
- When the user asks for "a quick diagram", produce the diagram inline without the Key Design Points section.
