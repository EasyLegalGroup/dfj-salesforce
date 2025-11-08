# API Gateway Configuration - Customer Portal API# API Gateway Configuration - Placeholder



## Overview## 🚪 API Gateway for Customer Portal



This directory contains the **PRODUCTION OpenAPI 3.0 specification** exported from AWS API Gateway for the Customer Portal API.This directory will contain API Gateway configurations including OpenAPI specifications, route definitions, and authorizer configurations.



## API Details### Files to Create:



**API Name:** `dfj-doc-presigner`  #### 1. `openapi-spec.yaml`

**Type:** HTTP API (API Gateway v2)  

**Region:** `eu-north-1` (Stockholm)  OpenAPI 3.0 specification defining all API endpoints:

**Stage:** `prod`  

**Endpoint:** `https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod`  ```yaml

**Lambda Function:** `dfj-doc-presigner` (ARN: `arn:aws:lambda:eu-north-1:641409597080:function:dfj-doc-presigner`)openapi: 3.0.0

info:

## Files  title: Customer Portal API

  version: 1.0.0

### `openapi/api-spec.json`  description: API for Din Familiejurist Customer Portal



Complete OpenAPI 3.0.1 specification exported from AWS API Gateway Production. This file includes:servers:

- ✅ All production API routes and methods  - url: https://api.customer-portal.dinfamiliejurist.dk/api/v1

- ✅ Lambda integration configurations      description: Production

- ✅ CORS settings  - url: https://dev-api.customer-portal.dinfamiliejurist.dk/api/v1

- ✅ AWS-specific extensions (`x-amazon-apigateway-*`)    description: Development

- ✅ Request/response configurations

paths:

**Last Export:** 2025-10-31 13:08:29 UTC  /auth/validate-token:

    post:

## API Routes      summary: Validate access token

      requestBody:

### Authentication Routes        required: true

        content:

| Method | Path | Description | Lambda Handler |          application/json:

|--------|------|-------------|----------------|            schema:

| POST | `/identifier/request-otp` | Request OTP for phone/email | `identifier_request_otp` |              type: object

| POST | `/identifier/verify-otp` | Verify OTP and get session | `identifier_verify_otp` |              properties:

| POST | `/otp-send` | (Legacy) Send OTP to journal | `otp_send_legacy` |                token:

| POST | `/otp-verify` | (Legacy) Verify journal OTP | `otp_verify_legacy` |                  type: string

      responses:

### Document Routes        '200':

          description: Token is valid

| Method | Path | Description | Lambda Handler |        '401':

|--------|------|-------------|----------------|          description: Token is invalid

| GET | `/identifier/list` | List documents for identifier | `identifier_list_docs` |

| GET | `/identifier/doc-url` | Get presigned URL (identifier-based) | `identifier_doc_url` |  /journals/{journalId}:

| POST | `/identifier/approve` | Approve document (identifier-based) | `identifier_approve` |    get:

| GET | `/doc-list` | (Legacy) List documents by journal | `doc_list_legacy` |      summary: Get journal details

| GET | `/doc-url` | (Legacy) Get presigned URL by journal | `doc_url_legacy` |      parameters:

| POST | `/approve` | (Legacy) Approve document by journal | `approve_legacy` |        - name: journalId

          in: path

### Chat Routes          required: true

          schema:

| Method | Path | Description | Lambda Handler |            type: string

|--------|------|-------------|----------------|      responses:

| GET | `/chat/list` | List chat messages | `chat_list` |        '200':

| POST | `/chat/send` | Send chat message | `chat_send` |          description: Journal details



### Utility Routes  /journals/{journalId}/messages:

    get:

| Method | Path | Description | Lambda Handler |      summary: Get chat messages

|--------|------|-------------|----------------|      parameters:

| GET | `/ping` | Health check endpoint | `ping` |        - name: journalId

| GET | `/sf-oauth-check` | Verify Salesforce OAuth status | `sf_oauth_check` |          in: path

          required: true

## Lambda Integration          schema:

            type: string

All routes integrate with the single Lambda function:      responses:

        '200':

```          description: List of messages

