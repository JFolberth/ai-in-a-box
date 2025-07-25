// Azure AI Foundry SPA Infrastructure Orchestrator
// This template orchestrates the deployment of frontend and backend to separate resource groups
// Each component gets its own Application Insights instance for better isolation

targetScope = 'subscription'

// =========== PARAMETERS ===========

// =========== CORE PARAMETERS ===========

@description('Application name used for resource naming')
param applicationName string = 'foundrytst'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure region for resource deployment')
param location string = 'eastus2'

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

// =========== AI FOUNDRY PARAMETERS ===========

// Note: AI Foundry agent deployment moved to GitHub Actions workflow step

@description('AI Foundry agent ID (optional - backend uses fallback default if empty)')
param aiFoundryAgentId string = ''

@description('AI Foundry agent name')
param aiFoundryAgentName string = 'AI in A Box'

@description('AI Foundry resource group name for RBAC assignment')
param aiFoundryResourceGroupName string = ''

@description('AI Foundry resource name for RBAC assignment')
param aiFoundryResourceName string = ''

@description('AI Foundry project name (for existing resources)')
param aiFoundryProjectName string = 'testProject'

@description('AI Foundry subscription ID - defaults to current deployment subscription')
param aiFoundrySubscriptionId string = subscription().subscriptionId

@description('Create new AI Foundry resource group or use existing')
param createAiFoundryResourceGroup bool = true

@description('AI Foundry model deployment name')
param aiFoundryModelDeploymentName string = 'gpt-4.1-mini'

@description('AI Foundry model version')
param aiFoundryModelVersion string = '2025-04-14'

@description('AI Foundry deployment capacity (TPM - Tokens Per Minute)')
param aiFoundryDeploymentCapacity int = 100

@description('AI Foundry project display name')
param aiFoundryProjectDisplayName string = 'AI in A Box Project'

@description('AI Foundry project description')
param aiFoundryProjectDescription string = 'AI in A Box foundry project with GPT-4.1-mini model deployment'

// =========== VARIABLES ===========

