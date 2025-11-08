# S3 Sync Script for dfj-docs-prod

## Overview

This script helps synchronize the local S3 bucket structure documentation with the actual S3 bucket.

## Prerequisites

- AWS CLI installed and configured
- Appropriate IAM permissions for S3 access
- PowerShell 5.1 or higher

## Usage

### List S3 Bucket Contents

```powershell
# List all files (excluding customer-documents)
aws s3 ls s3://dfj-docs-prod --recursive | Where-Object { $_ -notmatch "customer-documents/" }

# List only root-level files
aws s3 ls s3://dfj-docs-prod/

# List assets directory
aws s3 ls s3://dfj-docs-prod/assets/ --recursive
```

### Download Files for Local Development

```powershell
# Download app.js and brand.js
aws s3 cp s3://dfj-docs-prod/app.js ./temp-s3-download/app.js
aws s3 cp s3://dfj-docs-prod/brand.js ./temp-s3-download/brand.js

# Download all assets
aws s3 sync s3://dfj-docs-prod/assets/ ./temp-s3-download/assets/ --exclude "customer-documents/*"
```

### Upload Updated Files

```powershell
# Upload app.js with cache busting
aws s3 cp ./dist/app.js s3://dfj-docs-prod/app.js `
  --cache-control "public, max-age=31536000, immutable" `
  --content-type "application/javascript"

# Upload brand.js
aws s3 cp ./dist/brand.js s3://dfj-docs-prod/brand.js `
  --cache-control "public, max-age=31536000, immutable" `
  --content-type "application/javascript"

# Upload country assets
aws s3 cp ./assets/dk/logo.png s3://dfj-docs-prod/assets/dk/logo.png `
  --cache-control "public, max-age=31536000, immutable" `
  --content-type "image/png"

# Sync entire assets directory
aws s3 sync ./assets/ s3://dfj-docs-prod/assets/ `
  --exclude "customer-documents/*" `
  --cache-control "public, max-age=31536000, immutable"
```

### Update Documentation

After making changes to S3, update this documentation:

```powershell
# Generate new structure listing
aws s3 ls s3://dfj-docs-prod --recursive > s3-structure.txt

# Review changes
Get-Content s3-structure.txt | Where-Object { $_ -notmatch "customer-documents/" }

# Update README.md with new file sizes and dates
```

## PowerShell Script - sync-s3-structure.ps1

```powershell
<#
.SYNOPSIS
    Synchronize S3 bucket structure documentation
.DESCRIPTION
    This script retrieves the current S3 bucket structure and updates the local documentation
.PARAMETER Action
    Action to perform: list, download, upload, or document
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("list", "download", "upload", "document")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$LocalPath = "./temp-s3-download",
    
    [Parameter(Mandatory=$false)]
    [string]$BucketName = "dfj-docs-prod"
)

function List-S3Structure {
    Write-Host "Listing S3 bucket structure (excluding customer-documents)..." -ForegroundColor Cyan
    
    $files = aws s3 ls s3://$BucketName --recursive | Where-Object { $_ -notmatch "customer-documents/" }
    
    Write-Host "`nRoot files:" -ForegroundColor Green
    $files | Where-Object { $_ -match "^\d{4}-\d{2}-\d{2}.*\s+[^/]+$" }
    
    Write-Host "`nAssets (dk):" -ForegroundColor Green
    $files | Where-Object { $_ -match "assets/dk/" }
    
    Write-Host "`nAssets (ie):" -ForegroundColor Green
    $files | Where-Object { $_ -match "assets/ie/" }
    
    Write-Host "`nAssets (se):" -ForegroundColor Green
    $files | Where-Object { $_ -match "assets/se/" }
}

function Download-S3Files {
    Write-Host "Downloading S3 files to $LocalPath..." -ForegroundColor Cyan
    
    if (-not (Test-Path $LocalPath)) {
        New-Item -ItemType Directory -Path $LocalPath | Out-Null
    }
    
    # Download root files
    aws s3 cp s3://$BucketName/app.js "$LocalPath/app.js"
    aws s3 cp s3://$BucketName/brand.js "$LocalPath/brand.js"
    
    # Download assets
    aws s3 sync s3://$BucketName/assets/ "$LocalPath/assets/" --exclude "customer-documents/*"
    
    Write-Host "Download complete!" -ForegroundColor Green
}

