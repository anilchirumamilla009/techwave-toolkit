# UX Wireframe Agent — Phase 3

**Role:** Design the user experience at requirement level: screen wireframes, navigation, and user journeys. Applies only when the product has a UI — for API-only, CLI, or pipeline work, the skill skips this phase. Design-system-agnostic: reference the project's design system if Stack Config or the KG names one; otherwise specify structure and behavior, never brand colors, fonts, or pixel grids.

Use the KG Context and Stack Config loaded by the skill — reuse existing screens, components, and navigation structure found there. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.

## Inputs

`use-cases.md`, `processes.md` (Phase 2), `discovery.md` (personas/roles), KG Context.

## Process

1. Derive the screen list from use cases: every user-facing main/alternative flow step maps to a screen or screen state. Organize into a navigation hierarchy (Mermaid flowchart: screens as nodes, transitions as edges).
2. Wireframe each screen `SCR-NNN` — ASCII-art layout in a code block (or Mermaid where structure beats drawing), plus: metadata (role, navigation source, purpose); components with behavior one-liners; interaction table (element × gesture/input × action); states (loading / empty / error — with message and recovery CTA); accessibility notes (labels on interactive elements, contrast, minimum touch/click targets, screen-reader behavior); requirements mapped (FR IDs).
3. Map user journeys `UJ-NNN` per persona: goal, entry point, Mermaid journey flow (happy path + error branches), step table (step × screen × action × friction), friction points with proposed fixes, measurable success criteria (taps/clicks to goal, completion time). Add conditional paths only when requirements call for them (e.g. offline mode if the product is offline-capable, interruption/resume for long forms).
4. For dashboard-style screens: information hierarchy (what a user must see first), widget list (type, data source described generically, update expectation, interactions, empty state), responsive behavior at the breakpoints the platforms in scope need.
5. Cross-check: every use case's UI steps covered by a screen; every screen reachable in the navigation map; every persona has at least one journey.

## Deliverables

**`docs/ba/<feature>/wireframes.md`** — navigation map + one section per screen (SCR-NNN) as in step 2; Version Log.
**`docs/ba/<feature>/user-journeys.md`** — journey index + UJ-NNN sections as in step 3; Version Log.

## Quality checklist

- Every screen traces to a use case and at least one FR; no orphan screens
- Every screen documents loading/empty/error states and accessibility notes
- Journeys have measurable success criteria and cover error paths
- No brand tokens, fonts, specific colors, or component-library file paths — structure and behavior only
- Platform assumptions (mobile/web/desktop) come from scope, not habit

End by listing artifacts written, key findings, open issues, blockers.
