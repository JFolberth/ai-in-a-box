#!/usr/bin/env pwsh
<#
.SYNOPSIS
Automated Quick-Start Deployment for AI Foundry SPA (Local Development Only)

.DESCRIPTION
This script provides a fully automated deployment experience for local development and getting-started scenarios.
It orchestrates the complete deployment process: infrastructure → agent → backend → frontend.

🚨 IMPORTANT: This is for LOCAL DEVELOPMENT ONLY. For production deployments, use GitHub Actions CI/CD pipeline.

The script:
1. Validates prerequisites (Azure CLI, .NET SDK, Node.js)
2. Prompts for configuration options (or uses defaults)
3. Deploys infrastructure using Bicep templates
4. Deploys/updates AI agent from YAML configuration
5. Deploys backend Function App with agent configuration
6. Deploys frontend Static Web App with backend integration
7. Provides final URLs and validation results

.PARAMETER Location
Azure region for deployment (default: eastus2)

.PARAMETER EnvironmentName
Environment name for resource naming (default: dev)

.PARAMETER ApplicationName
Application name used for resource naming (default: ai-foundry-spa)

.PARAMETER SkipValidation
Skip prerequisite validation (use with caution)

.PARAMETER UseExistingAiFoundry
Use existing AI Foundry resources instead of creating new ones

.PARAMETER UseExistingLogAnalytics
Use existing Log Analytics workspace instead of creating new one

.PARAMETER InteractiveMode
Prompt for all configuration options (default: true)

.EXAMPLE
# Full automated deployment with defaults
.\deploy-quickstart.ps1

.EXAMPLE
# Automated deployment with specific location and application name
.\deploy-quickstart.ps1 -Location "westus2" -ApplicationName "my-ai-app"

.EXAMPLE
# Automated deployment with specific location
.\deploy-quickstart.ps1 -Location "westus2"

.EXAMPLE
# Use existing AI Foundry resources
.\deploy-quickstart.ps1 -UseExistingAiFoundry

.EXAMPLE
# Non-interactive mode with all defaults
.\deploy-quickstart.ps1 -InteractiveMode:$false

.PREREQUISITES
- Azure CLI installed and authenticated (az login)
- .NET 8 SDK for backend development
- Node.js 18+ for frontend development
- Azure subscription with appropriate permissions

.OUTPUT
- Deployed AI Foundry SPA with all components
- Frontend URL for accessing the application
- Backend API URL for health checks
- Agent ID and configuration details
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApplicationName = "ai-foundry-spa",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseExistingAiFoundry,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseExistingLogAnalytics,
    
    [Parameter(Mandatory = $false)]
    [bool]$InteractiveMode = $true
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to prompt for user input with default
function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [switch]$Required
    )
    
    if (-not $InteractiveMode -and -not [string]::IsNullOrEmpty($Default)) {
        return $Default
    }
    
    do {
        if (-not [string]::IsNullOrEmpty($Default)) {
            $input = Read-Host "$Prompt [$Default]"
            if ([string]::IsNullOrEmpty($input)) {
                $input = $Default
            }
        }
        else {
            $input = Read-Host $Prompt
        }
        
        if ($Required -and [string]::IsNullOrEmpty($input)) {
            Write-ColorOutput "This field is required. Please provide a value." "Red"
        }
    } while ($Required -and [string]::IsNullOrEmpty($input))
    
    return $input
}

Write-ColorOutput "🚀 AI Foundry SPA - Automated Quick-Start Deployment" "Green"
Write-ColorOutput "================================================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "⚠️  IMPORTANT: This is for LOCAL DEVELOPMENT ONLY" "Yellow"
Write-ColorOutput "   For production deployments, use GitHub Actions CI/CD pipeline" "Yellow"
Write-ColorOutput ""

# Validate workspace location
$workspaceRoot = Join-Path $PSScriptRoot ".."
if (-not (Test-Path $workspaceRoot)) {
    Write-ColorOutput "Cannot find workspace root. Please run this script from the deploy-scripts directory." "Red"
    exit 1
}

Write-ColorOutput "Workspace root: $workspaceRoot" "Cyan"
Set-Location $workspaceRoot

