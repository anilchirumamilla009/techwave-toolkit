# MCP Tool Signatures — Orchestrator Reference

This file lists known MCP tool names for each source system. The orchestrator checks for these names to decide whether to auto-fetch or prompt the user to paste content.

MCP tool names follow the pattern: `mcp__<server-name>__<operation>`
The server name part comes from what was used in `claude mcp add <name> ...`.

---

## Jira

Common server names: `jira`, `atlassian-jira`, `jira-cloud`

| Tool name variants | Operation |
|---|---|
| `mcp__jira__getIssue` | Fetch issue by key |
| `mcp__jira__get_issue` | Fetch issue by key (snake_case variant) |
| `mcp__jira__fetchTicket` | Fetch ticket by key |
| `mcp__jira__getTicket` | Fetch ticket by key |
| `mcp__atlassian-jira__getIssue` | If registered as `atlassian-jira` |
| `mcp__jira-cloud__getIssue` | If registered as `jira-cloud` |

**Expected response fields:**
```json
{
  "key": "PROJ-123",
  "fields": {
    "summary": "...",
    "description": "...",
    "issuetype": { "name": "Story|Bug|Task|Epic" },
    "labels": [...],
    "components": [...],
    "acceptanceCriteria": "..."
  }
}
```

**How to add Jira MCP:**
```bash
claude mcp add --transport http jira https://your-jira-mcp-endpoint
# or for Atlassian's official MCP:
claude mcp add --transport http jira https://mcp.atlassian.com/v1/mcp
```

---

## Confluence

Common server names: `confluence`, `atlassian-confluence`, `wiki`

| Tool name variants | Operation |
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

**How to add Confluence MCP:**
```bash
claude mcp add --transport http confluence https://your-confluence-mcp-endpoint
```

---

## GitHub

Common server names: `github`, `gh`

| Tool name variants | Operation |
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
claude mcp add --transport http github https://api.githubcopilot.com/mcp/v1
# Requires GITHUB_PERSONAL_ACCESS_TOKEN in environment
```

---

## Linear

Common server names: `linear`, `linear-app`

| Tool name variants | Operation |
|---|---|
| `mcp__linear__getIssue` | Fetch issue by ID |
| `mcp__linear__get_issue` | Fetch issue (snake_case) |
| `mcp__linear-app__getIssue` | If registered as `linear-app` |

**Ticket ID pattern:** `[A-Z]+-\d+` same as Jira — if both are configured, Jira is tried first. If the ticket key prefix matches a known Linear team prefix (check `mcp__linear__getTeams` if available), use Linear instead.

**How to add Linear MCP:**
```bash
claude mcp add --transport http linear https://mcp.linear.app/sse
# Requires Linear API key
```

---

## ServiceNow

Common server names: `servicenow`, `snow`

| Tool name variants | Operation |
|---|---|
| `mcp__servicenow__getTicket` | Fetch incident/story by ID |
| `mcp__snow__getRecord` | Fetch record |

**Ticket ID pattern:** `INC\d+`, `STRY\d+`, `CHG\d+`

---

## Azure DevOps (Work Items)

Common server names: `azure-devops`, `ado`

| Tool name variants | Operation |
|---|---|
| `mcp__azure-devops__getWorkItem` | Fetch work item by ID |
| `mcp__ado__getWorkItem` | If registered as `ado` |

**Ticket ID pattern:** numeric only (e.g. `12345`) — ambiguous with plain numbers, only activate if Azure DevOps MCP is present and user explicitly mentions "ADO" or "work item".

---

## Fallback — No MCP Available

When no MCP tool is detected for the input type, prompt:

```
I couldn't find a [Jira/Confluence/GitHub] MCP server in this session.

To auto-fetch in the future, add one:
  claude mcp add --transport http jira https://your-mcp-url

For now, paste the [ticket/page/issue] content below and I'll proceed from that:
```

Then treat the pasted content as plain text input and continue normally.
