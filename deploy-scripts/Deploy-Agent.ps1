#!/usr/bin/env pwsh
<#
.SYNOPSIS
AI Foundry Agent Deployment Script

.DESCRIPTION
This script deploys an AI agent to Azure AI Foundry using configuration from a YAML file.
It handles authentication via managed identity or Azure CLI and provides detailed logging 
and error handling for the deployment process.

.PARAMETER AiFoundryEndpoint
The AI Foundry endpoint URL for API calls.

.PARAMETER OutputFormat
Output format for results (default: "human", options: "human", "json").

.PARAMETER AgentYamlPath
Path to the agent YAML configuration file (default: "src/agent/ai_in_a_box.yaml").

.PARAMETER LogLevel
Logging level (default: "Information", options: "Error", "Warning", "Information", "Verbose").

.PARAMETER AgentName
Override the agent name from YAML. Optional.

.PARAMETER Force
Force update if agent already exists. Default: false.

.EXAMPLE
./Deploy-Agent.ps1 -AiFoundryEndpoint "https://ai-foundry-dev.services.ai.azure.com/api/projects/myproject"

.EXAMPLE
./Deploy-Agent.ps1 -AiFoundryEndpoint "https://ai-foundry.services.ai.azure.com/api/projects/prod" -OutputFormat "json"

.NOTES
Author: AI Foundry SPA Project
Version: 4.0 (Unified)
Last Modified: 2025-07-13

This script is designed to work both locally and in CI/CD environments.
For CI/CD integration, use OutputFormat 'json' and parse the AGENT_DEPLOYMENT_RESULT line.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AiFoundryEndpoint,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("human", "json")]
    [string]$OutputFormat = "human",
    
    [Parameter(Mandatory = $false)]
    [string]$AgentYamlPath = "src/agent/ai_in_a_box.yaml",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Information", "Verbose")]
    [string]$LogLevel = "Information",
    
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Determine the workspace root (project root directory)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir

# Resolve agent YAML path relative to workspace root
$agentYamlFullPath = Join-Path $workspaceRoot $AgentYamlPath

