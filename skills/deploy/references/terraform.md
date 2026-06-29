# Terraform Reference

## Module Directory Structure

```
infrastructure/
├── main.tf              # Root module: calls child modules
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output value declarations
├── providers.tf         # Provider configuration
├── backend.tf           # Remote state configuration
├── terraform.tfvars.example  # Example values (commit this)
├── terraform.tfvars     # Actual values (NEVER commit this)
└── modules/
    ├── networking/      # VPC, subnets, security groups
    ├── compute/         # ECS/EC2/Lambda
    ├── database/        # RDS, ElastiCache
    └── storage/         # S3, ECR
```

## `backend.tf` (Remote State — Required)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "my-service/production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Create the S3 bucket and DynamoDB table once before initializing:
```bash
aws s3 mb s3://my-company-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket my-company-terraform-state --versioning-configuration Status=Enabled
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## `providers.tf`

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

## `variables.tf`

```hcl
variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Deployment environment (staging, production)"
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_password" {
  type        = string
  description = "RDS master password"
  sensitive   = true   # Never shown in plan output or state display
}

variable "app_image_tag" {
  type        = string
  description = "Docker image tag to deploy"
}
```

## `terraform.tfvars.example`

```hcl
# Copy to terraform.tfvars and fill in real values
# NEVER commit terraform.tfvars to version control

project_name  = "my-service"
environment   = "staging"
aws_region    = "us-east-1"
app_image_tag = "abc1234"

# Secrets: use AWS Secrets Manager or SSM Parameter Store instead of this file
# db_password = "CHANGE_ME"
```

## `main.tf` (Typical ECS Deployment)

```hcl
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

module "database" {
  source      = "./modules/database"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  db_password = var.db_password
  environment = var.environment
}

module "compute" {
  source        = "./modules/compute"
  vpc_id        = module.networking.vpc_id
  subnet_ids    = module.networking.private_subnet_ids
  db_url        = module.database.connection_url
  image_tag     = var.app_image_tag
  environment   = var.environment
}
```

## Workspace-Based Environment Strategy

Use Terraform workspaces to separate state per environment:

```bash
# One-time setup
terraform workspace new staging
terraform workspace new production

# Deploy to staging
terraform workspace select staging
terraform plan -var-file=env/staging.tfvars
terraform apply -var-file=env/staging.tfvars

# Deploy to production
terraform workspace select production
terraform plan -var-file=env/production.tfvars
terraform apply -var-file=env/production.tfvars
```

Reference the workspace name in resources:
```hcl
resource "aws_ecs_service" "app" {
  name    = "${var.project_name}-${terraform.workspace}"
  # ...
}
```

## `outputs.tf`

```hcl
output "load_balancer_url" {
  value       = module.compute.load_balancer_dns
  description = "URL of the application load balancer"
}

output "database_endpoint" {
  value     = module.database.endpoint
  sensitive = true
}
```

## CI/CD Integration

```bash
# In CI pipeline (never run apply manually in production)
terraform init
terraform workspace select ${ENVIRONMENT}
terraform plan \
  -var="app_image_tag=${IMAGE_TAG}" \
  -var="db_password=${DB_PASSWORD}" \
  -var-file="env/${ENVIRONMENT}.tfvars" \
  -out=tfplan

# After plan review / approval:
terraform apply tfplan
```

## Key Rules

- **Never commit `terraform.tfvars`** — add to `.gitignore`
- **Mark all secrets with `sensitive = true`** — prevents values from appearing in `terraform plan` output
- **Pin provider versions with `~>`** — allows patch updates but prevents breaking major version changes
- **Always use remote state** — local state cannot be shared across CI runs or team members
- **Use `terraform plan -out=tfplan`** then `terraform apply tfplan` — ensures what was reviewed is exactly what gets applied
- **Never store actual secret values in `.tfvars` files** — use `TF_VAR_` environment variables or fetch from AWS Secrets Manager via `data "aws_secretsmanager_secret_version"`
