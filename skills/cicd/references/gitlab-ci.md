# GitLab CI Reference

## Complete `.gitlab-ci.yml`

```yaml
image: docker:24

stages:
  - test
  - security
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  STAGING_URL: https://staging.example.com
  PRODUCTION_URL: https://example.com

# ─────────────────────────────────────────
# 1. Test
# ─────────────────────────────────────────
test:
  stage: test
  image: node:20-alpine
  cache:
    paths:
      - node_modules/
  script:
    - npm ci
    - npm test -- --coverage --coverageReporters=cobertura
  coverage: '/Statements\s+:\s+(\d+\.?\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Python variant:
# test:
#   stage: test
#   image: python:3.12-slim
#   script:
#     - pip install poetry && poetry install
#     - poetry run pytest --cov --cov-report=term-missing

# ─────────────────────────────────────────
# 2. Security Scan
# ─────────────────────────────────────────
dependency_scanning:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy fs --exit-code 1 --severity HIGH,CRITICAL .
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

sast:
  stage: security
  # GitLab built-in SAST (requires Ultimate or Gold tier)
  # For free tier, use Semgrep:
  image: returntocorp/semgrep:latest
  script:
    - semgrep --config=auto --error .
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# ─────────────────────────────────────────
# 3. Build Docker Image
# ─────────────────────────────────────────
build:
  stage: build
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build --cache-from $CI_REGISTRY_IMAGE:latest -t $IMAGE_TAG -t $CI_REGISTRY_IMAGE:latest .
    - docker push $IMAGE_TAG
    - docker push $CI_REGISTRY_IMAGE:latest
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# ─────────────────────────────────────────
# 4. Deploy to Staging (auto, main branch)
# ─────────────────────────────────────────
deploy-staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  environment:
    name: staging
    url: $STAGING_URL
  before_script:
    - kubectl config set-cluster staging --server=$KUBE_STAGING_URL
    - kubectl config set-credentials gitlab --token=$KUBE_STAGING_TOKEN
    - kubectl config set-context default --cluster=staging --user=gitlab
    - kubectl config use-context default
  script:
    - kubectl set image deployment/my-service my-service=$IMAGE_TAG -n staging
    - kubectl rollout status deployment/my-service -n staging --timeout=5m
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# ─────────────────────────────────────────
# 5. Deploy to Production (manual approval)
# ─────────────────────────────────────────
deploy-production:
  stage: deploy-production
  image: bitnami/kubectl:latest
  environment:
    name: production
    url: $PRODUCTION_URL
  when: manual     # Requires clicking "play" in the GitLab UI
  allow_failure: false
  before_script:
    - kubectl config set-cluster production --server=$KUBE_PROD_URL
    - kubectl config set-credentials gitlab --token=$KUBE_PROD_TOKEN
    - kubectl config set-context default --cluster=production --user=gitlab
    - kubectl config use-context default
  script:
    - kubectl set image deployment/my-service my-service=$IMAGE_TAG -n production
    - kubectl rollout status deployment/my-service -n production --timeout=10m
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## GitLab CI Variables to Configure

In GitLab → Settings → CI/CD → Variables:

| Variable | Description | Protected | Masked |
|---|---|---|---|
| `KUBE_STAGING_URL` | Kubernetes API endpoint for staging | Yes | No |
| `KUBE_STAGING_TOKEN` | Service account token for staging | Yes | Yes |
| `KUBE_PROD_URL` | Kubernetes API endpoint for production | Yes | No |
| `KUBE_PROD_TOKEN` | Service account token for production | Yes | Yes |

Note: GitLab provides `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD`, and `CI_REGISTRY` automatically for the GitLab Container Registry.

## Key Patterns

- `when: manual` — requires a human to click "play" in the pipeline UI for production deployments
- `cache: paths:` — caches `node_modules/` between runs on the same runner
- `CI_COMMIT_SHORT_SHA` — built-in variable, provides a unique 8-character commit reference for image tags
- `environment: name: production` — links to GitLab Environments for deployment history and URL tracking
