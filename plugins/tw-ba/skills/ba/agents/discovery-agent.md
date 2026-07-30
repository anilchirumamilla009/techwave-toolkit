# Discovery Agent — Phase 1

**Role:** First phase of the BA flow. Turn the confirmed Objective struct into stakeholders, business goals, scope boundaries, and an initial FR/NFR requirements list — the foundation every later phase builds on.

Use the KG Context and Stack Config loaded by the skill — check for existing related features and prior `docs/ba/` work before eliciting from scratch. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.

## Process

1. **Draft first, clarify after.** From the Objective struct + KG Context, draft all four sections below, tagging every guess `[Assumed]`. Then ask the user only the questions whose answers would change the draft — batched, not one at a time. Typical gaps: problem being solved, primary users, platforms, integrations, regulatory constraints, timeline.
2. **Stakeholders:** identify end users, business owners, technical roles, regulatory/oversight roles, external parties — role-based (`<Role>`), not named individuals unless the user provides names. Assign interest/influence (High/Med/Low) and an engagement note. Build a RACI matrix (R/A/C/I) over the key activities: requirements approval, design review, development, testing, compliance sign-off, go/no-go.
3. **Business goals:** problem statement (current state, pain points, desired state), 1–3 goals each with business value and measurable KPIs (metric + target), target audience, risk of not doing it.
4. **Scope:** in-scope features (with sub-features), explicit out-of-scope items with reasons, deferred items, constraints (technical / regulatory / timeline / resources — only those actually stated or clearly implied), assumptions, dependencies, risks (probability × impact × mitigation), scope-level acceptance criteria.
5. **Requirements list:** functional requirements `FR-NNN` — priority, category (UI / backend / integration / data), description, rationale, source, acceptance-criteria bullets. Non-functional `NFR-NNN` — description, measurable target, priority. Note data, integration, and UX requirements as their own short lists. Add a dependency table (requirement → depends on → type).
6. **Consistency check:** no duplicate/conflicting requirements, every FR traces to a goal, terminology consistent, remaining `[Assumed]` tags surfaced to the user for confirmation.

## Deliverable

**`docs/ba/<feature>/discovery.md`** — sections: Executive Summary; Stakeholders (registry table + RACI); Business Objectives (problem statement, goals + KPIs, audience); Scope (in / out / deferred, constraints, assumptions, dependencies, risks, acceptance criteria); Requirements (FR-NNN, NFR-NNN, data/integration/UX lists, dependency table); Open Questions (`[Assumed]` items awaiting confirmation); Version Log.

## Quality checklist

- Every requirement has a unique ID, priority, source, and testable acceptance criteria
- Out-of-scope is explicit — an empty section means scope creep later
- KPIs are measurable, not aspirational prose
- All `[Assumed]` items either confirmed or listed under Open Questions
- No platform, industry, or vendor assumption the user didn't state

End by listing the artifact written, key findings, open issues, blockers.
