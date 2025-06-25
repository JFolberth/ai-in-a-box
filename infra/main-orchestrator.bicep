// AI Foundry SPA Infrastructure Orchestrator
// This template orchestrates the deployment of frontend and backend to separate resource groups
// Each component gets its own Application Insights instance for better isolation

targetScope = 'subscription'

// =========== PARAMETERS ===========

@description('AI Foundry agent ID for endpoint interaction')
param aiFoundryAgentId string = 'asst_dH7M0nbmdRblhSQO8nIGIYF4'

@description('AI Foundry agent name for endpoint interaction')
param aiFoundryAgentName string = 'AI in a Box'

@description('AI Foundry endpoint URL for API calls')
param aiFoundryEndpoint string = 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject'

@description('AI Foundry project name')
param aiFoundryProjectName string = 'ai-foundry-dev-eus'

@description('AI Foundry resource group name for RBAC assignment')
param aiFoundryResourceGroupName string = 'rg-ai-foundry-dev-eus'

@description('AI Foundry resource name for RBAC assignment')
param aiFoundryResourceName string = 'ai-foundry-dev-eus'

@description('AI Foundry subscription ID - defaults to current deployment subscription')
param aiFoundrySubscriptionId string = subscription().subscriptionId

@description('Application name used for resource naming')
param applicationName string = 'ai-foundry-spa'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure region for resource deployment')
param location string = 'eastus'

@description('Create new Log Analytics workspace or use existing')
param createLogAnalyticsWorkspace bool = false

@description('Log Analytics Workspace Name for consolidated logging')
param logAnalyticsWorkspaceName string = 'la-logging-dev-eus'

@description('Resource Group containing the Log Analytics Workspace')
param logAnalyticsResourceGroupName string = 'rg-logging-dev-eus'

@description('Log Analytics workspace pricing tier')
@allowed(['Free', 'Standard', 'Premium', 'PerNode', 'PerGB2018', 'Standalone'])
param logAnalyticsWorkspacePricingTier string = 'PerGB2018'

@description('Log Analytics workspace data retention period in days')
@minValue(30)
@maxValue(730)
param logAnalyticsWorkspaceRetentionInDays int = 90



@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: applicationName
  AIFoundryAgent: aiFoundryAgentName
}

@description('Enable AI Foundry resource deployment (creates new AI Foundry resources)')
param enableAiFoundryDeployment bool = true

@description('AI Foundry model deployment name')
param aiFoundryModelDeploymentName string = 'gpt-4o-mini'

@description('AI Foundry model version')
param aiFoundryModelVersion string = '2024-07-18'

@description('AI Foundry deployment capacity (TPM - Tokens Per Minute)')
param aiFoundryDeploymentCapacity int = 10000

@description('AI Foundry project display name')
param aiFoundryProjectDisplayName string = 'AI in A Box Project'

@description('AI Foundry project description')
param aiFoundryProjectDescription string = 'AI in A Box foundry project with GPT-4o-mini model deployment'

// =========== VARIABLES ===========

var backendResourceGroupName = 'rg-${applicationName}-backend-${environmentName}-${uniqueString(subscription().id, applicationName, 'backend')}'
var frontendResourceGroupName = 'rg-${applicationName}-frontend-${environmentName}-${uniqueString(subscription().id, applicationName, 'frontend')}'
var newAiFoundryResourceGroupName = 'rg-${applicationName}-aifoundry-${environmentName}-${uniqueString(subscription().id, applicationName, 'aifoundry')}'

// =========== RESOURCE GROUPS ===========

// Frontend Resource Group using AVM module
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

// Backend Resource Group using AVM module
module backendResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'backend-rg-deployment'
  params: {
    name: backendResourceGroupName
    location: location
    tags: union(tags, {
      Component: 'Backend'
      ResourceType: 'FunctionApp'
    })
  }
}

// AI Foundry Resource Group (conditional deployment)
module newAiFoundryResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = if (enableAiFoundryDeployment) {
  name: 'aifoundry-rg-deployment'
  params: {
    name: newAiFoundryResourceGroupName
    location: location
    tags: union(tags, {
      Component: 'AI-Foundry'
      ResourceType: 'CognitiveServices-AIFoundry'
    })
  }
}

// =========== LOG ANALYTICS WORKSPACE (OPTIONAL) ===========

