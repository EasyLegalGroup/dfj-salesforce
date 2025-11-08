# Terraform Infrastructure as Code - Placeholder

## 🏗️ Terraform Configuration for Customer Portal

This directory will contain Terraform configurations to provision all AWS resources for the Customer Portal.

### Files to Create:

#### 1. `main.tf` - Main Terraform Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "dfj-terraform-state"
    key            = "customer-portal/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Customer Portal"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Lambda Functions
module "lambda_functions" {
  source = "./modules/lambda"
  
  environment = var.environment
  vpc_config  = var.vpc_config
}

# API Gateway
module "api_gateway" {
  source = "./modules/api-gateway"
  
  environment      = var.environment
  lambda_functions = module.lambda_functions.function_arns
}

# S3 Bucket for Frontend
module "frontend_bucket" {
  source = "./modules/s3-frontend"
  
  environment   = var.environment
  domain_name   = var.frontend_domain
}

# CloudFront Distribution
module "cloudfront" {
  source = "./modules/cloudfront"
  
  environment       = var.environment
  s3_bucket_id      = module.frontend_bucket.bucket_id
  domain_name       = var.frontend_domain
  certificate_arn   = var.certificate_arn
}
```

#### 2. `variables.tf` - Input Variables

```hcl
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "frontend_domain" {
  description = "Domain name for the frontend"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for CloudFront"
  type        = string
}

variable "salesforce_instance_url" {
  description = "Salesforce instance URL"
  type        = string
  default     = "https://login.salesforce.com"
}

variable "vpc_config" {
  description = "VPC configuration for Lambda functions"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}
```

#### 3. `outputs.tf` - Output Values

```hcl
output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.invoke_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.frontend_bucket.bucket_name
}

output "lambda_function_arns" {
  description = "ARNs of Lambda functions"
  value       = module.lambda_functions.function_arns
  sensitive   = true
}
```

#### 4. `terraform.tfvars` (for each environment)

**terraform.dev.tfvars:**
```hcl
environment              = "dev"
frontend_domain          = "dev-portal.dinfamiliejurist.dk"
certificate_arn          = "arn:aws:acm:us-east-1:ACCOUNT:certificate/..."
salesforce_instance_url  = "https://test.salesforce.com"
```

**terraform.prod.tfvars:**
```hcl
environment              = "prod"
frontend_domain          = "portal.dinfamiliejurist.dk"
certificate_arn          = "arn:aws:acm:us-east-1:ACCOUNT:certificate/..."
salesforce_instance_url  = "https://login.salesforce.com"
```

### Module Structure:

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.dev.tfvars
├── terraform.prod.tfvars
└── modules/
    ├── lambda/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── api-gateway/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3-frontend/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── cloudfront/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Usage:

```bash
# Initialize Terraform
terraform init

# Select workspace (environment)
terraform workspace new dev
terraform workspace select dev

# Plan changes
terraform plan -var-file="terraform.dev.tfvars"

# Apply changes
terraform apply -var-file="terraform.dev.tfvars"

# Destroy resources
terraform destroy -var-file="terraform.dev.tfvars"
```

### State Management:

Terraform state is stored in S3 with DynamoDB for locking:

```bash
# Create state bucket (one-time setup)
aws s3 mb s3://dfj-terraform-state --region eu-west-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

### TODO:
- [ ] Create main.tf with all resources
- [ ] Define variables for all environments
- [ ] Create modules for Lambda, API Gateway, S3, CloudFront
- [ ] Set up state backend
- [ ] Add IAM roles and policies
- [ ] Configure CloudWatch Logs
- [ ] Add Secrets Manager for Salesforce credentials
- [ ] Create deployment scripts
- [ ] Add cost estimation
