using 'main.bicep'

// Application configuration
param applicationName = 'ai-foundry-spa'
param environmentName = 'validation'
param location = 'eastus2'

// Log Analytics configuration
param logAnalyticsWorkspaceName = 'la-logging-validation-eus2'
param logAnalyticsResourceGroupName = 'rg-logging-validation-eus2'

// Resource tags
param tags = {
  Environment: 'validation'
  Application: 'ai-foundry-spa'
  Purpose: 'CI-Validation'
}
