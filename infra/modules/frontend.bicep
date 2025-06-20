// Frontend Infrastructure Module
// This module deploys the frontend resources: Storage Account + Application Insights

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

@description('Tags to apply to all resources')
param tags object

// =========== VARIABLES ===========

var resourceNames = {
  storageAccount: 'staifrontspa${resourceToken}'
  applicationInsights: 'appi-${applicationName}-frontend-${environmentName}-${resourceToken}'
}

// =========== EXISTING RESOURCES ===========

// Reference to existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}

// =========== APPLICATION INSIGHTS (AVM) ===========

// Application Insights for frontend monitoring using AVM
module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'frontend-applicationInsights'
  params: {
    name: resourceNames.applicationInsights
    location: location
    tags: union(tags, {
      Component: 'Frontend-ApplicationInsights'
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

// =========== STORAGE ACCOUNT (AVM) ===========

// Storage Account for hosting the static website using AVM
module storageAccount 'br/public:avm/res/storage/storage-account:0.20.0' = {
  name: 'frontend-storageAccount'
  params: {
    name: resourceNames.storageAccount
    location: location
    tags: union(tags, {
      Component: 'Frontend-Storage'
    })
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    
    // Enable system-assigned managed identity
    managedIdentities: {
      systemAssigned: true
    }
    
    // Storage account properties
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    
    // Enable CORS through blob services
    blobServices: {
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 7
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
    
    // Network access rules
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    
    // Enable infrastructure encryption
    requireInfrastructureEncryption: false
  }
}

// =========== RBAC ASSIGNMENTS ===========

// Storage Blob Data Contributor role for the system-assigned managed identity
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(storageAccount.name, 'StorageBlobDataContributor', 'SystemAssigned')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: storageAccount.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Monitoring Metrics Publisher role for Application Insights (system-assigned identity)
resource monitoringRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(applicationInsights.name, 'MonitoringMetricsPublisher', 'SystemAssigned')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb') // Monitoring Metrics Publisher
    principalId: storageAccount.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// =========== OUTPUTS ===========

@description('Storage Account Name')
output storageAccountName string = storageAccount.outputs.name

@description('Storage Account Primary Endpoint')
output storageAccountPrimaryEndpoint string = storageAccount.outputs.primaryBlobEndpoint

@description('Static Website URL')
output staticWebsiteUrl string = replace(storageAccount.outputs.primaryBlobEndpoint, '//', '//')

@description('System Assigned Managed Identity Principal ID')
output systemAssignedIdentityPrincipalId string = storageAccount.outputs.systemAssignedMIPrincipalId

@description('Application Insights Resource ID')
output applicationInsightsId string = applicationInsights.outputs.resourceId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString
