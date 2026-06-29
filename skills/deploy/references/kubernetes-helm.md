# Kubernetes + Helm Reference

## Chart Directory Structure

```
my-service/
├── Chart.yaml
├── values.yaml              # Base values (all environments inherit)
├── values-staging.yaml      # Staging overrides
├── values-prod.yaml         # Production overrides
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml             # Horizontal Pod Autoscaler
    ├── configmap.yaml
    ├── externalsecret.yaml  # External Secrets Operator pattern
    └── _helpers.tpl
```

## `Chart.yaml`

```yaml
apiVersion: v2
name: my-service
description: My Service Helm chart
type: application
version: 0.1.0
appVersion: "0.1.0"
```

## `values.yaml` (base)

```yaml
replicaCount: 1

image:
  repository: myregistry.azurecr.io/my-service
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  host: my-service.example.com
  tls:
    enabled: true

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

env:
  - name: NODE_ENV
    value: production
  - name: PORT
    value: "3000"

externalSecrets:
  enabled: true
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  refreshInterval: 1h
  secrets:
    - name: DATABASE_URL
      remoteKey: my-service/production/database-url
    - name: API_KEY
      remoteKey: my-service/production/api-key

livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## `values-staging.yaml`

```yaml
replicaCount: 1

image:
  tag: "latest"

ingress:
  host: staging.my-service.example.com

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 250m
    memory: 256Mi

externalSecrets:
  secrets:
    - name: DATABASE_URL
      remoteKey: my-service/staging/database-url
    - name: API_KEY
      remoteKey: my-service/staging/api-key
```

## `values-prod.yaml`

```yaml
replicaCount: 3

image:
  tag: ""   # Always set explicitly on deploy — never use :latest in production

ingress:
  host: my-service.example.com

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 60

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

## `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-service.fullname" . }}
  labels:
    {{- include "my-service.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-service.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-service.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          env:
            {{- toYaml .Values.env | nindent 12 }}
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "my-service.fullname" . }}-secrets
                  key: DATABASE_URL
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

## `templates/externalsecret.yaml` (External Secrets Operator)

```yaml
{{- if .Values.externalSecrets.enabled }}
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "my-service.fullname" . }}-secrets
spec:
  refreshInterval: {{ .Values.externalSecrets.refreshInterval }}
  secretStoreRef:
    name: {{ .Values.externalSecrets.secretStoreRef.name }}
    kind: {{ .Values.externalSecrets.secretStoreRef.kind }}
  target:
    name: {{ include "my-service.fullname" . }}-secrets
    creationPolicy: Owner
  data:
    {{- range .Values.externalSecrets.secrets }}
    - secretKey: {{ .name }}
      remoteRef:
        key: {{ .remoteKey }}
    {{- end }}
{{- end }}
```

## Deploy Commands

```bash
# Install/upgrade staging
helm upgrade --install my-service ./my-service \
  -f values.yaml -f values-staging.yaml \
  --namespace staging --create-namespace \
  --set image.tag=abc1234

# Install/upgrade production
helm upgrade --install my-service ./my-service \
  -f values.yaml -f values-prod.yaml \
  --namespace production --create-namespace \
  --set image.tag=abc1234 \
  --atomic --timeout 10m   # --atomic rolls back automatically on failure

# Rollback
helm rollback my-service 1 --namespace production

# View history
helm history my-service --namespace production
```

## Key Patterns

- **Never use `latest` tag in production** — always set `image.tag` explicitly on deploy for deterministic rollbacks
- **ExternalSecrets Operator** — pulls secrets from AWS Secrets Manager / Vault at deploy time; no secret values in Helm values files ever
- **`--atomic`** — if any pod fails to become Ready within the timeout, Helm automatically rolls back to the previous release
- **Separate values files per environment** — staging and prod have different resource limits and replica counts
- **HPA for production** — autoscaling enabled only in prod values to avoid complexity in staging
