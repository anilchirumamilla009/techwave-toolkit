# Story Templates Reference

## User Story Template (Standard)

```
## [Story Title] [Size: XS/S/M/L]

**As a** [persona — who benefits]
**I want** [the capability or action]
**So that** [the outcome or benefit]

### Acceptance Criteria
- [ ] Given [precondition], when [action], then [expected result]
- [ ] Given [precondition], when [action], then [expected result]
- [ ] [Error/edge case]: Given [error condition], when [action], then [graceful handling]

### Out of Scope
- [Explicit exclusion 1]
- [Explicit exclusion 2]

### Technical Notes *(optional)*
- [Constraint — e.g., "must complete in < 500ms at p99"]
- [Integration note — e.g., "must be idempotent for retry safety"]

### Size Rationale *(for L-sized stories)*
[Why this is L and whether it should be broken down further]
```

---

## Epic Template

```
## Epic: [Epic Name]

**Problem statement:**
[1–2 sentences describing the user problem this epic solves]

**Persona(s) affected:**
[List the users who benefit]

**Success metric:**
[How we'll know this epic is done and successful]

**Stories in this epic:**
1. [Story 1 title] — [Size] — [Dependency: none / blocks Story 3]
2. [Story 2 title] — [Size] — [Dependency: after Story 1]
3. [Story 3 title] — [Size] — [Dependency: after Stories 1 and 2]

**Out of scope for this epic:**
- [What is explicitly deferred]

**Walking skeleton story** (ship this first):
[Identify which story, if shipped alone, would deliver the thinnest end-to-end value]
```

---

## Sizing Guide

| Size | Effort | Signal |
|---|---|---|
| XS | < 4 hours | Single UI change, copy change, config flag |
| S | 1–2 days | Single feature with 1–2 acceptance criteria |
| M | 3–5 days | Feature with multiple criteria, one integration |
| L | 1–2 weeks | Complex feature with multiple integrations — consider breaking down |

**When to break down an L story:**
- It has more than 5 acceptance criteria
- It touches more than 2 external systems
- Different team members would work on different parts simultaneously

---

## Jira Field Mapping

When outputting for Jira:

```
Summary: [Story title — one line]
Issue Type: Story
Story Points: [XS=1, S=2, M=3, L=5, XL=8]
Description:
  h3. User Story
  As a [persona], I want [goal] so that [benefit].

  h3. Acceptance Criteria
  * Given [context], when [action], then [result]
  * ...

  h3. Out of Scope
  * ...

Labels: [epic-name], [team-name]
Epic Link: [epic name]
```

---

## Linear Field Mapping

When outputting for Linear:

```
Title: [Story title]
Description:
  **User Story**
  As a [persona], I want [goal] so that [benefit].

  **Acceptance Criteria**
  - [ ] Given..., when..., then...

  **Out of Scope**
  - ...

Estimate: [XS=1, S=2, M=3, L=5]
Labels: [epic], [area]
```

---

## Common Persona Library

Use consistent persona names to avoid ambiguity:

| Domain | Personas |
|---|---|
| B2C app | Guest user, Registered user, Premium subscriber |
| B2B SaaS | Workspace admin, Regular member, Billing contact |
| Healthcare | Patient, Clinician, Administrator, Billing staff |
| E-commerce | Shopper, Seller, Fulfillment operator, Support agent |
| Internal tool | Analyst, Operations manager, Engineer, Superadmin |
| Developer platform | Developer (API consumer), Marketplace publisher, Platform admin |

---

## Worked Example: Authentication Epic

### Epic: User Authentication

**Problem statement:** Users cannot access their account securely — we have no login system.

**Success metric:** Users can log in and out; sessions persist across browser refresh; accounts are locked after 5 failed attempts.

**Stories:**
1. Basic email/password login — M — no dependency
2. Session persistence (remember me) — S — after Story 1
3. Account lockout after failed attempts — S — after Story 1
4. Password reset flow — M — after Story 1

---

### Story 1: Email/Password Login — M

**As a** registered user
**I want** to log in with my email and password
**So that** I can access my account securely

**Acceptance Criteria:**
- [ ] Given valid credentials, when I submit the login form, then I am redirected to the dashboard
- [ ] Given invalid credentials, when I submit, then I see "Incorrect email or password" (never specify which is wrong)
- [ ] Given correct credentials, when the session is established, then an HTTP-only cookie is set (not localStorage)
- [ ] Given a login attempt, when the form submits, then the password field is cleared

**Out of Scope:** SSO/OAuth login, multi-factor authentication, biometric login

**Technical Notes:** Passwords must be hashed with bcrypt (cost factor ≥ 12). Response time must be consistent regardless of whether email exists (prevent user enumeration).
