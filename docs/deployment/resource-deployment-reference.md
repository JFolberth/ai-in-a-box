# Resource Deployment Reference

This document provides comprehensive documentation for the expected Azure resources and their configurations that are deployed by the AI in A Box infrastructure templates.

## 🎯 Overview

The AI in A Box infrastructure supports **three deployment scenarios** based on whether you create new AI Foundry and Log Analytics resources or use existing ones. Each scenario deploys a consistent set of frontend and backend resources, with conditional AI Foundry and Log Analytics infrastructure.

## 📋 Deployment Scenarios Matrix

### Scenario Configuration Parameters

| Parameter | Scenario A | Scenario B | Scenario C |
|-----------|------------|------------|------------|
| `createAiFoundryResourceGroup` | `true` | `false` | `false` |
| `createLogAnalyticsWorkspace` | `true` | `true` | `false` |
| **Description** | **Complete New Deployment** | **Existing AI Foundry + New Logging** | **Use All Existing Resources** |

### Resource Deployment Matrix

| Resource Type | Scenario A | Scenario B | Scenario C | Notes |
|---------------|------------|------------|------------|-------|
| **Frontend Resource Group** | ✅ Created | ✅ Created | ✅ Created | Always created |
| **Backend Resource Group** | ✅ Created | ✅ Created | ✅ Created | Always created |
| **AI Foundry Resource Group** | ✅ Created | ❌ Use Existing | ❌ Use Existing | Conditional |
| **Log Analytics Resource Group** | ✅ Created | ✅ Created | ❌ Use Existing | Conditional |
| **Static Web App** | ✅ Created | ✅ Created | ✅ Created | Always created |
| **Function App** | ✅ Created | ✅ Created | ✅ Created | Always created |
| **Cognitive Services** | ✅ Created | ❌ Use Existing | ❌ Use Existing | Conditional |
| **AI Project** | ✅ Created | ❌ Use Existing | ❌ Use Existing | Conditional |
| **Model Deployment** | ✅ Created | ❌ Use Existing | ❌ Use Existing | Conditional |
| **Log Analytics Workspace** | ✅ Created | ✅ Created | ❌ Use Existing | Conditional |

## 🏗️ Resource Groups and Naming Patterns

### Resource Group Naming Convention

| Component | Pattern | Example |
|-----------|---------|---------|
| **Frontend** | `rg-{applicationName}-frontend-{env}-{region}` | `rg-conspiracy-bot-frontend-dev-eus2` |
| **Backend** | `rg-{applicationName}-backend-{env}-{region}` | `rg-conspiracy-bot-backend-dev-eus2` |
| **AI Foundry** | `rg-{applicationName}-aifoundry-{env}-{region}` | `rg-conspiracy-bot-aifoundry-dev-eus2` |
| **Log Analytics** | `rg-{applicationName}-logging-{env}-{region}` | `rg-conspiracy-bot-logging-dev-eus2` |

### Region Reference Mapping

The infrastructure uses abbreviated region codes for consistent naming:

| Azure Region | Code | Example Usage |
|--------------|------|---------------|
| `eastus` | `eus` | `rg-myapp-frontend-dev-eus` |
| `eastus2` | `eus2` | `rg-myapp-frontend-dev-eus2` |
| `westus` | `wus` | `rg-myapp-frontend-dev-wus` |
| `westus3` | `wus3` | `rg-myapp-frontend-dev-wus3` |
| `centralus` | `cus` | `rg-myapp-frontend-dev-cus` |

> **Note**: Only regions where Cognitive Services AIServices are available are supported. Full list available in `main-orchestrator.bicep`.

## 📦 Complete Resource Inventory

### Frontend Resources (Always Deployed)

**Resource Group**: `rg-{applicationName}-frontend-{env}-{region}`

| Resource Type | Naming Pattern | Purpose | Key Configuration |
|---------------|----------------|---------|-------------------|
| **Static Web App** | `stapp-{nameSuffix}` | Hosts JavaScript SPA | Global CDN, automatic HTTPS, custom domains |
| **Application Insights** | `appi-{nameSuffix}` | Frontend monitoring | Connected to Log Analytics workspace |

**Example Resources for `applicationName: "conspiracy-bot"`, `env: "dev"`, `location: "eastus2"`:**
- Static Web App: `stapp-conspiracy-bot-frontend-dev-eus2`
- Application Insights: `appi-conspiracy-bot-frontend-dev-eus2`