// Reference to existing Log Analytics workspace resource group
resource logAnalyticsResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: logAnalyticsResourceGroupName
  scope: subscription()
}

// Conditionally create Log Analytics workspace using our module
module logAnalyticsWorkspace 'modules/log-analytics.bicep' = if (createLogAnalyticsWorkspace) {
  name: 'shared-log-analytics'
  scope: logAnalyticsResourceGroup
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    pricingTier: logAnalyticsWorkspacePricingTier
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    tags: union(tags, {
      Component: 'Shared-LogAnalytics'
      Purpose: 'CentralizedLogging'
    })
  }
}

// =========== FRONTEND DEPLOYMENT ===========

// Deploy frontend infrastructure (Static Web App + Application Insights)
module frontendInfrastructure 'environments/frontend/main.bicep' = {
  name: 'frontend-deployment'
  scope: resourceGroup(frontendResourceGroupName)
  dependsOn: [
    frontendResourceGroup
  ]
  params: {
    environmentName: environmentName
    applicationName: applicationName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
    tags: union(tags, {
      Component: 'Frontend'
    })
  }
}

// =========== BACKEND DEPLOYMENT ===========

// Deploy backend infrastructure (Function App + Application Insights)
module backendInfrastructure 'environments/backend/main.bicep' = {
  name: 'backend-deployment'
  scope: resourceGroup(backendResourceGroupName)
  dependsOn: [
    backendResourceGroup
  ]
  params: {
    environmentName: environmentName
    applicationName: applicationName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
    aiFoundryInstanceName: aiFoundryResourceName
    aiFoundryResourceGroupName: aiFoundryResourceGroupName
    aiFoundryAgentId: aiFoundryAgentId
    aiFoundryEndpoint: aiFoundryEndpoint
    aiFoundryAgentName: aiFoundryAgentName
    tags: union(tags, {
      Component: 'Backend'
    })
  }
}

// =========== AI FOUNDRY DEPLOYMENT ===========

