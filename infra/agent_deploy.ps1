<#
.SYNOPSIS
Infrastructure-driven Azure AI Foundry agent creation script.

.DESCRIPTION
This script creates an Azure AI Foundry agent using the Azure REST API after infrastruc    # =========== GET ACCESS TOKEN ===========
It reads agent instructions from a file and uses the deployed AI Foundry resources to create the agent.
This script is designed to be called from Azure Deployment Scripts within Bicep templates.

.PARAMETER AiFoundryEndpoint
The AI Foundry endpoint URL for API calls.

.PARAMETER AgentName
The name of the AI agent to create or update. Defaults to "AI in A Box Agent" if not specified.

.EXAMPLE
# Basic usage (typically called from Bicep deployment script)
.\agent_deploy.ps1 -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"

.EXAMPLE
# With custom agent name
.\agent_deploy.ps1 -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject" -AgentName "Custom AI Assistant"

.EXAMPLE
# Full absolute path (recommended for Bicep deployment scripts)
& "C:\deployments\infra\agent_deploy.ps1" -AiFoundryEndpoint "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject" -AgentName "Production AI Agent"

.PREREQUISITES
- Azure CLI must be installed and authenticated
- User/Service Principal must have appropriate permissions to AI Foundry resources

.EXPECTED_OUTPUT
- Agent creation status and details
- Created agent ID and endpoint information
- Success/failure status with detailed error messages if applicable

.NOTES
This script is designed to be infrastructure-driven and called as part of the deployment process.
It uses Azure CLI for authentication and Azure REST API for agent creation.
Supports multiple environments through configuration files and parameters.

Author: AI Foundry SPA Project
Version: 1.0
Last Modified: 2025-06-26
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$AiFoundryEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "AI in A Box Agent"
)

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

try {
    # =========== VALIDATION ===========
    
    Write-Log "🔍 Validating prerequisites..." -Level "Information"
    
    # Check if Azure CLI is available
    $null = az version --output tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not installed or not available in PATH"
    }
    Write-Log "✅ Azure CLI is available" -Level "Information"
    
    # Check authentication
    $currentUser = az account show --query "user.name" -o tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Not authenticated with Azure CLI. Please run 'az login'"
    }
    Write-Log "✅ Authenticated as: $currentUser" -Level "Information"
    
    # =========== READ INSTRUCTIONS ===========
    
    Write-Log "📖 Using embedded agent instructions..." -Level "Information"
    
    # Embedded agent instructions (same across all environments)
    $agentInstructions = @"
You are the AI in A Box intelligent assistant, designed to help users with their AI and cloud computing needs.

# Core Responsibilities

## Primary Function
You are an expert AI assistant specializing in:
- Azure AI services and solutions
- Cloud architecture and best practices
- AI/ML model deployment and management
- Troubleshooting and optimization
- Developer productivity and automation

## Key Capabilities
- **Technical Expertise**: Provide accurate, up-to-date information on Azure AI services, including AI Foundry, Cognitive Services, and Machine Learning platforms
- **Solution Architecture**: Help design and implement scalable AI solutions on Azure
- **Best Practices**: Guide users toward optimal configurations, security practices, and cost-effective implementations
- **Troubleshooting**: Diagnose issues and provide step-by-step resolution guidance
- **Code Assistance**: Help with sample code, templates, and integration patterns

## Communication Style
- **Clear and Concise**: Provide actionable information without unnecessary complexity
- **Professional yet Approachable**: Maintain a helpful, supportive tone while demonstrating expertise
- **Structured Responses**: Use headings, bullet points, and code blocks to organize information effectively
- **Context-Aware**: Adapt responses based on the user's apparent skill level and specific needs

## Response Guidelines
- Always prioritize security and best practices in recommendations
- Provide working code examples when applicable
- Include relevant documentation links and references
- Suggest multiple approaches when appropriate, explaining trade-offs
- Acknowledge limitations and recommend when to seek additional expertise

