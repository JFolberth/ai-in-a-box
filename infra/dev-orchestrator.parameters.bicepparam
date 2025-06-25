using 'main-orchestrator.bicep'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryAgentId = 'asst_dH7M0nbmdRblhSQO8nIGIYF4'
param aiFoundryAgentName = 'AI in a Box'
param aiFoundryEndpoint = 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject'
param aiFoundryProjectName = 's'
param aiFoundryResourceGroupName = 'rg-ai-foundry-dev-eus'
param aiFoundryResourceName = 'ai-foundry-dev-eus'
// aiFoundrySubscriptionId will use subscription() function default - no need to specify

// AI Foundry deployment configuration (when enableAiFoundryDeployment = true)
param enableAiFoundryDeployment = true // Set to true to deploy new AI Foundry resources
param aiFoundryModelDeploymentName = 'gpt-4o-mini'
param aiFoundryModelVersion = '2024-07-18'
param aiFoundryDeploymentCapacity = 10000
param aiFoundryProjectDisplayName = 'AI in A Box Project'
param aiFoundryProjectDescription = 'AI in A Box foundry project with GPT-4o-mini model deployment'

// Environment and application configuration
param applicationName = 'ai-foundry-spa'
param environmentName = 'dev'
param location = 'eastus2'

// Log Analytics workspace configuration (existing resource lookup)
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'

// Resource tags (alphabetized by key)
param tags = {
  AIFoundryAgent: 'AI in a Box'
  Application: 'ai-foundry-spa'
  Architecture: 'Multi-ResourceGroup'
  DeployedBy: 'Azure-CLI'
  Environment: 'dev'
  ManagedIdentity: 'SystemAssigned'
  Monitoring: 'ApplicationInsights'
  ProjectType: 'AI-Foundry-SPA'
}