### Backend Resources (Always Deployed)

**Resource Group**: `rg-{applicationName}-backend-{env}-{region}`

| Resource Type | Naming Pattern | Purpose | Key Configuration |
|---------------|----------------|---------|-------------------|
| **Function App** | `func-{nameSuffix}` | AI Foundry proxy API | .NET 8 isolated, managed identity |
| **App Service Plan** | `asp-{nameSuffix}` | Function hosting plan | Flex Consumption (FC1) |
| **Storage Account** | `st{nameSuffixShort}` | Function App storage | Standard_LRS, HTTPS only |
| **Application Insights** | `appi-{nameSuffix}` | Backend monitoring | Connected to Log Analytics workspace |

**Example Resources for `applicationName: "conspiracy-bot"`, `env: "dev"`, `location: "eastus2"`:**
- Function App: `func-conspiracy-bot-backend-dev-eus2`
- App Service Plan: `asp-conspiracy-bot-backend-dev-eus2`
- Storage Account: `stconspiracybotbackenddeveus2` (no hyphens, max 24 chars)
- Application Insights: `appi-conspiracy-bot-backend-dev-eus2`

### AI Foundry Resources (Scenario A Only)

**Resource Group**: `rg-{applicationName}-aifoundry-{env}-{region}`

| Resource Type | Naming Pattern | Purpose | Key Configuration |
|---------------|----------------|---------|-------------------|
| **Cognitive Services** | `cs-{nameSuffix}` | AI Foundry backend | AIServices kind, S0 SKU |
| **AI Project** | `aiproj-{nameSuffix}` | Foundry project workspace | System-assigned identity |
| **Model Deployment** | `{modelDeploymentName}` | GPT model deployment | gpt-4.1-mini, configurable TPM |

**Example Resources for `applicationName: "conspiracy-bot"`, `env: "dev"`, `location: "eastus2"`:**
- Cognitive Services: `cs-conspiracy-bot-aifoundry-dev-eus2`
- AI Project: `aiproj-conspiracy-bot-aifoundry-dev-eus2`
- Model Deployment: `gpt-4.1-mini` (configurable via `aiFoundryModelDeploymentName`)

### Log Analytics Resources (Scenarios A & B)

**Resource Group**: `rg-{applicationName}-logging-{env}-{region}`

| Resource Type | Naming Pattern | Purpose | Key Configuration |
|---------------|----------------|---------|-------------------|
| **Log Analytics Workspace** | `la-{nameSuffix}` | Centralized logging | PerGB2018 pricing, 90-day retention |

**Example Resources for `applicationName: "conspiracy-bot"`, `env: "dev"`, `location: "eastus2"`:**
- Log Analytics Workspace: `la-conspiracy-bot-logging-dev-eus2`

## 🔐 RBAC Assignments Reference

### Backend Function App Permissions

The Function App requires specific permissions to access AI Foundry resources across resource groups:

| Role | Scope | Purpose | Assignment Location |
|------|-------|---------|-------------------|
| **Storage Blob Data Contributor** | Backend Resource Group | Function App storage access for Flex Consumption | `backend/main.bicep` |
| **Azure AI User** | AI Foundry Cognitive Services | Read and call AI Foundry agents | `backend/main.bicep` |
| **Cognitive Services OpenAI User** | AI Foundry Cognitive Services | Create threads, send messages, read responses | `backend/main.bicep` |

### Role Definition IDs

| Role Name | Role Definition ID | Description |
|-----------|-------------------|-------------|
| **Storage Blob Data Contributor** | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | Full access to blob storage data |
| **Azure AI User** | `53ca6127-db72-4b80-b1b0-d745d6d5456d` | AI project-level access for Foundry |
| **Cognitive Services OpenAI User** | `a97b65f3-24c7-4388-baec-2e87135dc908` | OpenAI API access for AI interactions |

### RBAC Assignment Pattern

```bicep
// Example: Azure AI User role assignment
module aiFoundryUserRbac 'rbac.bicep' = {
  name: 'backend-aifoundry-user-rbac-${uniqueString(resourceGroup().id, resourceNames.functionApp)}'
  scope: resourceGroup(aiFoundryResourceGroupName)
  params: {
    principalId: functionApp.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
    targetResourceId: aiFoundryInstance.id
    principalType: 'ServicePrincipal'
  }
}
```

