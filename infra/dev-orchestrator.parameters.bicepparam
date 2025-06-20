using 'main-orchestrator.bicep'

// Environment and application configuration
param environmentName = 'dev'
param applicationName = 'ai-foundry-spa'
param location = 'eastus2'
param resourceToken = '001'

// Log Analytics workspace configuration (existing resource lookup)
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryAgentName = 'CancerBot'
param aiFoundryAgentId = 'asst_dH7M0nbmdRblhSQO8nIGIYF4'
param aiFoundryEndpoint = 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject'
// aiFoundrySubscriptionId will use subscription() function default - no need to specify
param aiFoundryResourceGroup = 'rg-ai-foundry-dev'
param aiFoundryProjectName = 's'

// AI Foundry resource for RBAC assignment
param aiFoundryResourceName = 'ai-foundry-dev-eus'
param aiFoundryResourceGroupName = 'rg-ai-foundry-dev-eus'

// Resource tags
param tags = {
  Environment: 'dev'
  Application: 'ai-foundry-spa'
  ProjectType: 'AI-Foundry-SPA'
  DeployedBy: 'Azure-CLI'
  AIFoundryAgent: 'CancerBot'
  ManagedIdentity: 'SystemAssigned'
  Monitoring: 'ApplicationInsights'
  Architecture: 'Multi-ResourceGroup'
}
