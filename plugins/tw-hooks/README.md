# tw-hooks

Shared guardrail hooks for **Claude Code** and **GitHub Copilot CLI**. This plugin carries no skills — it registers two hooks that protect every session, regardless of which TechWave plugins (tw-ba, tw-dev, tw-qa) you use. Install it alongside any of them; the hooks previously shipped inside tw-dev and were moved here so all plugins share one guardrail set.

## What it enforces

### 1. Sensitive-data guard — `PreToolUse` (blocking)

Runs **before** every Read / Bash / PowerShell tool call and **blocks** it when it would expose secret material:

- **Reading secret files** — `.env` (all variants except `.env.example`/`.sample`/`.template`/`.dist`), `*.pem`, `*.key`, `id_rsa*`/`id_ed25519*`, `*.p12`/`*.pfx`/`*.keystore`/`*.jks`, `credentials(.json)`, `service-account*.json`, `~/.aws/credentials`, `.netrc`, `*.tfstate`, `secrets.{json,yml,yaml,env,properties}`, `.npmrc`, `.pypirc`, `.docker/config.json`
- **Shell commands that print, encode, copy out, or upload those files** — `cat`/`head`/`tail`/`base64`/`xxd`/`curl`/`wget`/`nc`/`scp`/`rsync`/`Get-Content`/`type` combined with a sensitive path

When blocked, the model is told to work with variable **names** via the template file (`.env.example`) and leave values on your machine. Secrets never enter the conversation context, so they can't leak into chat, commits, or generated code.

### 2. Compliance scan — `PostToolUse` (warning)

Runs **after** every Write / Edit and feeds warnings back to the model when the written file contains:

- **Hardcoded credentials** — `password/api_key/secret/token = "..."` assignments
- **PII in log statements** — SSN, credit card, phone, DOB, patient ID inside `console.log`/`logger.*`/`print`/`logging.*`
- **Cloud access keys** — AWS Access Key ID patterns (`AKIA...`)

The model receives the warning (exit 2) and corrects the file; a clean file passes silently.

> Known limitation: pattern-based scanning flags documentation that *quotes* credential examples (this repo's own READMEs trigger it). Warnings are advisory — the write itself is not blocked.

## Installation

```bash
# Claude Code
claude plugin marketplace add anilchirumamilla009/techwave-toolkit   # once per machine
claude plugin install tw-hooks@techwave

# Copilot CLI
copilot plugin marketplace add anilchirumamilla009/techwave-toolkit
copilot plugin install tw-hooks@techwave
```

Restart the CLI — hooks load at startup. No configuration needed; both hooks are active immediately in every project.

## Requirements

- `bash` (Git Bash on Windows) — both hook scripts are POSIX shell
- `jq` optional — used when present, with a `sed` fallback

## Structure

```
tw-hooks/
├── plugin.json
└── hooks/
    ├── hooks.json                 # Claude Code hook registration (Pre + Post)
    ├── copilot-hooks.json         # Copilot CLI hook registration
    ├── sensitive-data-guard.sh    # PreToolUse blocker
    └── compliance-scan.sh         # PostToolUse scanner
```

## License

MIT
