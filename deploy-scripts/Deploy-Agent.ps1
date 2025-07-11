#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy AI Foundry Agent from YAML configuration

.DESCRIPTION
This script deploys an AI Foundry agent using YAML configuration and REST API calls.
It models the current GitHub Actions CI workflow steps for agent deployment and can be used
for local development, testing, or manual deployment scenarios.

The script:
1. Reads agent configuration from YAML file
2. Authenticates with Azure (CLI or managed identity)
3. Calls AI Foundry REST API to create/update the agent
4. Returns deployment results in JSON format

.PARAMETER AiFoundryEndpoint
The AI Foundry endpoint URL for API calls. Required.
Example: "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"

.PARAMETER AgentYamlPath
Path to the agent YAML configuration file. Defaults to "src/agent/ai_in_a_box.yaml"

.PARAMETER AgentName
Override the agent name from YAML. Optional.

.PARAMETER OutputFormat
Output format: 'json' for machine parsing, 'human' for human-readable. Default: 'human'

.PARAMETER Force
Force update if agent already exists. Default: false

.EXAMPLE
./Deploy-Agent.ps1 -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"

.EXAMPLE
./Deploy-Agent.ps1 -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject" -AgentYamlPath "custom/agent.yaml" -OutputFormat "json"

.EXAMPLE
& "C:\Users\BicepDeveloper\repo\ai-in-a-box\deploy-scripts\Deploy-Agent.ps1" -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject" -Force

.PREREQUISITES
- Azure CLI installed and authenticated OR running in Azure environment with managed identity
- User/Service Principal must have appropriate permissions to AI Foundry resources
- Agent YAML configuration file must exist

.EXPECTED_OUTPUT
Human format:
- Deployment status messages
- Agent details (ID, name, endpoint)
- Success/failure status with error details

JSON format:
- {"success": true, "agentId": "asst_...", "agentName": "...", "endpoint": "..."}
- {"success": false, "error": "Error message"}

.NOTES
This script is designed to be used independently or called from other deployment scripts.
It follows the same pattern as the GitHub Actions CI workflow for consistency.

For CI/CD integration, use OutputFormat 'json' and parse the result.
For local development and testing, use OutputFormat 'human' for better readability.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AiFoundryEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$AgentYamlPath = "src/agent/ai_in_a_box.yaml",
    
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('json', 'human')]
    [string]$OutputFormat = 'human',
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write output based on format
function Write-Output-Message {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    if ($OutputFormat -eq 'human') {
        switch ($Level) {
            "Info" { Write-Host $Message -ForegroundColor Green }
            "Warning" { Write-Host $Message -ForegroundColor Yellow }
            "Error" { Write-Host $Message -ForegroundColor Red }
            "Success" { Write-Host $Message -ForegroundColor Green -BackgroundColor Black }
        }
    }
}

# Function to output final result
function Write-Final-Result {
    param(
        [bool]$Success,
        [string]$AgentId = "",
        [string]$AgentName = "",
        [string]$Endpoint = "",
        [string]$Error = ""
    )
    
    if ($OutputFormat -eq 'json') {
        if ($Success) {
            $result = @{
                success = $true
                agentId = $AgentId
                agentName = $AgentName
                endpoint = $Endpoint
            }
        } else {
            $result = @{
                success = $false
                error = $Error
            }
        }
        
        $jsonOutput = $result | ConvertTo-Json -Compress
        Write-Output "AGENT_DEPLOYMENT_RESULT: $jsonOutput"
    } else {
        if ($Success) {
            Write-Output-Message "🎉 Agent deployment completed successfully! 🎉" "Success"
            Write-Output-Message ""
            Write-Output-Message "📋 Agent Details:" "Info"
            Write-Output-Message "   Agent ID: $AgentId" "Info"
            Write-Output-Message "   Agent Name: $AgentName" "Info"
            Write-Output-Message "   Endpoint: $Endpoint" "Info"
        } else {
            Write-Output-Message "❌ Agent deployment failed: $Error" "Error"
        }
    }
}