// Region reference mapping - ONLY regions where Cognitive Services AIServices are available
// Source: az cognitiveservices account list-skus --query "[?kind=='AIServices'].locations[]" -o tsv | sort -u
var regionReference = {
  australiaeast: 'ause'
  brazilsouth: 'brs'
  canadacentral: 'cac'
  canadaeast: 'cae'
  eastus: 'eus'
  eastus2: 'eus2'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  italynorth: 'itn'
  japaneast: 'jpe'
  koreacentral: 'krc'
  northcentralus: 'ncus'
  norwayeast: 'noe'
  polandcentral: 'poc'
  southafricanorth: 'san'
  southcentralus: 'scus'
  southeastasia: 'sea'
  southindia: 'ins'
  spaincentral: 'spc'
  swedencentral: 'swc'
  switzerlandnorth: 'swn'
  switzerlandwest: 'sww'
  uaenorth: 'uaen'
  uksouth: 'uks'
  westeurope: 'weu'
  westus: 'wus'
  westus3: 'wus3'
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

// AI Foundry endpoint - either from deployed infrastructure or existing resource
var effectiveAiFoundryEndpoint = createAiFoundryResourceGroup
  ? aiFoundryInfrastructure.?outputs.aiFoundryEndpoint ?? ''
  : '${existingCognitiveServices.?properties.endpoint ?? ''}api/projects/${aiFoundryProjectName}'

// Cognitive Services Account - either from deployed infrastructure or existing resource
var effectiveCognitiveServicesAccount = createAiFoundryResourceGroup
  ? aiFoundryInfrastructure.?outputs.cognitiveServicesName ?? ''
  : existingCognitiveServices.?name ?? ''

// AI Foundry project name - either from deployed infrastructure or existing parameter
var effectiveAiFoundryProjectName = createAiFoundryResourceGroup
  ? aiFoundryInfrastructure.?outputs.aiProjectName ?? aiFoundryProjectName
  : aiFoundryProjectName

// =========== RESOURCE GROUPS ===========

// Frontend Resource Group using AVM module
module frontendResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'frontend-rg-deployment-${regionReference[location]}'
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
  name: 'backend-rg-deployment-${regionReference[location]}'
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
  name: 'aifoundry-rg-deployment-${regionReference[location]}'
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
  name: 'loganalytics-rg-deployment-${regionReference[location]}'
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

// Reference to existing Log Analytics workspace (when not creating new)
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = if (!createLogAnalyticsWorkspace) {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}

// =========== AI FOUNDRY REFERENCES ===========

// Reference to existing Cognitive Services resource (when not creating new)
resource existingCognitiveServices 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = if (!createAiFoundryResourceGroup) {
  name: aiFoundryResourceName
  scope: resourceGroup(aiFoundryResourceGroupName)
}

// Create Log Analytics workspace (conditionally creates both resource group and workspace)
module logAnalyticsWorkspace 'modules/log-analytics.bicep' = if (createLogAnalyticsWorkspace) {
  name: 'shared-log-analytics-${regionReference[location]}'
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
  name: 'frontend-deployment-${regionReference[location]}'
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

// =========== AI FOUNDRY DEPLOYMENT ===========

// Deploy AI Foundry infrastructure (Cognitive Services + AI Project + Model)
module aiFoundryInfrastructure 'modules/ai-foundry.bicep' = if (createAiFoundryResourceGroup) {
  name: 'aifoundry-deployment-${regionReference[location]}'
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
    // RBAC will be assigned separately after backend deployment
    deployRbac: false
    modelDeploymentName: aiFoundryModelDeploymentName
    modelVersion: aiFoundryModelVersion
    deploymentCapacity: aiFoundryDeploymentCapacity
    projectName: aiFoundryProjectDisplayName
    projectDescription: aiFoundryProjectDescription
    namePrefix: applicationName
  }
}

// =========== BACKEND DEPLOYMENT ===========

// Deploy backend infrastructure (Function App + Application Insights)
// RBAC Requirements for AI Foundry Access:
// - Cognitive Services OpenAI User: Required for creating threads, sending messages, and reading responses
// - Azure AI User: Required for reading and calling AI Foundry agents at the project level
// These roles provide least-privilege access for AI agent interactions via managed identity
module backendInfrastructure 'environments/backend/main.bicep' = {
  name: 'backend-deployment-${regionReference[location]}'
  scope: resourceGroup(backendResourceGroupName)
  // EXPLICIT DEPENDENCY REQUIRED: Backend needs AI Foundry endpoint when creating new AI Foundry resources
  dependsOn: createLogAnalyticsWorkspace && createAiFoundryResourceGroup
    ? [
        backendResourceGroup
        logAnalyticsWorkspace
        aiFoundryInfrastructure
      ]
    : createLogAnalyticsWorkspace && !createAiFoundryResourceGroup
        ? [
            backendResourceGroup
            logAnalyticsWorkspace
          ]
        : !createLogAnalyticsWorkspace && createAiFoundryResourceGroup
            ? [
                backendResourceGroup
                aiFoundryInfrastructure
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
    aiFoundryInstanceName: effectiveCognitiveServicesAccount
    aiFoundryResourceGroupName: effectiveAiFoundryResourceGroupName
    aiFoundryEndpoint: effectiveAiFoundryEndpoint
    aiFoundryAgentId: aiFoundryAgentId
    aiFoundryAgentName: aiFoundryAgentName
    // Agent ID and Name will be set by GitHub Actions deployment step
    tags: union(tags, {
      Component: 'Backend'
    })
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
  endpoint: effectiveAiFoundryEndpoint
  subscriptionId: aiFoundrySubscriptionId
  resourceGroup: effectiveAiFoundryResourceGroupName
  projectName: effectiveAiFoundryProjectName
  projectDisplayName: aiFoundryProjectDisplayName
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
  VITE_AI_FOUNDRY_ENDPOINT: effectiveAiFoundryEndpoint
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
output aiFoundryEndpoint string = effectiveAiFoundryEndpoint

@description('AI Foundry Resource Group Name')
output aiFoundryResourceGroupName string = createAiFoundryResourceGroup
  ? newAiFoundryResourceGroup.?outputs.name ?? ''
  : aiFoundryResourceGroupName

@description('AI Foundry Resource Group Location')
output aiFoundryResourceGroupLocation string = createAiFoundryResourceGroup
  ? newAiFoundryResourceGroup.?outputs.location ?? location
  : location

@description('Log Analytics Resource Group Name')
output logAnalyticsResourceGroupName string = createLogAnalyticsWorkspace
  ? newLogAnalyticsResourceGroup.?outputs.name ?? ''
  : logAnalyticsResourceGroup.?name ?? ''

@description('Log Analytics Workspace Name (effective - created or existing)')
output logAnalyticsWorkspaceName string = createLogAnalyticsWorkspace
  ? logAnalyticsWorkspace.?outputs.workspaceName ?? ''
  : effectiveLogAnalyticsWorkspaceName

@description('Log Analytics Workspace ID (effective - created or existing)')
output logAnalyticsWorkspaceId string = createLogAnalyticsWorkspace
  ? logAnalyticsWorkspace.?outputs.workspaceId ?? ''
  : existingLogAnalyticsWorkspace.?id ?? ''

@description('Log Analytics Resource Group Location')
output logAnalyticsResourceGroupLocation string = createLogAnalyticsWorkspace
  ? newLogAnalyticsResourceGroup.?outputs.location ?? location
  : logAnalyticsResourceGroup.?location ?? location
