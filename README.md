# techwave-toolkit

A Claude Code plugin providing AI-assisted skills for every major SDLC phase. Tech-stack agnostic — works with Node.js, Python, Go, Java, Rust, React, and more.

## Skills

| Command | Phase | Description |
|---|---|---|
| `/orchestrator` | **Entry point** | Accepts a Jira ticket, Confluence page, GitHub issue, or plain text — drives all phases in sequence |
| `/requirements` | Requirements | User stories, acceptance criteria, BDD scenarios, epic breakdown |
| `/design` | Architecture | Mermaid diagrams, ADRs, tech stack evaluation |
| `/scaffold [stack]` | Development | Full project boilerplate for any tech stack |
| `/test-plan` | Testing | Test strategy document + runnable test stubs |
| `/compliance [domain]` | Compliance | HIPAA, PCI DSS, GDPR, SOC 2 code-level review |
| `/cicd` | CI/CD | GitHub Actions, GitLab CI, Jenkins, Azure DevOps pipelines |
| `/deploy [target]` | Deployment | Docker Compose, Helm/K8s, Terraform, cloud IaC |

## Installation

```bash
# Load for this session only (no install step)
claude --plugin-dir /path/to/techwave-toolkit

# Permanent install — symlink into the skills-dir (auto-loaded every session)
ln -s /path/to/techwave-toolkit ~/.claude/skills/techwave-toolkit

# Permanent install via local marketplace
claude plugin marketplace add /path/to/techwave-toolkit
claude plugin install techwave-toolkit

# Install from marketplace (once published)
claude plugin install techwave-toolkit
claude plugin install techwave-toolkit@techwave   # from named marketplace
```

## Plugin Management

```bash
claude plugin list                    # see all installed plugins + versions
claude plugin details techwave-toolkit     # inspect skills, estimated token cost
claude plugin update techwave-toolkit      # pull latest version
claude plugin disable techwave-toolkit     # disable without uninstalling
claude plugin enable techwave-toolkit      # re-enable
claude plugin uninstall techwave-toolkit   # clean removal
claude plugin validate .              # validate plugin.json (run from plugin dir)
```

## Usage

### Orchestrator — Start Here

The orchestrator is the single entry point. Give it a ticket ID, URL, or plain text and it drives the full SDLC workflow:

```
/orchestrator PROJ-123
/orchestrator https://github.com/org/repo/issues/42
/orchestrator https://wiki.company.com/pages/123456/Feature+Design
/orchestrator Build a JWT authentication module with refresh token support
```

If a Jira, Confluence, or GitHub MCP server is configured, the orchestrator fetches content automatically. Otherwise it prompts you to paste.

**Adding MCP sources for auto-fetch:**
```bash
claude mcp add --transport http jira https://your-jira-mcp-url
claude mcp add --transport http confluence https://your-confluence-mcp-url
claude mcp add --transport http github https://api.githubcopilot.com/mcp/v1
```

### Individual Skills

Use any skill directly without going through the orchestrator:

**Requirements**
```
/requirements write user stories for a user login feature
/requirements break down the epic: "User Profile Management"
```

**Architecture & Design**
```
/design create a C4 container diagram for a payments service
/design write an ADR for choosing PostgreSQL over MongoDB
/design recommend a tech stack for a real-time chat app
```

**Scaffolding**
```
/scaffold nodejs          # Node.js + TypeScript + Express
/scaffold python          # Python + FastAPI + Poetry
/scaffold go              # Go + Gin
/scaffold java            # Java + Spring Boot
/scaffold react           # React + Vite + TypeScript
/scaffold rust            # Rust + Axum
/scaffold                 # Auto-detects stack from existing files
```

**Testing**
```
/test-plan write a test plan for the user authentication module
/test-plan generate test stubs for the OrderService class
```

**Compliance**
```
/compliance health        # HIPAA technical safeguards review
/compliance finance       # PCI DSS v4.0 code controls
/compliance eu            # GDPR (consent, erasure, portability)
/compliance soc2          # SOC 2 CC6/7/8 controls
/compliance               # Auto-detects domain from codebase
```

**CI/CD**
```
/cicd                     # Auto-detects platform and stack
/cicd github              # GitHub Actions workflow
/cicd gitlab              # GitLab CI pipeline
/cicd jenkins             # Declarative Jenkinsfile
/cicd azure               # Azure DevOps pipeline
```

**Deployment**
```
/deploy compose           # Docker Compose (multi-environment)
/deploy helm              # Helm chart for Kubernetes
/deploy terraform         # Terraform module (AWS/Azure/GCP)
/deploy aws               # AWS-specific services (ECS, RDS, etc.)
/deploy                   # Ask for deployment target
```

## Plugin Structure

```
techwave-toolkit/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── skills/                        # One directory per skill
│   ├── orchestrator/
│   │   ├── SKILL.md               # Entry point — drives all other skills
│   │   └── references/
│   │       └── mcp-sources.md     # Jira/Confluence/GitHub MCP tool signatures
│   ├── requirements/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── design/
│   ├── scaffold/
│   ├── test-plan/
│   ├── compliance/
│   ├── cicd/
│   └── deploy/
└── hooks/
    ├── hooks.json                 # PostToolUse compliance reminder
    └── compliance-scan.sh         # Detects hardcoded secrets / PII in logs
```

## How Skills Work

Each skill is a `SKILL.md` file with a `description` field containing trigger phrases. Claude Code loads skills automatically and invokes the right skill when you type the matching slash command.

Skills use a **progressive disclosure** pattern:
1. `SKILL.md` — core instructions (~1,000–2,000 words, always loaded)
2. `references/*.md` — detailed domain knowledge (loaded on-demand)

## Contributing

1. Fork this repository
2. Add or update a skill in `skills/<skill-name>/SKILL.md`
3. Validate: `claude plugin validate .`
4. Test: `claude --plugin-dir .` then invoke the skill
5. Submit a pull request

### Skill Quality Checklist

- [ ] `description` field has 8+ distinct trigger phrases
- [ ] SKILL.md has a clear step-by-step process section
- [ ] All file-generating skills have `disable-model-invocation: true`
- [ ] Parameterized skills have a complete routing table for `$ARGUMENTS`
- [ ] Reference files are dense with concrete examples (templates, code, patterns)
- [ ] Skill exits gracefully when context is ambiguous (asks the user, doesn't guess)
- [ ] `claude plugin validate .` passes before submitting

## License

MIT — free to use, modify, and distribute within your team.
