---
name: ba
description: Use when the user asks for "business analysis", "BA flow", "analyze this business objective", "requirements discovery", "stakeholder analysis", "process modeling", "as-is to-be", "use cases", "wireframes", "user journeys", "data dictionary", "API contract from requirements", "compliance requirements", "functional spec", "FRD", "product backlog", "RTM", "requirements traceability" — or wants a business objective turned into complete, development-ready BA deliverables. Domain-agnostic; works for any industry and any project type.
version: 0.1.0
disable-model-invocation: false
user-invocable: true
---

# Business Analysis Skill

Drives a business objective through up to six BA phases, each producing artifacts in `docs/ba/<feature>/`. Load exactly one `agents/*.md` file per phase — never preload later phases.

```
Phase 1 discovery → Phase 2 domain, process → Phase 3 ux, data
        → Phase 4 compliance → Phase 5 functional-spec → Phase 6 knowledge (opt-in)
```

Phases 2 and 3 pair related analyses; run them back-to-back in order. Later phases depend on earlier outputs (2←1, 3←2, 4←1-3, 5←all).

---

## Step 0 — Knowledge Graph & Stack Config (REQUIRED)

**Reuse first:** if Stack Config and KG Context are already loaded in this conversation, reuse them and skip 0.0–0.3.

**0.0** Read Stack Config: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. Note any `Domain:` line.
**0.1** `command -v graphify` — if missing, ask once: install `graphifyy==0.9.16` (pinned) and wire it in (`.gitignore` entry, `graphify claude install`)? Declined → skip 0.2–0.3, don't re-ask.
**0.2** `if [ -f graphify-out/GRAPH_REPORT.md ]; then graphify .; else graphify . && graphify claude install; fi`
**0.3** Read `graphify-out/GRAPH_REPORT.md` selectively → hold **KG Context**: existing related features, entities, flows, prior `docs/ba/` artifacts.

**Greenfield skip:** no source files → skip 0.1–0.3; BA often precedes code, so the objective + Stack Config alone is normal.

Full protocol: `../shared/knowledge-graph.md`

## Step 0.5 — Domain detection

From Stack Config `Domain:` or the objective text, check `references/domains/` for a matching file (e.g. `healthcare-fhir.md`). Match found → note it; phase agents load it on top of their generic instructions. No match → proceed fully generic. **Never assume an industry; a missing domain file is never a blocker.**

## Step 1 — Parse the objective

Sources, in order of preference: Jira ticket / Confluence page via MCP tools if available (never require them — if absent or the fetch fails, ask the user to paste the content and continue), GitHub issue, or plain text from `$ARGUMENTS`.

Normalize into an **Objective struct**: Feature name (kebab-case) / Objective / Stakeholder hints / Domain / Scope signals / Constraints. Show it and confirm with the user before Phase 1.

## Step 2 — Detect what exists

Check `docs/ba/<feature>/` for artifacts from the map below. For each phase whose artifacts already exist, propose **update** rather than regenerate. Propose only the phases relevant to the request — small changes may need only discovery + functional-spec; skip UX for API-only work, data for process-only work. Present the proposed sequence and get confirmation.

## Step 3 — Drive the phases

For each confirmed phase:
1. Announce: `[BA] Phase N: <name>`
2. Load that phase's file from `agents/` (one file only) and run it to completion
3. Summarize: artifacts written, key findings, open issues, blockers
4. Gate: `Continue? (yes / skip / stop)`

| Phase | Agent file | Writes to `docs/ba/<feature>/` |
|---|---|---|
| 1 Discovery | `agents/discovery-agent.md` | `discovery.md` |
| 2 Domain | `agents/domain-agent.md` | `domain-model.md`, `business-rules.md` |
| 2 Process | `agents/process-agent.md` | `processes.md`, `use-cases.md` |
| 3 UX | `agents/ux-wireframe-agent.md` | `wireframes.md`, `user-journeys.md` |
| 3 Data | `agents/data-agent.md` | `data-model.md`, `data-dictionary.md`, `api-spec.md` |
| 4 Compliance | `agents/compliance-agent.md` | `compliance-requirements.md` |
| 5 Functional spec | `agents/functional-spec-agent.md` | `FRD.md`, `RTM.md`, `RTM.csv` |
| 6 Knowledge (opt-in) | `agents/knowledge-agent.md` | `knowledge-index.md` |

**Loop-backs:** a compliance gap found in Phase 4 re-opens the affected earlier phase (max 2 iterations, then surface the conflict to the user with options). A feasibility question in any phase goes to the user — never invent an answer.

**Phase 6 is opt-in:** after Phase 5, offer it (`Also produce the knowledge index and lessons-learned? (yes / no)`); default is skip.

## Step 4 — Final summary

One table: phase, artifacts (paths), open issues. Then the handoff line: deliverables in `docs/ba/<feature>/` are ready for the development flow (e.g. tw-dev `/orchestrator` picks up the FRD and stories; run code-level compliance after implementation).

---

## Key Rules

- **Context first.** No phase starts before Step 0; agents check KG Context for existing features/entities/flows before analyzing from scratch.
- **Edit in place.** If a target artifact exists, update it with the Edit tool — never create `*-v2`/copy files or duplicate sections. Before revising, snapshot the current file to `docs/ba/ba-history/<basename>-v<N>.md` (N from the doc's Version Log; never overwrite a snapshot), then bump the Version Log in the canonical file.
- **Every artifact ends with a Version Log table** (`| Version | Date | Change summary |`), starting at 1.
- **Complete deliverables** — no TODO placeholders, no empty skeleton sections; omit a section that doesn't apply rather than leaving it blank.
- **RTM is always dual-format:** `RTM.md` + `RTM.csv` (RFC 4180: quote fields containing commas/quotes/newlines; header `Req-ID,Type,Source,Story,Acceptance-Criteria,Design-Ref,Test-Ref,Status`).
- **Domain-agnostic core.** Industry specifics live only in `references/domains/*.md`; add a new domain by adding a file there — agents never hardcode one.
- **Don't paste artifacts into chat** — write files, report paths + counts + notable decisions.
- Deliverables are requirement-level; code-level verification belongs to the development flow.