# Step 1: Validate Prerequisites
if (-not $SkipValidation) {
    Write-ColorOutput "`n📋 Step 1: Validating Prerequisites..." "Green"
    
    # Check Azure CLI
    Write-ColorOutput "Checking Azure CLI..." "Yellow"
    if (-not (Test-Command "az")) {
        Write-ColorOutput "❌ Azure CLI not found. Please install Azure CLI first." "Red"
        Write-ColorOutput "   Download: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" "Cyan"
        exit 1
    }
    
    # Check Azure login
    try {
        $null = az account show 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Not logged into Azure. Please run 'az login' first." "Red"
            exit 1
        }
        Write-ColorOutput "✅ Azure CLI authenticated" "Green"
        
        $currentSubscription = az account show --query "name" -o tsv
        Write-ColorOutput "   Current subscription: $currentSubscription" "Cyan"
    }
    catch {
        Write-ColorOutput "❌ Azure authentication check failed. Please run 'az login' first." "Red"
        exit 1
    }
    
    # Check .NET SDK
    Write-ColorOutput "Checking .NET SDK..." "Yellow"
    if (-not (Test-Command "dotnet")) {
        Write-ColorOutput "❌ .NET SDK not found. Please install .NET 8 SDK." "Red"
        Write-ColorOutput "   Download: https://dotnet.microsoft.com/download/dotnet/8.0" "Cyan"
        exit 1
    }
    
    try {
        $dotnetVersion = dotnet --version
        Write-ColorOutput "✅ .NET SDK found: $dotnetVersion" "Green"
    }
    catch {
        Write-ColorOutput "❌ Failed to get .NET version." "Red"
        exit 1
    }
    
    # Check Node.js
    Write-ColorOutput "Checking Node.js..." "Yellow"
    if (-not (Test-Command "node")) {
        Write-ColorOutput "❌ Node.js not found. Please install Node.js 18+ for frontend development." "Red"
        Write-ColorOutput "   Download: https://nodejs.org/" "Cyan"
        exit 1
    }
    
    try {
        $nodeVersion = node --version
        Write-ColorOutput "✅ Node.js found: $nodeVersion" "Green"
    }
    catch {
        Write-ColorOutput "❌ Failed to get Node.js version." "Red"
        exit 1
    }
    
    Write-ColorOutput "✅ All prerequisites validated successfully!" "Green"
}
else {
    Write-ColorOutput "⚠️  Skipping prerequisite validation (as requested)" "Yellow"
}

# Remove preflight checks from here - they will be moved after configuration setup

# Functions for preflight checks (will be called after configuration)
function Test-AzureOpenAIQuota {
    param(
        [string]$Location,
        [int]$RequiredCapacity = 150
    )
    
    Write-ColorOutput "Checking Azure OpenAI quota in $Location..." "Yellow"
    
    try {
        # Check if we can get quota information
        $quotaCheck = az cognitiveservices account list-skus --location $Location --query "[?resourceType == 'Account' && kind == 'OpenAI']" --output json 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "   ⚠️  Unable to check OpenAI quota directly. Deployment will validate quota during creation." "Yellow"
            return $true
        }
        
        # Try to get existing OpenAI accounts to estimate quota usage
        $openAIAccounts = az cognitiveservices account list --query "[?kind=='OpenAI']" --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $openAIAccounts) {
            $accounts = $openAIAccounts | ConvertFrom-Json
            $accountCount = $accounts.Count
            
            # Rough estimate: each standard deployment uses ~150k TPM
            $estimatedUsedCapacity = $accountCount * 150
            $estimatedAvailableCapacity = 450 - $estimatedUsedCapacity
            
            Write-ColorOutput "   📊 OpenAI quota check: Found $accountCount existing OpenAI accounts" "Green"
            Write-ColorOutput "   📊 Estimated used capacity: $($estimatedUsedCapacity)k TPM" "Cyan"
            Write-ColorOutput "   📊 Estimated available capacity: $($estimatedAvailableCapacity)k TPM" "Cyan"
            Write-ColorOutput "   📊 Required for deployment: $($RequiredCapacity)k TPM" "Cyan"
            
            if ($estimatedAvailableCapacity -lt ($RequiredCapacity / 1000)) {
                Write-ColorOutput "   ❌ INSUFFICIENT QUOTA DETECTED!" "Red"
                Write-ColorOutput "   ⚠️  Required: $($RequiredCapacity)k TPM, Available: ~$($estimatedAvailableCapacity)k TPM" "Yellow"
                Write-ColorOutput "   💡 SOLUTIONS:" "Yellow"
                Write-ColorOutput "      • Use existing AI Foundry resources (-UseExistingAiFoundry)" "Cyan"
                Write-ColorOutput "      • Request quota increase: https://aka.ms/azure-openai-quota" "Cyan"
                Write-ColorOutput "      • Delete unused OpenAI resources to free quota" "Cyan"
                Write-ColorOutput "      • Try a different region with available quota" "Cyan"
                return $false
            }
            else {
                Write-ColorOutput "   ✅ Sufficient quota available for deployment" "Green"
            }
        }
        else {
            Write-ColorOutput "   ✅ OpenAI quota check: Found 0 existing OpenAI accounts. Should have sufficient quota." "Green"
        }
        
        return $true
        
    }
    catch {
        Write-ColorOutput "   ⚠️  OpenAI quota check failed: $($_.Exception.Message)" "Yellow"
        Write-ColorOutput "   💡 Deployment will validate quota during creation" "Cyan"
        return $true
    }
}

