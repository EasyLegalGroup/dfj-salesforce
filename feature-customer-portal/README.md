# Customer Portal Feature

## 📋 Overview

The Customer Portal is a comprehensive solution that enables clients of Din Familiejurist to interact with their legal cases, documents, and communicate with legal advisors through a secure web portal. The system integrates Salesforce backend services with an AWS-hosted SPA (Single Page Application).

## 🎯 Purpose

**Primary Goals:**
- Enable clients to view and manage their legal journal/case information
- Provide secure document upload, viewing, and approval capabilities
- Facilitate real-time communication between clients and legal advisors via chat
- Streamline document workflow and client approval processes

**Key Features:**
1. **Simplified Chat** (`simplifiedChat` LWC)
   - Real-time messaging between clients and legal team
   - Message history and threading
   - Attachment support for documents
   - Email notifications for new messages

2. **Journal Document Console** (`journalDocConsole` LWC)
   - Document viewing and management interface
   - Client document approval workflow
   - Secure document access via token-based authentication
   - PDF preview and download capabilities

3. **Secure Client Access**
   - Token-based authentication for external client access
   - Time-limited access tokens with expiration
   - Impersonation support for client login simulation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Browser                          │
│  (Customer Portal SPA - React/Vue.js hosted on AWS S3/CloudFront)│
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ HTTPS API Calls
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS API Gateway                              │
│  - REST API endpoints                                           │
│  - Authentication & Authorization                               │
│  - Rate limiting & throttling                                   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ Invokes
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Lambda Functions                         │
│  - Salesforce API integration                                   │
│  - Business logic & data transformation                         │
│  - Document processing                                          │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ REST API / SOAP API
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Salesforce Platform                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Lightning Web Components (LWC)                          │   │
│  │  - simplifiedChat: Chat interface                       │   │
│  │  - journalDocConsole: Document management UI            │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Apex Classes                                            │   │
│  │  - SimplifiedChatService: Chat message CRUD             │   │
│  │  - ChatService: Advanced chat with Slack integration   │   │
│  │  - ClientImpersonationService: Secure token management │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Custom Objects                                          │   │
│  │  - ChatMessage__c: Chat message records                │   │
│  │  - Journal__c: Legal case/journal records              │   │
│  │  - Journal_Access_Token__c: Client access tokens       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
feature-customer-portal/
├── README.md                           # This file
├── ARCHITECTURE.md                     # Detailed architecture documentation
├── DEPLOYMENT.md                       # Deployment instructions
│
├── salesforce/                         # Salesforce metadata
│   └── main/default/
│       ├── lwc/
│       │   ├── simplifiedChat/         # Chat component
│       │   └── journalDocConsole/      # Document console component
│       ├── classes/
│       │   ├── SimplifiedChatService.cls          # Chat service
│       │   ├── SimplifiedChatServiceTest.cls      # Chat tests
│       │   ├── ChatService.cls                    # Advanced chat with Slack
│       │   └── ClientImpersonationService.cls     # Token management
│       └── objects/
│           ├── ChatMessage__c/         # Chat message object
│           ├── Journal__c/             # Legal case object
│           └── Journal_Access_Token__c/ # Access token object
│
├── aws-infrastructure/                 # AWS infrastructure as code
│   ├── lambda-functions/               # Lambda function code
│   │   ├── salesforce-api-proxy/       # Salesforce API proxy
│   │   ├── document-processor/         # Document processing
│   │   └── authentication-service/     # Token validation
│   ├── api-gateway/                    # API Gateway configurations
│   │   ├── openapi-spec.yaml           # API specification
│   │   └── routes.json                 # Route definitions
│   ├── terraform/                      # Terraform IaC
│   │   ├── main.tf                     # Main Terraform config
│   │   ├── variables.tf                # Variables
│   │   └── outputs.tf                  # Outputs
│   └── cloudformation/                 # CloudFormation templates (alternative)
│       └── customer-portal-stack.yaml
│
└── spa-frontend/                       # Single Page Application
    ├── src/                            # Source code
    │   ├── components/                 # React/Vue components
    │   ├── services/                   # API service layer
    │   ├── store/                      # State management
    │   └── utils/                      # Utilities
    ├── public/                         # Static assets
    │   ├── index.html
    │   └── assets/
    ├── dist/                           # Build output (for S3 upload)
    ├── package.json                    # NPM dependencies
    ├── vite.config.js                  # Build configuration
    └── README.md                       # Frontend documentation
