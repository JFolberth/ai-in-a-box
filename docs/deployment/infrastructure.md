# Infrastructure Reference

This guide provides detailed information about the Azure AI Foundry SPA infrastructure, architecture decisions, and deployment patterns.

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
│  │  │ Azure Static    │    │  │  │    Azure Functions      │  │ │
│  │  │   Web Apps      │    │  │  │  (AI Foundry Proxy)     │  │ │
│  │  │ (SPA Hosting)   │    │  │  └─────────────────────────┘  │ │
│  │  └─────────────────┘    │  │                                │ │
│  │                         │  │  ┌─────────────────────────┐  │ │
│  │  ┌─────────────────┐    │  │  │   Azure Storage         │  │ │
│  │  │ Application     │    │  │  │  (Function Storage)     │  │ │
│  │  │   Insights      │    │  │  └─────────────────────────┘  │ │
│  │  │  (Frontend)     │    │  │                                │ │
│  │  └─────────────────┘    │  │  ┌─────────────────────────┐  │ │
│  └─────────────────────────┘  │  │    Application Insights │  │ │
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

## 🎯 Architecture Principles

### 1. **Separation of Concerns**
- **Frontend Resources**: Static hosting and frontend monitoring
- **Backend Resources**: Compute, storage, and backend monitoring  
- **Cross-Resource Group RBAC**: Secure access across boundaries

### 2. **Security by Design**
- **Managed Identity**: No stored credentials, automatic token handling
- **Least Privilege Access**: Azure AI Developer role (not Contributor)
- **Network Security**: CORS, HTTPS-only, controlled access patterns

### 3. **Scalability and Performance**
- **Consumption-Based**: Resources scale automatically with demand
- **Global CDN**: Static Web Apps provide worldwide content delivery
- **Serverless**: No always-on costs, pay only for usage

### 4. **Operational Excellence**
- **Centralized Logging**: Shared Log Analytics workspace
- **Distributed Monitoring**: Application Insights per component
- **Infrastructure as Code**: Complete Bicep automation

## 🏗️ Component Details

### Frontend Resource Group

**Resources:**
- **Azure Static Web Apps**: Hosts the JavaScript SPA
- **Application Insights**: Frontend-specific telemetry
- **Custom Domain (Optional)**: Production custom domain support

**Naming Convention:**
```
Resource Group: rg-ai-foundry-spa-frontend-{env}-{region}
Static Web App: stapp-ai-foundry-spa-frontend-{env}-{uniqueString}
App Insights: appi-ai-foundry-spa-frontend-{env}-{uniqueString}
```

**Key Features:**
- **Global CDN**: Automatic worldwide content distribution
- **SSL/TLS**: Automatic HTTPS with managed certificates
- **Custom Domains**: Support for production domain names
- **Build Integration**: Automatic build and deployment from Git

### Backend Resource Group

**Resources:**
- **Azure Functions**: Serverless API proxy to AI Foundry
- **Azure Storage**: Function App storage (required)
- **App Service Plan**: Consumption plan (serverless)
- **Application Insights**: Backend-specific telemetry

**Naming Convention:**
```
Resource Group: rg-ai-foundry-spa-backend-{env}-{region}
Function App: func-ai-foundry-spa-backend-{env}-{uniqueString}
Storage Account: stfnbackspa{uniqueString}
App Service Plan: asp-ai-foundry-spa-backend-{env}-{uniqueString}
App Insights: appi-ai-foundry-spa-backend-{env}-{uniqueString}
```

**Key Features:**
- **Consumption Plan**: Automatic scaling, no idle costs
- **Managed Identity**: Secure AI Foundry access without credentials
- **CORS Configuration**: Allows frontend domain access
- **Application Insights**: Detailed performance and error tracking

### Shared Resources

**Log Analytics Workspace:**
- **Centralized Logging**: Single workspace for all components
- **Cross-Resource Queries**: Correlate frontend and backend logs
- **Retention Policies**: Configurable data retention
- **Access Control**: Shared read access across teams