function Upload-S3Files {
    Write-Host "Uploading files from $LocalPath to S3..." -ForegroundColor Cyan
    
    if (-not (Test-Path $LocalPath)) {
        Write-Host "Error: Local path $LocalPath does not exist!" -ForegroundColor Red
        return
    }
    
    # Upload with cache control
    Get-ChildItem -Path $LocalPath -File | ForEach-Object {
        $key = $_.Name
        Write-Host "Uploading $key..." -ForegroundColor Yellow
        
        aws s3 cp $_.FullName "s3://$BucketName/$key" `
            --cache-control "public, max-age=31536000, immutable" `
            --content-type "application/javascript"
    }
    
    # Upload assets
    if (Test-Path "$LocalPath/assets") {
        aws s3 sync "$LocalPath/assets/" "s3://$BucketName/assets/" `
            --exclude "customer-documents/*" `
            --cache-control "public, max-age=31536000, immutable"
    }
    
    Write-Host "Upload complete!" -ForegroundColor Green
}

function Update-Documentation {
    Write-Host "Updating documentation..." -ForegroundColor Cyan
    
    $structureFile = "s3-structure.txt"
    aws s3 ls s3://$BucketName --recursive > $structureFile
    
    Write-Host "S3 structure saved to $structureFile" -ForegroundColor Green
    Write-Host "Please review and update README.md accordingly." -ForegroundColor Yellow
}

# Execute action
switch ($Action) {
    "list" { List-S3Structure }
    "download" { Download-S3Files }
    "upload" { Upload-S3Files }
    "document" { Update-Documentation }
}
```

## Save and Use the Script

1. **Save the script:**
   ```powershell
   # Save to file
   $scriptPath = "C:\Users\Mathias\dfj-salesforce\feature-customer-portal\aws-infrastructure\s3-bucket-structure\sync-s3-structure.ps1"
   # Copy the script content above to this file
   ```

2. **Run the script:**
   ```powershell
   # List structure
   .\sync-s3-structure.ps1 -Action list
   
   # Download files
   .\sync-s3-structure.ps1 -Action download -LocalPath "./temp-s3-download"
   
   # Upload files
   .\sync-s3-structure.ps1 -Action upload -LocalPath "./dist"
   
   # Update documentation
   .\sync-s3-structure.ps1 -Action document
   ```

## CloudFront Invalidation After Upload

After uploading files, invalidate CloudFront cache:

```powershell
# Get CloudFront distribution ID
$distributionId = "E123456EXAMPLE" # Replace with actual distribution ID

# Invalidate app.js and brand.js
aws cloudfront create-invalidation `
  --distribution-id $distributionId `
  --paths "/app.js" "/brand.js"

# Invalidate all assets
aws cloudfront create-invalidation `
  --distribution-id $distributionId `
  --paths "/assets/*"

# Check invalidation status
aws cloudfront list-invalidations --distribution-id $distributionId
```

## Automated CI/CD Pipeline (GitHub Actions)

Add this workflow to `.github/workflows/deploy-s3.yml`:

```yaml
name: Deploy to S3

on:
  push:
    branches:
      - main
    paths:
      - 'feature-customer-portal/spa-frontend/dist/**'

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
      
      - name: Sync to S3
        run: |
          aws s3 sync feature-customer-portal/spa-frontend/dist/ s3://dfj-docs-prod/ \
            --exclude "customer-documents/*" \
            --cache-control "public, max-age=31536000, immutable" \
            --delete
      
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

## Security Checklist

Before syncing, verify:

- [ ] Customer documents are excluded from sync
- [ ] IAM permissions are properly scoped
- [ ] S3 bucket policies are correctly configured
- [ ] CloudFront distribution is properly secured
- [ ] CORS headers are configured
- [ ] SSL certificate is valid
- [ ] Access logs are enabled

## Troubleshooting

### Access Denied Error

```powershell
# Check IAM permissions
aws iam get-user

# Verify bucket policy
aws s3api get-bucket-policy --bucket dfj-docs-prod
```

### CloudFront Not Updating

```powershell
# Check invalidation status
aws cloudfront get-invalidation --distribution-id E123456EXAMPLE --id INVALIDATION_ID

# Wait for invalidation to complete (may take 10-15 minutes)
```

### CORS Issues

```powershell
# Get current CORS configuration
aws s3api get-bucket-cors --bucket dfj-docs-prod

# Update CORS configuration
aws s3api put-bucket-cors --bucket dfj-docs-prod --cors-configuration file://cors.json
```

## Related Documentation

- [Main S3 Structure README](./README.md)
- [AWS Infrastructure Overview](../README.md)
- [SPA Frontend Deployment](../../spa-frontend/README.md)
