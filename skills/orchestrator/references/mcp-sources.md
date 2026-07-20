# MCP Tool Signatures — Orchestrator Reference

This file lists known MCP tool names for each source system. The orchestrator checks for these names to decide whether to auto-fetch or prompt the user to paste content.

MCP tool names follow the pattern: `mcp__<server-name>__<operation>`
The server name part comes from what was used in `claude mcp add <name> ...`.

---

## Jira / Atlassian (Official Remote MCP)

Atlassian provides an official Remote MCP server at `https://mcp.atlassian.com/v1/mcp`.
This is the **preferred** integration — it covers both Jira and Confluence with a single connection.

**Recommended registration name:** `atlassian`
```bash
copilot mcp add atlassian --transport http https://mcp.atlassian.com/v1/mcp
```

### Tool names (registered as `atlassian`)

| Tool name | Operation |
|---|---|
| `mcp__atlassian__get_issue` | Fetch Jira issue by key (e.g. PROJ-123) |
| `mcp__atlassian__search_issues_using_jql` | Search Jira issues via JQL query |
| `mcp__atlassian__get_issue_comments` | Fetch comments on a Jira issue |
| `mcp__atlassian__get_projects_paginated` | List accessible Jira projects |
| `mcp__atlassian__get_transitions` | Get available transitions for an issue |
| `mcp__atlassian__get_confluence_page_content` | Fetch Confluence page by ID |
| `mcp__atlassian__search_confluence` | Search Confluence by text or CQL |
| `mcp__atlassian__get_confluence_space` | Get a Confluence space by key |

**Expected `get_issue` response fields:**
```json
{
  "key": "PROJ-123",
  "fields": {
    "summary": "...",
    "description": { "content": [...] },
    "issuetype": { "name": "Story|Bug|Task|Epic" },
    "status": { "name": "To Do|In Progress|Done" },
    "priority": { "name": "High|Medium|Low" },
    "labels": ["..."],
    "components": [{ "name": "..." }],
    "assignee": { "displayName": "..." },
    "reporter": { "displayName": "..." },
    "customfield_10016": "...",
    "comment": { "comments": [...] }
  }
}
```

> **`description` format note:** Atlassian's API returns description in Atlassian Document Format (ADF) — a nested JSON object, not a plain string. Extract text from `fields.description.content[*].content[*].text` recursively. Fall back to `fields.description` if it is a plain string (older Jira Server).

> **Acceptance criteria note:** Jira does not have a standard `acceptanceCriteria` field. Look in this order:
> 1. `customfield_10016` (common AC custom field)
> 2. `customfield_10034` or any `customfield_*` whose name contains "acceptance"
> 3. The description body — look for a section labelled "Acceptance Criteria" or "AC:"

### Tool names (registered as `jira` — legacy / self-hosted)

| Tool name | Operation |
|---|---|
| `mcp__jira__getIssue` | Fetch issue by key |
| `mcp__jira__get_issue` | Fetch issue by key (snake_case) |
| `mcp__jira__fetchTicket` | Fetch ticket by key |
| `mcp__jira__getTicket` | Fetch ticket by key |
| `mcp__atlassian-jira__getIssue` | If registered as `atlassian-jira` |
| `mcp__jira-cloud__getIssue` | If registered as `jira-cloud` |

### Detection order

When input matches `[A-Z]{2,}-\d+`, check in this order:
1. `mcp__atlassian__get_issue` (official Remote MCP, preferred)
2. `mcp__jira__getIssue` or `mcp__jira__get_issue` (legacy server name)
3. `mcp__atlassian-jira__getIssue` (alternate registration name)
4. `mcp__jira-cloud__getIssue` (alternate registration name)
5. None found → prompt user (see Fallback section)

---

## Confluence (Official Remote MCP)

Covered by the same `atlassian` server registration above.

| Tool name | Operation |
|---|---|
| `mcp__atlassian__get_confluence_page_content` | Fetch page by ID |
| `mcp__atlassian__search_confluence` | Search by text or CQL |
| `mcp__atlassian__get_confluence_space` | Get space by key |

Legacy (separate Confluence server):

| Tool name | Operation |
|---|---|
| `mcp__confluence__getPage` | Fetch page by ID |
| `mcp__confluence__get_page` | Fetch page by ID (snake_case) |
| `mcp__confluence__fetchPage` | Fetch page by ID |
| `mcp__confluence__searchPages` | Search by title |
| `mcp__confluence__search` | Search pages |
| `mcp__wiki__getPage` | If registered as `wiki` |

**Page ID extraction from URL:**
```
https://company.atlassian.net/wiki/spaces/ENG/pages/123456789/Page+Title
                                                    ↑ this is the page ID
```

---

## GitHub

Common server names: `github`, `gh`

| Tool name | Operation |
|---|---|
| `mcp__github__getIssue` | Fetch issue by owner/repo/number |
| `mcp__github__get_issue` | Fetch issue (snake_case) |
| `mcp__github__fetchIssue` | Fetch issue |
| `mcp__gh__getIssue` | If registered as `gh` |

**Input parsing:**
```
https://github.com/owner/repo/issues/42
→ owner: "owner", repo: "repo", number: 42
```

**How to add GitHub MCP:**
```bash
copilot mcp add github --transport http https://api.githubcopilot.com/mcp/v1
# Requires GITHUB_PERSONAL_ACCESS_TOKEN in environment
```

---

## Linear

Common server names: `linear`, `linear-app`

| Tool name | Operation |
|---|---|
| `mcp__linear__getIssue` | Fetch issue by ID |
| `mcp__linear__get_issue` | Fetch issue (snake_case) |
| `mcp__linear-app__getIssue` | If registered as `linear-app` |

**Ticket ID pattern:** `[A-Z]+-\d+` same as Jira — if both are configured, Jira is tried first. If the ticket key prefix matches a known Linear team prefix (check `mcp__linear__getTeams` if available), use Linear instead.

**How to add Linear MCP:**
```bash
copilot mcp add linear --transport http https://mcp.linear.app/sse
# Requires Linear API key
```

---

## ServiceNow

Common server names: `servicenow`, `snow`

| Tool name | Operation |
|---|---|
| `mcp__servicenow__getTicket` | Fetch incident/story by ID |
| `mcp__snow__getRecord` | Fetch record |

**Ticket ID pattern:** `INC\d+`, `STRY\d+`, `CHG\d+`

---

## Azure DevOps (Work Items)

Common server names: `azure-devops`, `ado`

| Tool name | Operation |
|---|---|
| `mcp__azure-devops__getWorkItem` | Fetch work item by ID |
| `mcp__ado__getWorkItem` | If registered as `ado` |

**Ticket ID pattern:** numeric only (e.g. `12345`) — ambiguous with plain numbers, only activate if Azure DevOps MCP is present and user explicitly mentions "ADO" or "work item".

---

## Fallback — No MCP Available

When no MCP tool is detected for the input type, prompt:

```
No Atlassian MCP detected. Either:
  1. Paste the ticket content here and I'll proceed from that, or
  2. Set up the Atlassian MCP server — see docs/mcp-setup.md for instructions.
```

Then treat the pasted content as plain text input and continue normally.