Function ARN: arn:aws:lambda:eu-north-1:641409597080:function:dfj-doc-presigner    post:

Integration Type: aws_proxy (Lambda proxy integration)      summary: Send chat message

Payload Format: 2.0 (API Gateway v2 format)      parameters:

Timeout: 30 seconds        - name: journalId

```          in: path

          required: true

## CORS Configuration          schema:

            type: string

### Allowed Origins (configured in Lambda)      requestBody:

        required: true

```        content:

https://dfj.lightning.force.com          application/json:

https://dfj.my.salesforce.com            schema:

https://dok.dinfamiliejurist.dk              type: object

https://dok.dinfamiljejurist.se              properties:

https://docs.hereslaw.ie                body:

http://localhost:3000                  type: string

http://localhost:5173                isInbound:

http://localhost:8000                  type: boolean

http://localhost:8080      responses:

```        '201':

          description: Message created

### CORS Headers

  /journals/{journalId}/documents:

```    get:

Access-Control-Allow-Origin: <dynamic based on request>      summary: List documents

Access-Control-Allow-Methods: GET, POST, OPTIONS      parameters:

Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With        - name: journalId

Access-Control-Max-Age: 3600          in: path

Access-Control-Allow-Credentials: true          required: true

```          schema:

            type: string

## Request/Response Examples      responses:

        '200':

### Request OTP          description: List of documents

    post:

**Request:**      summary: Upload document

```http      parameters:

POST /prod/identifier/request-otp HTTP/1.1        - name: journalId

Host: ysu7eo2haj.execute-api.eu-north-1.amazonaws.com          in: path

Content-Type: application/json          required: true

Origin: https://dok.dinfamiliejurist.dk          schema:

            type: string

{      requestBody:

  "identifier": "+4512345678",        required: true

  "type": "phone"        content:

}          multipart/form-data:

```            schema:

              type: object

**Response:**              properties:

```http                file:

HTTP/1.1 200 OK                  type: string

Content-Type: application/json                  format: binary

Access-Control-Allow-Origin: https://dok.dinfamiliejurist.dk      responses:

        '201':

{          description: Document uploaded

  "success": true,

  "message": "OTP sent to +4512345678"  /documents/{documentId}:

}    get:

```      summary: Download document

      parameters:

### List Documents        - name: documentId

          in: path

**Request:**          required: true

```http          schema:

GET /prod/identifier/list?session=eyJzaWduYXR1cmUi... HTTP/1.1            type: string

Host: ysu7eo2haj.execute-api.eu-north-1.amazonaws.com      responses:

Origin: https://dok.dinfamiliejurist.dk        '200':

```          description: Document file

          content:

**Response:**            application/pdf:

```http              schema:

HTTP/1.1 200 OK                type: string

Content-Type: application/json                format: binary

```

{

  "documents": [#### 2. `routes.json`

    {

      "journalId": "J-0012345",Route definitions with Lambda integrations:

      "journalName": "John Doe - Testament",

      "documents": [```json

        {{

          "id": "a1b2c3d4",  "routes": [

          "name": "Testament.pdf",    {

          "approved": false,      "path": "/auth/validate-token",

          "created": "2025-11-08T10:00:00Z"      "method": "POST",

        }      "integration": {

      ]        "type": "AWS_PROXY",

    }        "lambda": "customer-portal-auth-service"

  ]      }

}    },

```    {

      "path": "/journals/{journalId}",

## Deployment & Management      "method": "GET",

      "integration": {

### Export Current Configuration from AWS        "type": "AWS_PROXY",

        "lambda": "customer-portal-salesforce-proxy"

```powershell      },

# Export OpenAPI spec from production API Gateway      "authorizer": "token-authorizer"

