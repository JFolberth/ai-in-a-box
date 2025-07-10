// Backend Infrastructure Module
// This module deploys the backend resources: Function App + Storage + Application Insights

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========
@description('Name for the Azure Deployment Environment')
param adeName string = ''

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

param devCenterProjectName string = ''
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
var nameSuffix = empty(adeName)
  ? toLower('${applicationName}-${typeInfrastructure}-${environmentName}-${regionReference[location]}')
  : '${devCenterProjectName}-${adeName}'
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

// =========== APPLICATION INSIGHTS (AVM) ===========

// Application Insights for backend monitoring using AVM
module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'backend-applicationInsights-${regionReference[location]}'
  params: {
    name: resourceNames.applicationInsights
    location: location
    tags: union(tags, {
      Component: 'Backend-ApplicationInsights'
    })
    kind: 'web'
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    disableIpMasking: false
    disableLocalAuth: false
  }
}

// =========== FUNCTION APP STORAGE ACCOUNT (AVM) ===========

// Storage account for Function App runtime requirements
module functionStorageAccount 'br/public:avm/res/storage/storage-account:0.20.0' = {
  name: 'backend-functionStorageAccount-${regionReference[location]}'
  params: {
    name: resourceNames.functionStorageAccount
    location: location
    tags: union(tags, {
      Component: 'Backend-FunctionStorage'
    })
    kind: 'StorageV2'
    skuName: 'Standard_LRS'

    // Enable system-assigned managed identity
    managedIdentities: {
      systemAssigned: true
    }

    // Storage account properties for Function App
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false

    // Basic blob services configuration
    blobServices: {
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
      containers: [
        {
          name: 'function-container'
          properties: {
            publicAccess: 'None'
            metadata: {
              createdBy: 'FunctionApp'
            }
          }
        }
      ]
    } // Network access rules
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
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
// =========== AZURE FUNCTION APP (AVM) ===========

// Function App for AI Foundry backend proxy using AVM
module functionApp 'br/public:avm/res/web/site:0.16.0' = {
  name: 'backend-functionApp-${regionReference[location]}'
  params: {
    name: resourceNames.functionApp
    location: location
    tags: union(tags, {
      Component: 'Backend-FunctionApp'
    })
    kind: 'functionapp'

    // Enable system-assigned managed identity for AI Foundry access
    managedIdentities: {
      systemAssigned: true
    }

    // Function App configuration
    functionAppConfig: {
      deployment: {
        storage: {
          value: '${functionStorageAccount.outputs.primaryBlobEndpoint}function-container'
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
    serverFarmResourceId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled' // Site configuration for Function App
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
          value: functionStorageAccount.outputs.name
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.outputs.connectionString
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
    principalId: functionApp.outputs.systemAssignedMIPrincipalId!
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
    principalId: functionApp.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
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
    principalId: functionApp.outputs.systemAssignedMIPrincipalId!
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
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
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

@description('Application Insights Resource ID')
output applicationInsightsId string = applicationInsights.outputs.resourceId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('Backend API URL for frontend configuration')
output backendApiUrl string = 'https://${functionApp.outputs.name}.azurewebsites.net/api'

@description('Function App Name')
output functionAppName string = functionApp.outputs.name

@description('Function App System Assigned Identity Principal ID')
output functionAppSystemAssignedIdentityPrincipalId string = functionApp.outputs.systemAssignedMIPrincipalId!

@description('Function App URL')
output functionAppUrl string = 'https://${functionApp.outputs.name}.azurewebsites.net'

@description('Function Storage Account Name')
output functionStorageAccountName string = functionStorageAccount.outputs.name

@description('Function Storage Account Resource ID')
output functionStorageAccountResourceId string = functionStorageAccount.outputs.resourceId
