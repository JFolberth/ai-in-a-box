# Infrastructure Guide

This guide provides detailed information about the [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) SPA infrastructure, architecture decisions, and deployment patterns.

## 🏗️ Architecture Overview

The Azure AI Foundry SPA uses a **modular, multi-resource group architecture** designed for separation of concerns, security, and scalability.

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
│  │  │ [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)  │    │  │  │    [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/)         │  │ │
│  │  │ (SPA Hosting)   │    │  │  │  (AI Foundry Proxy)     │  │ │
│  │  └─────────────────┘    │  │  └─────────────────────────┘  │ │
│  │                         │  │                                │ │
│  │  ┌─────────────────┐    │  │  ┌─────────────────────────┐  │ │
│  │  │ [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)    │    │  │  │   [Azure Storage](https://learn.microsoft.com/en-us/azure/storage/)       │  │ │
│  │  │  (Frontend)     │    │  │  │  (Function Storage)     │  │ │
│  │  └─────────────────┘    │  │  └─────────────────────────┘  │ │
│  └─────────────────────────┘  │                                │ │
│                               │  ┌─────────────────────────┐  │ │
│                               │  │    Application Insights         │  │ │
│                               │  │     (Backend)           │  │ │
│                               │  └─────────────────────────┘  │ │
│                               │                                │ │
│                               │  ┌─────────────────────────┐  │ │
│                               │  │   [App Service Plan](https://learn.microsoft.com/en-us/azure/app-service/overview-hosting-plans)      │  │ │
│                               │  │    (Consumption)        │  │ │
│                               │  └─────────────────────────┘  │ │
│                               └─────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │            Shared [Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)                   │ │
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
- **System-assigned [managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)** for service authentication
- **Least privilege access** with [Azure AI Developer role](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-ai-developer)
- **No secrets in configuration** - managed identity only
- **[CORS policies](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings#cors)** restrict cross-origin access

### 3. **Scalability and Performance**
- **Consumption-based Azure Functions** scales automatically
- **Static website hosting** with global [Azure CDN](https://learn.microsoft.com/en-us/azure/cdn/) capability
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
| [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/) | `Microsoft.Web/staticSites` | Modern SPA hosting with built-in CI/CD |
| Application Insights | `Microsoft.Insights/components` | Frontend monitoring and analytics |

**Key Features**:
- Native SPA routing and fallback handling
- HTTPS-only access with automatic SSL certificates
- Built-in global [Azure CDN](https://learn.microsoft.com/en-us/azure/cdn/) for optimal performance
- Integrated CI/CD with preview environments

### Backend Resource Group  
**Name Pattern**: `rg-ai-foundry-spa-backend-{env}-{token}`

| Resource | Type | Purpose |
|----------|------|---------|
| [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) | `Microsoft.Web/sites` | Azure AI Foundry proxy and API |
| [Azure Storage](https://learn.microsoft.com/en-us/azure/storage/) Account | `Microsoft.Storage/storageAccounts` | Azure Functions runtime storage |
| [App Service Plan](https://learn.microsoft.com/en-us/azure/app-service/overview-hosting-plans) | `Microsoft.Web/serverfarms` | Azure Functions hosting plan |
| Application Insights | `Microsoft.Insights/components` | Backend monitoring and telemetry |

**Key Features**:
- [.NET 8](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8) Isolated runtime for performance
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
- **[Azure AI Developer](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-ai-developer)** role on Azure AI Foundry resource
  - Scope: Specific Azure AI Foundry resource
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
- Azure Static Web Apps: HTTPS-only configuration
- Azure Functions: HTTPS redirect enabled
- No HTTP traffic allowed in production

## 🏗️ Infrastructure as Code

### Azure Verified Modules (AVM)

The project uses [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) for:
- **Consistent resource provisioning**
- **Best practice configurations**
- **Reduced boilerplate code**
- **Community-maintained standards**

#### AVM Modules Used

The following table lists all Azure Verified Modules implemented in this project:

| Module | Version | Purpose | Official Documentation |
|--------|---------|---------|------------------------|
| **Resource Groups** | 0.4.0 | Create and manage resource groups for multi-RG architecture | [avm/res/resources/resource-group](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/resources/resource-group) |
| **Application Insights** | 0.6.0 | Monitoring and telemetry for frontend and backend components | [avm/res/insights/component](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/insights/component) |
| **Azure Functions** | 0.16.0 | Serverless compute for Azure AI Foundry proxy backend | [avm/res/web/site](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/web/site) |
| **Storage Accounts** | 0.20.0 | Azure Functions runtime storage with secure configuration | [avm/res/storage/storage-account](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/storage/storage-account) |
| **Log Analytics Workspace** | 0.9.0 | Centralized logging and monitoring workspace | [avm/res/operational-insights/workspace](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/operational-insights/workspace) |
| **Azure Static Web Apps** | 0.5.0 | Modern SPA hosting for the frontend application | [avm/res/web/static-site](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/web/static-site) |
| **App Service Plans** | 0.4.1 | Compute hosting plans for Azure Functions | [avm/res/web/serverfarm](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/web/serverfarm) |

#### AVM Benefits for This Project

- **Security by Default**: All modules include security best practices and managed identity support
- **Standardized Configuration**: Consistent parameter names and resource configurations across environments
- **Version Control**: Pinned module versions ensure deployment reproducibility
- **Community Support**: Modules are maintained by Microsoft and the Azure community
- **Compliance**: Built-in configurations meet [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/) principles

#### Usage Examples

**Resource Group Creation (Orchestrator)**
```bicep
module frontendResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'frontend-rg-deployment'
  params: {
    name: frontendResourceGroupName
    location: location
    tags: union(tags, {
      Component: 'Frontend'
      ResourceType: 'Storage-StaticWebsite'
    })
  }
}
```

**Application Insights with Log Analytics Integration**
```bicep
module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'backend-applicationInsights'
  params: {
    name: resourceNames.applicationInsights
    location: location
    kind: 'web'
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspace.id
    tags: union(tags, {
      Component: 'Backend-ApplicationInsights'
    })
  }
}
```

**Function App with Managed Identity**
```bicep
module functionApp 'br/public:avm/res/web/site:0.16.0' = {
  name: 'backend-functionApp'
  params: {
    name: resourceNames.functionApp
    location: location
    kind: 'functionapp'
    managedIdentities: {
      systemAssigned: true
    }
    tags: union(tags, {
      Component: 'Backend-FunctionApp'
    })
  }
}
```

#### Module Structure
```
infra/
├── main-orchestrator.bicep          # Main deployment orchestrator
├── dev-orchestrator.parameters.bicepparam  # Environment parameters
├── modules/
│   └── log-analytics.bicep          # Log Analytics Workspace module
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

#### Log Analytics Workspace Module

The project includes a dedicated `infra/modules/log-analytics.bicep` module using Azure Verified Modules (AVM):

**Module Features:**
- **Azure Verified Module**: Uses `br/public:avm/res/operational-insights/workspace` for consistency
- **Configurable retention**: 30-730 day retention period (default: 30 days in environments, 90 days in orchestrator)
- **Flexible pricing**: Supports all Azure Log Analytics pricing tiers (default: PerGB2018)
- **Security options**: Configurable public network access for ingestion and query
- **Secure outputs**: Provides workspace ID and connection details for Application Insights integration (sensitive keys are not exposed)

**Usage Patterns:**
```bicep
// Optional workspace creation in orchestrator
module logAnalyticsWorkspace 'modules/log-analytics.bicep' = if (createLogAnalyticsWorkspace) {
  name: 'shared-log-analytics'
  scope: logAnalyticsResourceGroup
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    pricingTier: 'PerGB2018'
    retentionInDays: 90
    tags: tags
  }
}

// Existing workspace reference in environments
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}
```

**Deployment Options:**
- **Existing workspace**: Reference external Log Analytics workspace (`createLogAnalyticsWorkspace = false`)
- **New workspace**: Create dedicated workspace using the module (`createLogAnalyticsWorkspace = true`)

**Testing the Module:**
```bash
# Test with existing workspace (default)
az deployment sub create \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam \
  --parameters createLogAnalyticsWorkspace=false

# Test with new workspace creation
az deployment sub create \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam \
  --parameters createLogAnalyticsWorkspace=true
```

**Security Best Practices:**
- **No shared keys**: The module does not expose Log Analytics shared keys in outputs for security
- **Managed identity**: Application Insights uses workspace resource ID for secure authentication
- **Connection strings**: Prefer Application Insights connection strings over direct Log Analytics access
- **RBAC-based access**: Use Azure RBAC for Log Analytics workspace access control

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
