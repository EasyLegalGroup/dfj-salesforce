# Customer Portal API Lambda Function

## Overview

This Lambda function (`app.py`) serves as the backend API for the Din Familiejurist Customer Portal. It handles document access, OTP authentication, chat functionality, and Salesforce integration.

## Function Details

**Runtime:** Python 3.x  
**Handler:** `app.lambda_handler`  
**Memory:** 512 MB (recommended)  
**Timeout:** 30 seconds  
**Concurrency:** Reserved capacity recommended for production

## Architecture

```
Client (SPA) → API Gateway → Lambda (app.py) → Salesforce API
                                             ↓
                                          S3 Bucket (dfj-docs-prod)
```

## Key Features

### 1. **OTP Authentication**
- **Legacy Journal OTP**: `/otp-send`, `/otp-verify`
- **New Identifier OTP**: `/identifier/request-otp`, `/identifier/verify-otp`
- Supports both phone and email delivery
- Session-based authentication with HMAC signing

### 2. **Document Management**
- **List Documents**: `/doc-list`, `/identifier/list`
- **Get Document URL**: `/doc-url`, `/identifier/doc-url`
- **Approve Documents**: `/approve`, `/identifier/approve`
- S3 presigned URLs with configurable TTL

### 3. **Chat Integration**
- **List Messages**: `/chat/list`
- **Send Message**: `/chat/send`
- Salesforce ChatMessage__c integration

### 4. **Multi-Brand Support**
Brand detection based on domain:
- `dinfamiliejurist.dk` → Denmark (dk)
- `dinfamiljejurist.se` → Sweden (se)
- `hereslaw.ie` → Ireland (ie)

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DOCS_BUCKET` | S3 bucket name | `dfj-docs-prod` |
| `SF_CLIENT_ID` | Salesforce Connected App Client ID | `3MVG9...` |
| `SF_CLIENT_SECRET` | Salesforce Connected App Secret | `ABC123...` |
| `SF_REFRESH_TOKEN` | Salesforce OAuth Refresh Token | `5Aep8...` |
| `SESSION_HMAC_SECRET` | Secret key for session signing | (generate with `secrets.token_hex(32)`) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_REGION` | `eu-north-1` | AWS region for S3/Lambda |
| `SF_LOGIN_URL` | `https://login.salesforce.com` | Salesforce auth endpoint |
| `SESSION_TTL_SECONDS` | `900` | Session timeout (15 minutes) |
| `DEBUG_ALLOW_IDENTIFIER_DOCURL` | `false` | Debug flag for identifier doc access |
| `S3_PREFIX_MAP` | `{}` | JSON map of market unit → S3 prefix |

### S3 Prefix Mapping

The function uses market unit-specific S3 prefixes:

```json
{
  "DFJ_DK": "dk/customer-documents",
  "FA_SE": "se/customer-documents",
  "Ireland": "ie/customer-documents"
}
```

Override via `S3_PREFIX_MAP` environment variable.

## API Endpoints

### Authentication Endpoints

#### POST `/identifier/request-otp`
Request OTP for phone or email.

**Request:**
```json
{
  "identifier": "+4512345678",  // or "email@example.com"
  "type": "phone"               // or "email"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent"
}
```

#### POST `/identifier/verify-otp`
Verify OTP and get session token.

**Request:**
```json
{
  "identifier": "+4512345678",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "session": "eyJ...",  // HMAC-signed session token
  "ttl": 900
}
```

### Document Endpoints

#### GET `/identifier/list?session=eyJ...`
List all documents for the authenticated identifier.

**Response:**
```json
{
  "documents": [
    {
      "journalId": "J-0012345",
      "journalName": "John Doe - Testament",
      "documents": [
        {
          "id": "a1b2c3d4",
          "name": "Testament.pdf",
          "approved": false,
          "created": "2025-11-08T10:00:00Z"
        }
      ]
    }
  ]
}
```