function Test-AzurePermissions {
    Write-ColorOutput "Checking Azure RBAC permissions..." "Yellow"
    
    try {
        # Get current user/service principal assignments
        $roleAssignments = az role assignment list --assignee (az account show --query user.name -o tsv) --query "[].roleDefinitionName" -o tsv 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $roleAssignments) {
            $hasOwner = $roleAssignments -contains "Owner"
            $hasContributor = $roleAssignments -contains "Contributor"
            $hasRoleBasedAccess = $roleAssignments -contains "Role Based Access Control Administrator" -or $roleAssignments -contains "User Access Administrator"
            
            if ($hasOwner) {
                Write-ColorOutput "   ✅ Permissions: Owner role detected - sufficient for deployment" "Green"
                return $true
            }
            elseif ($hasContributor -and $hasRoleBasedAccess) {
                Write-ColorOutput "   ✅ Permissions: Contributor + RBAC admin roles detected - sufficient for deployment" "Green"
                return $true
            }
            else {
                Write-ColorOutput "   ⚠️  Limited permissions detected. May need Owner or Contributor + User Access Administrator roles" "Yellow"
                Write-ColorOutput "   📋 Required permissions: Create resource groups, deploy Bicep templates, assign RBAC roles" "Cyan"
                return $true  # Continue anyway - let deployment validate
            }
        }
        else {
            Write-ColorOutput "   ⚠️  Could not retrieve role assignments" "Yellow"
            Write-ColorOutput "   💡 Continuing - deployment will validate permissions" "Cyan"
            return $true
        }
        
    }
    catch {
        Write-ColorOutput "   ⚠️  Permission check failed: $($_.Exception.Message)" "Yellow"
        Write-ColorOutput "   💡 Continuing - deployment will validate permissions" "Cyan"
        return $true
    }
}

function Test-ResourceProviders {
    Write-ColorOutput "Checking Azure resource provider registrations..." "Yellow"
    
    $requiredProviders = @(
        "Microsoft.Web",
        "Microsoft.CognitiveServices", 
        "Microsoft.OperationalInsights",
        "Microsoft.Insights",
        "Microsoft.Authorization"
    )
    
    $allRegistered = $true
    
    foreach ($provider in $requiredProviders) {
        try {
            $providerStatus = az provider show --namespace $provider --query "registrationState" -o tsv 2>$null
            
            if ($providerStatus -eq "Registered") {
                Write-ColorOutput "   ✅ ${provider}: Registered" "Green"
            }
            elseif ($providerStatus -eq "Registering") {
                Write-ColorOutput "   🔄 ${provider}: Currently registering..." "Yellow"
            }
            else {
                Write-ColorOutput "   ❌ ${provider}: Not registered ($providerStatus)" "Red"
                Write-ColorOutput "   💡 Run: az provider register --namespace $provider" "Cyan"
                $allRegistered = $false
            }
        }
        catch {
            Write-ColorOutput "   ⚠️  Could not check $provider registration status" "Yellow"
        }
    }
    
    return $allRegistered
}

# Step 2: Configuration
Write-ColorOutput "`n⚙️  Step 2: Configuration Setup..." "Green"

# Get deployment configuration
$deployLocation = Get-UserInput "Azure region for deployment" $Location
$deployEnvironment = Get-UserInput "Environment name" $EnvironmentName
$deployApplicationName = Get-UserInput "Application name for resource naming" $ApplicationName

# AI Foundry configuration
if ($UseExistingAiFoundry) {
    $createAiFoundry = $false
    Write-ColorOutput "Using existing AI Foundry resources (as requested)" "Cyan"
}
else {
    if ($InteractiveMode) {
        $createAiFoundryInput = Get-UserInput "Create new AI Foundry resources? (y/n)" "y"
        $createAiFoundry = $createAiFoundryInput.ToLower() -eq "y"
    }
    else {
        $createAiFoundry = $true
        Write-ColorOutput "Will create new AI Foundry resources (default)" "Cyan"
    }
}

