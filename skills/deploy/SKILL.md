---
name: deploy
description: This skill should be used when the user asks to "deploy this app", "create Docker Compose", "generate Helm chart", "write Terraform", "Kubernetes manifests", "deploy to AWS", "deploy to GCP", "deploy to Azure", "infrastructure as code", "IaC for this service", "create a deployment config", "containerize this app", "write a docker-compose file", "set up Kubernetes", or needs any deployment or infrastructure configuration. This skill generates complete deployment artifacts for any target environment.
version: 0.1.0
disable-model-invocation: true
---

# Deployment Skill

## Overview

This skill generates complete deployment and infrastructure-as-code artifacts: Docker Compose, Helm charts, Terraform modules, and cloud-specific configurations. All generated artifacts are multi-environment (dev/staging/prod) and never hardcode secrets.

## When to Use

Invoke when the user wants to deploy a service or create infrastructure configuration. This skill generates real, complete files — not partial templates or pseudocode.

## Arguments Routing

| `$ARGUMENTS` value(s) | Target | Reference file |
|---|---|---|
| `compose`, `docker`, `docker-compose` | Docker Compose | `references/docker-compose.md` |
| `helm`, `k8s`, `kubernetes` | Helm + Kubernetes | `references/kubernetes-helm.md` |
| `terraform`, `tf`, `iac` | Terraform | `references/terraform.md` |
| `aws`, `azure`, `gcp`, `cloud` | Cloud-specific | `references/cloud-providers.md` → then ask which service |
| *(empty)* | Ask the user to choose a deployment target |

## Step-by-Step Process

### 1. Determine Deployment Target

Apply the routing table above. If `$ARGUMENTS` is empty, ask:

```
What deployment target do you need?
1. Docker Compose (local dev, single-host)
2. Helm / Kubernetes (container orchestration)
3. Terraform (infrastructure as code, any cloud)
4. Cloud-specific (AWS / Azure / GCP — I'll help pick the right services)
```

### 2. Detect the Application

Read existing files to understand the application:
- `Dockerfile` present → containerized, use as-is
- No `Dockerfile` → generate one using the `/scaffold` reference for the detected stack
- `docker-compose.yml` present → extend it rather than overwrite
- Port exposures: read from source code or existing config

### 3. Confirm Before Generating

Show planned files and ask the user to confirm:

```
I'll create the following deployment artifacts:

[list of files with one-line description each]

Environments covered: dev / staging / production
Secrets handling: [mechanism — e.g., .env files for Compose, External Secrets Operator for K8s]

Shall I generate these files?
```

### 4. Generate the Deployment Files

Load the appropriate reference file and generate complete artifacts. Multi-environment rules:
- **Docker Compose**: `docker-compose.yml` (base) + `docker-compose.override.yml` (dev overrides)
- **Helm**: `values.yaml` (base) + `values-staging.yaml` + `values-prod.yaml`
- **Terraform**: `main.tf` + `variables.tf` + `outputs.tf` + `terraform.tfvars.example` (never commit actual tfvars)

**Secrets handling rules (non-negotiable):**
- Docker Compose: secrets via `.env` file (provide `.env.example` and add `.env` to `.gitignore`)
- Kubernetes/Helm: use External Secrets Operator pattern (reference `kubernetes-helm.md`) — never put secret values in values files
- Terraform: use `sensitive = true` on all secret variables, reference from cloud secrets manager

### 5. Post-Generation Summary

```
Deployment artifacts created:
[list of files]

To deploy:
[environment-specific deploy commands]

Security checklist:
- [ ] Copy .env.example to .env and fill in real values (never commit .env)
- [ ] Verify secrets are loaded from your secrets manager, not the config files
- [ ] Run /compliance before deploying to production if handling regulated data
```

## Key Rules

- Never hardcode secrets, passwords, or API keys in any generated file
- Always generate multi-environment configurations (dev/staging/prod) — single-env configs create drift
- For Kubernetes: always include `resources.requests` and `resources.limits` — unbounded containers get evicted
- For Terraform: always include remote state configuration — never local state for shared infrastructure
- For cloud deployments: load `references/cloud-providers.md` to select the right managed services (not always EC2/VMs)
- Generated Docker images must use multi-stage builds for production — development dependencies must not be in the final image
