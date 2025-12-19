using 'main.bicep'

// AI Foundry configuration
param aiFoundryInstanceName = 'example-ai-foundry-workspace'
param aiFoundryResourceGroupName = 'rg-ai-foundry-validation-eus2'
param aiFoundryEndpoint = 'https://example-ai-foundry.services.ai.azure.com/api/projects/exampleProject'
param aiFoundryAgentId = 'asst_example_agent_id'
param aiFoundryAgentName = 'AI In A Box'

// Application configuration
param applicationName = 'ai-box'
param environmentName = 'validation'
param location = 'eastus2'

// Log Analytics configuration
param logAnalyticsWorkspaceName = 'la-logging-validation-eus2'
param logAnalyticsResourceGroupName = 'rg-logging-validation-eus2'

// Resource tags
param tags = {
  Environment: 'validation'
  Application: 'ai-box'
  Purpose: 'CI-Validation'
  AIFoundryAgent: 'AI in A Box'
}
