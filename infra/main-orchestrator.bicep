// Azure AI Foundry SPA Infrastructure Orchestrator
// This template orchestrates the deployment of frontend and backend to separate resource groups
// Each component gets its own Application Insights instance for better isolation

targetScope = 'subscription'

// =========== PARAMETERS ===========

// =========== CORE PARAMETERS ===========

@description('Application name used for resource naming')
param applicationName string = 'ai-foundry-spa'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure region for resource deployment')
param location string = 'eastus'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: applicationName
  AIFoundryAgent: 'AI in A Box'
}

// =========== FRONTEND PARAMETERS ===========

// No specific frontend parameters currently - frontend uses core parameters

// =========== BACKEND PARAMETERS ===========

// No specific backend parameters currently - backend uses core parameters

// =========== LOG ANALYTICS PARAMETERS ===========

@description('Create new Log Analytics workspace or use existing')
param createLogAnalyticsWorkspace bool = true

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

// =========== AI FOUNDRY PARAMETERS ===========

// Note: AI Foundry agent deployment moved to GitHub Actions workflow step

@description('AI Foundry endpoint URL for API calls')
param aiFoundryEndpoint string = 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject'

@description('AI Foundry agent ID (will be set by GitHub Actions after agent deployment)')
param aiFoundryAgentId string = 'placeholder-agent-id'

@description('AI Foundry agent name')
param aiFoundryAgentName string = 'AI in A Box'

@description('AI Foundry resource group name for RBAC assignment')
param aiFoundryResourceGroupName string = 'rg-foundry-dev-eus'

@description('AI Foundry resource name for RBAC assignment')
param aiFoundryResourceName string = 'ai-foundry-dev-eus'

@description('AI Foundry subscription ID - defaults to current deployment subscription')
param aiFoundrySubscriptionId string = subscription().subscriptionId

@description('Create new AI Foundry resource group or use existing')
param createAiFoundryResourceGroup bool = false

@description('AI Foundry model deployment name')
param aiFoundryModelDeploymentName string = 'gpt-4o-mini'

@description('AI Foundry model version')
param aiFoundryModelVersion string = '2024-07-18'

@description('AI Foundry deployment capacity (TPM - Tokens Per Minute)')
param aiFoundryDeploymentCapacity int = 150

@description('AI Foundry project display name')
param aiFoundryProjectDisplayName string = 'AI in A Box Project'

@description('AI Foundry project description')
param aiFoundryProjectDescription string = 'AI in A Box foundry project with GPT-4o-mini model deployment'

// =========== VARIABLES ===========

// Region reference mapping for consistent naming
var regionReference = {
  centralus: 'cus'
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
}

// Name suffix patterns following backend naming convention
var backendNameSuffix = toLower('${applicationName}-backend-${environmentName}-${regionReference[location]}')
var frontendNameSuffix = toLower('${applicationName}-frontend-${environmentName}-${regionReference[location]}')
var aiFoundryNameSuffix = toLower('${applicationName}-aifoundry-${environmentName}-${regionReference[location]}')
var logAnalyticsNameSuffix = toLower('${applicationName}-logging-${environmentName}-${regionReference[location]}')

var backendResourceGroupName = 'rg-${backendNameSuffix}'
var frontendResourceGroupName = 'rg-${frontendNameSuffix}'
var newAiFoundryResourceGroupName = 'rg-${aiFoundryNameSuffix}'
var newLogAnalyticsResourceGroupName = 'rg-${logAnalyticsNameSuffix}'
var newLogAnalyticsWorkspaceName = 'la-${logAnalyticsNameSuffix}'

// AI Foundry resource group - either create new or use existing
var effectiveAiFoundryResourceGroupName = createAiFoundryResourceGroup
  ? newAiFoundryResourceGroupName
  : aiFoundryResourceGroupName

// Log Analytics resource group - either create new or use existing
var effectiveLogAnalyticsResourceGroupName = createLogAnalyticsWorkspace
  ? newLogAnalyticsResourceGroupName
  : logAnalyticsResourceGroupName