// Deploy AI Foundry infrastructure (Cognitive Services + AI Project + Model)
module aiFoundryInfrastructure 'modules/ai-foundry.bicep' = if (enableAiFoundryDeployment) {
  name: 'aifoundry-deployment'
  scope: resourceGroup(newAiFoundryResourceGroupName)
  dependsOn: [
    newAiFoundryResourceGroup
  ]
  params: {
    namePrefix: 'aifoundry'
    location: location
    environment: environmentName
    tags: union(tags, {
      Component: 'AI-Foundry'
    })
    appInsightsWorkspaceResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${logAnalyticsResourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/${logAnalyticsWorkspaceName}'
    modelDeploymentName: aiFoundryModelDeploymentName
    modelVersion: aiFoundryModelVersion
    deploymentCapacity: aiFoundryDeploymentCapacity
    projectName: aiFoundryProjectDisplayName
    projectDescription: aiFoundryProjectDescription
  }
}

// Deploy RBAC assignments for AI Foundry (separate module for better isolation)
module aiFoundryRbac 'modules/ai-foundry-rbac.bicep' = if (enableAiFoundryDeployment) {
  name: 'aifoundry-rbac-deployment'
  scope: resourceGroup(newAiFoundryResourceGroupName)
  params: {
    functionAppPrincipalId: backendInfrastructure.outputs.functionAppSystemAssignedIdentityPrincipalId
    cognitiveServicesName: enableAiFoundryDeployment ? aiFoundryInfrastructure.outputs.cognitiveServicesName : ''
    principalType: 'ServicePrincipal'
  }
}

// =========== OUTPUTS ===========

@description('AI Foundry Configuration')
output aiFoundryConfig object = {
  agentName: {
    value: aiFoundryAgentName
    description: 'AI Foundry agent name for endpoint interaction'
  }
  endpoint: {
    value: enableAiFoundryDeployment ? aiFoundryInfrastructure.outputs.modelEndpoint : aiFoundryEndpoint
    description: 'AI Foundry endpoint URL for API calls'
  }
  subscriptionId: {
    value: enableAiFoundryDeployment ? subscription().subscriptionId : aiFoundrySubscriptionId
    description: 'AI Foundry subscription ID'
  }
  resourceGroup: {
    value: enableAiFoundryDeployment ? newAiFoundryResourceGroup.outputs.name : aiFoundryResourceGroupName
    description: 'AI Foundry resource group name'
  }
  projectName: {
    value: enableAiFoundryDeployment ? aiFoundryInfrastructure.outputs.aiProjectName : aiFoundryProjectName
    description: 'AI Foundry project name'
  }
}

@description('Backend API URL for frontend configuration')
output backendApiUrl string = backendInfrastructure.outputs.backendApiUrl

@description('Backend Application Insights Connection String')
output backendApplicationInsightsConnectionString string = backendInfrastructure.outputs.applicationInsightsConnectionString

@description('Backend Function App Name')
output backendFunctionAppName string = backendInfrastructure.outputs.functionAppName

@description('Backend Function App URL')
output backendFunctionAppUrl string = backendInfrastructure.outputs.functionAppUrl

@description('Backend Resource Group Name')
output backendResourceGroupName string = backendResourceGroup.outputs.name

@description('Frontend Application Insights Connection String')
output frontendApplicationInsightsConnectionString string = frontendInfrastructure.outputs.applicationInsightsConnectionString

@description('Environment Variables for Frontend Application')
output frontendEnvironmentVariables object = {
  VITE_AI_FOUNDRY_AGENT_NAME: aiFoundryAgentName
  VITE_AI_FOUNDRY_AGENT_ID: aiFoundryAgentId
  VITE_AI_FOUNDRY_ENDPOINT: aiFoundryEndpoint
  VITE_BACKEND_URL: backendInfrastructure.outputs.backendApiUrl
  VITE_USE_BACKEND: 'true'
  VITE_PUBLIC_MODE: 'false'
  VITE_STATIC_WEB_APP_NAME: frontendInfrastructure.outputs.staticWebAppName
  VITE_APPLICATION_INSIGHTS_CONNECTION_STRING: frontendInfrastructure.outputs.applicationInsightsConnectionString
}

@description('Frontend Resource Group Name')
output frontendResourceGroupName string = frontendResourceGroup.outputs.name

@description('Frontend Static Website URL')
output frontendStaticWebsiteUrl string = frontendInfrastructure.outputs.staticWebsiteUrl

@description('Frontend Static Web App Name')
output frontendStaticWebAppName string = frontendInfrastructure.outputs.staticWebAppName

@description('AI Foundry Infrastructure (when enabled)')
output aiFoundryInfrastructure object = enableAiFoundryDeployment ? {
  cognitiveServicesName: aiFoundryInfrastructure.outputs.cognitiveServicesName
  cognitiveServicesEndpoint: aiFoundryInfrastructure.outputs.cognitiveServicesEndpoint
  aiStudioWorkspaceName: aiFoundryInfrastructure.outputs.aiStudioWorkspaceName
  aiProjectName: aiFoundryInfrastructure.outputs.aiProjectName
  modelDeploymentName: aiFoundryInfrastructure.outputs.modelDeploymentName
  modelEndpoint: aiFoundryInfrastructure.outputs.modelEndpoint
  aiFoundryStudioUrl: aiFoundryInfrastructure.outputs.aiFoundryStudioUrl
  connectionName: aiFoundryInfrastructure.outputs.connectionName
  resourceGroupName: newAiFoundryResourceGroup.outputs.name
} : {}

@description('AI Foundry Resource Group Name (when enabled)')
output aiFoundryResourceGroupName string = enableAiFoundryDeployment ? newAiFoundryResourceGroup.outputs.name : ''

@description('Updated Frontend Environment Variables (with AI Foundry when enabled)')
output updatedFrontendEnvironmentVariables object = {
  VITE_AI_FOUNDRY_AGENT_NAME: aiFoundryAgentName
  VITE_AI_FOUNDRY_AGENT_ID: aiFoundryAgentId
  VITE_AI_FOUNDRY_ENDPOINT: enableAiFoundryDeployment ? aiFoundryInfrastructure.outputs.modelEndpoint : aiFoundryEndpoint
  VITE_BACKEND_URL: backendInfrastructure.outputs.backendApiUrl
  VITE_USE_BACKEND: 'true'
  VITE_PUBLIC_MODE: 'false'
  VITE_STATIC_WEB_APP_NAME: frontendInfrastructure.outputs.staticWebAppName
  VITE_APPLICATION_INSIGHTS_CONNECTION_STRING: frontendInfrastructure.outputs.applicationInsightsConnectionString
  VITE_AI_FOUNDRY_DEPLOYED: enableAiFoundryDeployment ? 'true' : 'false'
}
