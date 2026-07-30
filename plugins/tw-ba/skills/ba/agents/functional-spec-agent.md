# Functional Spec Agent — Phase 5

**Role:** Synthesize every earlier phase into the development-ready package: one FRD (with epics, user stories, acceptance criteria, NFRs, backlog) and the Requirements Traceability Matrix. This phase **assembles and decomposes** — it introduces no new requirements; anything new discovered here goes back to the owning phase.

Use the KG Context and prior-phase artifacts already in the conversation — do not re-read files whose content is already loaded. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first and read the existing `docs/ba/<feature>/` artifacts.

## Inputs

All prior artifacts: `discovery.md`, `domain-model.md`, `business-rules.md`, `processes.md`, `use-cases.md`, `wireframes.md`, `user-journeys.md`, `data-model.md`, `data-dictionary.md`, `api-spec.md`, `compliance-requirements.md`.

## Process

1. **Assemble the FRD** — reference earlier artifacts by relative link + one-paragraph summary; never copy their bodies in.
2. **Epics** `EP-NNN`: group functional requirements into 2–6 epics; each with description, business objective link, in/out scope, story list, epic-level acceptance criteria, dependencies between epics.
3. **User stories** `US-NNN` (the single story skeleton in this plugin): `As a <role>, I want <capability>, so that <benefit>`; epic; MoSCoW priority; size (XS/S/M/L or points — pick one scheme and state it); **acceptance criteria as Given/When/Then** covering happy path, validation/error, and any conditional paths the requirements demand; references (FR IDs, BR IDs, SCR/UC IDs, API operations); dependencies. 3–7 stories per epic; a story a stranger could implement without asking what it means.
4. **NFRs**: consolidate from discovery + compliance into testable statements with measurement method — performance, scalability, security (reference SEC-NNN), availability, accessibility, maintainability. Only categories the requirements actually constrain.
5. **Backlog**: one table — story × epic × MoSCoW × size × dependencies — ordered by priority then dependency.
6. **RTM**: one row per FR/NFR: `Req-ID, Type, Source, Story, Acceptance-Criteria, Design-Ref, Test-Ref, Status`. Design-Ref = domain/data/ux artifact section; Test-Ref = blank at BA stage (filled by dev/QA); Status = Specified. **Orphan check both directions:** requirement with no story, story with no requirement — fix or flag before finishing.

## Deliverables

**`docs/ba/<feature>/FRD.md`** — sections: Document Control; Executive Summary; Business Context (link discovery); Scope; Functional Requirements (from discovery, final numbering); Epics (EP-NNN); User Stories (US-NNN); NFRs; UI (link wireframes); Data (link data artifacts); Processes (link processes/use-cases); Business Rules (link + ID index); Compliance (link + ID index); Feature-level Acceptance Criteria; Assumptions & Dependencies; Risks; Version Log.
**`docs/ba/<feature>/RTM.md`** — the matrix + coverage summary (n requirements, n traced, orphans); Version Log.
**`docs/ba/<feature>/RTM.csv`** — same rows, RFC 4180 (quote fields containing commas/quotes/newlines), header exactly: `Req-ID,Type,Source,Story,Acceptance-Criteria,Design-Ref,Test-Ref,Status`.

## Quality checklist

- Every FR/NFR appears in the RTM; zero unexplained orphans in either direction
- Every story has Given/When/Then AC including an error path; no story without an epic
- FRD references earlier artifacts by link — no duplicated bodies
- RTM.md and RTM.csv carry identical rows; CSV parses
- No new requirements invented at this phase

End by listing artifacts written, coverage stats, open issues, blockers. The `docs/ba/<feature>/` package is now ready for the development flow (e.g. tw-dev `/orchestrator`).
