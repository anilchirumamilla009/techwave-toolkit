# GitHub Actions Reference

## Complete Workflow: Build, Test, Scan, Deploy

Save as `.github/workflows/ci.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write   # Required for OIDC authentication to AWS/GCP

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # ─────────────────────────────────────────
  # 1. Test (runs on every PR and push)
  # ─────────────────────────────────────────
  test:
    name: Build & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Node.js variant
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v4

      # Python variant (replace Node.js steps above with these)
      # - uses: actions/setup-python@v5
      #   with: { python-version: '3.12' }
      # - run: pip install poetry && poetry install
      # - run: poetry run pytest --cov

      # Go variant
      # - uses: actions/setup-go@v5
      #   with: { go-version: '1.22' }
      # - run: go test ./... -race -coverprofile=coverage.out

  # ─────────────────────────────────────────
  # 2. Security Scan
  # ─────────────────────────────────────────
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      # Dependency vulnerability scan
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

  # ─────────────────────────────────────────
  # 3. Build & Push Docker Image (main branch only)
  # ─────────────────────────────────────────
  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/main'
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,suffix=,format=short
            type=ref,event=branch

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ─────────────────────────────────────────
  # 4. Deploy to Staging (auto, main branch)
  # ─────────────────────────────────────────
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/checkout@v4

      # OIDC-based AWS authentication (no long-lived secrets)
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-deploy
          aws-region: us-east-1

      # Example: ECS deployment
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster my-cluster-staging \
            --service my-service \
            --force-new-deployment \
            --region us-east-1

  # ─────────────────────────────────────────
  # 5. Deploy to Production (manual approval)
  # ─────────────────────────────────────────
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production
      url: https://example.com
    # GitHub Environments with required reviewers provides the approval gate
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-deploy-prod
          aws-region: us-east-1

      - name: Deploy to ECS Production
        run: |
          aws ecs update-service \
            --cluster my-cluster-prod \
            --service my-service \
            --force-new-deployment \
            --region us-east-1
```

## Secrets to Configure

In GitHub → Settings → Secrets and Variables → Actions:

| Secret | Value |
|---|---|
| `AWS_ACCOUNT_ID` | Your AWS account number |
| (No long-lived AWS credentials needed — OIDC handles auth) |

## OIDC Setup in AWS

```bash
# Create OIDC provider (one-time setup)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list <thumbprint>

# Create IAM role with trust policy for your repo
# Trust policy: github.com/yourorg/yourrepo on main branch only
```

## Key Patterns

- **Cache**: `cache-from: type=gha` re-uses Docker layer cache between runs — cuts build time by 50–80%
- **OIDC auth**: `id-token: write` permission + `configure-aws-credentials` with `role-to-assume` — no stored AWS keys
- **Environment gates**: GitHub Environments with `required_reviewers` enforce human approval for production
- **Digest pinning**: use `${{ steps.build.outputs.digest }}` (sha256 hash) instead of floating tags for production deployments
