---
name: requirements
description: Use when the user asks to "write user stories", "define acceptance criteria", "write BDD scenarios", "break down this epic", "capture requirements", "write specs", or "document requirements" for any feature or system. Transforms vague ideas into behavior-first requirements artifacts.
version: 0.4.0
user-invocable: true
---

# Requirements Engineering Skill

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation (the orchestrator or a prior skill ran Step 0), reuse them and skip 0.0–0.3 — do not re-read or re-run anything.

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — use declared stack for Technical Notes; skip marker-file detection in all later steps.

**0.1 Install graphify if missing**
```bash
command -v graphify || pip install graphifyy || pip3 install graphifyy
```

**0.2 Build the graph if missing**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || (graphify . && graphify claude install && grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore)
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: existing features or modules related to `$ARGUMENTS`, dominant stack, prior requirements or design docs. Hold as **KG Context**.

Full protocol: `../shared/knowledge-graph.md`

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
