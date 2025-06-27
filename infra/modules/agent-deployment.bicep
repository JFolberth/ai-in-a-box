// Agent Deployment Module
// This module creates an Azure Deployment Script to deploy an AI Foundry agent
// after the infrastructure has been deployed

targetScope = 'resourceGroup'

// =========== PARAMETERS ===========

@description('Azure region for resource deployment')
param location string

@description('AI Foundry endpoint URL for API calls')
param aiFoundryEndpoint string

@description('Name of the AI agent to create or update')
param agentName string = 'AI in A Box Agent'

@description('Tags to apply to all resources')
param tags object = {}

// =========== VARIABLES ===========

var deploymentScriptName = 'deploy-aifoundry-agent'

// =========== RESOURCES ===========

// Deploy AI Foundry agent using AVM deployment script module
module agentDeploymentScript 'br/public:avm/res/resources/deployment-script:0.4.0' = {
  name: 'agent-deployment-script'
  params: {
    name: deploymentScriptName
    location: location
    kind: 'AzurePowerShell'
    azPowerShellVersion: '9.0'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    scriptContent: loadTextContent('../agent_deploy.ps1')
    arguments: '-AiFoundryEndpoint "${aiFoundryEndpoint}" -AgentName "${agentName}"'
    environmentVariables: [
      {
        name: 'AI_FOUNDRY_ENDPOINT'
        value: aiFoundryEndpoint
      }
    ]
    // System-assigned managed identity for Azure CLI authentication
    // Note: AVM uses system-assigned by default when managedIdentities is not specified
    enableTelemetry: false
    tags: tags
    // Force script re-run by not using runOnce (defaults to false)
    runOnce: false
  }
}

// Get reference to the actual deployment script resource for identity access
// This is needed because AVM module doesn't expose the identity in outputs
resource deploymentScriptResource 'Microsoft.Resources/deploymentScripts@2023-08-01' existing = {
  name: deploymentScriptName
  dependsOn: [
    agentDeploymentScript
  ]
}

// Note: RBAC assignment for deployment script identity to access AI Foundry resources
// will be handled by the main orchestrator due to cross-resource-group scope requirements

// =========== OUTPUTS ===========

@description('Agent deployment script name')
output deploymentScriptName string = agentDeploymentScript.outputs.name

@description('Agent deployment script resource ID')
output deploymentScriptResourceId string = agentDeploymentScript.outputs.resourceId

@description('Agent deployment script identity (system-assigned)')
output deploymentScriptIdentity object = deploymentScriptResource.identity

@description('Agent deployment script outputs (if any)')
output deploymentScriptOutputs object = agentDeploymentScript.outputs.outputs

@description('Agent deployment status')
output deploymentStatus object = {
  scriptName: agentDeploymentScript.outputs.name
  resourceId: agentDeploymentScript.outputs.resourceId
  aiFoundryEndpoint: aiFoundryEndpoint
}
