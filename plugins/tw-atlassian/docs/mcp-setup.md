# MCP Server Setup — Atlassian (Jira & Confluence)

This guide sets up the Atlassian Remote MCP server so the **tw-dev** orchestrator can automatically fetch Jira ticket details when you provide a ticket ID (e.g. `PROJ-123`).

Once configured, running `/orchestrator PROJ-123` will pull the full ticket — summary, description, acceptance criteria, labels, status — without any copy-paste.

---

## Prerequisites

- A GitHub Copilot CLI installation with the tw-dev plugin installed
- An Atlassian account (Jira Cloud) with access to the projects you want to fetch from

---

## Step 1 — Add the MCP Server

Run this command in your terminal:

```bash
copilot mcp add atlassian --transport http https://mcp.atlassian.com/v1/mcp
```

---

## Step 2 — Authenticate via Browser

The first time the MCP server is used, Atlassian will automatically open your browser to complete OAuth authentication:

1. A browser window opens to the Atlassian login page
2. Log in with your Atlassian account (or confirm if already logged in)
3. Click **Allow** to grant Copilot CLI access to your Jira and Confluence data
4. The browser redirects and authentication completes — return to your terminal

No API tokens or environment variables are needed. Authentication is stored securely by the MCP server for future sessions.

---

## Step 3 — Verify the Connection

In your Copilot CLI session, run:

```
/orchestrator PROJ-123
```

Replace `PROJ-123` with a real ticket ID from your Jira project. The orchestrator should automatically fetch and display the ticket details.

If it works, you'll see:
```
[Orchestrator] Fetched from Jira (mcp__atlassian__get_issue):
  Title: <your ticket summary>
  Type: Story | Bug | Task
  ...
```

---

## Troubleshooting

### "No Atlassian MCP detected"
The MCP server is not registered. Re-run Step 1.

```bash
# Check currently registered MCP servers
copilot mcp list
```

### Browser did not open / authentication stuck
Try removing and re-adding the server to restart the OAuth flow:
```bash
copilot mcp remove atlassian
copilot mcp add atlassian --transport http https://mcp.atlassian.com/v1/mcp
```

### "Issue not found" / 404
- Check the ticket ID is correct (case-sensitive: `PROJ-123` not `proj-123`)
- Check your Atlassian account has permission to view that project
- Re-authenticate if your OAuth session has expired (remove and re-add)

---

## Removing the MCP Server

```bash
copilot mcp remove atlassian
```

---

## What Data Is Fetched

When you provide a Jira ticket ID, the orchestrator fetches:

| Field | Source |
|---|---|
| Title / Summary | `fields.summary` |
| Description | `fields.description` (ADF format, extracted as text) |
| Issue type | `fields.issuetype.name` |
| Status | `fields.status.name` |
| Priority | `fields.priority.name` |
| Labels | `fields.labels` |
| Components | `fields.components[*].name` |
| Acceptance criteria | `fields.customfield_10016` or AC section in description |
| Recent comments | `fields.comment.comments` (latest 3) |

No data is stored or sent anywhere other than your local Copilot CLI session.
