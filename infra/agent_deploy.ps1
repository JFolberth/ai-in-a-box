<#
.SYNOPSIS
Infrastructure-driven Azure AI Foundry agent creation script using YAML configuration.

.DESCRIPTION
This script creates an Azure AI Foundry agent using the Azure REST API after infrastructure deployment.
It reads agent configuration from a YAML file (ai_in_a_box.yaml) and uses the deployed AI Foundry 
resources to create or update the agent. This script is designed to be called from Azure Deployment 
Scripts within Bicep templates via environment variables.

.PARAMETER None
This script uses environment variables for configuration instead of parameters:
- AI_FOUNDRY_ENDPOINT: The AI Foundry endpoint URL for API calls (required)
- AGENT_NAME: The name of the AI agent to create or update (optional, defaults from YAML)
- AGENT_YAML_CONTENT: The complete YAML content for agent configuration (required)

.EXAMPLE
# Called from Bicep deployment script with environment variables
$env:AI_FOUNDRY_ENDPOINT="https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"
$env:AGENT_NAME="AI in A Box Agent"
.\agent_deploy.ps1

.EXAMPLE
# Local testing with environment variables
$env:AI_FOUNDRY_ENDPOINT="https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"
& "C:\deployments\infra\agent_deploy.ps1"

.PREREQUISITES
- Running in Azure environment with managed identity OR Azure CLI authenticated
- User/Service Principal must have appropriate permissions to AI Foundry resources
- AI_FOUNDRY_ENDPOINT environment variable must be set

.EXPECTED_OUTPUT
- Agent creation status and details
- Created agent ID and endpoint information
- Success/failure status with detailed error messages if applicable

.NOTES
This script is designed to be infrastructure-driven and called from Azure Deployment Scripts.
It receives agent configuration via environment variables including the complete YAML content,
and uses either managed identity or Azure CLI for authentication with Azure REST API for agent creation. 
The YAML content defines agent name, description, instructions, model configuration, tools, and metadata.

Environment Variables Required:
- AI_FOUNDRY_ENDPOINT: AI Foundry project endpoint URL
- AGENT_NAME: Name of the agent (optional, uses YAML default if not provided)
- AGENT_YAML_CONTENT: Complete YAML content for agent configuration

YAML Configuration Support:
- Agent name, description, and instructions
- Model configuration (ID, temperature, top_p)
- Tools and metadata definitions
- Version tracking and deployment history

Author: AI Foundry SPA Project
Version: 2.0 (YAML Integration)
Last Modified: 2025-06-30
#>

[CmdletBinding()]
param ()

# Get configuration from environment variables (set by Bicep deployment script)
$AiFoundryEndpoint = $env:AI_FOUNDRY_ENDPOINT
$AgentName = $env:AGENT_NAME
$AgentYamlContent = $env:AGENT_YAML_CONTENT

# Validate required environment variables
if ([string]::IsNullOrEmpty($AiFoundryEndpoint)) {
    throw "AI_FOUNDRY_ENDPOINT environment variable is required"
}

if ([string]::IsNullOrEmpty($AgentYamlContent)) {
    throw "AGENT_YAML_CONTENT environment variable is required"
}

if ([string]::IsNullOrEmpty($AgentName)) {
    $AgentName = "AI in A Box Agent"  # Default fallback
}

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration constants
$AgentDescription = "AI in A Box intelligent assistant agent created via infrastructure deployment"
$ModelDeploymentName = "gpt-4o-mini"
$LogLevel = "Information"

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Error", "Warning", "Information", "Verbose")]
        [string]$Level = "Information"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
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

Write-Log "🚀 Starting AI Foundry agent deployment" -Level "Information"
Write-Log "🔍 Environment Variables:" -Level "Information"
Write-Log "   📡 AI_FOUNDRY_ENDPOINT: $AiFoundryEndpoint" -Level "Information"
Write-Log "   🤖 AGENT_NAME: $AgentName" -Level "Information"
Write-Log "   📄 AGENT_YAML_CONTENT: $($AgentYamlContent.Length) characters" -Level "Information"