## ⚙️ Configuration Dependencies

### Environment Variables

**Frontend Environment Variables** (Static Web App):
```javascript
VITE_AI_FOUNDRY_AGENT_NAME: "AI in A Box"
VITE_AI_FOUNDRY_ENDPOINT: "${effectiveAiFoundryEndpoint}"
VITE_BACKEND_URL: "${backendInfrastructure.outputs.backendApiUrl}"
VITE_USE_BACKEND: "true"
VITE_PUBLIC_MODE: "false"
VITE_APPLICATION_INSIGHTS_CONNECTION_STRING: "${applicationInsightsConnectionString}"
```

**Backend Environment Variables** (Function App):
```csharp
AzureWebJobsStorage__accountname: "${storageAccountName}"
APPLICATIONINSIGHTS_CONNECTION_STRING: "${applicationInsightsConnectionString}"
AI_FOUNDRY_ENDPOINT: "${aiFoundryEndpoint}"
AI_FOUNDRY_WORKSPACE_NAME: "${aiFoundryInstanceName}"
AI_FOUNDRY_AGENT_ID: "${aiFoundryAgentId}"
AI_FOUNDRY_AGENT_NAME: "${aiFoundryAgentName}"
```

### Cross-Resource Group References

| Source | Target | Reference Type | Purpose |
|--------|--------|----------------|---------|
| Backend | AI Foundry | Resource reference | API access and RBAC |
| Frontend/Backend | Log Analytics | Workspace ID | Centralized logging |
| Backend | AI Foundry | Endpoint URL | API communication |

### Managed Identity Configuration

**Function App System-Assigned Identity**:
- Automatically created with Function App
- Principal ID used for RBAC assignments
- No stored credentials required
- Automatic token management

## ✅ Deployment Validation Checklist

Use this checklist to verify successful deployment:

### Infrastructure Validation
- [ ] All expected resource groups exist with correct naming
- [ ] All expected resources exist within each resource group
- [ ] Resource naming follows established conventions
- [ ] All resources are in the correct Azure region

### Frontend Validation
- [ ] Static Web App is accessible via HTTPS
- [ ] Custom domain is configured (if applicable)
- [ ] Application Insights is receiving telemetry
- [ ] Build and deployment pipeline is configured

### Backend Validation
- [ ] Function App is running and accessible
- [ ] Function App has system-assigned managed identity
- [ ] Storage account is accessible by Function App
- [ ] Application Insights is receiving telemetry
- [ ] API endpoints respond correctly

### AI Foundry Integration Validation
- [ ] RBAC assignments are correctly configured
- [ ] Function App can authenticate to AI Foundry
- [ ] AI Foundry agent endpoints are accessible
- [ ] Model deployment is active and responsive

### Monitoring and Logging Validation
- [ ] Log Analytics workspace is receiving logs
- [ ] Application Insights telemetry is flowing
- [ ] Cross-component correlation is working
- [ ] Alerts and dashboards are configured

### End-to-End Validation
- [ ] Frontend can reach backend API
- [ ] Backend can communicate with AI Foundry
- [ ] Complete user journey works as expected
- [ ] Error handling and logging is working

## 🛠️ Troubleshooting Common Issues

### Resource Naming Conflicts
**Problem**: Resource names already exist
**Solution**: Check `applicationName` parameter uniqueness or use different environment/region

### RBAC Assignment Failures
**Problem**: Permission denied during RBAC assignment
**Solution**: Verify deploying user has User Access Administrator role

### AI Foundry Connection Issues
**Problem**: Function App cannot access AI Foundry
**Solution**: Verify managed identity has correct roles and AI Foundry endpoint is accessible

### Cross-Resource Group Dependencies
**Problem**: Resources in different resource groups cannot communicate
**Solution**: Verify RBAC assignments span resource groups correctly

## 📚 Related Documentation

- **[Infrastructure Overview](infrastructure.md)** - Detailed architecture and components
- **[Multi-RG Architecture](../architecture/multi-rg-architecture.md)** - Resource group separation strategy
- **[Deployment Guide](deployment-guide.md)** - Step-by-step deployment instructions
- **[RBAC Assignment Reference](rbac-reference.md)** - Detailed RBAC configuration guide

---

**Next Steps**: Use the [Post-Deployment Validation Script](../../scripts/Test-DeploymentValidation.ps1) to automatically verify your deployment meets all requirements.