# Configuration constants
$DefaultModelName = "gpt-4o-mini"

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Error", "Warning", "Information", "Verbose")]
        [string]$Level = "Information"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($OutputFormat -eq "human") {
        switch ($Level) {
            "Error" { 
                Write-Error $logMessage
            }
            "Warning" { 
                if ($LogLevel -in @("Warning", "Information", "Verbose")) {
                    Write-Warning $logMessage
                }
            }
            "Information" { 
                if ($LogLevel -in @("Information", "Verbose")) {
                    Write-Host $logMessage -ForegroundColor Green
                }
            }
            "Verbose" { 
                if ($LogLevel -eq "Verbose") {
                    Write-Verbose $logMessage
                }
            }
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
        [string]$ErrorMessage = "",
        [string]$Model = "",
        [string]$OperationType = ""
    )
    
    if ($OutputFormat -eq "json") {
        if ($Success) {
            $result = @{
                success          = $true
                agentId          = $AgentId
                agentName        = $AgentName
                endpoint         = $Endpoint
                model            = $Model
                operationType    = $OperationType
                wasExistingAgent = ($OperationType -eq "updated")
            }
        }
        else {
            $result = @{
                success = $false
                error   = "Deployment script failed: $ErrorMessage"
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
        }
        
        $jsonOutput = $result | ConvertTo-Json -Compress
        Write-Output "AGENT_DEPLOYMENT_RESULT: $jsonOutput"
    }
    else {
        if ($Success) {
            Write-Log "🎉 Agent deployment completed successfully!" -Level "Information"
            Write-Log "   Agent ID: $AgentId" -Level "Information"
            Write-Log "   Operation: $OperationType" -Level "Information"
        }
        else {
            Write-Log "💥 Agent deployment failed: $ErrorMessage" -Level "Error"
        }
    }
}

Write-Log "🚀 Starting AI Foundry agent deployment" -Level "Information"

try {
    # =========== VALIDATION ===========
    
    Write-Log "🔍 Validating prerequisites..." -Level "Information"
    
    # Validate YAML file exists
    if (-not (Test-Path $agentYamlFullPath)) {
        throw "Agent YAML file not found: $agentYamlFullPath"
    }
    
    # Read YAML content
    try {
        $yamlContent = Get-Content -Path $agentYamlFullPath -Raw
        if ([string]::IsNullOrEmpty($yamlContent)) {
            throw "YAML file is empty"
        }
        Write-Log "✅ YAML file loaded successfully" -Level "Information"
    }
    catch {
        throw "Failed to read YAML file: $($_.Exception.Message)"
    }
    
    # Validate endpoint URL format
    try {
        $uri = [System.Uri]$AiFoundryEndpoint
        if ($uri.Scheme -notin @('http', 'https')) {
            throw "Invalid endpoint scheme. Must be http or https."
        }
        Write-Log "✅ Endpoint URL format is valid" -Level "Information"
    }
    catch {
        Write-Log "❌ Invalid AI Foundry endpoint URL: $AiFoundryEndpoint" -Level "Error"
        throw "Invalid AI Foundry endpoint URL format: $($_.Exception.Message)"
    }
    
    # Function to get access token for API calls
    function Get-AccessToken {
        try {
            # Try managed identity first
            $tokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://ai.azure.com/"
            $headers = @{ 'Metadata' = 'true' }
            $tokenResponse = Invoke-RestMethod -Uri $tokenUri -Headers $headers -Method Get -TimeoutSec 10
            Write-Log "✅ Retrieved access token via managed identity" -Level "Verbose"
            return $tokenResponse.access_token
        }
        catch {
            Write-Log "⚠️ Managed identity token retrieval failed, trying Azure CLI..." -Level "Verbose"
            
            # Fallback to Azure CLI
            try {
                $token = az account get-access-token --scope "https://ai.azure.com/.default" --query "accessToken" -o tsv 2>$null
                if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($token)) {
                    Write-Log "✅ Retrieved access token via Azure CLI" -Level "Verbose"
                    return $token
                }
                else {
                    throw "Azure CLI token retrieval failed"
                }
            }
            catch {
                Write-Log "❌ Failed to get access token from Azure CLI: $($_.Exception.Message)" -Level "Error"
                throw "Unable to retrieve access token. Ensure you're authenticated with Azure CLI or running with managed identity."
            }
        }
    }
    
    # Function to parse YAML agent configuration
    function Read-AgentYaml {
        param([string]$YamlContent)
        
        try {
            Write-Log "✅ Processing YAML content ($($YamlContent.Length) characters)" -Level "Information"
            
            # Parse YAML fields using regex
            $name = if ($YamlContent -match 'name:\s*(.+)') { $matches[1].Trim() } else { "" }
            $version = if ($YamlContent -match 'version:\s*(.+)') { $matches[1].Trim() } else { "1.0.0" }
            
            # Extract description (handle multiline literal scalar with |)
            $description = ""
            if ($YamlContent -match 'description:\s*\|\s*\r?\n((?:\s{2}.*\r?\n?)*?)(?=\r?\n\s*#|\r?\n\s*[a-zA-Z_]+:|$)') {
                $description = $matches[1] -replace '^\s{2}', '' -replace '\r?\n\s{2}', "`n" -replace '\r?\n$', ''
                $description = $description.Trim()
            }
            elseif ($YamlContent -match 'description:\s*"([^"]*(?:\\.[^"]*)*)"') {
                $description = $matches[1] -replace '\\r\\n', "`r`n" -replace '\\n', "`n" -replace '\\"', '"'
            }
            elseif ($YamlContent -match 'description:\s*(.+)') {
                $description = $matches[1].Trim()
            }
            
            # Extract instructions (handle multiline literal scalar with |)
            $instructions = ""
            if ($YamlContent -match 'instructions:\s*\|\s*\r?\n((?:\s{2}(?!#).*\r?\n?)*?)(?=\r?\n\s*[a-zA-Z_]+:|$)') {
                $instructions = $matches[1] -replace '^\s{2}', '' -replace '\r?\n\s{2}', "`n" -replace '\r?\n$', ''
                $instructions = $instructions.Trim()
            }
            elseif ($YamlContent -match 'instructions:\s*"([^"]*(?:\\.[^"]*)*)"') {
                $instructions = $matches[1] -replace '\\r\\n', "`r`n" -replace '\\n', "`n" -replace '\\"', '"'
            }
            elseif ($YamlContent -match 'instructions:\s*(.+)') {
                $instructions = $matches[1].Trim()
            }
            
            # Extract model configuration
            $modelId = $DefaultModelName # Default fallback
            if ($YamlContent -match 'model:\s*\n\s*#[^\n]*\n\s*id:\s*(.+)') {
                $modelId = $matches[1].Trim()
            }
            elseif ($YamlContent -match 'model:\s*\n\s*id:\s*(.+)') {
                $modelId = $matches[1].Trim()
            }
            
            # Extract model options if present
            $temperature = 1
            $topP = 1
            if ($YamlContent -match 'temperature:\s*(.+)') {
                $temperature = [double]$matches[1].Trim()
            }
            if ($YamlContent -match 'top_p:\s*(.+)') {
                $topP = [double]$matches[1].Trim()
            }
            
            # Extract tools
            $tools = @()
            
            $result = @{
                name         = $name
                description  = $description
                instructions = $instructions
                model        = $modelId
                temperature  = $temperature
                topP         = $topP
                tools        = $tools
                version      = $version
            }
            
            Write-Log "✅ Parsed agent configuration:" -Level "Information"
            Write-Log "   📝 Name: $name" -Level "Information"
            Write-Log "   🤖 Model: $modelId" -Level "Information"
            Write-Log "   📊 Temperature: $temperature" -Level "Verbose"
            Write-Log "   📋 Instructions length: $($instructions.Length) characters" -Level "Information"
            
            return $result
        }
        catch {
            throw "Failed to parse YAML content: $($_.Exception.Message)"
        }
    }
    
    # =========== READ AGENT CONFIGURATION FROM YAML ===========
    
    Write-Log "📖 Reading agent configuration from YAML..." -Level "Information"
    
    $agentConfig = Read-AgentYaml -YamlContent $yamlContent
    
    # Extract configuration values (allow override from parameter)
    $finalAgentName = if (-not [string]::IsNullOrEmpty($AgentName)) { $AgentName } elseif (-not [string]::IsNullOrEmpty($agentConfig.name)) { $agentConfig.name } else { "AI in A Box Agent" }
    $agentDescription = if (-not [string]::IsNullOrEmpty($agentConfig.description)) { $agentConfig.description } else { "AI in A Box intelligent assistant agent" }
    $agentInstructions = $agentConfig.instructions
    $modelName = if (-not [string]::IsNullOrEmpty($agentConfig.model)) { $agentConfig.model } else { $DefaultModelName }
    
    # Validate essential configuration
    if ([string]::IsNullOrEmpty($agentInstructions)) {
        throw "Agent instructions are empty in YAML file"
    }
    
    if ([string]::IsNullOrEmpty($finalAgentName)) {
        throw "Agent name is empty in YAML file"
    }
    
    Write-Log "✅ Agent configuration loaded successfully" -Level "Information"
    Write-Log "   Agent Name: $finalAgentName" -Level "Information"
    Write-Log "   Model: $modelName" -Level "Information"
    
    # =========== GET ACCESS TOKEN ===========
    
    Write-Log "🔑 Obtaining access token..." -Level "Information"
    
    $accessToken = Get-AccessToken
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Failed to obtain access token"
    }
    
    Write-Log "✅ Authentication successful" -Level "Information"
    
    # =========== PREPARE AGENT PAYLOAD ===========
    
    Write-Log "📦 Preparing agent payload..." -Level "Information"
    
    $agentPayload = @{
        name         = $finalAgentName
        description  = $agentDescription
        instructions = $agentInstructions
        model        = $modelName
        tools        = $agentConfig.tools
        metadata     = @{
            created_by        = "deploy-agent-script"
            created_date      = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            yaml_version      = $agentConfig.version
            deployment_method = "unified-script"
        }
    }
    
    # Note: model_options (temperature, top_p) are not supported by the Azure AI Foundry API
    # These settings from YAML are parsed but not included in the API payload
    
    $agentPayloadJson = $agentPayload | ConvertTo-Json -Depth 10
    
    Write-Log "✅ Agent payload prepared" -Level "Information"
    if ($LogLevel -eq "Verbose") {
        Write-Log "🔍 DEBUG: Full payload being sent:" -Level "Information"
        Write-Log "$agentPayloadJson" -Level "Information"
    }
    
    # =========== CHECK FOR EXISTING AGENT ===========
    
    Write-Log "🔍 Checking for existing agent..." -Level "Information"
    
    # Prepare headers
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type'  = 'application/json'
        'User-Agent'    = 'AI-Foundry-Deploy-Agent-Unified/4.0'
    }
    
    # Construct the assistants API endpoint
    $cleanEndpoint = $AiFoundryEndpoint.TrimEnd('/')
    $agentsEndpoint = "$cleanEndpoint/assistants?api-version=2025-05-01"
    
    Write-Log "📡 Final agents endpoint: '$agentsEndpoint'" -Level "Information"
    
    $existingAgent = $null
    try {
        Write-Log "🔍 Attempting to list existing assistants..." -Level "Information"
        $existingAgents = Invoke-RestMethod -Uri $agentsEndpoint -Method Get -Headers $headers -ErrorAction Stop
        
        if ($existingAgents -and $existingAgents.data) {
            $existingAgent = $existingAgents.data | Where-Object { $_.name -eq $finalAgentName } | Select-Object -First 1
            
            if ($existingAgent) {
                Write-Log "✅ Found existing agent: $($existingAgent.id)" -Level "Information"
            }
            else {
                Write-Log "ℹ️ No existing agent found with name '$finalAgentName'" -Level "Information"
            }
        }
    }
    catch {
        Write-Log "⚠️ Could not check for existing assistants: $($_.Exception.Message)" -Level "Warning"
        Write-Log "🔄 Proceeding with agent creation..." -Level "Information"
    }
    
    # =========== CREATE OR UPDATE AGENT ===========
    
    $response = $null
    $isUpdate = $false
    
    try {
        if ($existingAgent) {
            Write-Log "🔄 Updating existing AI Foundry agent..." -Level "Information"
            
            try {
                # Update existing agent
                $updateEndpoint = "$cleanEndpoint/assistants/$($existingAgent.id)?api-version=2025-05-01"
                $webResponse = Invoke-WebRequest -Uri $updateEndpoint -Method Post -Body $agentPayloadJson -Headers $headers -ContentType "application/json" -ErrorAction Stop
                $response = $webResponse.Content | ConvertFrom-Json
                $isUpdate = $true
                Write-Log "✅ Successfully updated existing agent" -Level "Information"
            }
            catch {
                Write-Log "⚠️ Failed to update existing agent: $($_.Exception.Message)" -Level "Warning"
                Write-Log "🔄 Attempting to create new agent instead..." -Level "Information"
                
                # If update fails, try to create new agent
                $webResponse = Invoke-WebRequest -Uri $agentsEndpoint -Method Post -Body $agentPayloadJson -Headers $headers -ContentType "application/json" -ErrorAction Stop
                $response = $webResponse.Content | ConvertFrom-Json
                $isUpdate = $false
            }
        }
        else {
            Write-Log "🤖 Creating new AI Foundry agent..." -Level "Information"
            
            # Create new agent with detailed error handling
            try {
                $ProgressPreference = 'SilentlyContinue'  # Suppress progress bars
                
                $webResponse = Invoke-WebRequest -Uri $agentsEndpoint -Method Post -Body $agentPayloadJson -Headers $headers -ContentType "application/json" -ErrorAction Stop
                $response = $webResponse.Content | ConvertFrom-Json
                $isUpdate = $false
                Write-Log "✅ Successfully created new agent" -Level "Information"
            }
            catch {
                Write-Log "🔍 Full Exception Details:" -Level "Error"
                Write-Log "  Type: $($_.Exception.GetType().FullName)" -Level "Error"
                Write-Log "  Message: $($_.Exception.Message)" -Level "Error"
                
                if ($_.ErrorDetails) {
                    Write-Log "🔍 PowerShell ErrorDetails: $($_.ErrorDetails)" -Level "Error"
                }
                
                throw $_.Exception.Message
            }
        }
        
        if ($response -and $response.id) {
            $agentId = $response.id
            $operationType = if ($isUpdate) { "updated" } else { "created" }
            Write-Log "✅ Successfully $operationType agent with ID: $agentId" -Level "Information"
            Write-Log "🎯 Agent name: $($response.name)" -Level "Information"
            
            # Output results
            Write-Final-Result -Success $true -AgentId $agentId -AgentName $response.name -Endpoint $AiFoundryEndpoint -Model $response.model -OperationType $operationType
        }
        else {
            throw "Agent operation succeeded but no agent ID returned in response"
        }
    }
    catch {
        $errorDetails = $_.Exception.Message
        Write-Log "❌ Failed to create agent: $errorDetails" -Level "Error"
        throw $errorDetails
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Final-Result -Success $false -ErrorMessage $errorMessage
    exit 1
}
finally {
    Write-Log "🏁 Agent deployment script completed" -Level "Information"
}