# Get existing AI Foundry resource details if not creating new
if (-not $createAiFoundry) {
    Write-ColorOutput "`n📝 Please provide existing AI Foundry resource information:" "Yellow"
    $aiFoundryResourceGroupName = Get-UserInput "AI Foundry resource group name" "rg-ai-foundry-spa-aifoundry-$deployEnvironment-eus2"
    $aiFoundryResourceName = Get-UserInput "AI Foundry resource name" "cs-ai-foundry-$deployEnvironment-eus2"
    $aiFoundryProjectName = Get-UserInput "AI Foundry project name" "aiproj-ai-foundry-$deployEnvironment-eus2"
    $aiFoundryAgentName = Get-UserInput "AI Foundry agent name" "AI In A Box"
    
    Write-ColorOutput "✅ Existing AI Foundry configuration:" "Green"
    Write-ColorOutput "   Resource Group: $aiFoundryResourceGroupName" "Cyan"
    Write-ColorOutput "   Resource Name: $aiFoundryResourceName" "Cyan"
    Write-ColorOutput "   Project Name: $aiFoundryProjectName" "Cyan"
    Write-ColorOutput "   Agent Name: $aiFoundryAgentName" "Cyan"
}

# Log Analytics configuration
if ($UseExistingLogAnalytics) {
    $createLogAnalytics = $false
    Write-ColorOutput "Using existing Log Analytics workspace (as requested)" "Cyan"
}
else {
    if ($InteractiveMode) {
        $createLogAnalyticsInput = Get-UserInput "Create new Log Analytics workspace? (y/n)" "y"
        $createLogAnalytics = $createLogAnalyticsInput.ToLower() -eq "y"
    }
    else {
        $createLogAnalytics = $true
        Write-ColorOutput "Will create new Log Analytics workspace (default)" "Cyan"
    }
}

# Get existing Log Analytics workspace details if not creating new
if (-not $createLogAnalytics) {
    Write-ColorOutput "`n📝 Please provide existing Log Analytics workspace information:" "Yellow"
    $logAnalyticsResourceGroupName = Get-UserInput "Log Analytics resource group name" "rg-logging-$deployEnvironment-eus"
    $logAnalyticsWorkspaceName = Get-UserInput "Log Analytics workspace name" "la-logging-$deployEnvironment-eus"
    
    Write-ColorOutput "✅ Existing Log Analytics configuration:" "Green"
    Write-ColorOutput "   Resource Group: $logAnalyticsResourceGroupName" "Cyan"
    Write-ColorOutput "   Workspace Name: $logAnalyticsWorkspaceName" "Cyan"
}

# Step 2.5: Preflight Checks (after configuration is collected)
Write-ColorOutput "`n🔍 Step 2.5: Preflight Checks (Azure Permissions & Quota)..." "Green"

$preflightPassed = $true

# Check resource providers
if (-not (Test-ResourceProviders)) {
    Write-ColorOutput "❌ Some resource providers are not registered" "Red"
    Write-ColorOutput "   Run the suggested 'az provider register' commands and try again" "Yellow"
    $preflightPassed = $false
}

# Check permissions
Test-AzurePermissions | Out-Null

# Check quota only if creating new AI Foundry resources (region-aware)
if ($createAiFoundry) {
    $quotaCheckResult = Test-AzureOpenAIQuota -Location $deployLocation -RequiredCapacity 150
    if (-not $quotaCheckResult) {
        Write-ColorOutput "❌ CRITICAL: Insufficient Azure OpenAI quota detected!" "Red"
        Write-ColorOutput "   Your subscription appears to be at or near the quota limit for OpenAI resources." "Yellow"
        Write-ColorOutput "   This deployment will fail due to quota restrictions." "Yellow"
        Write-ColorOutput "" "White"
        Write-ColorOutput "🔧 IMMEDIATE SOLUTIONS:" "Yellow"
        Write-ColorOutput "   1. Use existing AI Foundry resources:" "Cyan"
        Write-ColorOutput "      .\deploy-quickstart.ps1 -UseExistingAiFoundry" "White"
        Write-ColorOutput "   2. Request quota increase:" "Cyan"
        Write-ColorOutput "      https://aka.ms/azure-openai-quota" "White"
        Write-ColorOutput "   3. Delete unused OpenAI resources to free quota" "Cyan"
        Write-ColorOutput "   4. Try deployment in a different region" "Cyan"
        Write-ColorOutput "" "White"
        Write-ColorOutput "Stopping deployment to prevent quota-related failures." "Red"
        $preflightPassed = $false
    }
}
else {
    Write-ColorOutput "Skipping quota check (using existing AI Foundry resources)" "Cyan"
}

if (-not $preflightPassed) {
    Write-ColorOutput "`n❌ Preflight checks failed. Please resolve the issues above before continuing." "Red"
    Write-ColorOutput "💡 Common solutions:" "Cyan"
    Write-ColorOutput "   • Register resource providers: az provider register --namespace Microsoft.CognitiveServices" "Cyan"
    Write-ColorOutput "   • Check subscription permissions with your Azure administrator" "Cyan"
    Write-ColorOutput "   • Verify Azure OpenAI quota: https://aka.ms/azure-openai-quota" "Cyan"
    exit 1
}

Write-ColorOutput "✅ Preflight checks completed successfully!" "Green"

