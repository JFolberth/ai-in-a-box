using 'main.bicep'

// AI Foundry configuration
param aiFoundryAgentId = 'asst_example_agent_id'
param aiFoundryAgentName = 'CancerBot'
param aiFoundryEndpoint = 'https://example-ai-foundry.services.ai.azure.com/api/projects/exampleProject'
param aiFoundryProjectName = 'example-ai-foundry'
param aiFoundryResourceGroup = 'rg-ai-foundry-validation'
param aiFoundrySubscriptionId = '00000000-0000-0000-0000-000000000000'

// Application configuration
param applicationName = 'ai-foundry-spa'
param environmentName = 'validation'
param location = 'eastus2'

// Log Analytics configuration
param logAnalyticsWorkspaceName = 'la-logging-validation-eus2'
param logAnalyticsResourceGroupName = 'rg-logging-validation-eus2'

param resourceToken = 'val'

// Resource tags
param tags = {
  Environment: 'validation'
  Application: 'ai-foundry-spa'
  Purpose: 'CI-Validation'
  AIFoundryAgent: 'CancerBot'
}