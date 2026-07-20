# tw-atlassian

Atlassian MCP integration plugin for the [TechWave toolkit](https://github.com/anilchirumamilla009/techwave-toolkit).

Install this plugin **in addition to `tw-dev`** if your team uses Jira. Once installed, the `/orchestrator` skill will automatically fetch ticket details when you provide a Jira ticket ID — no copy-paste needed.

## Install

```bash
copilot plugin install https://github.com/anilchirumamilla009/techwave-toolkit --plugin tw-atlassian
```

## What it does

- Registers the [Atlassian Remote MCP server](https://mcp.atlassian.com/v1/mcp) in your Copilot session
- Authenticates via browser OAuth — no API tokens or environment variables needed
- Enables `/orchestrator PROJ-123` to auto-fetch the Jira ticket (summary, description, acceptance criteria, labels, status)

## Setup

See [docs/mcp-setup.md](docs/mcp-setup.md) for step-by-step instructions.

**Quick start:**
```bash
copilot plugin install https://github.com/anilchirumamilla009/techwave-toolkit --plugin tw-atlassian
# → Browser opens for Atlassian login on first use
# → Run: /orchestrator PROJ-123
```

## Note

`tw-dev` and `tw-atlassian` are independent plugins. `tw-dev` works fully without `tw-atlassian` — the orchestrator simply prompts you to paste ticket content if the MCP server is not present.
