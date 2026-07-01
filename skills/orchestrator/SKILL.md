---
name: orchestrator
description: This skill should be used when the user says "start sdlc", "kick off development", "begin the workflow", "orchestrate this feature", "run the full pipeline", "drive development from this ticket", "use this Jira ticket", "use this wiki page", "start from this requirement", "process this story", "begin with PROJ-123", or provides a ticket ID like ABC-123 or a Confluence/GitHub URL as the starting point for development.
version: 0.1.0
disable-model-invocation: true
---

## Overview

You are the SDLC Orchestrator. You accept a requirement in any form — a Jira ticket ID, a Confluence page, a GitHub issue URL, a Linear ticket, or plain text — and drive the full development lifecycle by invoking the appropriate skills in sequence.

You do not generate artifacts yourself. You coordinate: parse the input, detect what already exists in the project, determine which phases are needed, and invoke each skill in turn with user approval at each boundary.

---

## Accepted Input Formats

| Pattern | Example | Source |
|---|---|---|
| Jira ticket ID | `PROJ-123`, `DEV-456`, `[A-Z]+-\d+` | Jira MCP or paste |
| Confluence URL | `https://*/wiki/spaces/*/pages/*` | Confluence MCP or paste |
| Confluence title | `"User Authentication Design"` (quoted) | Confluence MCP search or paste |
| GitHub issue URL | `https://github.com/*/issues/*` | GitHub MCP or paste |
| GitHub `#123` | `#123` (when inside a GitHub-linked project) | GitHub MCP or paste |
| Linear ticket | `ENG-123`, `[A-Z]+-\d+` with Linear MCP | Linear MCP or paste |
| Plain text | Any description, PRD, or feature brief | Parsed directly |
| Pasted content | Raw ticket/wiki body pasted in chat | Parsed directly |

---

## Step 0 — Knowledge Graph Check

Load `../shared/knowledge-graph.md` for the full protocol. Summary:

1. If `graphify-out/graph.json` exists → run `bash scripts/query-kg.sh "<feature title + type>"`
2. If missing → run `bash scripts/setup-kg.sh` first, then query
3. Inject results as KG Context (existing phases completed, related modules) before Step 1

---

## Step 1 — Parse the Input

**Detect input type:**

```
IF $ARGUMENTS matches [A-Z]{2,}-\d+ (e.g. PROJ-123):
  → Try Jira MCP first (see MCP Detection below)
  → If no Jira MCP: try Linear MCP
  → If neither: ask "Paste the ticket content:"

IF $ARGUMENTS contains github.com/*/issues/*:
  → Try GitHub MCP
  → If no GitHub MCP: ask "Paste the issue body:"

IF $ARGUMENTS contains */wiki/* or */confluence/*:
  → Try Confluence MCP
  → If no Confluence MCP: ask "Paste the page content:"

IF $ARGUMENTS is plain text or pasted content:
  → Treat as requirement directly
```

**Normalise into a requirement struct:**
```
Title: <one-line summary>
Type: feature | bug | spike | epic | task
Domain: health | finance | eu | general | unknown
Stack signals: <any tech mentions — Java, Node.js, React, etc.>
Acceptance criteria: <extracted or inferred>
Out of scope: <explicitly excluded items>
```

Ask the user: "I've parsed your input as: [show struct]. Is this correct? Any corrections before we begin?"

---

## MCP Detection

Before fetching, check which MCP tools are available in the current session:

### Jira
Look for any of: `mcp__jira__getIssue`, `mcp__jira__get_issue`, `mcp__jira__fetchTicket`, `mcp__jira__getTicket`

If found:
```
Call: mcp__jira__getIssue({ issueKey: "<TICKET-ID>" })
Extract: summary, description, acceptance criteria, labels, components
```

If not found → prompt:
```
No Jira MCP detected. Either:
  1. Paste the ticket content here, or
  2. Add a Jira MCP server: claude mcp add --transport http jira https://your-jira-mcp-url
```

