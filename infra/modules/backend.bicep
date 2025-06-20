// Backend Infrastructure Module
// This module deploys the backend resources: Function App + Storage + Application Insights

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string

@description('Application name used for resource naming')
param applicationName string

@description('Azure region for resource deployment')
param location string

@description('Resource token for unique naming')
param resourceToken string

@description('Log Analytics Workspace Name for consolidated logging')
param logAnalyticsWorkspaceName string

@description('Resource Group containing the Log Analytics Workspace')
param logAnalyticsResourceGroupName string

@description('AI Foundry agent ID for endpoint interaction')
param aiFoundryAgentId string

@description('AI Foundry endpoint URL for API calls')
param aiFoundryEndpoint string

@description('AI Foundry agent name for endpoint interaction')
param aiFoundryAgentName string

@description('AI Foundry subscription ID')
param aiFoundrySubscriptionId string

@description('AI Foundry resource group name')
param aiFoundryResourceGroup string

@description('AI Foundry project name')
param aiFoundryProjectName string

@description('Tags to apply to all resources')
param tags object

// =========== VARIABLES ===========

var resourceNames = {
  functionStorageAccount: 'stfnbackspa${resourceToken}'
  applicationInsights: 'appi-${applicationName}-backend-${environmentName}-${resourceToken}'
  functionApp: 'func-${applicationName}-backend-${environmentName}-${resourceToken}'
  appServicePlan: 'asp-${applicationName}-backend-${environmentName}-${resourceToken}'
}

// =========== EXISTING RESOURCES ===========

// Reference to existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}

// =========== APPLICATION INSIGHTS (AVM) ===========

// Application Insights for backend monitoring using AVM
module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'backend-applicationInsights'
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
  name: 'backend-functionStorageAccount'
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
    }
    
    // Network access rules
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
  name:  resourceNames.appServicePlan
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
  name: 'backend-functionApp'
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
    functionAppConfig:{
      deployment: {
        storage: {
          value: functionStorageAccount.outputs.primaryBlobEndpoint
          type: 'blobContainer'
           authentication:{
              type: 'SystemAssignedIdentity'
           }
          }
        }
      runtime:{
        name:'dotnet-isolated'
        version:'8.0'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 40
        }
      }
    serverFarmResourceId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
      // Site configuration for Function App
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
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
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
          name: 'AI_FOUNDRY_SUBSCRIPTION_ID'
          value: aiFoundrySubscriptionId
        }
        {
          name: 'AI_FOUNDRY_RESOURCE_GROUP'
          value: aiFoundryResourceGroup
        }
        {
          name: 'AI_FOUNDRY_PROJECT_NAME'
          value: aiFoundryProjectName
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

// Note: Azure AI Developer role assignment is handled at the orchestrator level
// due to cross-resource group scope requirements

// =========== OUTPUTS ===========
/**/
@description('Function App Name')
output functionAppName string = functionApp.outputs.name

@description('Function App URL')
output functionAppUrl string = 'https://${functionApp.outputs.defaultHostname}'

@description('Function App System Assigned Identity Principal ID')
output functionAppSystemAssignedIdentityPrincipalId string = functionApp.outputs.systemAssignedMIPrincipalId!

@description('Backend API URL for frontend configuration')
output backendApiUrl string = 'https://${functionApp.outputs.defaultHostname}/api'

@description('Application Insights Resource ID')
output applicationInsightsId string = applicationInsights.outputs.resourceId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

@description('Function Storage Account Name')
output functionStorageAccountName string = functionStorageAccount.outputs.name

@description('Function Storage Account Resource ID')
output functionStorageAccountResourceId string = functionStorageAccount.outputs.resourceId