**AI Foundry Integration:**
- **Flexible Deployment**: Can use existing resources OR create new ones via `createAiFoundryResourceGroup` parameter
- **Secure Access**: Via managed identity and RBAC
- **Agent Configuration**: "AI in A Box" agent
- **Connection Management**: Resilient connection handling
- **Automated Setup**: Full AI Foundry lifecycle automation available

## 🔧 Infrastructure Deployment

### Bicep Module Structure

```
infra/
├── main-orchestrator.bicep           # Main orchestrator (subscription scope)
├── dev-orchestrator.parameters.bicepparam  # Parameters for orchestrator
└── modules/
    ├── frontend.bicep               # Frontend resources module
    ├── backend.bicep                # Backend resources module
    └── rbac.bicep                   # Cross-RG RBAC assignments
```

### Deployment Process

**1. Subscription-Level Orchestrator**
- Creates resource groups
- Orchestrates module deployments
- Handles cross-resource group dependencies
- Manages shared resources

**2. Frontend Module**
- Deploys Static Web Apps
- Configures Application Insights
- Sets up monitoring and logging

**3. Backend Module**  
- Deploys Function App and dependencies
- Configures storage and compute
- Sets up Application Insights

**4. RBAC Module**
- Assigns managed identity permissions
- Configures Azure AI Developer role
- Handles cross-resource group access

### Key Deployment Features

**Deterministic Naming:**
```bicep
// Generates consistent, unique names
var backendNameSuffix = toLower('${applicationName}-backend-${environmentName}-${regionReference[location]}')
var uniqueSuffix = uniqueString(subscription().id, applicationName, 'backend')
var functionAppName = 'func-${backendNameSuffix}-${uniqueSuffix}'
```

**Environment Support:**
- **Development**: Basic configuration, shared resources
- **Staging**: Production-like, separate resource groups
- **Production**: High availability, premium features

**Region Support:**
```bicep
var regionReference = {
  centralus: 'cus'
  eastus: 'eus'  
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
}
```

## 🔒 Security Architecture

### AI Foundry Deployment Options

**AI Foundry Deployment Options:**
The orchestrator supports two deployment models for AI Foundry resources:

1. **Use Existing Resources** (`createAiFoundryResourceGroup: false`)
   - Reference pre-existing AI Foundry workspace and project
   - Faster deployment, leverages existing setup
   - Ideal for shared environments

2. **Create New Resources** (`createAiFoundryResourceGroup: true`)
   - Orchestrator creates complete AI Foundry environment
   - Includes Cognitive Services, AI project, and model deployment
   - Ideal for isolated environments and new deployments

### Identity and Access Management

**Managed Identity Flow:**
1. Function App has system-assigned managed identity
2. Identity assigned Azure AI Developer role on AI Foundry
3. Function App accesses AI Foundry using identity tokens
4. No credentials stored in configuration

**RBAC Assignments:**
```bicep
// Least-privilege access
resource aiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryResource.id, functionAppIdentity.principalId, 'Azure AI Developer')
  scope: aiFoundryResource
  properties: {
    principalId: functionAppIdentity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/64702f94-c441-49e6-a78b-ef80e0188fee'
  }
}
```

### Network Security

**HTTPS Enforcement:**
- All endpoints require HTTPS
- Automatic SSL certificate management
- HTTP to HTTPS redirection

**CORS Configuration:**
```csharp
// Backend CORS settings
services.AddCors(options =>
{
    options.AddDefaultPolicy(builder =>
    {
        builder.WithOrigins(allowedOrigins)
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();
    });
});
```

**API Security:**
- Input validation on all endpoints
- Rate limiting (via Azure Functions)
- Request/response logging

## 📊 Monitoring and Observability

### Application Insights Strategy

**Distributed Telemetry:**
- **Frontend App Insights**: User interactions, page views, client errors
- **Backend App Insights**: API performance, dependencies, server errors
- **Correlation**: End-to-end request tracking across components

**Key Metrics Tracked:**
- **Performance**: Response times, throughput, availability
- **Usage**: Active users, feature adoption, conversion rates
- **Errors**: Exception rates, failure patterns, error details
- **Dependencies**: AI Foundry response times, external service health

