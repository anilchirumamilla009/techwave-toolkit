---
name: requirements
description: This skill should be used when the user asks to "write user stories", "define acceptance criteria", "write BDD scenarios", "break down this epic", "capture requirements for", "write specs for", "create acceptance tests definition", "document requirements", "define done criteria", "write feature requirements", "create a product backlog item", or needs structured requirements for any feature or system. Use this skill to transform vague ideas into well-formed, behavior-first requirements artifacts.
version: 0.1.0
---

# Requirements Engineering Skill

## Overview

This skill transforms raw ideas, features, or epics into structured, behavior-first requirements artifacts. It produces user stories, acceptance criteria, BDD scenarios, and epic breakdowns — independent of any technology choice.

## When to Use

Invoke this skill whenever the user wants to capture WHAT a system should do (not HOW). If the user provides implementation details (tech stack, database, framework), strip them from the story and place them in a separate Technical Notes section.

## Step-by-Step Process

### 1. Identify the Input Type

Determine what the user has provided:
- **Raw idea / vague request** → ask 3 clarifying questions (Who? What outcome? Why?)
- **Epic** → decompose into 3–7 sized stories
- **Feature description** → produce one user story + acceptance criteria
- **"Just write BDD"** → produce Given/When/Then scenarios using `references/bdd-patterns.md`

### 2. Identify the Persona

Determine who benefits from this requirement. Ask if not clear:
- End user (customer, patient, student, shopper)
- Internal user (admin, ops, analyst)
- External system (API consumer, webhook receiver)

### 3. Produce the Artifact

Use the templates in `references/story-templates.md`. Follow these rules:
- **Stories are behavior-first**: describe observable outcomes, not database tables or API calls
- **Acceptance criteria are testable**: each criterion can be verified true/false by a QA engineer
- **Done criteria are explicit**: include non-functional requirements (performance, security, accessibility) only if the user mentions them

### 4. Size and Sequence (for Epics)

When decomposing an epic:
- Target story sizes: XS (< 1 day), S (1–2 days), M (3–5 days), L (1–2 weeks)
- Flag L-sized stories as candidates for further breakdown
- Identify dependencies between stories and note blocking relationships
- Order stories so the first one delivers the thinnest walking skeleton

### 5. Output Format

Produce output in this exact order:
1. **Epic statement** (if applicable)
2. **User stories** (using the template from `references/story-templates.md`)
3. **Acceptance criteria** for each story
4. **BDD scenarios** (optional — include if user asks or if the feature has complex branching)
5. **Technical Notes** (only for constraints the dev team needs — never implementation choices)
6. **Out of Scope** (list what this story explicitly does NOT cover)

## Output Template

```
## Epic: [Epic Name]
As a [type of user], I want [goal] so that [benefit].

---

### Story 1: [Story Name] [Size: S/M/L/XS]

**As a** [persona]
**I want** [action or capability]
**So that** [benefit or outcome]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [outcome]
- [ ] [Edge case or alternate path]
- [ ] [Non-happy path: what happens on error]

**Out of Scope:**
- [What this story does NOT cover]

**Technical Notes:** *(optional)*
- [Constraint, not solution — e.g., "must respond in < 200ms" not "use Redis"]
```

## Key Rules

- Never include database schema, API endpoints, or class names in acceptance criteria
- Never write "the system should" — write "the user can" or "the user sees"
- If the user says "just be brief", produce only the story title + 3 acceptance criteria bullets
- For Jira/Linear format output, refer to `references/story-templates.md` for the exact field mapping
- Load `references/bdd-patterns.md` when producing Given/When/Then to ensure idiomatic phrasing
