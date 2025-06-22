using 'main-orchestrator.bicep'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryAgentId = 'asst_dH7M0nbmdRblhSQO8nIGIYF4'
param aiFoundryAgentName = 'CancerBot'
param aiFoundryEndpoint = 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject'
param aiFoundryProjectName = 's'
param aiFoundryResourceGroup = 'rg-ai-foundry-dev'
param aiFoundryResourceGroupName = 'rg-ai-foundry-dev-eus'
param aiFoundryResourceName = 'ai-foundry-dev-eus'
// aiFoundrySubscriptionId will use subscription() function default - no need to specify

// Environment and application configuration
param applicationName = 'ai-foundry-spa'
param environmentName = 'dev'
param location = 'eastus2'

// Log Analytics workspace configuration (existing resource lookup)
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'

param resourceToken = '001'

// Resource tags (alphabetized by key)
param tags = {
  AIFoundryAgent: 'CancerBot'
  Application: 'ai-foundry-spa'
  Architecture: 'Multi-ResourceGroup'
  DeployedBy: 'Azure-CLI'
  Environment: 'dev'
  ManagedIdentity: 'SystemAssigned'
  Monitoring: 'ApplicationInsights'
  ProjectType: 'AI-Foundry-SPA'
}