**Custom Telemetry:**
```csharp
// Backend custom metrics
telemetryClient.TrackEvent("AIFoundryRequest", new Dictionary<string, string>
{
    ["AgentName"] = agentName,
    ["ThreadId"] = threadId,
    ["ResponseTime"] = responseTime.ToString()
});
```

### Log Analytics Integration

**Centralized Logging:**
```kusto
// Cross-component queries
requests
| join kind=inner (dependencies) on operation_Id
| where name contains "AIFoundry"
| project timestamp, operation_Id, requestDuration=duration, dependencyDuration=duration1
```

**Alert Rules:**
- **High Error Rate**: >5% error rate for 5 minutes
- **Slow Response**: >10 second average response time
- **AI Foundry Failures**: Dependency failures to AI service
- **Resource Health**: Function App availability monitoring

## 🚀 Scalability Considerations

### Automatic Scaling

**Azure Static Web Apps:**
- **Global CDN**: Automatic worldwide distribution
- **Edge Caching**: Static content cached at edge locations
- **Instant Scale**: No scaling configuration needed

**Azure Functions:**
- **Consumption Plan**: Scales from 0 to thousands of instances
- **Cold Start Optimization**: Optimized runtime initialization
- **Concurrent Execution**: Multiple requests per instance

### Performance Optimization

**Frontend Optimization:**
- **Code Splitting**: Lazy loading of application components
- **Asset Optimization**: Minified CSS/JS, optimized images
- **Caching Strategy**: Efficient browser and CDN caching

**Backend Optimization:**
- **Connection Pooling**: Efficient AI Foundry SDK usage
- **Response Caching**: Cache frequent AI responses (where appropriate)
- **Async Processing**: Non-blocking request handling

## 💰 Cost Optimization

### Consumption-Based Resources

**Azure Static Web Apps:**
- **Free Tier**: Development usage typically free
- **Standard Tier**: ~$9/month for advanced features

**Azure Functions:**
- **Consumption Plan**: Pay per execution and resource usage
- **First 1M executions free** per month
- **Typical cost**: $0-10/month for development

**Storage and Monitoring:**
- **Storage**: ~$1-5/month for Function App storage
- **Application Insights**: First 5GB free, then $2.30/GB
- **Log Analytics**: Pay per data ingestion and retention

### Cost Monitoring

**Budget Alerts:**
```bicep
// Budget monitoring
resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: 'ai-foundry-spa-budget'
  properties: {
    amount: 50  // $50/month alert
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: utcNow()
    }
    notifications: {
      actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [alertEmail]
      }
    }
  }
}
```

## 🔗 Related Documentation

- **[Deployment Guide](deployment-guide.md)** - Step-by-step deployment instructions
- **[Multi-Environment Setup](multi-environment.md)** - Dev/staging/production patterns
- **[Security Guide](../advanced/security.md)** - Advanced security considerations
- **[Monitoring Setup](../operations/monitoring.md)** - Detailed monitoring configuration

---

**Ready to deploy this infrastructure?** → Continue to [Deployment Guide](deployment-guide.md)

## 🏗️ Infrastructure as Code

### Azure Verified Modules (AVM)

The project uses Azure Verified Modules (AVM) for:
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
- **Compliance**: Built-in configurations meet Azure Well-Architected Framework principles

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

## 📚 Resource Provider API Reference

This section provides the current Azure Resource Provider API versions used in the AI Foundry SPA infrastructure, ensuring compatibility and access to the latest features.

### 🎯 Current API Versions (October 2025)

#### **Microsoft.Resources** - Resource Groups and Deployments
- **API Version**: `2024-03-01`
- **Used In**: `main-orchestrator.bicep`, all environment templates
- **Resources**: Resource Groups, Deployments, Subscriptions
- **Schema Reference**: [Microsoft.Resources API](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?pivots=deployment-language-bicep)

```bicep
// Resource Group Example
resource frontendRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: frontendResourceGroupName
  location: location
  tags: resourceTags
}
```

