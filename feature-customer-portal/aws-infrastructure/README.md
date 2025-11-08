# AWS Infrastructure - Customer Portal

## 📋 Overview

This directory contains all AWS infrastructure components for the Customer Portal, including Lambda functions, API Gateway configurations, and Infrastructure as Code (IaC) templates.

## 🏗️ Components

### 1. Lambda Functions (`lambda-functions/`)

Lambda functions provide the serverless compute layer that bridges the SPA frontend and Salesforce backend.

**Recommended Functions:**

- **`salesforce-api-proxy/`**
  - Proxies requests from API Gateway to Salesforce REST/SOAP APIs
  - Handles OAuth authentication with Salesforce
  - Transforms data between API Gateway and Salesforce formats
  
- **`authentication-service/`**
  - Validates Journal Access Tokens
  - Manages session tokens for portal users
  - Integrates with Salesforce for token verification
  
- **`document-processor/`**
  - Handles document uploads/downloads
  - Processes document metadata
  - Integrates with Salesforce Files/ContentVersion

- **`chat-service/`**
  - Real-time chat message handling
  - WebSocket support for live updates
  - Integrates with SimplifiedChatService in Salesforce

### 2. API Gateway (`api-gateway/`)

API Gateway provides the HTTP/REST interface for the SPA.

**Expected Files:**

- **`openapi-spec.yaml`** - OpenAPI 3.0 specification for all endpoints
- **`routes.json`** - Route definitions and Lambda integrations
- **`cors-config.json`** - CORS configuration for SPA domain
- **`authorizers.json`** - Custom authorizer configurations

**Recommended Endpoints:**

```
GET    /api/v1/journals/{journalId}          # Get journal details
GET    /api/v1/journals/{journalId}/messages # Get chat messages
POST   /api/v1/journals/{journalId}/messages # Send chat message
GET    /api/v1/journals/{journalId}/documents # List documents
POST   /api/v1/journals/{journalId}/documents # Upload document
GET    /api/v1/documents/{documentId}        # Download document
POST   /api/v1/auth/validate-token           # Validate access token
```

### 3. Terraform (`terraform/`)

Infrastructure as Code using Terraform to provision all AWS resources.

**Expected Files:**

- **`main.tf`** - Main Terraform configuration
  - Lambda functions
  - API Gateway
  - IAM roles and policies
  - CloudWatch Logs
  - S3 buckets for frontend hosting
  - CloudFront distribution

- **`variables.tf`** - Input variables
  - `environment` (dev/staging/prod)
  - `region`
  - `salesforce_instance_url`
  - `frontend_domain`

- **`outputs.tf`** - Output values
  - API Gateway URL
  - CloudFront distribution URL
  - Lambda function ARNs

- **`backend.tf`** - Terraform state backend (S3 + DynamoDB)

**Usage:**
```bash
cd terraform
terraform init
terraform workspace select production  # or dev/staging
terraform plan
terraform apply
```

### 4. CloudFormation (`cloudformation/`)

Alternative to Terraform using AWS CloudFormation templates.

**Expected Files:**

- **`customer-portal-stack.yaml`** - Main CloudFormation stack
- **`parameters-dev.json`** - Dev environment parameters
- **`parameters-prod.json`** - Production environment parameters

**Usage:**
```bash
aws cloudformation create-stack \
  --stack-name customer-portal-prod \
  --template-body file://customer-portal-stack.yaml \
  --parameters file://parameters-prod.json \
  --capabilities CAPABILITY_IAM
```

## 🔐 Security Best Practices

### IAM Roles & Policies

- **Lambda Execution Role**: Minimum permissions
  - CloudWatch Logs write access
  - Secrets Manager read access (for Salesforce credentials)
  - S3 read/write for document processing

- **API Gateway Execution Role**: 
  - Lambda invoke permissions only

### Secrets Management

Store Salesforce credentials in **AWS Secrets Manager**:

```json
{
  "salesforce_instance_url": "https://login.salesforce.com",
  "salesforce_client_id": "...",
  "salesforce_client_secret": "...",
  "salesforce_username": "integration@dinfamiliejurist.dk",
  "salesforce_password": "...",
  "salesforce_security_token": "..."
}
```

### API Gateway Security

