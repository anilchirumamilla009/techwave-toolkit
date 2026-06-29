---
name: cicd
description: This skill should be used when the user asks to "create CI/CD pipeline", "GitHub Actions workflow", "Jenkinsfile", "GitLab CI", "Azure DevOps pipeline", "CircleCI config", "set up CI", "automate builds", "configure deployment pipeline", "add a build pipeline", "create a release workflow", "automate testing in CI", or needs any continuous integration or continuous deployment configuration. This skill generates complete, working pipeline files for any CI/CD platform.
version: 0.1.0
disable-model-invocation: true
---

# CI/CD Pipeline Skill

## Overview

This skill generates complete, working CI/CD pipeline configurations for any major platform (GitHub Actions, GitLab CI, Jenkins, Azure DevOps). Pipelines are multi-stage with build, test, security scan, artifact creation, and environment-gated deployment stages.

## When to Use

Invoke when the user wants to create or extend a CI/CD pipeline. This skill always generates real YAML/Groovy — never pseudocode or partially-filled templates.

## Step-by-Step Process

### 1. Detect the CI/CD Platform

**If `$ARGUMENTS` specifies a platform** (e.g., `/cicd github`, `/cicd jenkins`): use it directly.

**If `$ARGUMENTS` is empty**: detect from existing files:

```bash
ls .github/workflows/*.yml .gitlab-ci.yml Jenkinsfile azure-pipelines.yml .circleci/config.yml 2>/dev/null
```

- `.github/workflows/` exists → GitHub Actions
- `Jenkinsfile` exists → Jenkins
- `.gitlab-ci.yml` exists → GitLab CI
- `azure-pipelines.yml` exists → Azure DevOps
- Multiple found → ask which platform to target
- None found → ask the user which platform they use

### 2. Detect the Tech Stack

Use the same detection logic as `/scaffold`:
- `package.json` → Node.js
- `go.mod` → Go
- `pom.xml` / `build.gradle` → Java
- `pyproject.toml` → Python
- `Cargo.toml` → Rust

Load the platform-specific reference from `references/<platform>.md` for idiomatic pipeline patterns.

### 3. Confirm Before Generating

Show the user the planned pipeline stages before writing any files:

```
I'll create a [Platform] pipeline for [Stack] with these stages:

1. Build — [build command]
2. Test — [test command, parallelized if applicable]
3. Security scan — [SAST tool]
4. Package — [artifact type: Docker image / JAR / binary]
5. Deploy to staging — [triggered on: main branch merge]
6. Deploy to production — [triggered on: manual approval]

File to create: [pipeline file path]

Shall I generate this pipeline?
```

### 4. Generate the Pipeline File

Load the platform reference and generate a complete pipeline file with:
- **Build stage**: language-specific compile/install commands
- **Test stage**: run unit tests + integration tests (parallel where the platform supports it)
- **Security scan stage**: SAST placeholder (e.g., `trivy`, `semgrep`, or `snyk`) — easily removable
- **Artifact stage**: Docker build+push or language-specific packaging
- **Deploy stages**: environment-gated (staging auto-deploys on main, production requires approval)

**Secrets handling rules:**
- Never hardcode credentials in pipeline files
- Use OIDC-based cloud authentication where possible (no long-lived secrets)
- Reference secrets via the platform's native secrets mechanism (GitHub Secrets, GitLab CI Variables, Jenkins Credentials, Azure DevOps variable groups)

### 5. Post-Generation Instructions

After writing the file, output:
```
Pipeline created at: [file path]

Setup steps:
1. [How to configure secrets in the platform's UI]
2. [How to enable OIDC if applicable]
3. [First run: push to main to trigger]

To extend this pipeline: run /cicd again with a specific stage to add (e.g., /cicd add-performance-test)
```

## Key Rules

- Generate complete, working YAML/Groovy — not pseudocode, not placeholder blocks
- Every stage must have real commands derived from the detected tech stack
- Production deployment stages must always have an approval gate or manual trigger
- Never put environment-specific configuration in the pipeline file — use the platform's variable/secret system
- For Docker builds: always use multi-stage builds and pin base image digests (not floating tags)
- Load `references/<platform>.md` to ensure idiomatic syntax for the chosen platform