# Prepare deployment parameters based on collected configuration
$parametersFile = Join-Path $workspaceRoot "infra" "dev-orchestrator.parameters.bicepparam"

# Prepare inline parameters based on collected configuration
$inlineParameters = @(
    "applicationName=$deployApplicationName"
    "environmentName=$deployEnvironment"
    "location=$deployLocation"
    "createAiFoundryResourceGroup=$($createAiFoundry.ToString().ToLower())"
    "createLogAnalyticsWorkspace=$($createLogAnalytics.ToString().ToLower())"
)

# Add existing resource parameters if not creating new ones
if (-not $createAiFoundry) {
    $inlineParameters += @(
        "aiFoundryResourceGroupName=$aiFoundryResourceGroupName"
        "aiFoundryResourceName=$aiFoundryResourceName"
        "aiFoundryProjectName=$aiFoundryProjectName"
        "aiFoundryAgentName=$aiFoundryAgentName"
    )
}

if (-not $createLogAnalytics) {
    $inlineParameters += @(
        "logAnalyticsResourceGroupName=$logAnalyticsResourceGroupName"
        "logAnalyticsWorkspaceName=$logAnalyticsWorkspaceName"
    )
}

Write-ColorOutput "✅ Configuration prepared:" "Green"
Write-ColorOutput "   Application Name: $deployApplicationName" "Cyan"
Write-ColorOutput "   Location: $deployLocation" "Cyan"
Write-ColorOutput "   Environment: $deployEnvironment" "Cyan"
Write-ColorOutput "   Create AI Foundry: $createAiFoundry" "Cyan"
Write-ColorOutput "   Create Log Analytics: $createLogAnalytics" "Cyan"

if (-not $createAiFoundry) {
    Write-ColorOutput "   AI Foundry RG: $aiFoundryResourceGroupName" "Cyan"
    Write-ColorOutput "   AI Foundry Resource: $aiFoundryResourceName" "Cyan"
    Write-ColorOutput "   AI Foundry Project: $aiFoundryProjectName" "Cyan"
}

if (-not $createLogAnalytics) {
    Write-ColorOutput "   Log Analytics RG: $logAnalyticsResourceGroupName" "Cyan"
    Write-ColorOutput "   Log Analytics Workspace: $logAnalyticsWorkspaceName" "Cyan"
}

# Step 3: Deploy Infrastructure
Write-ColorOutput "`n🏗️  Step 3: Deploying Infrastructure..." "Green"

$infrastructureTemplate = Join-Path $workspaceRoot "infra" "main-orchestrator.bicep"

Write-ColorOutput "Starting Bicep deployment (this may take 8-15 minutes)..." "Yellow"
Write-ColorOutput "Template: $infrastructureTemplate" "Cyan"
Write-ColorOutput "Parameters: $parametersFile" "Cyan"

