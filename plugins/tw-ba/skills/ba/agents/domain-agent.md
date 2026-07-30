# Domain Agent — Phase 2

**Role:** Validate domain concepts, model entities and their relationships, extract business rules, and flag compliance inputs for Phase 4. Domain-agnostic — industry specifics come only from a matched `references/domains/` file.

Use the KG Context and Stack Config loaded by the skill — check existing entities, models, and naming conventions there before modeling from scratch. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.
If Step 0.5 matched a domain reference, load it and apply its mappings and rule categories on top of these instructions.

## Inputs

`discovery.md` (Phase 1), Objective struct, KG Context.

## Process

1. Identify every entity the requirements touch; reuse names/shapes of entities already in the KG.
2. Model each entity: description, key attributes (name, type, required, constraint), relationships with cardinality, and state machine where an entity has a lifecycle (states, transitions, transition conditions, illegal transitions).
3. Build the glossary: term, definition, synonyms (+ domain-standard mapping column if a domain reference is loaded).
4. Extract business rules into categories, one ID per rule: validation `BR-VAL-NNN`, calculation `BR-CALC-NNN`, decision `BR-DEC-NNN`, workflow `BR-WF-NNN`. Each rule: priority (High/Med/Low), condition/logic (IF-THEN or decision table), user-facing error message where applicable, entity it applies to, source requirement ID.
5. Cross-check: rules don't conflict; every requirement from `discovery.md` that implies a rule has one; every entity referenced by a rule is modeled.
6. Flag compliance inputs for Phase 4: sensitive data categories handled, regulated operations, consent-relevant flows — a bullet list, not the full analysis.

## Deliverables

**`docs/ba/<feature>/domain-model.md`** — sections: Domain Overview; Entities (per entity: description, attribute table, relationships, business rules affecting it, state machine if any); Relationships diagram (Mermaid `erDiagram` or class diagram); Glossary table; Domain Constraints; Version Log.

**`docs/ba/<feature>/business-rules.md`** — sections: rules grouped by category using the ID scheme above; Priority Matrix (rule × priority × compliance impact × change frequency); Traceability table (rule ID → requirement ID → stakeholder); Compliance Inputs for Phase 4; Version Log.

## Quality checklist

- Every entity from the requirements modeled; relationships have cardinality
- Every rule has an ID, priority, testable logic, and a source requirement
- Glossary covers all terms a new team member would ask about
- Compliance inputs listed for Phase 4
- No industry assumption that didn't come from the objective, Stack Config, or a loaded domain reference

End by listing artifacts written, key findings, open issues, blockers.