- **API Keys**: For rate limiting and usage tracking
- **WAF Rules**: Protect against common attacks
- **Throttling**: Rate limit requests per client
- **CORS**: Restrict to portal domain only

### VPC Configuration (Optional)

For enhanced security, deploy Lambda functions in VPC:
- Private subnets
- NAT Gateway for Salesforce API access
- Security groups restricting inbound/outbound traffic

## 📊 Monitoring & Logging

### CloudWatch Logs

All Lambda functions should log to CloudWatch with structured logging:

```javascript
console.log(JSON.stringify({
  level: 'INFO',
  message: 'Processing chat message',
  journalId: 'xxx',
  timestamp: new Date().toISOString()
}));
```

### CloudWatch Metrics

Create custom metrics for:
- API request count by endpoint
- Lambda invocation count and duration
- Error rates
- Salesforce API call latency

### CloudWatch Alarms

Set up alarms for:
- Lambda error rate > 5%
- API Gateway 5xx error rate > 1%
- Lambda duration > 10 seconds
- Salesforce API rate limit approaching

### X-Ray Tracing

Enable AWS X-Ray for distributed tracing across Lambda and API Gateway.

## 🚀 Deployment Process

### 1. Prerequisites

```bash
# Install AWS CLI
aws --version

# Install Terraform
terraform --version

# Configure AWS credentials
aws configure
```

### 2. Deploy Infrastructure

**Using Terraform:**

```bash
cd terraform

# Initialize Terraform
terraform init

# Select workspace (environment)
terraform workspace select production

# Review planned changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

**Using CloudFormation:**

```bash
cd cloudformation

# Validate template
aws cloudformation validate-template \
  --template-body file://customer-portal-stack.yaml

# Deploy stack
aws cloudformation deploy \
  --stack-name customer-portal-prod \
  --template-file customer-portal-stack.yaml \
  --parameter-overrides file://parameters-prod.json \
  --capabilities CAPABILITY_IAM
```

### 3. Deploy Lambda Functions

```bash
cd lambda-functions/salesforce-api-proxy

# Install dependencies
npm install

# Package function
zip -r function.zip .

# Upload to Lambda
aws lambda update-function-code \
  --function-name customer-portal-salesforce-proxy \
  --zip-file fileb://function.zip
```

### 4. Test API Gateway

```bash
# Get API Gateway URL from Terraform output
API_URL=$(terraform output -raw api_gateway_url)

# Test authentication endpoint
curl -X POST $API_URL/api/v1/auth/validate-token \
  -H "Content-Type: application/json" \
  -d '{"token": "test-token"}'
```

## 🧪 Testing

### Local Testing

Use AWS SAM or LocalStack for local testing:

```bash
# Install SAM CLI
brew install aws-sam-cli

# Start local API
sam local start-api

# Invoke function locally
sam local invoke SalesforceProxyFunction \
  --event events/test-event.json
```

### Integration Testing

Create test scripts in `tests/` directory:

```bash
cd tests
npm install
npm test
```

## 📈 Cost Optimization

- **Lambda**: Use ARM64 architecture for lower costs
- **API Gateway**: Consider HTTP API instead of REST API (cheaper)
- **CloudWatch Logs**: Set retention period (e.g., 30 days)
- **S3**: Enable lifecycle policies for old logs/documents
- **CloudFront**: Cache static assets to reduce origin requests

## 🔄 CI/CD Integration

### GitHub Actions Workflow Example

```yaml
name: Deploy Customer Portal Infrastructure

on:
  push:
    branches:
      - main
    paths:
      - 'feature-customer-portal/aws-infrastructure/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: |
          cd feature-customer-portal/aws-infrastructure/terraform
          terraform init
      
      - name: Terraform Plan
        run: |
          cd feature-customer-portal/aws-infrastructure/terraform
          terraform plan
      
      - name: Terraform Apply
        run: |
          cd feature-customer-portal/aws-infrastructure/terraform
          terraform apply -auto-approve
```

## 📞 Support

For AWS infrastructure issues:
- **DevOps Team**: devops@easylegalgroup.com
- **AWS Support**: Via AWS Console (if Business/Enterprise support plan)

## 📚 Additional Resources

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Salesforce REST API Guide](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
