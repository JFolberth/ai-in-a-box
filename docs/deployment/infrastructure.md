# Infrastructure Guide

*Understanding the Azure architecture and infrastructure patterns used in the AI Foundry SPA.*

## 🏗️ Architecture Overview

The AI Foundry SPA uses a **multi-resource group, microservices architecture** designed for enterprise-grade security, scalability, and maintainability.

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