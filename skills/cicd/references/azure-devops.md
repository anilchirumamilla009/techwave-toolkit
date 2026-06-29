# Azure DevOps Pipeline Reference

## Complete `azure-pipelines.yml`

```yaml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - '*.md'

pr:
  branches:
    include:
      - main

pool:
  vmImage: ubuntu-latest

variables:
  - group: my-service-secrets          # Variable group for secrets (see setup below)
  - name: IMAGE_NAME
    value: my-service
  - name: CONTAINER_REGISTRY
    value: myregistry.azurecr.io
  - name: IMAGE_TAG
    value: $(Build.SourceVersion)

stages:
# ─────────────────────────────────────────
# 1. Build & Test
# ─────────────────────────────────────────
- stage: BuildTest
  displayName: Build and Test
  jobs:
  - job: Test
    displayName: Install, Test, Lint
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '20.x'

    - script: npm ci
      displayName: Install dependencies

    - script: npm test -- --coverage --reporters=jest-junit
      displayName: Run tests
      env:
        CI: true

    - task: PublishTestResults@2
      inputs:
        testResultsFormat: JUnit
        testResultsFiles: 'test-results.xml'
      condition: always()

    - task: PublishCodeCoverageResults@2
      inputs:
        summaryFileLocation: coverage/cobertura-coverage.xml
        pathToSources: src/
      condition: always()

  - job: SecurityScan
    displayName: Security Scan
    steps:
    - script: |
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        trivy fs --exit-code 1 --severity HIGH,CRITICAL .
      displayName: Trivy vulnerability scan

# ─────────────────────────────────────────
# 2. Build Docker Image (main branch only)
# ─────────────────────────────────────────
- stage: BuildImage
  displayName: Build Docker Image
  dependsOn: BuildTest
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - job: BuildPush
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(IMAGE_NAME)
        dockerfile: Dockerfile
        containerRegistry: my-acr-service-connection   # Service connection to ACR
        tags: |
          $(Build.SourceVersion)
          latest

# ─────────────────────────────────────────
# 3. Deploy to Staging (auto)
# ─────────────────────────────────────────
- stage: DeployStaging
  displayName: Deploy to Staging
  dependsOn: BuildImage
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployStaging
    environment: staging        # Azure DevOps Environment with approval checks
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@1
            displayName: Deploy to staging AKS
            inputs:
              action: deploy
              kubernetesServiceConnection: aks-staging-service-connection
              namespace: staging
              manifests: k8s/deployment.yaml
              containers: $(CONTAINER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# ─────────────────────────────────────────
# 4. Deploy to Production (requires approval)
# ─────────────────────────────────────────
- stage: DeployProduction
  displayName: Deploy to Production
  dependsOn: DeployStaging
  condition: succeeded()
  jobs:
  - deployment: DeployProduction
    environment: production     # Azure DevOps Environment — configure approvers here
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@1
            displayName: Deploy to production AKS
            inputs:
              action: deploy
              kubernetesServiceConnection: aks-production-service-connection
              namespace: production
              manifests: k8s/deployment.yaml
              containers: $(CONTAINER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
```

## Setup Steps

### 1. Create Variable Group
Pipelines → Library → Variable Groups → New group named `my-service-secrets`

Add variables (mark sensitive ones as "secret"):
| Variable | Value | Secret |
|---|---|---|
| `DATABASE_URL` | connection string | Yes |
| `API_KEY` | your key | Yes |

### 2. Create Service Connections
Project Settings → Service connections:
- **Azure Container Registry**: Connect to your ACR (name: `my-acr-service-connection`)
- **Kubernetes**: Connect to each AKS cluster (staging + production)

### 3. Configure Approval Gates
Pipelines → Environments → `production` → Approvals and checks:
- Add approval check: select required approvers (team lead, release manager)
- Set timeout (e.g., 24 hours before pipeline expires)

## Key Patterns

- **Variable groups**: Secrets shared across pipelines without repeating them in YAML
- **Environments with approvals**: Azure DevOps Environments have built-in approval gates — clicking "Approve" in the UI unblocks the stage
- **Service connections**: Securely connect to Azure resources and Kubernetes without embedding credentials in YAML
- **`condition: and(succeeded(), eq(...))`**: Gates stages to main branch and prior stage success