try {
    # Deploy infrastructure
    $deploymentName = "quickstart-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    Write-ColorOutput "   Running deployment command..." "Cyan"
    Write-ColorOutput "   Deployment name: $deploymentName" "Cyan"
    Write-ColorOutput "   Using inline parameters based on collected configuration" "Cyan"
    
    # Use inline parameters to ensure collected configuration is used
    $parametersString = $inlineParameters -join " "
    Write-ColorOutput "   Parameters: $parametersString" "Gray"
    
    # Deploy with template file and inline parameters
    az deployment sub create --template-file $infrastructureTemplate --parameters $parametersString --location $deployLocation --name $deploymentName
    
    $deployResult = $LASTEXITCODE
    
    if ($deployResult -ne 0) {
        Write-ColorOutput "❌ Infrastructure deployment failed!" "Red"
        Write-ColorOutput "   Exit code: $deployResult" "Yellow"
        Write-ColorOutput "   Check the Azure portal or run 'az deployment sub show --name $deploymentName' for details" "Yellow"
        exit 1
    }
    
    Write-ColorOutput "✅ Infrastructure deployment completed!" "Green"
    
    # Extract deployment outputs using the specific deployment name
    Write-ColorOutput "Extracting deployment outputs..." "Yellow"
    Write-ColorOutput "   Using deployment name: $deploymentName" "Cyan"
    
    # First, verify the deployment exists and get its status
    $deploymentStatus = az deployment sub show --name $deploymentName --query "properties.provisioningState" -o tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Deployment '$deploymentName' not found!" "Red"
        Write-ColorOutput "   Listing recent deployments for reference..." "Yellow"
        az deployment sub list --query '[].{name:name, state:properties.provisioningState, timestamp:properties.timestamp}' --output table
        exit 1
    }
    
    Write-ColorOutput "   Deployment status: $deploymentStatus" "Cyan"
    
    if ($deploymentStatus -ne "Succeeded") {
        Write-ColorOutput "❌ Deployment did not succeed! Status: $deploymentStatus" "Red"
        Write-ColorOutput "   Getting deployment error details..." "Yellow"
        az deployment sub show --name $deploymentName --query "properties.error" --output table
        exit 1
    }
    
    # Extract outputs from the successful deployment
    $outputsJsonString = (az deployment sub show --name $deploymentName --query "properties.outputs" --output json 2>$null)
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to query deployment outputs!" "Red"
        exit 1
    }
    
    # Convert JSON string to object immediately
    try {
        $outputs = $outputsJsonString | ConvertFrom-Json
    }
    catch {
        Write-ColorOutput "❌ Failed to parse deployment outputs JSON!" "Red"
        Write-ColorOutput "   Error: $($_.Exception.Message)" "Red"
        Write-ColorOutput "   Raw JSON: $outputsJsonString" "Cyan"
        exit 1
    }
    
    # Check if outputs exist and have expected properties
    if ($null -eq $outputs) {
        Write-ColorOutput "❌ No deployment outputs found!" "Red"
        Write-ColorOutput "   Raw outputs JSON: $outputsJsonString" "Cyan"
        exit 1
    }
    
    Write-ColorOutput "   Found $($outputs.PSObject.Properties.Count) outputs" "Cyan"
    
    # Debug: Show all available outputs
    Write-ColorOutput "   Available outputs:" "Yellow"
    $outputs.PSObject.Properties | ForEach-Object {
        $outputName = $_.Name
        $outputValue = if ($_.Value.value) { $_.Value.value } else { $_.Value }
        Write-ColorOutput "     - ${outputName}: ${outputValue}" "Cyan"
    }
    
    # Extract individual output values with error checking
    if ($outputs.PSObject.Properties['backendFunctionAppName']) {
        $functionAppName = $outputs.backendFunctionAppName.value
    }
    else {
        Write-ColorOutput "⚠️  backendFunctionAppName output not found in deployment" "Yellow"
        $functionAppName = ""
    }
    
    if ($outputs.PSObject.Properties['backendResourceGroupName']) {
        $functionAppResourceGroup = $outputs.backendResourceGroupName.value
    }
    else {
        Write-ColorOutput "⚠️  backendResourceGroupName output not found in deployment" "Yellow"
        $functionAppResourceGroup = ""
    }
    
    if ($outputs.PSObject.Properties['frontendStaticWebAppName']) {
        $staticWebAppName = $outputs.frontendStaticWebAppName.value
    }
    else {
        Write-ColorOutput "⚠️  frontendStaticWebAppName output not found in deployment" "Yellow"
        $staticWebAppName = ""
    }
    
    if ($outputs.PSObject.Properties['frontendResourceGroupName']) {
        $staticWebAppResourceGroup = $outputs.frontendResourceGroupName.value
    }
    else {
        Write-ColorOutput "⚠️  frontendResourceGroupName output not found in deployment" "Yellow"
        $staticWebAppResourceGroup = ""
    }
    
    if ($outputs.PSObject.Properties['aiFoundryEndpoint']) {
        $aiFoundryEndpoint = $outputs.aiFoundryEndpoint.value
    }
    else {
        Write-ColorOutput "⚠️  aiFoundryEndpoint output not found in deployment" "Yellow"
        $aiFoundryEndpoint = ""
    }
    
    # Extract agent ID from deployment outputs if available
    if ($outputs.PSObject.Properties['aiFoundryAgentId']) {
        $deployedAgentId = $outputs.aiFoundryAgentId.value
        if (-not [string]::IsNullOrEmpty($deployedAgentId)) {
            Write-ColorOutput "   Found agent ID from deployment: $deployedAgentId" "Cyan"
        }
    }
    
    # Note: Some outputs like logAnalyticsWorkspaceId may be empty when using existing resources
    # This is expected behavior and not an error
    
    # Verify we have the essential outputs
    if ([string]::IsNullOrEmpty($functionAppName) -or [string]::IsNullOrEmpty($functionAppResourceGroup)) {
        Write-ColorOutput "❌ Essential deployment outputs missing!" "Red"
        Write-ColorOutput "   Available outputs:" "Yellow"
        $outputs.PSObject.Properties | ForEach-Object { 
            Write-ColorOutput "   - $($_.Name): $($_.Value.value)" "Cyan" 
        }
        exit 1
    }
    
    Write-ColorOutput "✅ Deployment outputs extracted:" "Green"
    Write-ColorOutput "   Function App: $functionAppName in $functionAppResourceGroup" "Cyan"
    Write-ColorOutput "   Static Web App: $staticWebAppName in $staticWebAppResourceGroup" "Cyan"
    Write-ColorOutput "   AI Foundry Endpoint: $aiFoundryEndpoint" "Cyan"
    
}
catch {
    Write-ColorOutput "❌ Infrastructure deployment failed: $($_.Exception.Message)" "Red"
    exit 1
}