## Ethical Guidelines
- Respect user privacy and data security
- Provide accurate information and acknowledge uncertainty when unsure
- Recommend sustainable and cost-effective solutions
- Support inclusive and accessible technology practices

You are here to make AI and cloud technologies more accessible and to help users achieve their goals efficiently and effectively.
"@
    
    $instructionsLength = $agentInstructions.Length
    Write-Log "✅ Using embedded instructions ($instructionsLength characters)" -Level "Information"
    
    if ($instructionsLength -eq 0) {
        throw "Embedded instructions are empty"
    }
    
    # Log first few lines for verification (but not full content for security)
    $firstLine = ($agentInstructions -split "`n")[0]
    Write-Log "📝 Instructions preview: $($firstLine.Substring(0, [Math]::Min(100, $firstLine.Length)))..." -Level "Verbose"
    
    # =========== GET ACCESS TOKEN ===========
    
    Write-Log "🔑 Obtaining access token for AI Foundry..." -Level "Information"
    
    try {
        # AI Foundry Agent API requires https://ai.azure.com scope (per Microsoft docs)
        $tokenScopes = @(
            "https://ai.azure.com/",
            "https://cognitiveservices.azure.com/",
            "https://management.azure.com/"
        )
        
        $accessToken = $null
        foreach ($scope in $tokenScopes) {
            try {
                Write-Log "🔍 Trying token scope: $scope" -Level "Verbose"
                $accessToken = az account get-access-token --resource $scope --query "accessToken" -o tsv 2>$null
                if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($accessToken)) {
                    Write-Log "✅ Successfully obtained access token with scope: $scope" -Level "Information"
                    break
                }
            }
            catch {
                Write-Log "⚠️ Failed to get token with scope $scope" -Level "Verbose"
            }
        }
        
        if ([string]::IsNullOrEmpty($accessToken)) {
            throw "Failed to obtain access token with any scope"
        }
    }
    catch {
        throw "Failed to get access token: $($_.Exception.Message)"
    }
    
    # =========== PREPARE AGENT PAYLOAD ===========
    
    Write-Log "📦 Preparing agent creation payload..." -Level "Information"
    
    $agentPayload = @{
        name = $AgentName
        description = $AgentDescription
        instructions = $agentInstructions
        model = $ModelDeploymentName
        tools = @()
        metadata = @{
            created_by = "infrastructure-deployment"
            created_date = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            deployment_script = "agent_deploy.ps1"
        }
    } | ConvertTo-Json -Depth 10
    
    Write-Log "✅ Agent payload prepared ($(($agentPayload | ConvertFrom-Json).name))" -Level "Information"
    
    # =========== CHECK FOR EXISTING AGENT ===========
    
    Write-Log "🔍 Checking for existing agent..." -Level "Information"
    
    # Prepare headers
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
        'User-Agent' = 'AI-Foundry-SPA-Agent-Deploy/1.0'
    }
    
    # Construct the assistants API endpoint with proper API version
    # AI Foundry uses 'assistants' endpoint, not 'agents'
    $cleanEndpoint = $AiFoundryEndpoint.TrimEnd('/')
    $agentsEndpoint = "$cleanEndpoint/assistants?api-version=2025-05-01"
    Write-Log "📡 Using endpoint: $agentsEndpoint" -Level "Information"
    
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
            } else {
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
        } else {
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
                success = $true
                agentId = $agentId
                agentName = $response.name
                agentDescription = $response.description
                endpoint = $AiFoundryEndpoint
                createdAt = $response.created_at
                updatedAt = $response.updated_at
                model = $response.model
                operationType = $operationType
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
        success = $false
        error = $errorMessage
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    
    Write-Host "AGENT_DEPLOYMENT_RESULT: $($failureResult | ConvertTo-Json -Compress)" -ForegroundColor Red
    
    # Exit with error code for Bicep deployment script
    exit 1
}
finally {
    Write-Log "🏁 Agent deployment script completed" -Level "Information"
}
