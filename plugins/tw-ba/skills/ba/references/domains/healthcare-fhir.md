# Domain Reference: Healthcare / FHIR

Load this file only when Step 0.5 detected a healthcare domain (Stack Config `Domain: health*` or the objective concerns patient care, clinical data, or medical services). Apply its mappings and checklists **on top of** the generic agent instructions — it never replaces them.

## Applies to phases

| Phase agent | What to apply |
|---|---|
| domain-agent | FHIR resource mapping, healthcare glossary pattern, clinical business-rule categories |
| data-agent | FHIR-aligned entities, PHI classification, clinical value sets, healthcare retention |
| compliance-agent | HIPAA checklist structure, PHI identifier inventory, consent-as-FHIR-Consent, audit specifics |
| functional-spec-agent | Reference compliance requirements as constraints in the FRD's NFR section |

---

## Domain modeling (domain-agent)

**Map every core entity to a FHIR R4 resource where one fits** — note the mapping in the domain model and glossary:

| Typical concept | FHIR R4 resource |
|---|---|
| Person receiving care | `Patient` |
| Care professional | `Practitioner` (+ `PractitionerRole`) |
| Care organization / tenant | `Organization` |
| Plan of care | `CarePlan` (activities as `activity[]`) |
| Measurement / vital / result | `Observation` |
| Appointment / visit | `Appointment`, `Encounter` |
| Medication | `Medication`, `MedicationRequest` |
| Condition / diagnosis | `Condition` |
| Message | `Communication` |
| Consent record | `Consent` |
| Document | `DocumentReference` |

- Add a **FHIR Mapping** column to the domain glossary.
- Note applicable profiles (e.g. US Core) as constraints, not implementations.
- Clinical business rules commonly needed: eligibility/coverage checks, care-plan status transitions, clinical-range validation on observations, role-based visibility of clinical data.

## Data modeling (data-agent)

- Align entity/attribute names with the FHIR resource's fields (`birthDate`, `telecom`, `period.start`) so the spec transfers to any FHIR-capable backend; flag deliberate divergences.
- **PHI column is mandatory** in the data dictionary — mark each field Yes/No.
- Clinical **value sets**: LOINC for observations/labs, SNOMED CT for diagnoses/conditions, RxNorm for medications, FHIR administrative value sets (e.g. AdministrativeGender) for demographics.
- **Retention defaults** (adjust to jurisdiction): clinical records 6–10 years (HIPAA commonly operationalized as 7); audit logs 7 years; soft-delete for patient identity records.
- Multi-tenant systems: every clinical entity carries an organization/tenant reference; cross-tenant isolation is a stated constraint.

## Compliance requirements (compliance-agent)

Structure the compliance-requirements deliverable around these sections when HIPAA applies:

**1. PHI inventory** — check the feature against the 18 identifiers (45 CFR §164.514(b)(2)): names; dates; phone; email; SSN; MRN; health-plan numbers; account numbers; certificate/license numbers; vehicle IDs; device IDs; URLs; IP addresses; biometrics; full-face photos; other unique IDs; and clinical data (diagnoses, medications, observations). For each handled identifier record: collected / stored / displayed / transmitted / encrypted.

**2. Privacy Rule (45 CFR 160, 164 A&E)** — per requirement, state the implementation expectation and a verification pointer:
- §164.502(b) minimum necessary — role-filtered fields in UI/API.
- §164.502(g) personal representatives — guardian/parent access to dependent records.
- §164.508 authorization — written/electronic consent before disclosure; core elements: what is disclosed, by whom, to whom, purpose, expiration, right to revoke.

**3. Security Rule (45 CFR 164 Subpart C)** — administrative (risk assessment cadence, workforce access reviews, least privilege), technical (unique user IDs, emergency access procedure, automatic logoff, encryption at rest and in transit), transmission security.

**4. Breach Notification (§§164.400–414)** — detection mechanism, individual notification ≤60 days, HHS notification threshold (≥500 individuals).

**5. Consent management** — enumerate consent types the feature needs (platform usage, data sharing with care team, third-party device/data integration, research/analytics on de-identified data). For each: required vs opt-in, when collected, withdrawal path, granular permissions. **Store consent as a FHIR `Consent` resource** (status, scope, category, patient, provision with actor/action/data) so grants are queryable at authorization time; enforcement = deny by default, permit on owner/role/consent match, log every decision.

**6. Audit logging** — log all PHI reads/writes/searches + auth events + consent changes; entry carries user, role, action, resource type/id, timestamp, source address, outcome, consent reference where applicable; append-only store, restricted access, 7-year retention; automated anomaly review (bulk access, after-hours, repeated denials).

**7. Business Associate Agreements** — any third-party service touching PHI (cloud, email/SMS, analytics, FHIR hosting) requires a BAA; list vendors + status.

## Handoff note

These are **requirement-level** controls (what must exist). Code-level verification of the implemented controls is a development-phase activity (e.g. tw-dev `/compliance health`).
