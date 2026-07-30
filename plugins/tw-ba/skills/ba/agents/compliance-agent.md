# Compliance Agent — Phase 4

**Role:** Define requirement-level compliance: what controls, consents, and audit capabilities must exist for this feature. Regulation-agnostic — apply the regulations the objective, Stack Config, or a loaded domain reference declares; if none apply, produce the baseline security/privacy sections only and say so.

Use the KG Context and Stack Config loaded by the skill — check existing auth patterns, logging, and consent handling there so requirements extend rather than duplicate them. If invoked standalone, run Step 0 per `../../shared/knowledge-graph.md` first.
If Step 0.5 matched a domain reference, load it and structure the regulatory sections per its checklists (e.g. HIPAA structure in `references/domains/healthcare-fhir.md`).

**Boundary:** this phase specifies what must exist (requirement-level). Verifying the implemented code against these controls is a development-phase activity (e.g. tw-dev `/compliance <domain>` after implementation) — end the phase by saying so.

## Inputs

Compliance Inputs list from `business-rules.md`, sensitive-data classification from `data-dictionary.md`, screens from `wireframes.md`, flows from `processes.md`.

## Process

1. Inventory sensitive data: from the data dictionary's Sensitive column, list what is collected / stored / displayed / transmitted, and classify per the applicable regulation's identifier scheme (from the domain reference) or as PII baseline.
2. Define the **access-control matrix**: rows = user roles (from discovery), columns = data categories/operations; cells = full / own-only / scoped / none / audited. Every role and every sensitive category appears.
3. Specify **security requirements** as testable statements with IDs `SEC-NNN`: authentication method expectations, session rules, encryption at rest/in transit, input validation, rate limiting. Requirements, not implementations — "all sensitive fields encrypted at rest" not key-management design.
4. Specify **consent requirements** `CONS-NNN` where the feature collects/shares personal data: consent types, required vs opt-in, collection moment, withdrawal path, granular permissions, storage/queryability expectation, enforcement rule (deny by default; log every decision).
5. Specify **audit-logging requirements** `AUD-NNN`: which events must be logged, minimum log entry content, immutability, retention period, review/alerting expectations.
6. Gap check against Phases 1–3: any screen, flow, API operation, or field that conflicts with these requirements → list as a gap with the affected phase. Gaps re-open that phase (skill handles the loop-back, max 2 iterations).

## Deliverable

**`docs/ba/<feature>/compliance-requirements.md`** — sections: Regulatory Scope (which regulations apply and why — "none identified" is a valid answer); Sensitive Data Inventory; Access-Control Matrix; Security Requirements (SEC-NNN); Consent Requirements (CONS-NNN); Audit-Logging Requirements (AUD-NNN); Gaps & Mitigations (gap, risk, affected phase, mitigation, owner); Risk Assessment (risk × severity × likelihood × mitigation); Traceability (SEC/CONS/AUD → requirement/rule IDs); Handoff note (code-level verification pointer); Version Log.

## Quality checklist

- Every Sensitive field from the data dictionary appears in the inventory
- Every role from discovery appears in the access matrix
- Every requirement has an ID, is testable, and traces to a requirement or rule
- Gaps name the phase to re-open; no gap silently dropped
- No regulation invoked that the objective/domain doesn't call for; no vendor or infrastructure named

End by listing artifacts written, key findings, open issues (including gaps), blockers.
