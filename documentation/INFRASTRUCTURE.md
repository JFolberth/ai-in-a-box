# Infrastructure Guide

This guide provides detailed information about the AI Foundry SPA infrastructure, architecture decisions, and deployment patterns.

## 🏗️ Architecture Overview

The AI Foundry SPA uses a **modular, multi-resource group architecture** designed for separation of concerns, security, and scalability.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────────────┐ │
│  │   Frontend Resource     │  │    Backend Resource Group      │ │
│  │       Group             │  │                                │ │
│  │                         │  │                                │ │
│  │  ┌─────────────────┐    │  │  ┌─────────────────────────┐  │ │
│  │  │ Static Web App  │    │  │  │    Function App         │  │ │
│  │  │ (SPA Hosting)   │    │  │  │  (AI Foundry Proxy)     │  │ │
│  │  └─────────────────┘    │  │  └─────────────────────────┘  │ │
│  │                         │  │                                │ │
│  │  ┌─────────────────┐    │  │  ┌─────────────────────────┐  │ │
│  │  │ App Insights    │    │  │  │   Storage Account       │  │ │
│  │  │  (Frontend)     │    │  │  │  (Function Storage)     │  │ │
│  │  └─────────────────┘    │  │  └─────────────────────────┘  │ │
│  └─────────────────────────┘  │                                │ │
│                               │  ┌─────────────────────────┐  │ │
│                               │  │    App Insights         │  │ │
│                               │  │     (Backend)           │  │ │
│                               │  └─────────────────────────┘  │ │
│                               │                                │ │
│                               │  ┌─────────────────────────┐  │ │
│                               │  │   App Service Plan      │  │ │
│                               │  │    (Consumption)        │  │ │
│                               │  └─────────────────────────┘  │ │
│                               └─────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │            Shared Log Analytics Workspace                   │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   AI Foundry Service                        │ │
│  │              (External Resource)                            │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Design Principles

### 1. **Separation of Concerns**
- **Frontend RG**: Static hosting and client-side monitoring
- **Backend RG**: Compute, storage, and server-side monitoring
- **Clear boundaries** between presentation and business logic

### 2. **Security by Design**
- **System-assigned managed identity** for service authentication
- **Least privilege access** with Azure AI Developer role
- **No secrets in configuration** - managed identity only
- **CORS policies** restrict cross-origin access

### 3. **Scalability and Performance**
- **Consumption-based Function App** scales automatically
- **Static website hosting** with global CDN capability
- **Separate monitoring** allows independent scaling insights

### 4. **Cost Optimization**
- **Consumption pricing** for compute (pay-per-execution)
- **Standard storage** for static website hosting
- **Shared Log Analytics** reduces monitoring costs

## 📋 Resource Groups

### Frontend Resource Group
**Name Pattern**: `rg-ai-foundry-spa-frontend-{env}-{token}`

| Resource | Type | Purpose |
|----------|------|---------|
| Static Web App | `Microsoft.Web/staticSites` | Modern SPA hosting with built-in CI/CD |
| Application Insights | `Microsoft.Insights/components` | Frontend monitoring and analytics |

**Key Features**:
- Native SPA routing and fallback handling
- HTTPS-only access with automatic SSL certificates
- Built-in global CDN for optimal performance
- Integrated CI/CD with preview environments

### Backend Resource Group  
**Name Pattern**: `rg-ai-foundry-spa-backend-{env}-{token}`

| Resource | Type | Purpose |
|----------|------|---------|
| Function App | `Microsoft.Web/sites` | AI Foundry proxy and API |
| Storage Account | `Microsoft.Storage/storageAccounts` | Function App runtime storage |
| App Service Plan | `Microsoft.Web/serverfarms` | Function App hosting plan |
| Application Insights | `Microsoft.Insights/components` | Backend monitoring and telemetry |

**Key Features**:
- .NET 8 Isolated runtime for performance
- System-assigned managed identity for security
- CORS configuration for frontend integration
- Consumption plan for cost efficiency

## 🔐 Security Architecture

### Identity and Access Management

#### System-Assigned Managed Identity
```bicep
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  identity: {
    type: 'SystemAssigned'
  }
}
```

#### Role Assignments
- **Azure AI Developer** role on AI Foundry resource
  - Scope: Specific AI Foundry resource
  - Permissions: Create agents, send messages, manage conversations
  - Principle: Least privilege access

```bicep
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiFoundryResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee') // Azure AI Developer
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Network Security

#### CORS Configuration
- **Development**: Allows localhost:5173, localhost:4173
- **Production**: Allows specific static website domain
- **No credentials**: Maintains stateless authentication

#### HTTPS Enforcement
- Static website: HTTPS-only configuration
- Function App: HTTPS redirect enabled
- No HTTP traffic allowed in production

## 🏗️ Infrastructure as Code

### Azure Verified Modules (AVM)

The project uses AVM modules for:
- **Consistent resource provisioning**
- **Best practice configurations**
- **Reduced boilerplate code**
- **Community-maintained standards**

#### Module Structure
```
infra/
├── main-orchestrator.bicep          # Main deployment orchestrator
├── dev-orchestrator.parameters.bicepparam  # Environment parameters
└── environments/
    ├── frontend/
    │   ├── main.bicep               # Frontend infrastructure
    │   └── environment.yaml        # ADE configuration
    └── backend/
        ├── main.bicep               # Backend infrastructure
        ├── rbac.bicep               # Backend RBAC assignments
        └── environment.yaml         # ADE configuration
