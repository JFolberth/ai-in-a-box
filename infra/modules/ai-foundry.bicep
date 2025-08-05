// AI Foundry Infrastructure Module
// This module deploys a complete AI Foundry environment including:
// - Cognitive Services Account (Multi-service AI Services)
// - AI Studio Workspace (Machine Learning Services)
// - AI Project (Foundry project workspace)
// - GPT-4.1-mini Model Deployment
// - RBAC assignment to Function App (Azure AI Developer role)

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Name prefix for AI Foundry resources')
param namePrefix string = 'ai-foundry'

@description('Azure region for resource deployment')
param location string

@description('Environment suffix for resource naming (e.g., dev, staging, prod)')
param environment string = 'dev'

@description('Resource tags to apply to all resources')
param tags object = {}

@description('AI model deployment name')
param modelDeploymentName string = 'gpt-4o-mini'

@description('AI model version')
param modelVersion string = '2024-07-18'

@description('Model deployment capacity (Tokens Per Minute)')
param deploymentCapacity int = 100

@description('AI Foundry project display name')
param projectName string = 'AI in A Box Project'

@description('AI Foundry project description')
param projectDescription string = 'AI in A Box foundry project with GPT-4.1-mini model deployment'

@description('Function App system-assigned managed identity principal ID for RBAC')
param functionAppPrincipalId string = ''

@description('Deploy RBAC assignment for Function App access')
param deployRbac bool = false

@description('Principal type for RBAC assignment')
@allowed(['User', 'Group', 'ServicePrincipal'])
param principalType string = 'ServicePrincipal'

@description('Name of the existing Bing Search resource')
param bingSearchResourceId string

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

// Consistent naming pattern following project standards
var nameSuffix = toLower('${namePrefix}-${environment}-${regionReference[location]}')
var cognitiveServicesName = 'cs-${nameSuffix}'
var aiProjectName = 'aiproj-${nameSuffix}'

// Azure AI Developer role definition ID (least privilege for AI Foundry access)
var azureAiDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'

// =========== RESOURCES ===========

// Cognitive Services Account (Multi-service AI Services)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: cognitiveServicesName
  location: location
  tags: union(tags, {
    Service: 'CognitiveServices'
    Purpose: 'AI-Foundry-Backend'
  })
  kind: 'AIServices'
  properties: {
    customSubDomainName: cognitiveServicesName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    allowProjectManagement: true
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Model Deployment (GPT-4.1-mini)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview' = {
  parent: cognitiveServices
  name: modelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1-mini'
      version: modelVersion
    }
    raiPolicyName: 'Microsoft.Default'
  }
  sku: {
    name: 'GlobalStandard'
    capacity: deploymentCapacity
  }
}

// AI Foundry Project (Cognitive Services Project)
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: cognitiveServices
  name: aiProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: projectName
  }
}
// Connected Services
resource bingGrounding 'Microsoft.CognitiveServices/accounts/connection@2025-04-01-preview' = if (!empty(bingSearchResourceId)) {
  parent: cognitiveServices
  name: 'bingsearch-connection'
  properties: {
    connectionType: 'BingSearch'
    displayName: 'Bing Search Connection'
    description: 'Connection to Bing Search for grounding'
    resourceId: bingSearchResourceId
  }
}

// RBAC Assignment: Grant Function App "Azure AI Developer" role on Cognitive Services
module functionAppRbac 'rbac-assignment.bicep' = if (deployRbac && !empty(functionAppPrincipalId)) {
  name: 'function-app-ai-foundry-rbac'
  params: {
    principalId: functionAppPrincipalId
    roleDefinitionId: azureAiDeveloperRoleId
    principalType: principalType
    targetResourceId: cognitiveServices.id
    roleDescription: 'Grants Function App least-privilege access to AI Foundry Cognitive Services'
  }
}

// =========== OUTPUTS ===========

@description('Cognitive Services account name')
output cognitiveServicesName string = cognitiveServices.name

@description('Cognitive Services endpoint URL')
output cognitiveServicesEndpoint string = cognitiveServices.properties.endpoint

@description('AI project name')
output aiProjectName string = aiProject.name

@description('Model deployment name')
output modelDeploymentName string = modelDeployment.name

@description('Model endpoint URL for API calls')
output modelEndpoint string = '${cognitiveServices.properties.endpoint}openai/deployments/${modelDeployment.name}'

@description('AI Foundry Studio URL for project management')
output aiFoundryStudioUrl string = 'https://ai.azure.com/projects/${aiProject.name}/overview'

@description('AI Foundry endpoint URL for API calls')
output aiFoundryEndpoint string = '${cognitiveServices.properties.endpoint}api/projects/${aiProject.name}'

@description('Cognitive Services resource ID')
output cognitiveServicesId string = cognitiveServices.id

@description('AI project resource ID')
output aiProjectId string = aiProject.id