// Log Analytics workspace name - either create new or use existing
var effectiveLogAnalyticsWorkspaceName = createLogAnalyticsWorkspace
  ? newLogAnalyticsWorkspaceName
  : logAnalyticsWorkspaceName



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
module newAiFoundryResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = if (createAiFoundryResourceGroup) {
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

// Log Analytics Resource Group (conditional deployment)
module newLogAnalyticsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = if (createLogAnalyticsWorkspace) {
  name: 'loganalytics-rg-deployment'
  params: {
    name: newLogAnalyticsResourceGroupName
    location: location
    tags: union(tags, {
      Component: 'Log-Analytics'
      ResourceType: 'LogAnalytics-Workspace'
    })
  }
}

// =========== LOG ANALYTICS WORKSPACE (OPTIONAL) ===========

// Reference to existing Log Analytics workspace resource group
resource logAnalyticsResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = if (!createLogAnalyticsWorkspace) {
  name: logAnalyticsResourceGroupName
  scope: subscription()
}

// Create Log Analytics workspace (conditionally creates both resource group and workspace)
module logAnalyticsWorkspace 'modules/log-analytics.bicep' = if (createLogAnalyticsWorkspace) {
  name: 'shared-log-analytics'
  scope: resourceGroup(effectiveLogAnalyticsResourceGroupName)
  dependsOn: [
    newLogAnalyticsResourceGroup
  ]
  params: {
    workspaceName: effectiveLogAnalyticsWorkspaceName
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
  // EXPLICIT DEPENDENCY REQUIRED: Conditional dependencies cannot be automatically inferred by Bicep
  // when the dependency itself is conditionally deployed. We need explicit dependsOn to ensure
  // Log Analytics workspace is fully created before Application Insights tries to reference it.
  dependsOn: createLogAnalyticsWorkspace
    ? [
        frontendResourceGroup
        logAnalyticsWorkspace // Only depend on Log Analytics workspace if we're creating it
      ]
    : [
        frontendResourceGroup
      ]
  params: {
    environmentName: environmentName
    applicationName: applicationName
    location: location
    logAnalyticsWorkspaceName: effectiveLogAnalyticsWorkspaceName
    logAnalyticsResourceGroupName: effectiveLogAnalyticsResourceGroupName
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
  // EXPLICIT DEPENDENCY REQUIRED: Same as frontend - conditional dependencies for Log Analytics
  // workspace cannot be automatically inferred when the workspace itself is conditionally deployed.
  dependsOn: createLogAnalyticsWorkspace
    ? [
        backendResourceGroup
        logAnalyticsWorkspace // Only depend on Log Analytics workspace if we're creating it
      ]
    : [
        backendResourceGroup
      ]
  params: {
    environmentName: environmentName
    applicationName: applicationName
    location: location
    logAnalyticsWorkspaceName: effectiveLogAnalyticsWorkspaceName
    logAnalyticsResourceGroupName: effectiveLogAnalyticsResourceGroupName
    aiFoundryInstanceName: aiFoundryResourceName
    aiFoundryResourceGroupName: aiFoundryResourceGroupName
    aiFoundryEndpoint: aiFoundryEndpoint
    aiFoundryAgentId: aiFoundryAgentId
    aiFoundryAgentName: aiFoundryAgentName
    // Agent ID and Name will be set by GitHub Actions deployment step
    tags: union(tags, {
      Component: 'Backend'
    })
  }
}

// =========== AI FOUNDRY DEPLOYMENT ===========

// Deploy AI Foundry infrastructure (Cognitive Services + AI Project + Model)
module aiFoundryInfrastructure 'modules/ai-foundry.bicep' = if (createAiFoundryResourceGroup) {
  name: 'aifoundry-deployment'
  scope: resourceGroup(effectiveAiFoundryResourceGroupName)
  dependsOn: [
    newAiFoundryResourceGroup
  ]
  params: {
    location: location
    environment: environmentName
    tags: union(tags, {
      Component: 'AI-Foundry'
    })
    functionAppPrincipalId: backendInfrastructure.outputs.functionAppSystemAssignedIdentityPrincipalId
    modelDeploymentName: aiFoundryModelDeploymentName
    modelVersion: aiFoundryModelVersion
    deploymentCapacity: aiFoundryDeploymentCapacity
    projectName: aiFoundryProjectDisplayName
    projectDescription: aiFoundryProjectDescription
  }
}

// =========== VALIDATION ===========

// Validate AI Foundry resource group naming standard
var aiFoundryRgNameValid = startsWith(aiFoundryResourceGroupName, 'rg-') && contains(aiFoundryResourceGroupName, '-ai') || contains(
  aiFoundryResourceGroupName,
  '-foundry'
) || contains(aiFoundryResourceGroupName, '-aifoundry')

// Validate Log Analytics resource group naming standard  
var logAnalyticsRgNameValid = startsWith(logAnalyticsResourceGroupName, 'rg-') && contains(
  logAnalyticsResourceGroupName,
  '-log'
)

// Display warnings for non-standard naming (these will show as outputs)
var aiFoundryNamingWarning = aiFoundryRgNameValid
  ? ''
  : 'WARNING: AI Foundry resource group name does not follow standard: rg-*-ai*|foundry*|aifoundry*'
var logAnalyticsNamingWarning = logAnalyticsRgNameValid
  ? ''
  : 'WARNING: Log Analytics resource group name does not follow standard: rg-*-log*'

// =========== VALIDATION OUTPUTS ===========

@description('AI Foundry resource group naming validation')
output aiFoundryNamingValidation string = aiFoundryNamingWarning

@description('Log Analytics resource group naming validation')
output logAnalyticsNamingValidation string = logAnalyticsNamingWarning

// =========== OUTPUTS ===========

@description('AI Foundry Configuration')
output aiFoundryConfig object = {
  agentName: aiFoundryAgentName
  endpoint: aiFoundryEndpoint
  subscriptionId: aiFoundrySubscriptionId
  resourceGroup: effectiveAiFoundryResourceGroupName

  projectName: aiFoundryProjectDisplayName
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

@description('AI Foundry Endpoint URL')
output aiFoundryEndpoint string = aiFoundryEndpoint

@description('AI Foundry Resource Group Name')
output aiFoundryResourceGroupName string = createAiFoundryResourceGroup
  ? newAiFoundryResourceGroup.outputs.name
  : aiFoundryResourceGroupName

@description('AI Foundry Resource Group Location')
output aiFoundryResourceGroupLocation string = createAiFoundryResourceGroup
  ? newAiFoundryResourceGroup.outputs.location
  : location

@description('Log Analytics Resource Group Name')
output logAnalyticsResourceGroupName string = createLogAnalyticsWorkspace
  ? newLogAnalyticsResourceGroup.outputs.name
  : logAnalyticsResourceGroup.name

@description('Log Analytics Workspace Name (when created)')
output logAnalyticsWorkspaceName string = createLogAnalyticsWorkspace
  ? logAnalyticsWorkspace.outputs.workspaceName
  : effectiveLogAnalyticsWorkspaceName

@description('Log Analytics Workspace ID (when created)')
output logAnalyticsWorkspaceId string = createLogAnalyticsWorkspace ? logAnalyticsWorkspace.outputs.workspaceId : ''

@description('Log Analytics Resource Group Location')
output logAnalyticsResourceGroupLocation string = createLogAnalyticsWorkspace
  ? newLogAnalyticsResourceGroup.outputs.location
  : logAnalyticsResourceGroup.location
