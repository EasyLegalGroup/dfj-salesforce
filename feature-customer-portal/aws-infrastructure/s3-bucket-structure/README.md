# S3 Bucket Structure - dfj-docs-prod

This directory documents the structure of the `dfj-docs-prod` S3 bucket (excluding customer-documents folder which contains sensitive customer data).

## Bucket Overview

**Bucket Name:** `dfj-docs-prod`  
**Region:** (Specify region)  
**Purpose:** Static assets and application resources for Din Familiejurist Customer Portal

## Directory Structure

```
dfj-docs-prod/
├── app.js                          # Main application JavaScript (75 KB)
├── brand.js                        # Branding/theming JavaScript (5.6 KB)
└── assets/                         # Static assets organized by country
    ├── dk/                         # Denmark assets
    │   ├── favicon.png            # (4.5 KB)
    │   └── logo.png               # (12.1 KB)
    ├── ie/                         # Ireland assets
    │   ├── favicon.png            # (39.4 KB)
    │   └── logo.png               # (15.6 KB)
    └── se/                         # Sweden assets
        ├── favicon.png            # (4.5 KB)
        └── logo.png               # (12.1 KB)
```

## File Inventory

### Root Level Files

| File | Size | Last Modified | Purpose |
|------|------|---------------|---------|
| `app.js` | 75.2 KB | 2025-11-05 20:17:15 | Main application bundle (React/Vue SPA) |
| `brand.js` | 5.6 KB | 2025-10-30 13:15:38 | Branding configuration and theme switcher |

### Assets Directory

The `assets/` directory contains country-specific branding assets organized by ISO country code:

#### Denmark (`dk/`)
- **favicon.png** - 4.5 KB - Browser favicon
- **logo.png** - 12.1 KB - Application logo for Danish customers

#### Ireland (`ie/`)
- **favicon.png** - 39.4 KB - Browser favicon
- **logo.png** - 15.6 KB - Application logo for Irish customers

#### Sweden (`se/`)
- **favicon.png** - 4.5 KB - Browser favicon
- **logo.png** - 12.1 KB - Application logo for Swedish customers

## Excluded Directories

- **customer-documents/** - Contains sensitive customer legal documents organized by journal numbers (J-XXXXXXX). This folder is excluded from this documentation for security reasons.

## Integration with Customer Portal

### Application Files

The root-level JavaScript files (`app.js`, `brand.js`) are served to the SPA frontend:

```javascript
// Example CloudFront/S3 URL structure
https://d123456abcdef.cloudfront.net/app.js
https://d123456abcdef.cloudfront.net/brand.js
```

### Static Assets

Country-specific assets are loaded dynamically based on user locale:

```javascript
// Example asset loading in SPA
const countryCode = user.country.toLowerCase(); // 'dk', 'ie', 'se'
const logoUrl = `https://d123456abcdef.cloudfront.net/assets/${countryCode}/logo.png`;
const faviconUrl = `https://d123456abcdef.cloudfront.net/assets/${countryCode}/favicon.png`;
```

## Deployment Process

### Uploading New Files

Upload files to S3 using AWS CLI:

```powershell
# Upload app.js with cache control
aws s3 cp ./dist/app.js s3://dfj-docs-prod/app.js --cache-control "public, max-age=31536000, immutable"

# Upload assets
aws s3 cp ./assets/ s3://dfj-docs-prod/assets/ --recursive --cache-control "public, max-age=31536000"

# Sync entire directory (use with caution)
aws s3 sync ./dist/ s3://dfj-docs-prod/ --exclude "customer-documents/*"
```

### CloudFront Invalidation

After uploading new files, invalidate CloudFront cache:

```powershell
# Invalidate app.js
aws cloudfront create-invalidation --distribution-id E123456EXAMPLE --paths "/app.js" "/brand.js"

# Invalidate all assets
aws cloudfront create-invalidation --distribution-id E123456EXAMPLE --paths "/assets/*"
```

## S3 Bucket Policies

### Public Read Access for Static Assets

The bucket should have public read access for specific paths:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::dfj-docs-prod/app.js",
        "arn:aws:s3:::dfj-docs-prod/brand.js",
        "arn:aws:s3:::dfj-docs-prod/assets/*"
      ]
    }
  ]
}
```

### Private Access for Customer Documents

Customer documents should be restricted:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PrivateDocumentAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::dfj-docs-prod/customer-documents/*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalArn": "arn:aws:iam::ACCOUNT_ID:role/CustomerPortalLambdaRole"
        }
      }
    }
  ]
}
```

## CORS Configuration

Enable CORS for cross-origin requests from SPA:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": [
      "https://portal.dinfamiliejurist.dk",
      "https://portal.easylegal.ie",
      "https://portal.dinsfamiljeadvokat.se"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

## CloudFront Distribution

### Distribution Configuration

- **Origin:** dfj-docs-prod.s3.eu-west-1.amazonaws.com
- **Default Root Object:** index.html (served from SPA)
- **Price Class:** Use All Edge Locations
- **SSL Certificate:** Custom SSL from ACM

### Cache Behaviors

| Path Pattern | TTL | Behavior |
|-------------|-----|----------|
| `/app.js` | 1 year | Cache with versioning |
| `/brand.js` | 1 year | Cache with versioning |
| `/assets/*` | 1 year | Cache with versioning |
| `/customer-documents/*` | No cache | Authenticated access via Lambda@Edge |

## Monitoring and Logging

### S3 Access Logs

Enable S3 access logging to track bucket usage:

```powershell
aws s3api put-bucket-logging --bucket dfj-docs-prod --bucket-logging-status '{
  "LoggingEnabled": {
    "TargetBucket": "dfj-logs",
    "TargetPrefix": "s3-access-logs/"
  }
}'
```

### CloudWatch Metrics

Monitor S3 bucket metrics:
- **NumberOfObjects** - Track file count
- **BucketSizeBytes** - Monitor storage usage
- **AllRequests** - Request volume
- **4xxErrors** - Client errors
- **5xxErrors** - Server errors

## Security Best Practices

1. **Encryption at Rest:** Enable default S3 encryption (AES-256 or KMS)
2. **Versioning:** Enable S3 versioning for recovery
3. **MFA Delete:** Require MFA for object deletion
4. **Block Public Access:** Block public access for customer-documents/
5. **IAM Roles:** Use IAM roles with least privilege for Lambda access
6. **CloudTrail:** Enable CloudTrail for audit logging

## Terraform Configuration

See `../terraform/modules/s3.tf` for Infrastructure as Code definition of this bucket.

## Related Documentation

- [Lambda Functions](../lambda-functions/README.md) - Backend Lambda functions accessing S3
- [API Gateway](../api-gateway/README.md) - API endpoints for document retrieval
- [SPA Frontend](../../spa-frontend/README.md) - Frontend application consuming S3 assets

## Last Updated

**Date:** 2025-11-08  
**Retrieved By:** AWS CLI (`aws s3 ls s3://dfj-docs-prod --recursive`)
