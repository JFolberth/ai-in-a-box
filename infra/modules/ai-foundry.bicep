// AI Foundry Infrastructure Module
// This module deploys a complete AI Foundry environment including:
// - Cognitive Services Account (Multi-service AI Services)
// - AI Studio Workspace (Machine Learning Services)
// - AI Project (Foundry project workspace)
// - GPT-4o-mini Model Deployment
// - RBAC assignment to Function App (Azure AI Developer role)

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Prefix for all AI Foundry resource names')
param namePrefix string = 'aifoundry'

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
param deploymentCapacity int = 10000

@description('AI Foundry project display name')
param projectName string = 'AI in A Box Project'

@description('AI Foundry project description')  
param projectDescription string = 'AI in A Box foundry project with GPT-4o-mini model deployment'

@description('Function App system-assigned managed identity principal ID for RBAC')
param functionAppPrincipalId string

@description('Principal type for RBAC assignment')
@allowed(['User', 'Group', 'ServicePrincipal'])
param principalType string = 'ServicePrincipal'

// =========== VARIABLES ===========

var cognitiveServicesName = '${namePrefix}-cogserv-${environment}-${uniqueString(resourceGroup().id)}'
var aiStudioWorkspaceName = '${namePrefix}-workspace-${environment}-${uniqueString(resourceGroup().id)}'
var aiProjectName = '${namePrefix}-project-${environment}-${uniqueString(resourceGroup().id)}'

// Azure AI Developer role definition ID (least privilege for AI Foundry access)
var azureAiDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'

// =========== RESOURCES ===========

// Cognitive Services Account (Multi-service AI Services)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: cognitiveServicesName
  location: location
  tags: union(tags, {
    Service: 'CognitiveServices'
    Purpose: 'AI-Foundry-Backend'
  })
  kind: 'AIServices'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    customSubDomainName: cognitiveServicesName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// AI Studio Workspace (Machine Learning Services)
resource aiStudioWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiStudioWorkspaceName
  location: location
  tags: union(tags, {
    Service: 'MachineLearningServices'
    Purpose: 'AI-Studio-Workspace'
  })
  properties: {
    friendlyName: '${projectName} Workspace'
    description: 'AI Studio workspace for ${projectDescription}'
    // Minimal configuration - no storage, key vault, or container registry dependencies
    publicNetworkAccess: 'Enabled'
    managedNetwork: {
      isolationMode: 'Disabled'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

// AI Project (Foundry Project Workspace)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  tags: union(tags, {
    Service: 'MachineLearningServices'
    Purpose: 'AI-Foundry-Project'
  })
  properties: {
    friendlyName: projectName
    description: projectDescription
    hubResourceId: aiStudioWorkspace.id
    publicNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

// Model Deployment (GPT-4o-mini)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveServices
  name: modelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: modelVersion
    }
    raiPolicyName: 'Microsoft.Default'
  }
  sku: {
    name: 'Standard'
    capacity: deploymentCapacity
  }
}

// AI Connection (Links AI Project to Cognitive Services)
resource aiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  parent: aiProject
  name: 'aoai-connection'
  properties: {
    category: 'AzureOpenAI'
    target: cognitiveServices.properties.endpoint
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: cognitiveServices.id
    }
  }
}

// RBAC Assignment: Grant Function App "Azure AI Developer" role on Cognitive Services
module functionAppRbac 'rbac-assignment.bicep' = {
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

@description('AI Studio workspace name')
output aiStudioWorkspaceName string = aiStudioWorkspace.name

@description('AI project name')
output aiProjectName string = aiProject.name

@description('Model deployment name')
output modelDeploymentName string = modelDeployment.name

@description('Model endpoint URL for API calls')
output modelEndpoint string = '${cognitiveServices.properties.endpoint}openai/deployments/${modelDeployment.name}'

@description('AI Foundry Studio URL for project management')
output aiFoundryStudioUrl string = 'https://ai.azure.com/projects/${aiProject.name}/overview'

@description('AI connection name')
output connectionName string = aiConnection.name

@description('Cognitive Services resource ID')
output cognitiveServicesId string = cognitiveServices.id

@description('AI Studio workspace resource ID')
output aiStudioWorkspaceId string = aiStudioWorkspace.id

@description('AI project resource ID')
output aiProjectId string = aiProject.id
