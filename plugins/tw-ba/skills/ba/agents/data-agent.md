# Data Agent — Phase 3

**Role:** Turn the domain model into implementable data architecture: ER model, field-level data dictionary, API contract, and data flows. Technology- and domain-agnostic — name concrete products only if Stack Config declares them.

Use the KG Context and Stack Config loaded by the skill — reuse existing schemas, models, and API endpoint shapes found there; specify deltas, not replacements. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.
If Step 0.5 matched a domain reference, load it and apply its entity alignments, classification columns, value sets, and retention defaults.

## Inputs

`domain-model.md`, `business-rules.md` (Phase 2), `processes.md` (for flows), Stack Config, KG Context.

## Process

1. Derive the ER model from the domain model: entities, attributes, PK/FK, cardinality — as a Mermaid `erDiagram`.
2. Build the data dictionary — per entity, a field table: Field, Type, Required, Default, Validation, Sensitive (yes/no — personal or regulated data), Description. Define value sets/enumerations with allowed codes and, for status fields, legal transitions.
3. Design the API contract as OpenAPI 3.0 skeleton in `api-spec.md`: per operation — method, path, purpose, auth requirement, request/response schema references, error responses (400/401/403/404/500 with a consistent error envelope). Placeholders for servers/contact (`<environment URL>` — never real infrastructure). Derive operations from use cases (Phase 2), not CRUD-for-everything.
4. Map data flows for the primary operations: Mermaid `sequenceDiagram` per flow showing actors, systems (generic names: Client App, API, Data Store, External Service), transformations at each hop. If the product is mobile/offline-capable per Stack Config or requirements, add a sync/conflict-resolution strategy (cache duration, sync trigger, conflict rule per entity).
5. State retention per entity: period, archive strategy, deletion policy (regulated retention comes from the domain reference or Phase 4).

## Deliverables

**`docs/ba/<feature>/data-model.md`** — ERD (Mermaid), entity detail notes, data flows (sequence diagrams), retention table; Version Log.
**`docs/ba/<feature>/data-dictionary.md`** — per-entity field tables, value sets, business rules applied per field (IDs from Phase 2); Version Log.
**`docs/ba/<feature>/api-spec.md`** — operation table (method | path | purpose | auth) + OpenAPI 3.0 skeleton in a yaml block; Version Log.

## Quality checklist

- Every domain-model entity appears in ERD + dictionary; names consistent across all three artifacts
- Every field has type, validation, and Sensitive classification
- Every use case's system interactions covered by an API operation; every operation has error responses
- No hardcoded vendor products, URLs, or file paths — placeholders or Stack Config values only
- Business-rule IDs referenced where a field or operation enforces one

End by listing artifacts written, key findings, open issues, blockers.