```

### Deployment Strategy

#### 1. Subscription-Scoped Deployment
```bicep
targetScope = 'subscription'

// Creates resource groups and deploys resources
resource frontendRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: frontendResourceGroupName
  location: location
}
```

#### 2. Modular Resource Deployment
```bicep
// Deploy frontend resources
module frontend 'modules/frontend.bicep' = {
  scope: frontendRG
  name: 'ai-foundry-spa-frontend'
  params: {
    // Frontend-specific parameters
  }
}

// Deploy backend resources  
module backend 'modules/backend.bicep' = {
  scope: backendRG
  name: 'ai-foundry-spa-backend'
  params: {
    // Backend-specific parameters
  }
}
```

#### 3. Environment-Specific RBAC Assignments
```bicep
// RBAC assignments are now handled within environment modules
// Example: Backend RBAC is managed in environments/backend/rbac.bicep
module functionAppAiFoundryRoleAssignment 'rbac.bicep' = {
  name: 'function-app-ai-foundry-rbac'
  scope: resourceGroup(aiFoundryResourceGroupName)
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    aiFoundryResourceId: aiFoundryInstance.id
    roleDefinitionId: 'Azure AI Developer'
  }
}
```

## 📊 Monitoring and Observability

### Application Insights Configuration

#### Frontend Monitoring
- **Page views** and user interactions
- **JavaScript errors** and performance metrics  
- **Custom events** for AI conversation tracking
- **User flows** and conversion analytics

#### Backend Monitoring
- **Function execution** metrics and duration
- **Dependency tracking** for AI Foundry calls
- **Exception logging** and error rates
- **Performance counters** and resource utilization

### Log Analytics Integration

#### Shared Workspace Benefits
- **Consolidated logging** across all services
- **Cross-service correlation** for troubleshooting
- **Unified queries** and dashboards
- **Cost optimization** through shared infrastructure

#### KQL Queries for Common Scenarios
```kusto
// Function App errors in last 24 hours
FunctionAppLogs
| where TimeGenerated > ago(24h)
| where Level == "Error"
| summarize Count = count() by bin(TimeGenerated, 1h)

// AI Foundry response times
AppDependencies  
| where TimeGenerated > ago(1h)
| where Type == "Http"
| where Target contains "cognitiveservices.azure.com"
| summarize avg(Duration) by bin(TimeGenerated, 5m)
```

## 🚀 Deployment Patterns

### Environment Strategy

#### Development Environment
- **Single deployment** for rapid iteration
- **Local development** with Azurite emulation
- **Minimal monitoring** to reduce costs
- **Relaxed CORS** for development flexibility

#### Production Environment  
- **Blue-green deployment** capability
- **Comprehensive monitoring** and alerting
- **Restricted CORS** for security
- **Custom domain** with SSL certificates

### CI/CD Integration

#### GitHub Actions Workflow
```yaml
name: Deploy to Azure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy Infrastructure
        run: |
          az deployment sub create \
            --template-file infra/main-orchestrator.bicep \
            --parameters infra/prod-orchestrator.parameters.bicepparam
```

## 🔧 Resource Configuration

### Static Web App (Frontend)
```bicep
staticSiteBuild: {
  skipGithubActionWorkflowGeneration: true
  appLocation: '/dist'
  outputLocation: ''
}
sku: {
  name: 'Free'
  tier: 'Free'
}
```

### Function App (Backend)
```bicep
siteConfig: {
  cors: {
    allowedOrigins: corsAllowedOrigins
    supportCredentials: false
  }
  appSettings: [
    {
      name: 'AI_FOUNDRY_ENDPOINT'
      value: aiFoundryEndpoint
    }
    {
      name: 'AI_FOUNDRY_DEPLOYMENT'  
      value: aiFoundryDeployment
    }
  ]
}
```

## 🔍 Cost Analysis

### Resource Costs (Estimated Monthly)

| Resource | Tier | Estimated Cost |
|----------|------|----------------|
| Function App (Consumption) | Pay-per-execution | $5-20 |
| Storage (Frontend) | Standard LRS | $1-5 |
| Storage (Backend) | Standard LRS | $1-3 |
| Application Insights | Pay-as-you-go | $5-15 |
| Log Analytics | Pay-per-GB | $2-10 |
| **Total** | | **$14-53** |

### Cost Optimization Tips
- Use **consumption pricing** for low-traffic scenarios
- Configure **data retention policies** for logs
- Implement **sampling** for Application Insights
- Monitor **storage usage** and clean up old data

## 🔗 Related Documentation

- [Setup Guide](SETUP.md) - Deployment instructions
- [Configuration Guide](CONFIGURATION.md) - Detailed configuration options
- [Development Guide](DEVELOPMENT.md) - Local development setup
- [Multi-RG Architecture](MULTI_RG_ARCHITECTURE.md) - Specific architecture decisions
- [Azure Deployment Environments](AZURE_DEPLOYMENT_ENVIRONMENTS.md) - ADE catalog definitions and schema compliance