#### **Microsoft.Web** - App Services, Function Apps, Static Web Apps
- **API Version**: `2023-12-01` (stable)
- **Used In**: Backend and Frontend environments
- **Resources**: Function Apps, App Service Plans, Static Web Apps
- **Schema Reference**: [Microsoft.Web API](https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites?pivots=deployment-language-bicep)

```bicep
// Function App Example (via AVM)
module functionApp 'br/public:avm/res/web/site:0.19.3' = {
  name: 'backend-functionApp'
  params: {
    name: resourceNames.functionApp
    location: location
    kind: 'functionapp'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    // Uses latest AVM which abstracts API version management
  }
}

// App Service Plan Example (via AVM)  
module appServicePlan 'br/public:avm/res/web/serverfarm:0.5.0' = {
  name: 'backend-appServicePlan'
  params: {
    name: resourceNames.appServicePlan
    location: location
    kind: 'functionapp'
    workerTierName: 'FlexConsumption'
    skuName: 'FC1'
    reserved: true
  }
}

// Static Web App Example (via AVM)
module staticWebApp 'br/public:avm/res/web/static-site:0.9.3' = {
  name: 'frontend-staticWebApp'
  params: {
    name: resourceNames.staticWebApp
    location: location
    // AVM handles the underlying API version
  }
}
```

#### **Microsoft.Storage** - Storage Accounts
- **API Version**: `2024-01-01` (stable)
- **Used In**: Backend environment for Function App storage
- **Resources**: Storage Accounts, Blob Services, Queue Services
- **Schema Reference**: [Microsoft.Storage API](https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep)

```bicep
// Storage Account Example (via AVM)
module functionStorageAccount 'br/public:avm/res/storage/storage-account:0.20.0' = {
  name: 'backend-storageAccount'
  params: {
    name: resourceNames.storageAccount
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}
```

#### **Microsoft.Insights** - Application Insights
- **API Version**: `2020-02-02` (stable)
- **Used In**: Both frontend and backend environments
- **Resources**: Application Insights Components
- **Schema Reference**: [Microsoft.Insights API](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep)

```bicep
// Application Insights Example (via AVM)
module applicationInsights 'br/public:avm/res/insights/component:0.6.1' = {
  name: 'frontend-applicationInsights'
  params: {
    name: resourceNames.applicationInsights
    location: location
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    applicationType: 'web'
    kind: 'web'
  }
}
```

#### **Microsoft.OperationalInsights** - Log Analytics Workspaces
- **API Version**: `2023-09-01` (stable)
- **Used In**: Log Analytics module for centralized logging
- **Resources**: Workspaces, Data Sources, Saved Searches
- **Schema Reference**: [Microsoft.OperationalInsights API](https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep)

```bicep
// Log Analytics Workspace Example (via AVM)
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'logAnalyticsWorkspace'
  params: {
    name: resourceNames.logAnalyticsWorkspace
    location: location
    skuName: 'PerGB2018'
    dataRetention: 30
    dailyQuotaGb: 1
  }
}
```

#### **Microsoft.CognitiveServices** - AI Foundry Services
- **API Version**: `2024-06-01-preview` (preview - required for AI Foundry)
- **Used In**: AI Foundry module for cognitive services
- **Resources**: Cognitive Services Accounts, AI Projects, Model Deployments
- **Schema Reference**: [Microsoft.CognitiveServices API](https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts?pivots=deployment-language-bicep)

```bicep
// Cognitive Services Account Example
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: resourceNames.cognitiveServices
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: resourceNames.cognitiveServices
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: resourceTags
}
```

#### **Microsoft.Authorization** - RBAC Role Assignments
- **API Version**: `2022-04-01` (stable)
- **Used In**: RBAC assignment modules
- **Resources**: Role Assignments, Role Definitions
- **Schema Reference**: [Microsoft.Authorization API](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep)

