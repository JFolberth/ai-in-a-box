using 'main-orchestrator.bicep'

// AI Foundry configuration (single endpoint) - Synced with local.settings.json
param aiFoundryProjectDisplayName = 'AI in A Box Project'
param aiFoundryResourceName = 'cs-ai-foundry-dev-eus2'
param aiFoundryResourceGroupName = 'rg-ai-foundry-spa-aifoundry-dev-eus2'
param aiFoundryProjectName = 'aiproj-ai-foundry-dev-eus2'
// aiFoundryAgentId parameter removed - backend will use fallback default and deployment script will update configuration
param aiFoundryAgentName = 'AI In A Box'
param aiFoundryAgentId = 'asst_O3mDIKF8Q7dAsOUd2m7kdz0H' // Placeholder, will be updated by deployment script
// Set to true to create new AI Foundry resources automatically, false to use existing
param createAiFoundryResourceGroup = true     // Using existing AI Foundry resources (specified above)
// aiFoundrySubscriptionId will use subscription() function default - no need to specify

// Environment and application configuration
param applicationName = 'conspiracy-bot'
param environmentName = 'dev'
param location = 'eastus2'

// AI Foundry model deployment configuration
param aiFoundryDeploymentCapacity = 100  // TPM (Tokens Per Minute) - matches Bicep template default

// Log Analytics workspace creation options - using defaults for pricing tier and retention
param createLogAnalyticsWorkspace = false      // Creates new Log Analytics workspace and resource group with standard naming
// When createLogAnalyticsWorkspace = true, creates: rg-ai-foundry-spa-logging-dev-eus2 and la-ai-foundry-spa-logging-dev-eus2
// When createLogAnalyticsWorkspace = false, uses existing resources specified below:
param logAnalyticsResourceGroupName = 'rg-logging-dev-eus'
param logAnalyticsWorkspaceName = 'la-logging-dev-eus'

// Bing Search configuration
param createBingSearchResourceGroup = true      // Creates new Bing Search service and resource group with standard naming
// When createBingSearchResourceGroup = true, creates: rg-conspiracy-bot-bingsearch-dev-eus2 and srch-conspiracy-bot-bingsearch-dev-eus2
// When createBingSearchResourceGroup = false, uses existing resources specified below:
param bingSearchResourceGroupName = ''
param bingSearchName = ''

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
