// Log Analytics Workspace Module
// This module creates a Log Analytics workspace using Azure Verified Modules (AVM)
// Provides centralized logging for both frontend and backend Application Insights
// Uses AVM-compatible parameter names: skuName and dataRetention

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Azure region for the workspace')
param location string = resourceGroup().location

@description('Pricing tier for the workspace')
@allowed(['Free', 'Standard', 'Premium', 'PerNode', 'PerGB2018', 'Standalone'])
param pricingTier string = 'PerGB2018'

@description('Data retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to the workspace')
param tags object = {}

// =========== LOG ANALYTICS WORKSPACE (AVM) ===========

// Log Analytics Workspace using Azure Verified Module
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'log-analytics-workspace'
  params: {
    name: workspaceName
    location: location
    tags: tags
    skuName: pricingTier
    dataRetention: retentionInDays
  }
}

// =========== OUTPUTS ===========

@description('Resource ID of the Log Analytics workspace')
output workspaceId string = logAnalyticsWorkspace.outputs.resourceId

@description('Name of the Log Analytics workspace')
output workspaceName string = logAnalyticsWorkspace.outputs.name

@description('Customer ID (workspace ID) for the Log Analytics workspace')
output customerId string = logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId

@description('Resource group name containing the workspace')
output resourceGroupName string = resourceGroup().name

@description('Location of the Log Analytics workspace')
output location string = location

@description('Pricing tier of the Log Analytics workspace')
output pricingTier string = pricingTier

@description('Data retention period of the Log Analytics workspace')
output retentionInDays int = retentionInDays