#### GET `/identifier/doc-url?session=eyJ...&docId=a1b2c3d4`
Get presigned S3 URL for document viewing.

**Response:**
```json
{
  "url": "https://dfj-docs-prod.s3.eu-north-1.amazonaws.com/...",
  "ttl": 900
}
```

#### POST `/identifier/approve`
Approve a document.

**Request:**
```json
{
  "session": "eyJ...",
  "docId": "a1b2c3d4"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Document approved"
}
```

### Chat Endpoints

#### GET `/chat/list?j=J-0012345&e=abc...`
List chat messages (legacy journal-based auth).

#### POST `/chat/send`
Send a chat message.

**Request:**
```json
{
  "j": "J-0012345",
  "e": "abc...",
  "message": "Hello, I have a question..."
}
```

## Salesforce Integration

### SOQL Queries

The Lambda executes SOQL queries against:
- `OTP__c` - OTP records for authentication
- `Journal__c` - Customer journals
- `ContentDocumentLink` - Document associations
- `ChatMessage__c` - Chat messages

### OAuth Flow

1. **Refresh Token Exchange**: Use stored refresh token to get access token
2. **API Calls**: Execute SOQL/REST API calls with access token
3. **Token Caching**: Cache access token for performance (expires after 2 hours)

### Example SOQL Query

```python
query = f"""
    SELECT Id, Name, Market_Unit__c 
    FROM Journal__c 
    WHERE Name IN ('{soql_escape(journal_name)}')
"""
```

## S3 Integration

### Presigned URLs

Generate time-limited URLs for document access:

```python
s3_client.generate_presigned_url(
    'get_object',
    Params={
        'Bucket': DOCS_BUCKET,
        'Key': f'dk/customer-documents/J-0012345/Testament.pdf'
    },
    ExpiresIn=SESSION_TTL_SECONDS
)
```

### File Organization

```
dfj-docs-prod/
├── dk/customer-documents/
│   └── J-0012345/
│       ├── Testament.pdf
│       └── Fremtidsfuldmagt.pdf
├── se/customer-documents/
└── ie/customer-documents/
```

## Security

### Session Token Structure

```
{signature}:{payload}
```

Where:
- **signature**: HMAC-SHA256 of payload + secret
- **payload**: Base64-encoded JSON with identifier, timestamp, etc.

### CORS Configuration

Allowed origins (hardcoded in Lambda):
```python
ALLOWED_ORIGINS = {
    "https://dfj.lightning.force.com",
    "https://dok.dinfamiliejurist.dk",
    "https://dok.dinfamiljejurist.se",
    "https://docs.hereslaw.ie",
    "http://localhost:3000",  # Development
}
```

### IAM Role Permissions

Required policies:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::dfj-docs-prod",
        "arn:aws:s3:::dfj-docs-prod/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

## Deployment

### Using AWS CLI

```powershell
# Create deployment package
Compress-Archive -Path app.py -DestinationPath function.zip

# Update Lambda function
aws lambda update-function-code `
  --function-name customer-portal-api `
  --zip-file fileb://function.zip
```

### Using AWS SAM

See `template.yaml` in parent directory.

### Environment Variables Setup

```powershell
aws lambda update-function-configuration `
  --function-name customer-portal-api `
  --environment "Variables={
    DOCS_BUCKET=dfj-docs-prod,
    SF_CLIENT_ID=3MVG9...,
    SF_CLIENT_SECRET=ABC123...,
    SF_REFRESH_TOKEN=5Aep8...,
    SESSION_HMAC_SECRET=$(python -c 'import secrets; print(secrets.token_hex(32))'),
    SESSION_TTL_SECONDS=900
  }"
```

## Monitoring

### CloudWatch Logs

All requests logged with structure:

```json
{
  "timestamp": "2025-11-08T10:00:00Z",
  "level": "INFO",
  "path": "/identifier/list",
  "method": "GET",
  "status": 200,
  "duration_ms": 234
}
```

### CloudWatch Metrics

Key metrics to monitor:
- **Invocations**: Total function calls
- **Duration**: Execution time (p50, p99)
- **Errors**: Failed invocations
- **Throttles**: Concurrency limits hit

### Custom Metrics

```python
cloudwatch.put_metric_data(
    Namespace='CustomerPortal',
    MetricData=[
        {
            'MetricName': 'OTPSent',
            'Value': 1.0,
            'Unit': 'Count'
        }
    ]
)
```

## Error Handling

### Error Response Format

```json
{
  "error": "Invalid OTP",
  "code": "INVALID_OTP",
  "details": "The OTP has expired or is incorrect"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_OTP` | 401 | OTP is incorrect or expired |
| `SESSION_EXPIRED` | 401 | Session token has expired |
| `DOCUMENT_NOT_FOUND` | 404 | Document ID not found |
| `UNAUTHORIZED` | 403 | Access denied to resource |
| `SF_ERROR` | 500 | Salesforce API error |
| `S3_ERROR` | 500 | S3 access error |

## Testing

### Local Testing with SAM

```powershell
# Start local API
sam local start-api

# Test endpoint
Invoke-WebRequest -Uri "http://localhost:3000/ping" -Method GET
```

### Unit Tests

```python
# test_app.py
import app

def test_soql_escape():
    assert app.soql_escape("O'Brien") == "O\\'Brien"

def test_detect_brand():
    event = {
        "headers": {"origin": "https://dok.dinfamiliejurist.dk"}
    }
    assert app.detect_brand(event) == "dk"
```

### Integration Tests

```python
# test_integration.py
def test_identifier_flow():
    # 1. Request OTP
    response = requests.post(f"{API_URL}/identifier/request-otp", json={
        "identifier": "+4512345678",
        "type": "phone"
    })
    assert response.status_code == 200
    
    # 2. Verify OTP (use test OTP from logs)
    # 3. List documents
    # 4. Approve document
```

## Troubleshooting

### Issue: 401 Unauthorized on Salesforce

**Cause**: Refresh token expired or invalid  
**Solution**: Generate new refresh token via Salesforce OAuth flow

### Issue: Presigned URLs expire immediately

**Cause**: System clock drift  
**Solution**: Sync Lambda execution environment clock with NTP

### Issue: CORS errors in browser

**Cause**: Origin not in ALLOWED_ORIGINS  
**Solution**: Add domain to ALLOWED_ORIGINS list in app.py

### Issue: OTP not received

**Cause**: Salesforce OTP__c trigger not firing  
**Solution**: Check Salesforce Process Builder/Flow for OTP delivery

## Performance Optimization

### Cold Start Mitigation

```python
# Import optimization - move heavy imports inside functions
def list_documents(event):
    import boto3  # Only import when needed
    # ...
```

### Connection Pooling

```python
# Reuse S3 client across invocations
s3_client = None

def get_s3_client():
    global s3_client
    if not s3_client:
        s3_client = boto3.client('s3')
    return s3_client
```

### Caching

```python
# Cache Salesforce access tokens
_sf_token_cache = {"token": None, "expires": 0}

def get_sf_token():
    now = time.time()
    if _sf_token_cache["expires"] > now:
        return _sf_token_cache["token"]
    # ... refresh token logic
```

## Related Documentation

- [API Gateway Configuration](../../api-gateway/README.md)
- [S3 Bucket Structure](../../s3-bucket-structure/README.md)
- [SPA Frontend Integration](../../../spa-frontend/README.md)
- [Terraform Infrastructure](../../terraform/README.md)

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-08 | 1.0 | Initial documentation of production Lambda |
| 2025-10-31 | 0.9 | Added identifier-based authentication |
| 2025-10-15 | 0.8 | Multi-brand support implemented |

## Support

For issues or questions:
- **Slack**: #customer-portal-dev
- **Email**: dev-team@dinfamiliejurist.dk
- **On-call**: PagerDuty escalation for production issues