# Step 4: Deploy AI Agent
Write-ColorOutput "`n🤖 Step 4: Deploying AI Agent..." "Green"
Write-ColorOutput "The agent deployment script handles both new and existing AI Foundry resources automatically." "Cyan"

$agentId = ""
try {
    $agentScript = Join-Path $workspaceRoot "deploy-scripts" "Deploy-Agent.ps1"
    Write-ColorOutput "Deploying/updating AI agent from YAML configuration..." "Yellow"
    $agentResult = & $agentScript -AiFoundryEndpoint $aiFoundryEndpoint -OutputFormat "json"
    
    if ($LASTEXITCODE -eq 0) {
        # Parse the agent result - look for the JSON after "AGENT_DEPLOYMENT_RESULT:"
        Write-ColorOutput "   Debug: Agent result type: $($agentResult.GetType().Name)" "Cyan"
        Write-ColorOutput "   Debug: Agent result count: $($agentResult.Count)" "Cyan"
        
        # Convert to array if it's not already
        $resultLines = @($agentResult)
        $jsonLine = $resultLines | Where-Object { $_ -like "*AGENT_DEPLOYMENT_RESULT:*" }
        
        if ($jsonLine) {
            Write-ColorOutput "   Debug: Found JSON line: $jsonLine" "Cyan"
            $jsonPart = $jsonLine -replace ".*AGENT_DEPLOYMENT_RESULT:\s*", ""
            Write-ColorOutput "   Debug: Extracted JSON: $jsonPart" "Cyan"
            
            try {
                $agentData = $jsonPart | ConvertFrom-Json
                $agentId = $agentData.agentId
                $agentName = $agentData.agentName
                # Check if wasExistingAgent property exists, default to false if not
                $wasExisting = if ($agentData.PSObject.Properties['wasExistingAgent']) { $agentData.wasExistingAgent } else { $false }
                $operationType = if ($wasExisting) { "updated" } else { "created" }
                Write-ColorOutput "✅ Agent $operationType successfully!" "Green"
                Write-ColorOutput "   Agent ID: $agentId" "Cyan"
                Write-ColorOutput "   Agent Name: $agentName" "Cyan"
            }
            catch {
                Write-ColorOutput "⚠️  JSON parsing failed: $($_.Exception.Message)" "Yellow"
                Write-ColorOutput "   JSON content: $jsonPart" "Cyan"
            }
        }
        else {
            Write-ColorOutput "⚠️  Could not find AGENT_DEPLOYMENT_RESULT line" "Yellow"
            Write-ColorOutput "   Raw output lines:" "Cyan"
            for ($i = 0; $i -lt $resultLines.Count; $i++) {
                Write-ColorOutput "   [$i]: $($resultLines[$i])" "Cyan"
            }
        }
    }
    else {
        Write-ColorOutput "⚠️  Agent deployment failed" "Yellow"
        Write-ColorOutput "   This may prevent the backend from working properly" "Red"
        Write-ColorOutput "   Consider checking AI Foundry permissions and endpoint configuration" "Yellow"
    }
}
catch {
    Write-ColorOutput "⚠️  Agent deployment error: $($_.Exception.Message)" "Yellow"
    Write-ColorOutput "   This may prevent the backend from working properly" "Red"
}

# Step 5: Deploy Backend
Write-ColorOutput "`n📦 Step 5: Deploying Backend Function App..." "Green"

