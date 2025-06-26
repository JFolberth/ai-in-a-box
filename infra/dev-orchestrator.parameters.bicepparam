using 'main-orchestrator.bicep'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryProjectDisplayName = 'AI in A Box Project (s)'
param aiFoundryResourceName = 'cs-ai-foundry-dev-eus2'
param aiFoundryResourceGroupName = 'rg-ai-foundry-spa-aifoundry-dev-eus2'
param aiFoundryEndpoint = 'https://cs-ai-foundry-dev-eus2.services.ai.azure.com/api/projects/exampleProject'
param aiFoundryAgentId = 'asst_r1FkmYZ9CPLMRDsJYhzzoVGa'
param aiFoundryAgentName = 'AI In A Box'
// aiFoundrySubscriptionId will use subscription() function default - no need to specify

// Environment and application configuration
param location = 'eastus2'

// Log Analytics workspace configuration (existing resource lookup)
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'


// Log Analytics workspace creation options - using defaults for pricing tier and retention

// Resource token parameter removed - naming now uses regionReference mapping

// Resource tags (alphabetized by key)
param tags = {
  AIFoundryAgent: 'AI in A Box'
  Application: 'ai-foundry-spa'
  Architecture: 'Multi-ResourceGroup'
  DeployedBy: 'Azure-CLI'
  Environment: 'dev'
  ManagedIdentity: 'SystemAssigned'
  Monitoring: 'ApplicationInsights'
  ProjectType: 'AI-Foundry-SPA'
}
