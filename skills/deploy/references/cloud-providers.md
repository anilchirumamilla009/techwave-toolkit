# Cloud Providers Reference

## App Type → Service Mapping

Use this table to select the right managed service for each deployment target.

| App Type | AWS | Azure | GCP | Notes |
|---|---|---|---|---|
| **Container (always-on)** | ECS Fargate | Container Apps | Cloud Run | Serverless containers, no cluster management |
| **Container (high scale/control)** | EKS | AKS | GKE | Managed Kubernetes — more ops overhead |
| **API / Microservice (low traffic)** | Lambda + API GW | Azure Functions | Cloud Functions | Pay-per-request, cold starts at low traffic |
| **API / Microservice (steady traffic)** | ECS Fargate | Container Apps | Cloud Run | Better for consistent traffic |
| **Static frontend** | S3 + CloudFront | Static Web Apps | Cloud Storage + Cloud CDN | Zero servers, global CDN |
| **Full-stack (SSR)** | ECS + ALB | App Service | Cloud Run | Server-side rendering needs a running process |
| **PostgreSQL** | RDS PostgreSQL | Azure Database for PostgreSQL | Cloud SQL (PostgreSQL) | Fully managed, automated backups |
| **MySQL** | RDS MySQL | Azure Database for MySQL | Cloud SQL (MySQL) | |
| **Redis** | ElastiCache Redis | Azure Cache for Redis | Memorystore Redis | |
| **Object storage** | S3 | Blob Storage | Cloud Storage | |
| **Container registry** | ECR | ACR | Artifact Registry | |
| **Secrets** | Secrets Manager | Key Vault | Secret Manager | |
| **Message queue** | SQS | Service Bus Queue | Cloud Pub/Sub (pull) | Point-to-point |
| **Pub/sub events** | SNS + SQS | Service Bus Topic | Cloud Pub/Sub | Fan-out to multiple consumers |
| **DNS + CDN** | Route 53 + CloudFront | Front Door | Cloud DNS + Cloud CDN | |

---

## AWS — Terraform Resource Names

| Service | Terraform Resource |
|---|---|
| ECS Cluster | `aws_ecs_cluster` |
| ECS Task Definition | `aws_ecs_task_definition` |
| ECS Service (Fargate) | `aws_ecs_service` |
| Application Load Balancer | `aws_lb` + `aws_lb_listener` + `aws_lb_target_group` |
| Lambda Function | `aws_lambda_function` |
| API Gateway v2 (HTTP) | `aws_apigatewayv2_api` |
| RDS PostgreSQL | `aws_db_instance` (engine = "postgres") |
| ElastiCache Redis | `aws_elasticache_replication_group` |
| S3 Bucket | `aws_s3_bucket` |
| ECR Repository | `aws_ecr_repository` |
| Secrets Manager | `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` |
| SQS Queue | `aws_sqs_queue` |
| VPC | `aws_vpc` |
| Subnet | `aws_subnet` |
| Security Group | `aws_security_group` |
| IAM Role | `aws_iam_role` |
| CloudFront | `aws_cloudfront_distribution` |
| Route 53 | `aws_route53_record` |

### AWS ECS Fargate Quick Pattern

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
    portMappings = [{ containerPort = 3000, protocol = "tcp" }]
    environment = [{ name = "NODE_ENV", value = "production" }]
    secrets = [{
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.db_url.arn
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"  = "/ecs/${var.project_name}"
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.replica_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 3000
  }
}
```

---

## Azure — Terraform Resource Names

| Service | Terraform Resource |
|---|---|
| Container Apps Environment | `azurerm_container_app_environment` |
| Container App | `azurerm_container_app` |
| AKS Cluster | `azurerm_kubernetes_cluster` |
| App Service | `azurerm_linux_web_app` |
| Azure Functions | `azurerm_linux_function_app` |
| PostgreSQL Flexible Server | `azurerm_postgresql_flexible_server` |
| Redis Cache | `azurerm_redis_cache` |
| Storage Account (Blob) | `azurerm_storage_account` |
| Container Registry | `azurerm_container_registry` |
| Key Vault | `azurerm_key_vault` + `azurerm_key_vault_secret` |
| Service Bus | `azurerm_servicebus_namespace` |
| Application Gateway | `azurerm_application_gateway` |
| Front Door | `azurerm_cdn_frontdoor_profile` |

---

## GCP — Terraform Resource Names

| Service | Terraform Resource |
|---|---|
| Cloud Run Service | `google_cloud_run_v2_service` |
| GKE Cluster | `google_container_cluster` |
| Cloud SQL (PostgreSQL) | `google_sql_database_instance` |
| Memorystore Redis | `google_redis_instance` |
| Cloud Storage | `google_storage_bucket` |
| Artifact Registry | `google_artifact_registry_repository` |
| Secret Manager | `google_secret_manager_secret` + `google_secret_manager_secret_version` |
| Pub/Sub | `google_pubsub_topic` + `google_pubsub_subscription` |
| Cloud CDN + Load Balancer | `google_compute_global_forwarding_rule` + `google_compute_backend_bucket` |

### GCP Cloud Run Quick Pattern

```hcl
resource "google_cloud_run_v2_service" "app" {
  name     = var.service_name
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo}/${var.service_name}:${var.image_tag}"
      ports { container_port = 8080 }
      resources {
        limits = { cpu = "1", memory = "512Mi" }
      }
      env {
        name  = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_url.secret_id
            version = "latest"
          }
        }
      }
    }
    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  location = google_cloud_run_v2_service.app.location
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"  # Remove for private services
}
```

---

## Decision Guide: Pick the Right Service

| Situation | Recommendation |
|---|---|
| Small team, want to ship fast | Cloud Run (GCP) or Container Apps (Azure) — managed, scales to zero |
| Already on AWS, steady traffic | ECS Fargate — simpler than EKS, no Kubernetes overhead |
| Need Kubernetes features (custom schedulers, sidecars, CRDs) | EKS / GKE / AKS |
| Sporadic traffic, event-driven | Lambda / Cloud Functions / Azure Functions |
| Static site with API | S3+CloudFront (AWS) or Static Web Apps (Azure) + separate API service |
| Multi-region active-active | Requires significant architecture work — raise as an ADR before committing |