try {
    Write-Output-Message "🤖 AI Foundry Agent Deployment" "Info"
    Write-Output-Message "===============================" "Info"
    
    # Change to project root (go up from deploy-scripts to project root)
    $projectRoot = Split-Path $PSScriptRoot -Parent
    Set-Location $projectRoot
    
    Write-Output-Message "📁 Project root: $projectRoot" "Info"
    Write-Output-Message "🎯 AI Foundry endpoint: $AiFoundryEndpoint" "Info"
    Write-Output-Message "📄 Agent YAML path: $AgentYamlPath" "Info"
    
    # Verify YAML file exists
    if (-not (Test-Path $AgentYamlPath)) {
        Write-Final-Result -Success $false -Error "Agent YAML file not found: $AgentYamlPath"
        exit 1
    }
    
    # Read YAML content
    Write-Output-Message "📖 Reading agent configuration from YAML..." "Info"
    $yamlContent = Get-Content -Path $AgentYamlPath -Raw
    
    if ([string]::IsNullOrEmpty($yamlContent)) {
        Write-Final-Result -Success $false -Error "Agent YAML file is empty or could not be read"
        exit 1
    }
    
    Write-Output-Message "✅ YAML content loaded successfully" "Info"
    
    # Check Azure CLI authentication
    Write-Output-Message "🔐 Checking Azure authentication..." "Info"
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        Write-Output-Message "✅ Azure CLI authenticated as: $($account.user.name)" "Info"
        Write-Output-Message "📋 Subscription: $($account.name) ($($account.id))" "Info"
    } catch {
        Write-Final-Result -Success $false -Error "Azure CLI not authenticated. Please run 'az login' first."
        exit 1
    }
    
    # Set environment variables for the agent deployment script
    Write-Output-Message "🔧 Configuring deployment environment..." "Info"
    $env:AI_FOUNDRY_ENDPOINT = $AiFoundryEndpoint
    $env:AGENT_YAML_CONTENT = $yamlContent
    
    if (-not [string]::IsNullOrEmpty($AgentName)) {
        $env:AGENT_NAME = $AgentName
        Write-Output-Message "🏷️ Using custom agent name: $AgentName" "Info"
    } else {
        Write-Output-Message "🏷️ Using agent name from YAML configuration" "Info"
    }
    
    if ($Force) {
        Write-Output-Message "⚡ Force mode enabled - will update existing agent" "Warning"
    }
    
    # Execute the infrastructure agent deployment script
    Write-Output-Message "🚀 Executing agent deployment..." "Info"
    $agentScriptPath = "infra/agent_deploy.ps1"
    
    if (-not (Test-Path $agentScriptPath)) {
        Write-Final-Result -Success $false -Error "Agent deployment script not found: $agentScriptPath"
        exit 1
    }
    
    # Run the agent deployment script and capture output
    $output = & $agentScriptPath 2>&1
    
    if ($OutputFormat -eq 'human') {
        Write-Output-Message "📄 Agent deployment script output:" "Info"
        Write-Host $output
    }
    
    # Look for the AGENT_DEPLOYMENT_RESULT line in the output
    $resultLine = $output | Where-Object { $_ -match "AGENT_DEPLOYMENT_RESULT:" }
    
    if ($resultLine) {
        $jsonPart = $resultLine -replace ".*AGENT_DEPLOYMENT_RESULT:\s*", ""
        
        if ($OutputFormat -eq 'human') {
            Write-Output-Message "🔍 Found deployment result: $jsonPart" "Info"
        }
        
        # Parse the JSON result
        $result = $jsonPart | ConvertFrom-Json
        
        if ($result.success) {
            Write-Final-Result -Success $true -AgentId $result.agentId -AgentName $result.agentName -Endpoint $AiFoundryEndpoint
        } else {
            Write-Final-Result -Success $false -Error $result.error
            exit 1
        }
    } else {
        Write-Final-Result -Success $false -Error "Could not find agent deployment result in script output"
        exit 1
    }
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Final-Result -Success $false -Error "Deployment script failed: $errorMessage"
    exit 1
}

Write-Output-Message ""
Write-Output-Message "✨ Agent deployment script completed! ✨" "Success"