aws apigatewayv2 export-api `    },

  --api-id ysu7eo2haj `    {

  --output-type JSON `      "path": "/journals/{journalId}/messages",

  --specification OAS30 `      "method": "GET",

  --stage-name prod `      "integration": {

  --no-cli-pager `        "type": "AWS_PROXY",

  > openapi/api-spec.json        "lambda": "customer-portal-chat-service"

      },

# Add date to documentation      "authorizer": "token-authorizer"

$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"    },

Write-Host "Exported at: $date UTC"    {

```      "path": "/journals/{journalId}/messages",

      "method": "POST",

### Import/Update API Gateway (Use with Caution)      "integration": {

        "type": "AWS_PROXY",

```powershell        "lambda": "customer-portal-chat-service"

# ⚠️ DANGEROUS: This will replace the entire API configuration      },

# Create new API from OpenAPI spec      "authorizer": "token-authorizer"

aws apigatewayv2 import-api `    }

  --body file://openapi/api-spec.json  ]

}

# ⚠️ DANGEROUS: Update existing API```

aws apigatewayv2 reimport-api `

  --api-id ysu7eo2haj `#### 3. `cors-config.json`

  --body file://openapi/api-spec.json

```CORS configuration:



### Using Terraform (Recommended)```json

{

See `../terraform/modules/api-gateway.tf` for Infrastructure as Code management.  "allowOrigins": [

    "https://portal.dinfamiliejurist.dk",

## Custom Domain Configuration    "https://dev-portal.dinfamiliejurist.dk"

  ],

### Domain Mapping (To Be Implemented)  "allowMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],

  "allowHeaders": [

| Domain | Stage | Certificate | Status |    "Content-Type",

|--------|-------|-------------|--------|    "Authorization",

| `api.dinfamiliejurist.dk` | prod | ACM cert in `eu-north-1` | 🔄 Planned |    "X-Requested-With"

| `api.dinfamiljejurist.se` | prod | ACM cert in `eu-north-1` | 🔄 Planned |  ],

| `api.hereslaw.ie` | prod | ACM cert in `eu-north-1` | 🔄 Planned |  "exposeHeaders": ["X-Request-ID"],

  "maxAge": 3600,

Currently using default API Gateway domain:  "allowCredentials": true

```}

ysu7eo2haj.execute-api.eu-north-1.amazonaws.com```

```

#### 4. `authorizers.json`

## Monitoring & Observability

Custom authorizer configurations:

### CloudWatch Metrics

```json

Key metrics to monitor:{

  "authorizers": [

| Metric | Description | Alarm Threshold |    {

|--------|-------------|-----------------|      "name": "token-authorizer",

| `Count` | Total API calls | N/A |      "type": "TOKEN",

| `IntegrationLatency` | Lambda execution time | > 5000ms (p99) |      "identitySource": "method.request.header.Authorization",

| `Latency` | Total request latency | > 10000ms (p99) |      "lambda": "customer-portal-auth-service",

| `4XXError` | Client errors | > 5% |      "resultTtlInSeconds": 300

| `5XXError` | Server errors | > 1% |    }

  ]

### Example CloudWatch Insights Query}

```

```sql

fields @timestamp, @message, path, statusCode, @duration### Deployment:

| filter path = "/identifier/verify-otp"

| stats count() by statusCode, bin(5m)Using AWS CLI:

```

```bash

### CloudWatch Alarms (Recommended)# Import OpenAPI specification

aws apigatewayv2 import-api \

```powershell  --body file://openapi-spec.yaml

# High error rate alarm

aws cloudwatch put-metric-alarm `# Or using Terraform (recommended)

  --alarm-name customer-portal-api-5xx-errors `terraform apply

  --metric-name 5XXError ````

  --namespace AWS/ApiGateway `

  --dimensions Name=ApiId,Value=ysu7eo2haj `### TODO:

  --statistic Sum `- [ ] Create openapi-spec.yaml

  --period 300 `- [ ] Define all API routes

  --evaluation-periods 2 `- [ ] Configure CORS

  --threshold 10 `- [ ] Set up custom authorizers

  --comparison-operator GreaterThanThreshold `- [ ] Add rate limiting

  --alarm-actions arn:aws:sns:eu-north-1:641409597080:ops-alerts- [ ] Configure WAF rules

```- [ ] Set up CloudWatch logging


## Security & Access Control

### API Gateway Resource Policy

Currently: **Open access** (no resource policy restrictions)

Recommended policy for production hardening:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:eu-north-1:641409597080:ysu7eo2haj/prod/*"
    }
  ]
}
```

### Lambda Invoke Permission

```powershell
# Verify Lambda permission
aws lambda get-policy --function-name dfj-doc-presigner
```

Should include statement allowing API Gateway to invoke:
```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "apigateway.amazonaws.com"
  },
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:eu-north-1:641409597080:function:dfj-doc-presigner",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:execute-api:eu-north-1:641409597080:ysu7eo2haj/*"
    }
  }
}
```

## Throttling & Rate Limits

### Current Configuration

| Parameter | Value |
|-----------|-------|
| **Throttle Burst Limit** | 5000 requests |
| **Throttle Rate Limit** | 10000 requests/second |
| **Quota** | Unlimited |

### Recommended Production Limits

```powershell
# Update route-level throttling
aws apigatewayv2 update-route `
  --api-id ysu7eo2haj `
  --route-id <route-id> `
  --throttle-settings BurstLimit=100,RateLimit=50
```

## Access Logging

### Enable Access Logs (Recommended)

```powershell
# Create log group
aws logs create-log-group `
  --log-group-name /aws/apigateway/customer-portal-api

# Update stage with logging
aws apigatewayv2 update-stage `
  --api-id ysu7eo2haj `
  --stage-name prod `
  --access-log-settings '{
    "DestinationArn": "arn:aws:logs:eu-north-1:641409597080:log-group:/aws/apigateway/customer-portal-api",
    "Format": "$context.requestId $context.routeKey $context.status $context.integrationLatency"
  }'
```

### Log Format (JSON)

```json
{
  "requestId": "$context.requestId",
  "ip": "$context.identity.sourceIp",
  "requestTime": "$context.requestTime",
  "httpMethod": "$context.httpMethod",
  "routeKey": "$context.routeKey",
  "status": "$context.status",
  "protocol": "$context.protocol",
  "responseLength": "$context.responseLength",
  "integrationLatency": "$context.integrationLatency",
  "errorMessage": "$context.error.message",
  "errorMessageString": "$context.error.messageString"
}
```

## Testing

### Health Check

```powershell
# Test ping endpoint
Invoke-RestMethod -Uri "https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/ping"
```

### Full Authentication Flow Test

```powershell
# 1. Request OTP
$otpRequest = @{
    identifier = "+4512345678"
    type = "phone"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/identifier/request-otp" `
  -Method Post `
  -Body $otpRequest `
  -ContentType "application/json"

# 2. Verify OTP (get OTP from phone/email)
$verifyRequest = @{
    identifier = "+4512345678"
    otp = "123456"
} | ConvertTo-Json

$session = Invoke-RestMethod `
  -Uri "https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/identifier/verify-otp" `
  -Method Post `
  -Body $verifyRequest `
  -ContentType "application/json"

# 3. List documents
$docs = Invoke-RestMethod `
  -Uri "https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/identifier/list?session=$($session.session)"
```

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 -H "Origin: https://dok.dinfamiliejurist.dk" \
  https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/ping

# Using wrk
wrk -t10 -c100 -d30s \
  -H "Origin: https://dok.dinfamiliejurist.dk" \
  https://ysu7eo2haj.execute-api.eu-north-1.amazonaws.com/prod/ping
```

## OpenAPI Extensions

### AWS-Specific Extensions in Use

The `api-spec.json` includes these AWS extensions:

| Extension | Purpose |
|-----------|---------|
| `x-amazon-apigateway-integration` | Lambda integration configuration |
| `payloadFormatVersion: "2.0"` | API Gateway v2 payload format |
| `httpMethod: "POST"` | Lambda invocation method (always POST) |
| `type: "aws_proxy"` | Proxy integration type |
| `uri` | Lambda function ARN |

### Example Integration Block

```json
{
  "x-amazon-apigateway-integration": {
    "payloadFormatVersion": "2.0",
    "type": "aws_proxy",
    "httpMethod": "POST",
    "uri": "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-north-1:641409597080:function:dfj-doc-presigner/invocations",
    "connectionType": "INTERNET"
  }
}
```

## Troubleshooting

### Issue: 403 Forbidden - Missing Authentication Token

**Cause**: Route not found or method not allowed  
**Solution**: Verify route exists in `api-spec.json` and method matches

### Issue: 502 Bad Gateway

**Cause**: Lambda function error, timeout, or invalid response format  
**Solutions:**
1. Check Lambda CloudWatch logs for errors
2. Verify Lambda response format (must include `statusCode`, `body`, `headers`)
3. Check Lambda timeout (should be < 30 seconds)

### Issue: CORS Preflight Fails

**Cause**: Origin not in allowed list or CORS headers not returned  
**Solutions:**
1. Verify origin is in Lambda's `ALLOWED_ORIGINS`
2. Check Lambda is returning proper CORS headers
3. Verify OPTIONS method handling if implemented

### Issue: IntegrationLatency High

**Cause**: Lambda cold starts or slow Salesforce API  
**Solutions:**
1. Enable Provisioned Concurrency for Lambda
2. Optimize Salesforce SOQL queries
3. Implement caching for frequently accessed data

## Performance Optimization

### Caching Strategy (Future Enhancement)

```powershell
# Enable stage-level caching
aws apigatewayv2 update-stage `
  --api-id ysu7eo2haj `
  --stage-name prod `
  --route-settings '{
    "GET /doc-list": {
      "ThrottlingBurstLimit": 100,
      "ThrottlingRateLimit": 50
    }
  }'
```

### Lambda Provisioned Concurrency

```powershell
# Add provisioned concurrency to reduce cold starts
aws lambda put-provisioned-concurrency-config `
  --function-name dfj-doc-presigner `
  --qualifier prod `
  --provisioned-concurrent-executions 5
```

## Version History

| Date | Version | Changes | Exported By |
|------|---------|---------|-------------|
| 2025-11-08 | Current | Imported production spec to repository | DevOps Team |
| 2025-10-31 | 1.3 | Added identifier-based authentication | Backend Team |
| 2025-10-15 | 1.2 | Multi-brand support implemented | Backend Team |
| 2025-09-20 | 1.1 | Added chat endpoints | Backend Team |
| 2025-08-01 | 1.0 | Initial API Gateway deployment | Infrastructure Team |

## Related Documentation

- [Lambda Function](../lambda-functions/customer-portal-api/README.md) - Backend implementation
- [SPA Frontend](../../spa-frontend/README.md) - Client application consuming this API
- [S3 Bucket Structure](../s3-bucket-structure/README.md) - Document storage
- [Terraform Infrastructure](../terraform/README.md) - Infrastructure as Code

## Support & Contacts

**Production Issues:**
- **PagerDuty**: Escalate to on-call engineer
- **Slack**: #customer-portal-prod-alerts

**Development Questions:**
- **Slack**: #customer-portal-dev
- **Email**: dev-team@dinfamiliejurist.dk

**AWS Console:**
- [API Gateway Console](https://eu-north-1.console.aws.amazon.com/apigateway/main/apis/ysu7eo2haj?api=ysu7eo2haj&region=eu-north-1)
- [Lambda Function Console](https://eu-north-1.console.aws.amazon.com/lambda/home?region=eu-north-1#/functions/dfj-doc-presigner)
- [CloudWatch Logs](https://eu-north-1.console.aws.amazon.com/cloudwatch/home?region=eu-north-1#logsV2:log-groups)
