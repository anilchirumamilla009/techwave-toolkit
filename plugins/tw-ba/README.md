# tw-ba — Business Analysis Plugin

Domain-agnostic BA workflow for Claude Code. One skill (`/ba`) drives a business objective through up to six analysis phases, each lazy-loading a small phase agent, and writes development-ready artifacts to `docs/ba/<feature>/`.

Works for any industry and any project type. Industry specifics (e.g. healthcare/FHIR) live in optional domain references loaded only when the project's domain matches — the core never assumes one.

## Install

```bash
claude plugin marketplace add anilchirumamilla009/techwave-toolkit   # once
claude plugin install tw-ba@techwave
```

## Invoke

```
/ba <business objective | Jira ticket ID | Confluence page URL | plain text>
```

Or just describe the need ("run business analysis for member self-scheduling") — the skill triggers on BA phrasing.

## Flow

| Phase | Agent | Writes to `docs/ba/<feature>/` |
|---|---|---|
| 0 | SKILL.md Step 0 | — (Stack Config + graphify knowledge graph → KG Context) |
| 1 Discovery | discovery-agent | `discovery.md` (stakeholders/RACI, goals+KPIs, scope, FR/NFR list) |
| 2 Domain | domain-agent | `domain-model.md`, `business-rules.md` |
| 2 Process | process-agent | `processes.md` (as-is/to-be, Mermaid flows), `use-cases.md` |
| 3 UX (UI products only) | ux-wireframe-agent | `wireframes.md`, `user-journeys.md` |
| 3 Data | data-agent | `data-model.md`, `data-dictionary.md`, `api-spec.md` |
| 4 Compliance | compliance-agent | `compliance-requirements.md` (requirement-level) |
| 5 Functional spec | functional-spec-agent | `FRD.md` (epics, stories, AC, NFRs, backlog), `RTM.md` + `RTM.csv` |
| 6 Knowledge (opt-in) | knowledge-agent | `knowledge-index.md` |

The skill proposes only the phases relevant to the request, gates each phase with `Continue? (yes / skip / stop)`, detects existing artifacts on re-runs (updates in place, snapshots prior versions to `docs/ba/ba-history/`), and loads exactly one agent file per phase.

## Context first (Step 0)

Before any analysis, the skill reads Stack Config (`.github/tech-stack.md` → `.claude/tech-stack.md`) and builds/refreshes the project knowledge graph with [graphify](https://graphify.net) (`graphifyy==0.9.16`, consent-gated install), then reads `graphify-out/GRAPH_REPORT.md`. Agents check this KG Context for existing features, entities, and flows before analyzing from scratch. Greenfield projects skip the graph — BA often precedes code.

Full protocol: `skills/shared/knowledge-graph.md`.

## Domain references

`skills/ba/references/domains/` holds optional per-industry guidance. Step 0.5 matches the project's domain (Stack Config `Domain:` line or the objective text) against this folder; a matched file is applied **on top of** the generic agents.

- Shipped: `healthcare-fhir.md` (FHIR R4 mappings, HIPAA checklist structure, consent-as-FHIR-Consent, clinical value sets)
- Add your own: drop `references/domains/<domain>.md` describing entity mappings, regulation checklists, and value sets for your industry — no agent changes needed

No matching file = fully generic run. A missing domain file is never a blocker.

## Handoff to development

Everything lands in `docs/ba/<feature>/`. A development flow (e.g. the tw-dev plugin's `/orchestrator`) picks up `FRD.md`, the stories, `api-spec.md`, and `compliance-requirements.md` from there.

**Compliance boundary:** tw-ba specifies requirement-level controls (what must exist). Code-level verification of the implemented controls is a development-phase activity (e.g. tw-dev `/compliance <domain>` after implementation).

## Key rules

- Artifacts are edited in place — re-runs update, never duplicate; prior versions snapshot to `docs/ba/ba-history/<basename>-v<N>.md` and every artifact carries a Version Log
- RTM ships as `.md` + RFC 4180 `.csv` (imports into Excel/Jira)
- Complete deliverables — no TODO stubs; inapplicable sections are omitted, not left blank
- Deliverables stay in files; chat gets paths, counts, and decisions

## Plugin structure

```
plugins/tw-ba/
├── plugin.json
├── README.md
└── skills/
    ├── shared/knowledge-graph.md        # Step 0 protocol (graphify)
    └── ba/
        ├── SKILL.md                     # /ba entry — phases, gates, rules
        ├── agents/                      # one file loaded per phase
        │   ├── discovery-agent.md
        │   ├── domain-agent.md
        │   ├── process-agent.md
        │   ├── ux-wireframe-agent.md
        │   ├── data-agent.md
        │   ├── compliance-agent.md
        │   ├── functional-spec-agent.md
        │   └── knowledge-agent.md
        └── references/domains/
            └── healthcare-fhir.md       # optional domain reference (example)
```
