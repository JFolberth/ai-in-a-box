using 'main-orchestrator.bicep'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryProjectDisplayName = 'AI in A Box Project (s)'
param aiFoundryResourceName = 'cs-ai-foundry-dev-eus2'
param aiFoundryResourceGroupName = 'rg-ai-foundry-spa-aifoundry-dev-eus2'
param aiFoundryProjectName = 'aiproj-ai-foundry-dev-eus2'
param aiFoundryAgentId = 'asst_PzcEzGaglsRr2TyX4N48qlAJ'
param aiFoundryAgentName = 'AI In A Box'
// aiFoundrySubscriptionId will use subscription() function default - no need to specify

// Environment and application configuration
param location = 'eastus2'

// Log Analytics workspace creation options - using defaults for pricing tier and retention
param createLogAnalyticsWorkspace = false      // Creates new Log Analytics workspace and resource group with standard naming
// When createLogAnalyticsWorkspace = true, creates: rg-ai-foundry-spa-logging-dev-eus2 and la-ai-foundry-spa-logging-dev-eus2
// When createLogAnalyticsWorkspace = false, uses existing resources specified below:
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'

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
