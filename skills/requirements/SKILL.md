---
name: requirements
description: This skill should be used when the user asks to "write user stories", "define acceptance criteria", "write BDD scenarios", "break down this epic", "capture requirements for", "write specs for", "create acceptance tests definition", "document requirements", "define done criteria", "write feature requirements", "create a product backlog item", or needs structured requirements for any feature or system. Use this skill to transform vague ideas into well-formed, behavior-first requirements artifacts.
version: 0.2.0
---

# Requirements Engineering Skill

## Step 0 — Knowledge Graph Check

Load `../shared/knowledge-graph.md` for the full protocol. Summary:

1. If `graphify-out/graph.json` exists → run `bash scripts/query-kg.sh "<feature name or epic title from $ARGUMENTS>"`
2. If missing → run `bash scripts/setup-kg.sh` first, then query
3. Inject results as KG Context (existing stories, related features) before Step 1

---

## Step-by-Step Process

### 1. Classify the Input

| Input type | Action |
|---|---|
| Epic (broad goal, multiple capabilities) | Decompose into 3–7 sized stories |
| Feature description (reasonably complete) | Produce one story + acceptance criteria |
| BDD request ("just write BDD") | Produce Given/When/Then using `references/bdd-patterns.md` |
| Incomplete text (missing persona, outcome, or scope) | **Draft immediately** using Step 2 — do not ask questions first |

### 2. Incomplete Input — Draft First, Clarify After

When the input lacks a clear persona, outcome, or scope, **do not ask clarifying questions upfront**. Instead:

1. Draft the full requirements document using best inferences
2. Mark every inferred element with `[Assumed]`
3. Present the draft, then ask one consolidating question at the end:
   > "I've made the assumptions marked [Assumed] above. Correct any that are wrong and I'll revise."

**Inference rules:**

| Missing element | Default assumption |
|---|---|
| Persona not stated | Infer from context (e.g., "user" for login, "admin" for a dashboard) |
| Outcome unclear | Infer the most direct business goal from the feature name |
| Scope not defined | Assume a minimal first iteration — thin walking skeleton |
| Non-functional requirements absent | Omit unless the feature type strongly implies them (e.g., payment → PCI note) |

This produces a usable draft immediately. The user corrects only what is wrong, not a questionnaire.

### 3. Identify Persona

Determine who benefits:
- End user (customer, patient, student, shopper)
- Internal user (admin, ops, analyst)
- External system (API consumer, webhook receiver)

If genuinely ambiguous between two distinct personas, draft separate stories for each.

### 4. Produce the Artifact

- Stories are **behavior-first**: describe observable outcomes, not database tables or API calls
- Acceptance criteria are **testable**: each criterion is verifiable true/false by a QA engineer
- Never write "the system should" — write "the user can" or "the user sees"
- Strip implementation details (tech stack, database, framework) from stories; place in Technical Notes only

### 5. Size and Sequence (for Epics)

| Size | Effort | Action |
|---|---|---|
| XS | < 1 day | Ship as-is |
| S | 1–2 days | Ship as-is |
| M | 3–5 days | Ship as-is |
| L | 1–2 weeks | Flag as candidate for further breakdown |

Order stories so the first delivers the thinnest walking skeleton. Note blocking dependencies.

---

## Output Template

```
## Epic: [Epic Name]                              ← omit if single story
As a [persona], I want [goal] so that [benefit].

---

### Story [N]: [Story Name]  [Size: XS/S/M/L]

**As a** [persona] [Assumed]                      ← add [Assumed] only on inferred items
**I want** [action or capability]
**So that** [benefit or outcome] [Assumed]

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [outcome]
- [ ] [Alternate path or edge case]
- [ ] [Error / failure path]

**Out of Scope:**
- [What this story explicitly does NOT cover]

**Technical Notes:** *(omit if none)*
- [Constraint only — e.g., "must respond in < 200ms", not "use Redis"]

---
[Assumptions to verify:]                          ← include only when [Assumed] tags present
- Persona assumed to be [X] — correct if wrong
- Outcome assumed to be [Y] — correct if wrong
```

---

## Key Rules

- Draft requirements from incomplete input — never block on clarifying questions
- `[Assumed]` tags make inferences visible and easy for the user to correct
- Acceptance criteria never contain schema names, class names, or endpoint paths
- For Jira/Linear format, use field mapping from `references/story-templates.md`
- For Given/When/Then phrasing, load `references/bdd-patterns.md`
- "Just be brief" → story title + 3 acceptance criteria bullets only