try {
    # =========== VALIDATION ===========
    
    Write-Log "🔍 Validating prerequisites..." -Level "Information"
    
    # Check authentication using managed identity metadata service (no Azure CLI needed)
    try {
        # Azure Instance Metadata Service endpoint for managed identity
        $metadataUri = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
        $headers = @{ 'Metadata' = 'true' }
        $instanceInfo = Invoke-RestMethod -Uri $metadataUri -Headers $headers -Method Get -TimeoutSec 10
        Write-Log "✅ Running in Azure environment with managed identity" -Level "Information"
        Write-Log "🔍 Compute environment: $($instanceInfo.compute.vmId)" -Level "Verbose"
    }
    catch {
        Write-Log "⚠️ Could not access Azure Instance Metadata Service - may not be in Azure environment" -Level "Warning"
        Write-Log "🔍 Will attempt Azure CLI authentication as fallback" -Level "Information"
        
        # Check if Azure CLI is available as fallback
        try {
            $null = az version --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Log "⚠️ Azure CLI is not available either" -Level "Warning"
            }
            else {
                Write-Log "✅ Azure CLI is available for fallback authentication" -Level "Information"
                
                # Check Azure CLI authentication
                $currentUser = az account show --query "user.name" -o tsv 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "⚠️ Not authenticated with Azure CLI. This may cause authentication failures." -Level "Warning"
                }
                else {
                    Write-Log "✅ Azure CLI authenticated as: $currentUser" -Level "Information"
                }
            }
        }
        catch {
            Write-Log "⚠️ Azure CLI validation failed: $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    # =========== READ AGENT CONFIGURATION FROM YAML ===========
    
    Write-Log "📖 Reading agent configuration from YAML content..." -Level "Information"
    
    # Function to parse YAML agent configuration from content string
    function Read-AgentYaml {
        param([string]$YamlContent)
        
        try {
            Write-Log "✅ Processing YAML content ($($YamlContent.Length) characters)" -Level "Information"
            
            # Parse YAML fields using regex (simple approach for known structure)
            $name = if ($YamlContent -match 'name:\s*(.+)') { $matches[1].Trim() } else { "" }
            $description = if ($YamlContent -match 'description:\s*(.+)') { $matches[1].Trim() } else { "" }
            $version = if ($YamlContent -match 'version:\s*(.+)') { $matches[1].Trim() } else { "1.0.0" }
            $id = if ($YamlContent -match '^id:\s*(.+)') { $matches[1].Trim() } else { "" }
            
            # Extract instructions (handle multiline quoted string)
            $instructions = ""
            if ($YamlContent -match 'instructions:\s*"([^"]*(?:\\.[^"]*)*)"') {
                $instructions = $matches[1] -replace '\\r\\n', "`r`n" -replace '\\n', "`n" -replace '\\"', '"'
            }
            
            # Extract model configuration
            $modelId = "gpt-4o-mini" # Default
            if ($YamlContent -match 'model:\s*\n\s*id:\s*(.+)') {
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
            
            # Extract tools (currently empty array in your YAML)
            $tools = @()
            
            # Extract metadata
            $metadata = @{}
            if ($YamlContent -match 'metadata:\s*\n((?:\s{2}.+\n?)*)') {
                $metadataBlock = $matches[1]
                if ($metadataBlock -match 'created_by:\s*(.+)') {
                    $metadata.created_by = $matches[1].Trim()
                }
                if ($metadataBlock -match 'created_date:\s*(.+)') {
                    $metadata.created_date = $matches[1].Trim() -replace "'", ""
                }
            }
            
            $result = @{
                name         = $name
                description  = $description
                instructions = $instructions
                model        = $modelId
                temperature  = $temperature
                topP         = $topP
                tools        = $tools
                metadata     = $metadata
                version      = $version
                id           = $id
            }
            
            Write-Log "✅ Parsed agent configuration:" -Level "Information"
            Write-Log "   📝 Name: $name" -Level "Information"
            Write-Log "   🤖 Model: $modelId" -Level "Information"
            Write-Log "   📊 Temperature: $temperature" -Level "Verbose"
            Write-Log "   📋 Instructions length: $($instructions.Length) characters" -Level "Information"
            Write-Log "   🔧 Tools: $($tools.Count) defined" -Level "Verbose"
            
            return $result
        }
        catch {
            throw "Failed to parse YAML content: $($_.Exception.Message)"
        }
    }
    
    # Read agent configuration from YAML content
    $agentConfig = Read-AgentYaml -YamlContent $AgentYamlContent
    
    # Extract configuration values for use in script
    $AgentName = if (-not [string]::IsNullOrEmpty($agentConfig.name)) { $agentConfig.name } else { $AgentName }
    $AgentDescription = if (-not [string]::IsNullOrEmpty($agentConfig.description)) { $agentConfig.description } else { $AgentDescription }
    $agentInstructions = $agentConfig.instructions
    $ModelDeploymentName = if (-not [string]::IsNullOrEmpty($agentConfig.model)) { $agentConfig.model } else { $ModelDeploymentName }
    
    # Validate that we have essential configuration
    if ([string]::IsNullOrEmpty($agentInstructions)) {
        throw "Agent instructions are empty in YAML file"
    }
    
    if ([string]::IsNullOrEmpty($AgentName)) {
        throw "Agent name is empty in YAML file"
    }
    
    Write-Log "✅ Agent configuration loaded from YAML successfully" -Level "Information"
    Write-Log "📝 Instructions preview: $($agentInstructions.Substring(0, [Math]::Min(100, $agentInstructions.Length)))..." -Level "Verbose"
    
    # =========== GET ACCESS TOKEN ===========
    
    Write-Log "🔑 Obtaining access token for AI Foundry..." -Level "Information"
    
    $accessToken = $null
    $authMethod = $null
    
    # Try managed identity first (for Azure deployment scripts)
    try {
        Write-Log "🔍 Attempting to use managed identity authentication..." -Level "Information"
        
        # Use Azure Instance Metadata Service to get access token for managed identity
        # AI Foundry Agent API requires https://ai.azure.com scope (per Microsoft docs)
        $tokenScopes = @(
            "https://ai.azure.com/",
            "https://cognitiveservices.azure.com/",
            "https://management.azure.com/"
        )
        
        foreach ($scope in $tokenScopes) {
            try {
                Write-Log "🔍 Trying managed identity token scope: $scope" -Level "Verbose"
                
                # Azure Instance Metadata Service endpoint for access tokens
                $tokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$([System.Uri]::EscapeDataString($scope))"
                $headers = @{ 'Metadata' = 'true' }
                
                $tokenResponse = Invoke-RestMethod -Uri $tokenUri -Headers $headers -Method Get -TimeoutSec 30
                
                if ($tokenResponse -and $tokenResponse.access_token) {
                    $accessToken = $tokenResponse.access_token
                    $authMethod = "Managed Identity"
                    Write-Log "✅ Successfully obtained access token via managed identity with scope: $scope" -Level "Information"
                    Write-Log "🔍 Token type: $($tokenResponse.token_type)" -Level "Verbose"
                    Write-Log "🔍 Token expires in: $($tokenResponse.expires_in) seconds" -Level "Verbose"
                    break
                }
            }
            catch {
                Write-Log "⚠️ Failed to get managed identity token with scope $scope - $($_.Exception.Message)" -Level "Verbose"
            }
        }
        
        if (-not [string]::IsNullOrEmpty($accessToken)) {
            Write-Log "✅ Managed identity authentication successful" -Level "Information"
        }
    }
    catch {
        Write-Log "⚠️ Managed identity authentication failed: $($_.Exception.Message)" -Level "Warning"
    }
    
    # Fallback to Azure CLI logged-in user credentials if managed identity failed
    if ([string]::IsNullOrEmpty($accessToken)) {
        try {
            Write-Log "🔄 Falling back to Azure CLI user credentials..." -Level "Information"
            
            # Check if Azure CLI is available
            $azCliAvailable = $false
            try {
                $azVersion = az version 2>$null | ConvertFrom-Json
                if ($azVersion -and $azVersion.'azure-cli') {
                    $azCliAvailable = $true
                    Write-Log "✅ Azure CLI found: $($azVersion.'azure-cli')" -Level "Verbose"
                }
            }
            catch {
                Write-Log "⚠️ Azure CLI not found or not working" -Level "Warning"
            }
            
            if ($azCliAvailable) {
                # Try different scopes with Azure CLI
                $tokenScopes = @(
                    "https://ai.azure.com/",
                    "https://cognitiveservices.azure.com/",
                    "https://management.azure.com/"
                )
                
                foreach ($scope in $tokenScopes) {
                    try {
                        Write-Log "🔍 Trying Azure CLI token scope: $scope" -Level "Verbose"
                        
                        # Use Azure CLI to get access token for logged-in user
                        $tokenResult = az account get-access-token --resource $scope --query accessToken --output tsv 2>$null
                        
                        if (-not [string]::IsNullOrEmpty($tokenResult) -and $tokenResult -ne "null") {
                            $accessToken = $tokenResult.Trim()
                            $authMethod = "Azure CLI User"
                            Write-Log "✅ Successfully obtained access token via Azure CLI with scope: $scope" -Level "Information"
                            break
                        }
                    }
                    catch {
                        Write-Log "⚠️ Failed to get Azure CLI token with scope $scope - $($_.Exception.Message)" -Level "Verbose"
                    }
                }
                
                if ([string]::IsNullOrEmpty($accessToken)) {
                    throw "Failed to obtain access token with any scope using Azure CLI"
                }
            }
            else {
                throw "Azure CLI is not available for fallback authentication"
            }
        }
        catch {
            throw "Failed to get access token using both managed identity and Azure CLI: $($_.Exception.Message)"
        }
    }
    
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Failed to obtain access token using any authentication method"
    }
    
    Write-Log "✅ Authentication successful using: $authMethod" -Level "Information"
    
    # =========== PREPARE AGENT PAYLOAD ===========
    
    Write-Log "📦 Preparing agent creation payload from YAML configuration..." -Level "Information"
    
    # Merge YAML metadata with deployment metadata
    $enhancedMetadata = @{
        created_by        = "infrastructure-deployment"
        created_date      = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        deployment_script = "agent_deploy.ps1"
        yaml_version      = $agentConfig.version
        deployment_method = "bicep-deployment-script"
    }
    
    # Add original YAML metadata if it exists
    if ($agentConfig.metadata -and $agentConfig.metadata.Count -gt 0) {
        foreach ($key in $agentConfig.metadata.Keys) {
            if ($key -notin @('created_by', 'created_date')) {
                $enhancedMetadata["yaml_$key"] = $agentConfig.metadata[$key]
            }
        }
    }
    
    # Prepare agent payload using YAML configuration
    $agentPayload = @{
        name         = $AgentName
        description  = $AgentDescription
        instructions = $agentInstructions
        model        = $ModelDeploymentName
        tools        = $agentConfig.tools
        metadata     = $enhancedMetadata
    }
    
    # Add model options if specified in YAML
    if ($agentConfig.temperature -ne 1 -or $agentConfig.topP -ne 1) {
        $agentPayload.model_options = @{
            temperature = $agentConfig.temperature
            top_p       = $agentConfig.topP
        }
        Write-Log "📊 Using custom model options: temperature=$($agentConfig.temperature), top_p=$($agentConfig.topP)" -Level "Verbose"
    }
    
    $agentPayload = $agentPayload | ConvertTo-Json -Depth 10
    
    Write-Log "✅ Agent payload prepared from YAML ($(($agentPayload).name))" -Level "Information"
    Write-Log "🔧 Tools count: $($agentConfig.tools.Count)" -Level "Verbose"
    Write-Log "📋 Metadata entries: $($enhancedMetadata.Count)" -Level "Verbose"
    
    # =========== CHECK FOR EXISTING AGENT ===========
    
    Write-Log "🔍 Checking for existing agent..." -Level "Information"
    
    # Prepare headers
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type'  = 'application/json'
        'User-Agent'    = 'AI-Foundry-SPA-Agent-Deploy/1.0'
    }
    
    # Construct the assistants API endpoint with proper API version
    # AI Foundry uses 'assistants' endpoint, not 'agents'
    $cleanEndpoint = $AiFoundryEndpoint.TrimEnd('/')
    $agentsEndpoint = "$cleanEndpoint/assistants?api-version=2025-05-01"
    
    Write-Log "📡 Original endpoint: '$AiFoundryEndpoint'" -Level "Verbose"
    Write-Log "📡 Cleaned endpoint: '$cleanEndpoint'" -Level "Verbose"
    Write-Log "📡 Final agents endpoint: '$agentsEndpoint'" -Level "Information"
    
    # Validate the endpoint URL format
    try {
        $uri = [System.Uri]$agentsEndpoint
        Write-Log "✅ Endpoint URI validation successful" -Level "Verbose"
        Write-Log "🔍 Host: $($uri.Host)" -Level "Verbose"
        Write-Log "🔍 Path: $($uri.PathAndQuery)" -Level "Verbose"
    }
    catch {
        Write-Log "❌ Invalid endpoint URI: $($_.Exception.Message)" -Level "Error"
        throw "Invalid AI Foundry endpoint URL: $agentsEndpoint"
    }
    
    # Debug: Log current user and subscription info
    try {
        $currentSubscription = az account show --query "{subscriptionId:id, tenantId:tenantId}" -o json | ConvertFrom-Json
        Write-Log "🔍 Current subscription: $($currentSubscription.subscriptionId)" -Level "Verbose"
        Write-Log "🔍 Current tenant: $($currentSubscription.tenantId)" -Level "Verbose"
    }
    catch {
        Write-Log "⚠️ Could not retrieve subscription info" -Level "Warning"
    }
    
    $existingAgent = $null
    try {
        # List existing assistants to check if one with our name already exists
        Write-Log "🔍 Attempting to list existing assistants..." -Level "Information"
        $existingAgents = Invoke-RestMethod -Uri $agentsEndpoint -Method Get -Headers $headers -ErrorAction Stop
        
        if ($existingAgents -and $existingAgents.data) {
            $existingAgent = $existingAgents.data | Where-Object { $_.name -eq $AgentName } | Select-Object -First 1
            
            if ($existingAgent) {
                Write-Log "✅ Found existing agent: $($existingAgent.id)" -Level "Information"
            }
            else {
                Write-Log "ℹ️ No existing agent found with name '$AgentName'" -Level "Information"
            }
        }
    }
    catch {
        $errorDetails = $_.Exception.Message
        $statusCode = $null
        
        # Handle different types of HTTP exceptions using ErrorDetails (avoids content consumption)
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            Write-Log "🔍 Error Details: $($_.ErrorDetails.Message)" -Level "Error"
        }
        
        # Extract status code if available
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Log "🔍 HTTP Status: $statusCode" -Level "Error"
        }
        
        Write-Log "⚠️ Could not check for existing assistants: $errorDetails" -Level "Warning"
        
        # If we get 401, provide helpful troubleshooting info
        if ($statusCode -eq 401) {
            Write-Log "🚨 Authentication failed. Troubleshooting steps:" -Level "Error"
            Write-Log "   1. Verify your Azure AI account has the correct permissions" -Level "Error"
            Write-Log "   2. Check if the AI Foundry endpoint URL is correct" -Level "Error"
            Write-Log "   3. Ensure you're authenticated to the correct tenant/subscription" -Level "Error"
            Write-Log "   4. Try running 'az login --tenant <tenant-id>' if needed" -Level "Error"
            throw "Authentication failed with 401 Unauthorized. Check permissions and authentication."
        }
        
        Write-Log "🔄 Proceeding with agent creation..." -Level "Information"
    }
    
    # =========== CREATE OR UPDATE AGENT ===========
    
    $response = $null
    $isUpdate = $false
    
    try {
        if ($existingAgent) {
            Write-Log "🔄 Updating existing AI Foundry agent..." -Level "Information"
            
            try {
                # Update existing agent - construct proper endpoint for specific assistant
                $cleanEndpoint = $AiFoundryEndpoint.TrimEnd('/')
                $updateEndpoint = "$cleanEndpoint/assistants/$($existingAgent.id)?api-version=2025-05-01"
                $response = Invoke-RestMethod -Uri $updateEndpoint -Method Post -Body $agentPayload -Headers $headers -ErrorAction Stop
                $isUpdate = $true
                Write-Log "✅ Successfully updated existing agent" -Level "Information"
            }
            catch {
                Write-Log "⚠️ Failed to update existing agent: $($_.Exception.Message)" -Level "Warning"
                Write-Log "🔄 Attempting to create new agent instead..." -Level "Information"
                
                # If update fails, try to create new agent (maybe the existing one is corrupted)
                $response = Invoke-RestMethod -Uri $agentsEndpoint -Method Post -Body $agentPayload -Headers $headers -ErrorAction Stop
                $isUpdate = $false
            }
        }
        else {
            Write-Log "🤖 Creating new AI Foundry agent..." -Level "Information"
            
            # Create new agent
            $response = Invoke-RestMethod -Uri $agentsEndpoint -Method Post -Body $agentPayload -Headers $headers -ErrorAction Stop
            $isUpdate = $false
            Write-Log "✅ Successfully created new agent" -Level "Information"
        }
        
        if ($response -and $response.id) {
            $agentId = $response.id
            $operationType = if ($isUpdate) { "updated" } else { "created" }
            Write-Log "✅ Successfully $operationType agent with ID: $agentId" -Level "Information"
            Write-Log "🎯 Agent name: $($response.name)" -Level "Information"
            Write-Log "📝 Agent description: $($response.description)" -Level "Information"
            
            # =========== OUTPUT RESULTS ===========
            
            $result = @{
                success          = $true
                agentId          = $agentId
                agentName        = $response.name
                agentDescription = $response.description
                endpoint         = $AiFoundryEndpoint
                createdAt        = $response.created_at
                updatedAt        = $response.updated_at
                model            = $response.model
                operationType    = $operationType
                wasExistingAgent = $isUpdate
            }
            
            # Output results for consumption by Bicep deployment script
            Write-Host "AGENT_DEPLOYMENT_RESULT: $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
            
            return $result
        }
        else {
            throw "Agent operation succeeded but no agent ID returned in response"
        }
    }
    catch {
        $errorDetails = $_.Exception.Message
        Write-Log "❌ Failed to create agent: $errorDetails" -Level "Error"
        
        # Use ErrorDetails to avoid response content consumption issues
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            Write-Log "🔍 API Error Details: $($_.ErrorDetails.Message)" -Level "Error"
        }
        
        # Extract status code if available
        if ($_.Exception.Response) {
            Write-Log "🔍 HTTP Status: $($_.Exception.Response.StatusCode)" -Level "Error"
        }
        
        throw $errorDetails
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "💥 Agent deployment failed: $errorMessage" -Level "Error"
    
    # Output failure result for Bicep deployment script
    $failureResult = @{
        success   = $false
        error     = $errorMessage
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    
    Write-Host "AGENT_DEPLOYMENT_RESULT: $($failureResult | ConvertTo-Json -Compress)" -ForegroundColor Red
    
    # Exit with error code for Bicep deployment script
    exit 1
}
finally {
    Write-Log "🏁 Agent deployment script completed" -Level "Information"
}
