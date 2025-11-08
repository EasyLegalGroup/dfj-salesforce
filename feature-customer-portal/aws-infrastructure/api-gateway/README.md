# API Gateway Configuration - Placeholder

## 🚪 API Gateway for Customer Portal

This directory will contain API Gateway configurations including OpenAPI specifications, route definitions, and authorizer configurations.

### Files to Create:

#### 1. `openapi-spec.yaml`

OpenAPI 3.0 specification defining all API endpoints:

```yaml
openapi: 3.0.0
info:
  title: Customer Portal API
  version: 1.0.0
  description: API for Din Familiejurist Customer Portal

servers:
  - url: https://api.customer-portal.dinfamiliejurist.dk/api/v1
    description: Production
  - url: https://dev-api.customer-portal.dinfamiliejurist.dk/api/v1
    description: Development

paths:
  /auth/validate-token:
    post:
      summary: Validate access token
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                token:
                  type: string
      responses:
        '200':
          description: Token is valid
        '401':
          description: Token is invalid

  /journals/{journalId}:
    get:
      summary: Get journal details
      parameters:
        - name: journalId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Journal details

  /journals/{journalId}/messages:
    get:
      summary: Get chat messages
      parameters:
        - name: journalId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of messages
    post:
      summary: Send chat message
      parameters:
        - name: journalId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                body:
                  type: string
                isInbound:
                  type: boolean
      responses:
        '201':
          description: Message created

  /journals/{journalId}/documents:
    get:
      summary: List documents
      parameters:
        - name: journalId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of documents
    post:
      summary: Upload document
      parameters:
        - name: journalId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                file:
                  type: string
                  format: binary
      responses:
        '201':
          description: Document uploaded

  /documents/{documentId}:
    get:
      summary: Download document
      parameters:
        - name: documentId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Document file
          content:
            application/pdf:
              schema:
                type: string
                format: binary
```

#### 2. `routes.json`

Route definitions with Lambda integrations:

```json
{
  "routes": [
    {
      "path": "/auth/validate-token",
      "method": "POST",
      "integration": {
        "type": "AWS_PROXY",
        "lambda": "customer-portal-auth-service"
      }
    },
    {
      "path": "/journals/{journalId}",
      "method": "GET",
      "integration": {
        "type": "AWS_PROXY",
        "lambda": "customer-portal-salesforce-proxy"
      },
      "authorizer": "token-authorizer"
    },
    {
      "path": "/journals/{journalId}/messages",
      "method": "GET",
      "integration": {
        "type": "AWS_PROXY",
        "lambda": "customer-portal-chat-service"
      },
      "authorizer": "token-authorizer"
    },
    {
      "path": "/journals/{journalId}/messages",
      "method": "POST",
      "integration": {
        "type": "AWS_PROXY",
        "lambda": "customer-portal-chat-service"
      },
      "authorizer": "token-authorizer"
    }
  ]
}
```

#### 3. `cors-config.json`

CORS configuration:

```json
{
  "allowOrigins": [
    "https://portal.dinfamiliejurist.dk",
    "https://dev-portal.dinfamiliejurist.dk"
  ],
  "allowMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  "allowHeaders": [
    "Content-Type",
    "Authorization",
    "X-Requested-With"
  ],
  "exposeHeaders": ["X-Request-ID"],
  "maxAge": 3600,
  "allowCredentials": true
}
```

#### 4. `authorizers.json`

Custom authorizer configurations:

```json
{
  "authorizers": [
    {
      "name": "token-authorizer",
      "type": "TOKEN",
      "identitySource": "method.request.header.Authorization",
      "lambda": "customer-portal-auth-service",
      "resultTtlInSeconds": 300
    }
  ]
}
```

### Deployment:

Using AWS CLI:

```bash
# Import OpenAPI specification
aws apigatewayv2 import-api \
  --body file://openapi-spec.yaml

# Or using Terraform (recommended)
terraform apply
```

### TODO:
- [ ] Create openapi-spec.yaml
- [ ] Define all API routes
- [ ] Configure CORS
- [ ] Set up custom authorizers
- [ ] Add rate limiting
- [ ] Configure WAF rules
- [ ] Set up CloudWatch logging
