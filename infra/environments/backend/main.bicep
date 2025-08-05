// Backend Infrastructure Module
// This module deploys the backend resources: Function App + Storage + Application Insights

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('AI Foundry hub/project instance name')
param aiFoundryInstanceName string

@description('Resource Group containing the AI Foundry instance')
param aiFoundryResourceGroupName string

@description('AI Foundry endpoint URL')
param aiFoundryEndpoint string

@description('AI Foundry agent ID')
param aiFoundryAgentId string = ''

@description('AI Foundry agent name')
param aiFoundryAgentName string = 'AI in A Box'

@description('Application name used for resource naming')
param applicationName string

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure region for resource deployment')
param location string = 'eastus2'

@description('Log Analytics Workspace Name for consolidated logging')
param logAnalyticsWorkspaceName string

@description('Resource Group containing the Log Analytics Workspace')
param logAnalyticsResourceGroupName string

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: applicationName
}

// =========== VARIABLES ===========
var nameSuffix = toLower('${applicationName}-${typeInfrastructure}-${environmentName}-${regionReference[location]}')
var nameSuffixShort = replace(nameSuffix, '-', '')

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
var resourceNames = {
  applicationInsights: 'appi-${nameSuffix}'
  appServicePlan: 'asp-${nameSuffix}'
  functionApp: 'func-${nameSuffix}'
  functionStorageAccount: 'st${nameSuffixShort}'
}
var typeInfrastructure = 'bk'

// =========== EXISTING RESOURCES ===========

// Reference to existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}

// Reference to existing AI Foundry Cognitive Services instance
resource aiFoundryInstance 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiFoundryInstanceName
  scope: resourceGroup(aiFoundryResourceGroupName)
}

// =========== APPLICATION INSIGHTS (NATIVE RESOURCE - TEMPORARY WORKAROUND) ===========

// Application Insights for backend monitoring using native resource
// TODO: Revert to AVM 'br/public:avm/res/insights/component:0.6.0' when registry connectivity is restored
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: resourceNames.applicationInsights
  location: location
  tags: union(tags, {
    Component: 'Backend-ApplicationInsights'
  })
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableIpMasking: false
    DisableLocalAuth: false
  }
}

// =========== FUNCTION APP STORAGE ACCOUNT (NATIVE RESOURCE - TEMPORARY WORKAROUND) ===========

// Storage account for Function App runtime requirements using native resource
// TODO: Revert to AVM 'br/public:avm/res/storage/storage-account:0.20.0' when registry connectivity is restored
resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: resourceNames.functionStorageAccount
  location: location
  tags: union(tags, {
    Component: 'Backend-FunctionStorage'
  })
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Blob service for storage account
resource functionStorageBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: functionStorageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Blob container for Function App
resource functionStorageBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: functionStorageBlobService
  name: 'function-container'
  properties: {
    publicAccess: 'None'
    metadata: {
      createdBy: 'FunctionApp'
    }
  }
}
/*
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'backend-appServicePlan'
  params: {
    name: resourceNames.appServicePlan
    location: location
    kind: 'functionApp'
    workerTierName: 'FlexConsumption'
      skuName: 'FC1'
      reserved: true

}
}
)*/
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: resourceNames.appServicePlan
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

// =========== APP SERVICE PLAN FOR FUNCTIONS ===========
/*
// App Service Plan for Function App using AVM
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'backend-appServicePlan'
  params: {
    name: resourceNames.appServicePlan
    location: location
    tags: union(tags, {
      Component: 'Backend-AppServicePlan'
    })
    
    // Consumption plan for Functions
    skuName: 'B1'
    workerTierName: 'Basic'
  }
}

*/
// =========== AZURE FUNCTION APP (NATIVE RESOURCE - TEMPORARY WORKAROUND) ===========

// Function App for AI Foundry backend proxy using native resource
// TODO: Revert to AVM 'br/public:avm/res/web/site:0.16.0' when registry connectivity is restored
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: resourceNames.functionApp
  location: location
  tags: union(tags, {
    Component: 'Backend-FunctionApp'
  })
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    functionAppConfig: {
      deployment: {
        storage: {
          value: '${functionStorageAccount.properties.primaryEndpoints.blob}function-container'
          type: 'blobContainer'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '8.0'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 40
      }
    }
    siteConfig: {
      alwaysOn: false
      http20Enabled: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountname'
          value: functionStorageAccount.name
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AI_FOUNDRY_ENDPOINT'
          value: aiFoundryEndpoint
        }
        {
          name: 'AI_FOUNDRY_WORKSPACE_NAME'
          value: aiFoundryInstanceName
        }
        {
          name: 'AI_FOUNDRY_AGENT_ID'
          value: aiFoundryAgentId
        }
        {
          name: 'AI_FOUNDRY_AGENT_NAME'
          value: aiFoundryAgentName
        }
      ]
    }
  }
}

// =========== RBAC ASSIGNMENTS ===========

// Storage Blob Data Contributor role for Function App managed identity
// Required for Flex Consumption model to access storage account
// Note: Using unique deployment-specific GUID to avoid conflicts with existing assignments
resource functionAppStorageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, resourceNames.functionApp, 'storage-blob-contributor-v2')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    ) // Storage Blob Data Contributor
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    description: 'Grants Storage Blob Data Contributor access to Function App managed identity for Flex Consumption model'
  }
}

// Azure AI User role assignment for Function App to access AI Foundry
// Required for reading and calling AI Foundry agents at the project level
module aiFoundryUserRbac 'rbac.bicep' = {
  name: 'backend-aifoundry-user-rbac-${uniqueString(resourceGroup().id, resourceNames.functionApp)}'
  scope: resourceGroup(aiFoundryResourceGroupName)
  params: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '53ca6127-db72-4b80-b1b0-d745d6d5456d'
    )
    targetResourceId: aiFoundryInstance.id
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services OpenAI User role assignment for Function App to access AI Foundry
// Required for creating threads, sending messages, and reading responses
module aiFoundryOpenAIRbac 'rbac.bicep' = {
  name: 'backend-aifoundry-openai-rbac-${uniqueString(resourceGroup().id)}'
  scope: resourceGroup(aiFoundryResourceGroupName)
  params: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a97b65f3-24c7-4388-baec-2e87135dc908'
    )
    targetResourceId: aiFoundryInstance.id
    principalType: 'ServicePrincipal'
  }
}

// NOTE: AI Foundry RBAC assignments are now handled locally in the backend environment

// =========== OUTPUTS ===========

@description('AI Foundry Instance Resource ID for RBAC assignments')
output aiFoundryInstanceResourceId string = aiFoundryInstance.id

@description('AI Foundry Instance Name')
output aiFoundryInstanceName string = aiFoundryInstance.name

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('Application Insights Resource ID')
output applicationInsightsId string = applicationInsights.id

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Backend API URL for frontend configuration')
output backendApiUrl string = 'https://${functionApp.name}.azurewebsites.net/api'

@description('Function App Name')
output functionAppName string = functionApp.name

@description('Function App System Assigned Identity Principal ID')
output functionAppSystemAssignedIdentityPrincipalId string = functionApp.identity.principalId

@description('Function App URL')
output functionAppUrl string = 'https://${functionApp.name}.azurewebsites.net'

@description('Function Storage Account Name')
output functionStorageAccountName string = functionStorageAccount.name

@description('Function Storage Account Resource ID')
output functionStorageAccountResourceId string = functionStorageAccount.id