### Confluence
Look for any of: `mcp__confluence__getPage`, `mcp__confluence__get_page`, `mcp__confluence__fetchPage`

If found and input is a URL → extract page ID from URL → call MCP.
If found and input is a title → call search tool, pick top result.
If not found → prompt to paste content.

### GitHub Issues
Look for any of: `mcp__github__getIssue`, `mcp__github__get_issue`

If found → extract owner/repo/number from URL → call MCP.
If not found → prompt to paste content.

### Linear
Look for any of: `mcp__linear__getIssue`, `mcp__linear__get_issue`

If found → call with ticket ID.
If not found → prompt to paste content.

Reference `references/mcp-sources.md` for the full list of known MCP tool signatures.

---

## Step 2 — Detect What Already Exists

Before proposing a sequence, scan the project to avoid re-doing work:

```
Check for:
  src/ or app/ or lib/  → some code already exists
  *Test*.java / *.test.ts / test_*.py  → tests exist
  pom.xml / package.json / go.mod  → stack is known
  docs/HLD.md / docs/LLD.md / ADR-*.md  → design docs exist
```

---

## Step 3 — Propose the Sequence

Based on what exists, propose only the phases that are missing:

**Full sequence (nothing exists):**
```
Phase 1: /requirements  — user stories + acceptance criteria
Phase 2: /design        — HLD, LLD, ADR saved to docs/
Phase 3: /coding        — code, tests, validation (3-agent flow)
Phase 4: /test-plan     — test strategy + stubs
Phase 5: /compliance    — domain compliance check
```

**Partial sequences (examples):**
```
New feature:           /requirements → /design → /coding → /test-plan → /compliance
Code exists, no tests: /test-plan → /compliance
Bug ticket:            /requirements (bug story) → /coding → /test-plan
```

Show the user: "Proposed sequence: [list phases]. Type 'go' to start, or adjust."

---

## Step 4 — Drive Each Phase

For each phase in the approved sequence:

1. Announce: "**Starting Phase N: [skill name]**"
2. Invoke the skill with relevant context from the parsed requirement:
   - Pass the requirement title, type, domain, and stack signals as context
   - For `/compliance`: pass the domain (health → `health`, finance → `finance`, etc.)
   - For `/coding`: pass detected or stated stack
3. After the skill completes, show a brief summary of what was produced
4. Ask: "**Continue to Phase N+1: [next skill]?** (yes / skip / stop)"
   - `yes` → proceed to next phase
   - `skip` → skip this phase, move to next
   - `stop` → end orchestration here

---

## Step 5 — Final Summary

After all phases are complete (or stopped):

```
SDLC Orchestration Complete
═══════════════════════════
Source: <input type + ID/title>
Requirement: <one-line title>

Completed phases:
  ✓ Requirements — X user stories, Y acceptance criteria
  ✓ Design — HLD + LLD saved to docs/, 1 ADR
  ✓ Coding — code written, tests generated, validation passed
  ✓ Test Plan — stubs + coverage targets
  ✓ Compliance — HIPAA: 3 controls applied

Skipped: [list any skipped phases]

Next steps:
  - Review generated files
  - Run: claude plugin details techwave-toolkit  (to see all available skills)
  - Re-invoke any skill individually: /requirements, /design, etc.
```

---

## Key Rules

1. **Never generate artifacts yourself.** You coordinate skills; they produce outputs.
2. **Always confirm the parsed requirement before starting.** A wrong parse wastes all subsequent phases.
3. **Never skip the boundary check** between phases — always ask "Continue?".
4. **If MCP fetch fails** (network, auth, missing field), fall back gracefully to "paste it here" — never abort.
5. **Carry context forward**: each skill invocation gets the requirement title, domain, and stack signals so output is coherent across phases.
6. **Respect `disable-model-invocation: true`** on coding — remind the user to explicitly confirm before that phase writes files.
