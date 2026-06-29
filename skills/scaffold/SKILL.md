---
name: scaffold
description: This skill should be used when the user asks to "scaffold a project", "generate boilerplate", "bootstrap a new service", "initialize a codebase", "create project structure", "create starter project for", "set up project skeleton", "generate a new app", "create the folder structure", or "start a new project". This skill generates complete, runnable project scaffolds for any technology stack. It detects the stack from existing files or the user's argument.
version: 0.1.0
disable-model-invocation: true
---

# Scaffolding & Development Skill

## Overview

This skill generates complete, runnable project scaffolds for any technology stack. It detects the stack automatically from existing marker files, or uses the user's explicit argument. It always confirms the planned structure with the user before writing any files.

## When to Use

Invoke when the user wants to create a new project or add boilerplate to an empty directory. This skill creates real, working files — not pseudocode or templates with placeholders.

## Arguments Routing

The user may invoke this skill with a stack name: `/scaffold nodejs`, `/scaffold python`, etc.

**Alias table — map any of these to the correct reference file:**

| Alias(es) | Reference file |
|---|---|
| `nodejs`, `node`, `express`, `fastify`, `hapi`, `typescript` | `references/stacks/nodejs.md` |
| `python`, `fastapi`, `django`, `flask`, `uvicorn` | `references/stacks/python.md` |
| `java`, `spring`, `springboot`, `quarkus`, `micronaut`, `maven`, `gradle` | `references/stacks/java.md` |
| `go`, `golang`, `gin`, `echo`, `chi`, `fiber` | `references/stacks/go.md` |
| `react`, `nextjs`, `next`, `vite`, `cra`, `frontend` | `references/stacks/react.md` |
| `rust`, `axum`, `actix`, `warp`, `tokio` | `references/stacks/rust.md` |

## Step-by-Step Process

### 1. Determine the Stack

**If `$ARGUMENTS` is provided:** Look up the alias table above. Load the matching reference file. If the alias is unrecognized, ask the user which stack they want.

**If `$ARGUMENTS` is empty (no argument given):** Run the detection sequence:

```bash
ls package.json go.mod pom.xml build.gradle pyproject.toml requirements.txt Cargo.toml tsconfig.json 2>/dev/null
```

Match the detected file to a stack:
- `package.json` + `tsconfig.json` → Node.js (TypeScript)
- `package.json` only → Node.js (JavaScript) — still use nodejs.md, note JS variant
- `go.mod` → Go
- `pom.xml` or `build.gradle` → Java
- `pyproject.toml` or `requirements.txt` → Python
- `Cargo.toml` → Rust
- If multiple detected (monorepo): ask which service to scaffold
- If none found: ask the user explicitly which stack to use

### 2. Load the Stack Reference

Read the appropriate `references/stacks/<stack>.md` file. It contains:
- The complete directory tree
- File contents for all essential files
- Entry point conventions
- Test setup
- Dockerfile

### 3. ALWAYS confirm before writing files

After loading the reference, output the planned directory tree and ask the user to confirm:

```
I'll scaffold a [Stack] project with the following structure:

[directory tree]

Key files:
- [file]: [one-line description]
- ...

Shall I create these files? You can request changes to the structure before I proceed.
```

**Do not write any files until the user confirms.**

### 4. Generate the Files

After confirmation, use the Write tool to create each file with the exact content from the reference. Do not omit any file from the reference — each one is required for the project to be runnable.

### 5. Post-Generation Summary

After writing all files, output:
```
Scaffold complete. To get started:

[stack-specific getting started commands from the reference]

Next steps:
- Run /test-plan to generate a test strategy for this project
- Run /cicd to add a CI/CD pipeline
- Run /compliance [domain] if this project handles regulated data
```

## Key Rules

- Never write files without user confirmation of the planned structure
- Never generate pseudocode or template files with `TODO` placeholders — generate real, runnable code
- Never hardcode secrets in generated files — use `.env.example` with placeholder values and `.gitignore` entries
- If the user modifies the planned structure (adds/removes a directory), honor their change exactly
- The generated project must be runnable immediately after scaffolding with the commands provided
