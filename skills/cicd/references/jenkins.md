# Jenkins Declarative Pipeline Reference

## Complete `Jenkinsfile`

```groovy
pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        REGISTRY = 'your-registry.example.com'
        IMAGE_NAME = 'my-service'
        IMAGE_TAG = "${env.GIT_COMMIT[0..7]}"
        STAGING_ENV = 'staging'
        PROD_ENV = 'production'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        // ─────────────────────────────────────────
        // 1. Install Dependencies
        // ─────────────────────────────────────────
        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }

        // ─────────────────────────────────────────
        // 2. Parallel: Test + Lint + Security
        // ─────────────────────────────────────────
        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        sh 'npm test -- --coverage'
                    }
                    post {
                        always {
                            junit 'coverage/junit.xml'
                            publishHTML(target: [
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
                stage('Security Scan') {
                    agent { docker { image 'aquasec/trivy:latest' } }
                    steps {
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
                    }
                }
            }
        }

        // ─────────────────────────────────────────
        // 3. Build Docker Image
        // ─────────────────────────────────────────
        stage('Build') {
            when {
                branch 'main'
            }
            agent { label 'docker' }
            steps {
                script {
                    def image = docker.build("${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                    docker.withRegistry("https://${REGISTRY}", 'registry-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        // ─────────────────────────────────────────
        // 4. Deploy to Staging
        // ─────────────────────────────────────────
        stage('Deploy Staging') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    string(credentialsId: 'kube-staging-token', variable: 'KUBE_TOKEN'),
                    string(credentialsId: 'kube-staging-url', variable: 'KUBE_URL')
                ]) {
                    sh """
                        kubectl --server=${KUBE_URL} --token=${KUBE_TOKEN} \\
                            set image deployment/my-service \\
                            my-service=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \\
                            -n staging
                        kubectl --server=${KUBE_URL} --token=${KUBE_TOKEN} \\
                            rollout status deployment/my-service -n staging --timeout=5m
                    """
                }
            }
        }

        // ─────────────────────────────────────────
        // 5. Deploy to Production (requires approval)
        // ─────────────────────────────────────────
        stage('Approve Production') {
            when {
                branch 'main'
            }
            steps {
                input message: "Deploy ${IMAGE_TAG} to production?",
                      ok: 'Deploy',
                      submitter: 'team-lead,release-manager'
            }
        }

        stage('Deploy Production') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    string(credentialsId: 'kube-prod-token', variable: 'KUBE_TOKEN'),
                    string(credentialsId: 'kube-prod-url', variable: 'KUBE_URL')
                ]) {
                    sh """
                        kubectl --server=${KUBE_URL} --token=${KUBE_TOKEN} \\
                            set image deployment/my-service \\
                            my-service=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \\
                            -n production
                        kubectl --server=${KUBE_URL} --token=${KUBE_TOKEN} \\
                            rollout status deployment/my-service -n production --timeout=10m
                    """
                }
            }
        }
    }

    post {
        failure {
            // Notify Slack or email on failure
            echo "Build failed for ${env.GIT_COMMIT[0..7]}"
        }
        success {
            echo "Build succeeded: ${env.IMAGE_TAG}"
        }
        always {
            cleanWs()
        }
    }
}
```

## Jenkins Credentials to Configure

In Jenkins → Manage Jenkins → Credentials:

| ID | Type | Value |
|---|---|---|
| `registry-credentials` | Username with password | Registry user/password |
| `kube-staging-token` | Secret text | Kubernetes service account token |
| `kube-staging-url` | Secret text | Kubernetes API server URL |
| `kube-prod-token` | Secret text | Kubernetes service account token |
| `kube-prod-url` | Secret text | Kubernetes API server URL |

## Key Patterns

- `parallel { }` — runs test, lint, and security scan concurrently, cutting stage time by up to 3x
- `input message:` — blocks the pipeline until a named approver clicks "Deploy" in the Jenkins UI
- `withCredentials([])` — injects secrets as environment variables for the duration of the block only
- `cleanWs()` — cleans workspace after every build to prevent artifact leakage
- `disableConcurrentBuilds()` — prevents two builds from deploying simultaneously to the same environment