```

## 🚀 Getting Started

### Prerequisites

- **Salesforce Access**: System Administrator access to deploy metadata
- **AWS Account**: With permissions for Lambda, API Gateway, S3, CloudFront
- **Development Tools**:
  - Salesforce CLI (`sf` or `sfdx`)
  - AWS CLI
  - Node.js & npm (for SPA frontend)
  - Terraform or CloudFormation (for infrastructure)

### Quick Start

1. **Deploy Salesforce Components**
   ```bash
   # From repository root
   sf project deploy start --source-dir feature-customer-portal/salesforce
   ```

2. **Deploy AWS Infrastructure**
   ```bash
   # Using Terraform
   cd feature-customer-portal/aws-infrastructure/terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Build & Deploy SPA Frontend**
   ```bash
   cd feature-customer-portal/spa-frontend
   npm install
   npm run build
   aws s3 sync dist/ s3://your-portal-bucket/
   ```

## 🔐 Security Considerations

- **Client Authentication**: Token-based with expiration times
- **API Gateway**: WAF rules, rate limiting, throttling
- **Salesforce Sharing**: Field-level and record-level security
- **Data Encryption**: In-transit (TLS) and at-rest (S3, Salesforce)
- **CORS**: Properly configured for SPA domain
- **Secrets Management**: AWS Secrets Manager for Salesforce credentials

## 📊 Key Salesforce Components

### Objects

| Object | Purpose | Key Fields |
|--------|---------|------------|
| `ChatMessage__c` | Stores chat messages between clients and advisors | Body__c, Is_Inbound__c, Parent_Record__c |
| `Journal__c` | Represents a legal case/journal | Account__c, Market_Unit__c, Access_Token__c |
| `Journal_Access_Token__c` | Manages secure client access tokens | Token__c, Expires_At__c, Is_Revoked__c |

### Apex Classes

| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `SimplifiedChatService` | Lightweight chat operations | getMessages(), createMessage() |
| `ChatService` | Advanced chat with Slack integration | sendMessageWithSlackNotification() |
| `ClientImpersonationService` | Token generation & validation | generateAccessToken(), validateToken() |

### Lightning Web Components

| Component | Purpose | Used By |
|-----------|---------|---------|
| `simplifiedChat` | Chat interface for messaging | Journal record pages, portal |
| `journalDocConsole` | Document viewing & approval | Journal record pages, portal |

## 🔄 Development Workflow

1. **Make Changes in Sandbox**
   - Use Integration Sandbox for development
   - Test LWC components locally with `sf lightning lwc start`

2. **Create DevOps Center Work Item**
   - Link to specific feature enhancements
   - Associate commits with Work Item

3. **Deploy Through Pipeline**
   - Integration Sandbox → Production

4. **AWS Infrastructure Changes**
   - Update Terraform configurations
   - Test in dev/staging AWS account first
   - Apply to production after approval

5. **SPA Frontend Updates**
   - Develop locally with API mock/proxy
   - Build and deploy to S3
   - Invalidate CloudFront cache

## 📞 Support & Contact

For questions or issues related to the Customer Portal:

- **Salesforce Components**: Salesforce development team
- **AWS Infrastructure**: DevOps/Infrastructure team
- **SPA Frontend**: Frontend development team

## 📚 Additional Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Detailed system architecture
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Step-by-step deployment guide
- [API_DOCUMENTATION.md](./aws-infrastructure/api-gateway/API_DOCUMENTATION.md) - API endpoints & contracts
- [FRONTEND_README.md](./spa-frontend/README.md) - Frontend development guide

## 🔖 Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-11-08 | Initial structure and documentation |

## 📄 License

Internal use only - Din Familiejurist / Easy Legal Group
