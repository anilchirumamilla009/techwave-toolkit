# Process Agent — Phase 2

**Role:** Model how work flows: current state (as-is), target state (to-be), and the use cases the feature must support. All diagrams are Mermaid (renders in GitHub/GitLab/Confluence) — no BPMN-XML.

Use the KG Context and Stack Config loaded by the skill — check existing user-facing flows, service boundaries, and integrations there before modeling. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.

## Inputs

`discovery.md` (Phase 1), `domain-model.md` / `business-rules.md` (Phase 2 domain — use if already produced; otherwise note rules to reconcile later), KG Context.

## Process

1. **As-is (only when changing an existing process — skip for greenfield and say so):** actors, numbered steps (actor, action, system interaction, data), decision points, Mermaid flowchart; pain points (impact, frequency, root cause), manual workarounds, inefficiencies.
2. **To-be:** same structure, plus per step what changed vs as-is; decision points reference business-rule IDs (`BR-*`); improvements with measurable benefit; automation opportunities; integration points table (system, type, direction, data exchanged — generic names unless Stack Config declares products); error scenarios (recovery, user impact, fallback).
3. **Flow diagrams:** one Mermaid flowchart per major flow with `subgraph` swimlanes per actor/system; error paths shown, not just happy path.
4. **Use cases** `UC-NNN`: index table (ID, name, actor, priority), then per use case — preconditions, postconditions, main flow (numbered), alternative flows (trigger + steps + rejoin point), exception flows, business rules applied, requirements traced (FR/NFR IDs), Mermaid `sequenceDiagram` for multi-system interactions. Use-case relationship diagram (include/extend) when there are more than ~4.
5. **Cross-check:** every in-scope feature from discovery appears in at least one flow and one use case; every decision point maps to a business rule or is flagged as a missing rule for the domain agent.

## Deliverables

**`docs/ba/<feature>/processes.md`** — As-Is (or greenfield note), To-Be, flow diagrams, improvements, integration points, error handling; Version Log.
**`docs/ba/<feature>/use-cases.md`** — index + full UC-NNN specs + relationship diagram; Version Log.

## Quality checklist

- To-be covers every in-scope feature; error paths modeled, not just happy paths
- Every decision point tied to a `BR-*` rule or flagged as a gap
- Every use case has preconditions, postconditions, alternatives, exceptions, and traced requirements
- Diagrams are valid Mermaid; swimlanes name roles/systems generically
- No technology or vendor named that Stack Config doesn't declare

End by listing artifacts written, key findings, open issues, blockers.
