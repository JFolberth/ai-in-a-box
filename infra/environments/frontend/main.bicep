// Frontend Infrastructure Module
// This module deploys the frontend resources: Static Web App + Application Insights

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Name for the Azure Deployment Environment')
param adeName string = ''

@description('Application name used for resource naming')
param applicationName string = 'aibox'

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
  staticWebApp: 'stapp-${nameSuffix}'
}

var typeInfrastructure = 'fd'

// =========== EXISTING RESOURCES ===========

// Reference to existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroupName)
}

// =========== APPLICATION INSIGHTS (AVM) ===========

// Application Insights for frontend monitoring using AVM
module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'frontend-applicationInsights-${regionReference[location]}'
  params: {
    name: resourceNames.applicationInsights
    location: location
    tags: union(tags, {
      Component: 'Frontend-ApplicationInsights'
    })
    kind: 'web'
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// =========== STATIC WEB APP (AVM) ===========

// Static Web App for hosting the frontend using AVM
module staticWebApp 'br/public:avm/res/web/static-site:0.5.0' = {
  name: 'frontend-staticWebApp-${regionReference[location]}'
  params: {
    name: resourceNames.staticWebApp
    location: location
    tags: union(tags, {
      Component: 'Frontend-StaticWebApp'
    })

    // Application Insights integration
    appSettings: {
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.outputs.instrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.outputs.connectionString
    }
  }
}

// =========== RBAC ASSIGNMENTS ===========

// For Static Web Apps, RBAC is typically managed through the platform
// No explicit role assignments needed for basic functionality

// =========== OUTPUTS ===========

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

@description('Application Insights Resource ID')
output applicationInsightsId string = applicationInsights.outputs.resourceId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('Static Web App URL')
output staticWebsiteUrl string = 'https://${staticWebApp.outputs.defaultHostname}'

@description('Static Web App Name')
output staticWebAppName string = staticWebApp.outputs.name

@description('Static Web App Default Hostname')
output staticWebAppHostname string = staticWebApp.outputs.defaultHostname

@description('Static Web App System Assigned Identity Principal ID')
output systemAssignedIdentityPrincipalId string = staticWebApp.outputs.?systemAssignedMIPrincipalId ?? ''
