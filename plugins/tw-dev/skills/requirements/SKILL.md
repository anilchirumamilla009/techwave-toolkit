---
name: requirements
description: 'Moved — requirements drafting belongs to the tw-ba plugin. Install tw-ba and use /ba; its output in docs/ba/<feature>/ is the input to tw-dev. This location is kept for backwards compatibility only.'
version: 0.6.0
user-invocable: false
---

# This skill has moved

Requirements drafting (user stories, acceptance criteria, functional spec) is owned by the **tw-ba** plugin — it is a business-analysis activity, not a dev phase.

```bash
claude plugin install tw-ba@techwave     # Claude Code
copilot plugin install tw-ba@techwave    # Copilot CLI
```

Run `/ba <business objective or ticket>`. Its artifacts in `docs/ba/<feature>/` (FRD, stories, RTM) are the **input** to the tw-dev pipeline — `/orchestrator` reads them automatically and proceeds to design → coding → QA → compliance.
