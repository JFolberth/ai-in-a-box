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

@description('AI Foundry resource group name')
param aiFoundryResourceGroup string = 'rg-ai-foundry-dev'

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

@description('Log Analytics Workspace Name for consolidated logging')
param logAnalyticsWorkspaceName string = 'la-logging-dev-eus'

@description('Resource Group containing the Log Analytics Workspace')
param logAnalyticsResourceGroupName string = 'rg-logging-dev-eus'

@description('Resource token for unique naming')
param resourceToken string

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: applicationName
  AIFoundryAgent: aiFoundryAgentName
}

// =========== VARIABLES ===========

var backendResourceGroupName = 'rg-${applicationName}-backend-${environmentName}-${resourceToken}'
var frontendResourceGroupName = 'rg-${applicationName}-frontend-${environmentName}-${resourceToken}'

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

// =========== OUTPUTS ===========

@description('AI Foundry Configuration')
output aiFoundryConfig object = {
  agentName: aiFoundryAgentName
  endpoint: aiFoundryEndpoint
  subscriptionId: aiFoundrySubscriptionId
  resourceGroup: aiFoundryResourceGroup
  projectName: aiFoundryProjectName
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
