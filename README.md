# TechWave Toolkit

AI-assisted SDLC skills for GitHub Copilot CLI — requirements, design, coding, QA, and compliance, all from a single Copilot session.

This repository hosts two plugins under the **techwave** marketplace:

| Plugin | What it does | Auth |
|---|---|---|
| **`tw-dev`** | All 6 SDLC skills (orchestrator, requirements, design, coding, QA, compliance) | ❌ None |
| **`tw-atlassian`** | Atlassian MCP — auto-fetch Jira tickets and Confluence pages for `/orchestrator` | ✅ Browser OAuth (optional) |

For full skill documentation see [`plugins/tw-dev/README.md`](plugins/tw-dev/README.md).

---

## Install

**Step 1 — Register the marketplace** (one-time per machine):
```bash
copilot plugin marketplace add anilchirumamilla009/techwave-toolkit
```

**Step 2 — Install tw-dev** (SDLC skills — everyone):
```bash
copilot plugin install tw-dev@techwave
```

**Step 3 — Install tw-atlassian** (optional — Jira users only):
```bash
copilot plugin install tw-atlassian@techwave
```
> On first use of `/orchestrator PROJ-123`, your browser opens for Atlassian OAuth login. No API token needed.

---

## Update

> ⚠️ Do **not** use `copilot plugin update` — it fails with a permissions error. Use the sequence below.

```bash
# Update tw-dev
copilot plugin uninstall tw-dev
copilot plugin marketplace update techwave
copilot plugin install tw-dev@techwave

# Update tw-atlassian
copilot plugin uninstall tw-atlassian
copilot plugin marketplace update techwave
copilot plugin install tw-atlassian@techwave
```

---

## Uninstall

```bash
# Remove tw-dev only
copilot plugin uninstall tw-dev

# Remove tw-atlassian only
copilot plugin uninstall tw-atlassian

# Remove everything including marketplace registration
copilot plugin uninstall tw-dev
copilot plugin uninstall tw-atlassian
copilot plugin marketplace remove techwave
```

---

## Verify

```bash
copilot plugin list                      # both plugins should appear
copilot plugin details tw-dev            # shows version + all 6 skills
copilot plugin details tw-atlassian      # shows version + MCP server status
```

---

## Available Skills (tw-dev)

| Command | Phase |
|---|---|
| `/orchestrator` | Entry point — drives full SDLC from a ticket, issue, or plain text |
| `/requirements` | User stories, acceptance criteria, BDD scenarios |
| `/design` | HLD, LLD, ADRs saved to `docs/` |
| `/coding` | Code + tests for any project type and stack |
| `/qa` | E2E scenarios, test data strategy, performance plan |
| `/compliance [domain]` | HIPAA, PCI DSS, GDPR, SOC 2 code-level review |

---

## Troubleshooting

**`copilot plugin update` → "Access denied (os error 5)"**
Use the [Update](#update) sequence above (uninstall → marketplace update → install).

**Skills not showing after install**
Reinstall using the Update steps — you may be on an older version.

**"I don't see an orchestrator skill available"**
Reinstall to get v0.9.1+ which fixes the `disable-model-invocation` flag.

**Marketplace not registered**
Run `copilot plugin marketplace add anilchirumamilla009/techwave-toolkit` first.

**Atlassian browser login does not open**
```bash
copilot plugin uninstall tw-atlassian
copilot plugin install tw-atlassian@techwave
```
Then invoke `/orchestrator PROJ-123` — the browser opens on first use.

---

**License:** MIT · **Author:** Venkata Anil Kumar Chirumamilla