try {
    $backendScript = Join-Path $workspaceRoot "deploy-scripts" "deploy-backend-func-code.ps1"
    
    if (-not [string]::IsNullOrEmpty($agentId)) {
        Write-ColorOutput "Deploying backend with agent configuration..." "Yellow"
        & $backendScript `
            -FunctionAppName $functionAppName `
            -ResourceGroupName $functionAppResourceGroup `
            -AgentId $agentId `
            -AgentName "AI in A Box" `
            -AiFoundryEndpoint $aiFoundryEndpoint
    }
    else {
        Write-ColorOutput "Deploying backend without agent configuration..." "Yellow"
        & $backendScript `
            -FunctionAppName $functionAppName `
            -ResourceGroupName $functionAppResourceGroup
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Backend deployment completed!" "Green"
    }
    else {
        Write-ColorOutput "❌ Backend deployment failed!" "Red"
        exit 1
    }
    
}
catch {
    Write-ColorOutput "❌ Backend deployment error: $($_.Exception.Message)" "Red"
    exit 1
}

# Step 6: Deploy Frontend
Write-ColorOutput "`n📱 Step 6: Deploying Frontend Static Web App..." "Green"

try {
    $frontendScript = Join-Path $workspaceRoot "deploy-scripts" "deploy-frontend-spa-code.ps1"
    $backendApiUrl = "https://$functionAppName.azurewebsites.net/api"
    
    Write-ColorOutput "Deploying frontend with backend API configuration..." "Yellow"
    Write-ColorOutput "   Backend API URL: $backendApiUrl" "Cyan"
    
    & $frontendScript `
        -StaticWebAppName $staticWebAppName `
        -ResourceGroupName $staticWebAppResourceGroup `
        -BackendUrl $backendApiUrl
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Frontend deployment completed!" "Green"
    }
    else {
        Write-ColorOutput "❌ Frontend deployment failed!" "Red"
        exit 1
    }
    
}
catch {
    Write-ColorOutput "❌ Frontend deployment error: $($_.Exception.Message)" "Red"
    exit 1
}

# Step 7: Final Validation and Results
Write-ColorOutput "`n✅ Step 7: Final Validation and Results..." "Green"

# Get application URLs
try {
    $frontendUrl = az staticwebapp show `
        --name $staticWebAppName `
        --resource-group $staticWebAppResourceGroup `
        --query "defaultHostname" -o tsv
    
    $backendUrl = az functionapp show `
        --name $functionAppName `
        --resource-group $functionAppResourceGroup `
        --query "defaultHostName" -o tsv
    
    Write-ColorOutput "`n🎉 DEPLOYMENT SUCCESSFUL!" "Green"
    Write-ColorOutput "================================================================" "Green"
    Write-ColorOutput ""
    Write-ColorOutput "📱 Frontend Application:" "Cyan"
    Write-ColorOutput "   URL: https://$frontendUrl" "White"
    Write-ColorOutput "   Description: Modern chat interface for AI conversations" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "🔧 Backend API:" "Cyan"
    Write-ColorOutput "   URL: https://$backendUrl" "White"
    Write-ColorOutput "   Health Check: https://$backendUrl/api/health" "White"
    Write-ColorOutput "   Description: Secure proxy to AI Foundry" "Gray"
    Write-ColorOutput ""
    
    if (-not [string]::IsNullOrEmpty($agentId)) {
        Write-ColorOutput "🤖 AI Agent:" "Cyan"
        Write-ColorOutput "   Agent ID: $agentId" "White"
        Write-ColorOutput "   Name: AI in A Box" "White"
        Write-ColorOutput "   Endpoint: $aiFoundryEndpoint" "White"
        Write-ColorOutput ""
    }
    
    # Test health endpoint
    Write-ColorOutput "🏥 Testing backend health endpoint..." "Yellow"
    try {
        Start-Sleep -Seconds 5  # Give the Function App a moment to start
        $healthResponse = Invoke-RestMethod -Uri "https://$backendUrl/api/health" -Method Get -TimeoutSec 30
        
        if ($healthResponse.status -eq "healthy") {
            Write-ColorOutput "✅ Backend health check passed!" "Green"
            if ($healthResponse.aiFoundryConnection) {
                Write-ColorOutput "✅ AI Foundry connection: $($healthResponse.aiFoundryConnection.status)" "Green"
            }
        }
        else {
            Write-ColorOutput "⚠️  Backend health check returned non-healthy status" "Yellow"
        }
    }
    catch {
        Write-ColorOutput "⚠️  Health check failed (Function App may still be starting)" "Yellow"
        Write-ColorOutput "   Manual test: https://$backendUrl/api/health" "Cyan"
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "🚦 Next Steps:" "Cyan"
    Write-ColorOutput "1. Open the frontend URL in your browser" "White"
    Write-ColorOutput "2. Start a conversation with the AI assistant" "White"
    Write-ColorOutput "3. Review the deployment in Azure Portal" "White"
    Write-ColorOutput "4. Set up GitHub Actions for production deployment" "White"
    Write-ColorOutput ""
    Write-ColorOutput "📚 Documentation:" "Cyan"
    Write-ColorOutput "   Quick Start: docs/getting-started/03-quick-start.md" "White"
    Write-ColorOutput "   Development: docs/development/local-development.md" "White"
    Write-ColorOutput "   Production: docs/deployment/deployment-guide.md" "White"
    Write-ColorOutput ""
    Write-ColorOutput "⚠️  Remember: This is a development deployment." "Yellow"
    Write-ColorOutput "   For production, use GitHub Actions CI/CD pipeline." "Yellow"
    
}
catch {
    Write-ColorOutput "⚠️  Error retrieving final URLs: $($_.Exception.Message)" "Yellow"
    Write-ColorOutput "   Check Azure Portal for resource details" "Cyan"
}

Write-ColorOutput "`n🎉 Automated Quick-Start Deployment Complete!" "Green"