```bicep
// Role Assignment Example (via AVM)
module rbacAssignment 'br/public:avm/ptn/authorization/role-assignment:0.1.1' = {
  name: 'functionApp-aiFoundry-rbac'
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionIdOrName: 'Azure AI Developer'
    resourceId: cognitiveServices.id
  }
}
```

### 🔄 Azure Verified Modules (AVM) Integration

The AI Foundry SPA infrastructure uses **Azure Verified Modules** which abstract and manage the underlying resource provider API versions:

#### **Current AVM Versions**
| **AVM Module** | **Version** | **Underlying Provider** | **API Version Managed** |
|----------------|-------------|------------------------|------------------------|
| `avm/res/resources/resource-group` | `0.4.2` | Microsoft.Resources | `2024-03-01` |
| `avm/res/web/serverfarm` | `0.5.0` | Microsoft.Web | `2023-12-01` |
| `avm/res/web/site` | `0.19.3` | Microsoft.Web | `2023-12-01` |
| `avm/res/web/static-site` | `0.9.3` | Microsoft.Web | `2023-12-01` |
| `avm/res/storage/storage-account` | `0.20.0` | Microsoft.Storage | `2024-01-01` |
| `avm/res/insights/component` | `0.6.1` | Microsoft.Insights | `2020-02-02` |
| `avm/res/operational-insights/workspace` | `0.12.0` | Microsoft.OperationalInsights | `2023-09-01` |

#### **Benefits of AVM Usage**
- ✅ **Automatic API Version Management**: AVM modules use tested, stable API versions
- ✅ **Best Practice Implementation**: Microsoft-verified configuration patterns
- ✅ **Security Compliance**: Built-in security configurations and recommendations
- ✅ **Consistent Updates**: Regular updates with latest Azure features
- ✅ **Reduced Complexity**: Simplified parameter interfaces for complex resources

### 🔍 API Version Validation Commands

#### **Check Current Provider Registrations**
```powershell
# List all registered resource providers
az provider list --output table

# Check specific provider registration
az provider show --namespace Microsoft.Web --output table
az provider show --namespace Microsoft.Storage --output table
az provider show --namespace Microsoft.Insights --output table
az provider show --namespace Microsoft.CognitiveServices --output table
```

#### **Register Required Providers**
```powershell
# Register providers if not already registered
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.Authorization
```

#### **Validate API Versions in Templates**
```powershell
# Validate Bicep templates with current API versions
az bicep build --file infra/main-orchestrator.bicep

# Check for API version warnings or errors
az deployment sub validate \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam \
  --location eastus2
```

### 📈 API Version Update Strategy

#### **Monitoring for Updates**
1. **AVM Module Updates**: Monitor [Azure Bicep Registry](https://azure.github.io/bicep-registry-modules/) for new AVM versions
2. **Provider API Updates**: Check [Azure REST API Reference](https://learn.microsoft.com/en-us/rest/api/azure/) for new stable versions
3. **Breaking Change Alerts**: Subscribe to [Azure Updates](https://azure.microsoft.com/updates/) for provider changes

#### **Update Process**
1. **Test in Development**: Update AVM versions in development environment first
2. **Validate Deployment**: Ensure all resources deploy successfully with new versions
3. **Function Testing**: Verify application functionality with updated resources
4. **Staged Rollout**: Deploy to staging before production
5. **Documentation Update**: Update this reference with new versions

### 🚨 Important Notes

#### **Preview API Versions**
- **Microsoft.CognitiveServices**: Uses `2024-06-01-preview` for AI Foundry features
- **Stability**: Preview APIs may have breaking changes
- **Monitoring**: Track preview API graduation to stable versions

#### **Deprecated API Versions**
- **Avoid**: Using API versions older than 2 years
- **Migration**: Plan migration from deprecated versions during maintenance windows
- **Testing**: Thoroughly test with new API versions before production deployment

#### **Regional Availability**
- **AI Services**: Limited to specific regions (see supported regions in main-orchestrator.bicep)
- **New Features**: Some API versions may not be available in all regions
- **Validation**: Always validate regional availability before deployment

This resource provider reference ensures our infrastructure uses current, supported API versions while providing clear guidance for future updates and maintenance.
