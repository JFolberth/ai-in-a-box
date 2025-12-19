#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy the backend Function App code to Azure

.DESCRIPTION
This script deploys the backend Function App code to an existing Azure Function App.
Both FunctionAppName and ResourceGroupName are required parameters.

For local development, use 'func start' instead.

.PARAMETER FunctionAppName
The name of the Azure Function App to deploy to. Required.

.PARAMETER ResourceGroupName
The name of the resource group containing the Function App. Required.

.PARAMETER SkipBuild
Skip the dotnet build step if the application is already built

.PARAMETER SkipTest
Skip the endpoint testing after deployment

.PARAMETER AgentId
Optional. AI Foundry Agent ID to update in Function App settings. 
Only needed when updating agent configuration after deployment.

.PARAMETER AgentName
Optional. AI Foundry Agent Name to update in Function App settings.
Only needed when updating agent configuration after deployment.

.PARAMETER AiFoundryEndpoint
Optional. AI Foundry Endpoint URL to update in Function App settings.
Only needed when updating agent configuration after deployment.

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2" -SkipBuild

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "my-custom-function-app" -ResourceGroupName "my-rg" -SkipBuild -SkipTest

.EXAMPLE
# Update agent configuration after GitHub Actions deploys the agent
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2" -AgentId "asst_abc123" -AgentName "AI in A Box" -AiFoundryEndpoint "https://ai-foundry.cognitiveservices.azure.com/" -SkipBuild
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTest,
    
    [Parameter(Mandatory = $false)]
    [string]$AgentId = "",
    
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$AiFoundryEndpoint = ""
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

Write-ColorOutput "AI Foundry SPA - Backend Function App Deployment Script" "Green"
Write-ColorOutput "================================================================" "Green"
Write-ColorOutput ""

# Validate Azure CLI
Write-ColorOutput "Validating Azure CLI..." "Yellow"
if (-not (Test-Command "az")) {
    Write-ColorOutput "Azure CLI not found. Please install Azure CLI first." "Red"
    exit 1
}

# Check Azure login status
Write-ColorOutput "Checking Azure authentication..." "Yellow"
try {
    $null = az account show 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Not logged into Azure. Please run 'az login' first." "Red"
        exit 1
    }
    Write-ColorOutput "Azure CLI authenticated" "Green"
} catch {
    Write-ColorOutput "Azure authentication check failed. Please run 'az login' first." "Red"
    exit 1
}

# Validate Function App exists
Write-ColorOutput "Validating Function App exists..." "Yellow"
try {
    $functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName --query "properties" 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $null -eq $functionApp) {
        Write-ColorOutput "Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'" "Red"
        Write-ColorOutput "   Please verify the Function App name and resource group are correct." "Red"
        exit 1
    }
    Write-ColorOutput "Function App '$FunctionAppName' found in resource group '$ResourceGroupName'" "Green"
    
    # Construct Function App URL using the default hostname
    $defaultHostName = $functionApp.defaultHostName
    if ([string]::IsNullOrEmpty($defaultHostName)) {
        # Fallback to constructed hostname if defaultHostName is not available
        $defaultHostName = "$FunctionAppName.azurewebsites.net"
        Write-ColorOutput "   Using constructed hostname: $defaultHostName" "Yellow"
    }
    $functionAppUrl = "https://$defaultHostName"
    Write-ColorOutput "Function App URL: $functionAppUrl" "Cyan"
} catch {
    Write-ColorOutput "Failed to validate Function App. Please check your parameters." "Red"
    exit 1
}

# Navigate to backend directory
$backendPath = Join-Path $PSScriptRoot ".." "src" "backend"
if (-not (Test-Path $backendPath)) {
    Write-ColorOutput "Backend directory not found at: $backendPath" "Red"
    exit 1
}

Write-ColorOutput "Navigating to backend directory: $backendPath" "Yellow"
Set-Location $backendPath

# Validate .NET SDK
Write-ColorOutput "Validating .NET SDK..." "Yellow"
if (-not (Test-Command "dotnet")) {
    Write-ColorOutput ".NET SDK not found. Please install .NET 8 SDK." "Red"
    exit 1
}

try {
    $dotnetVersion = dotnet --version
    Write-ColorOutput ".NET SDK found: $dotnetVersion" "Green"
} catch {
    Write-ColorOutput "Failed to get .NET version." "Red"
    exit 1
}

# Build the Function App (unless skipped)
if (-not $SkipBuild) {
    Write-ColorOutput "Building Function App..." "Yellow"
    try {
        dotnet clean > $null 2>&1
        dotnet build --configuration Release
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Build failed!" "Red"
            exit 1
        }
        Write-ColorOutput "Build completed successfully" "Green"
    } catch {
        Write-ColorOutput "Build process failed!" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "Skipping build (as requested)" "Yellow"
}

# Create deployment package
Write-ColorOutput "Creating deployment package..." "Yellow"
try {
    dotnet publish --configuration Release --output ./bin/publish
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Publish failed!" "Red"
        exit 1
    }
    
    # Create ZIP file for deployment
    $zipPath = "./deploy.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    # Change to publish directory and create zip from there to include all files and hidden directories
    Push-Location "./bin/publish"
    try {
        # Use Compress-Archive with relative paths to include all files including hidden ones
        $allItems = Get-ChildItem -Path "." -Force | ForEach-Object { $_.Name }
        Compress-Archive -Path $allItems -DestinationPath "../../deploy.zip"
    }
    finally {
        Pop-Location
    }
    Write-ColorOutput "Deployment package created: $zipPath" "Green"
} catch {
    Write-ColorOutput "Failed to create deployment package!" "Red"
    exit 1
}

# Deploy to Azure Function App
Write-ColorOutput "Deploying to Azure Function App..." "Yellow"

# Deploy the code package
Write-ColorOutput "Uploading code package..." "Cyan"
az functionapp deployment source config-zip --resource-group $ResourceGroupName --name $FunctionAppName --src $zipPath

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "Deployment completed successfully!" "Green"
    Write-ColorOutput "Function App: $FunctionAppName" "Cyan"
    Write-ColorOutput "Resource Group: $ResourceGroupName" "Cyan"
    Write-ColorOutput "URL: https://$FunctionAppName.azurewebsites.net" "Green"
    
    # Update Function App settings with agent configuration if provided
    $settingsToUpdate = @()
    
    if (-not [string]::IsNullOrEmpty($AgentId)) {
        $settingsToUpdate += "AI_FOUNDRY_AGENT_ID=$AgentId"
        Write-ColorOutput "Will update AI_FOUNDRY_AGENT_ID setting" "Cyan"
    }
    
    if (-not [string]::IsNullOrEmpty($AgentName)) {
        $settingsToUpdate += "AI_FOUNDRY_AGENT_NAME=$AgentName"
        Write-ColorOutput "Will update AI_FOUNDRY_AGENT_NAME setting" "Cyan"
    }
    
    if (-not [string]::IsNullOrEmpty($AiFoundryEndpoint)) {
        $settingsToUpdate += "AI_FOUNDRY_ENDPOINT=$AiFoundryEndpoint"
        Write-ColorOutput "Will update AI_FOUNDRY_ENDPOINT setting" "Cyan"
    }
    
    if ($settingsToUpdate.Count -gt 0) {
        Write-ColorOutput "Updating Function App settings with agent configuration..." "Yellow"
        try {
            # Use az functionapp config appsettings set with proper parameter passing
            $azArgs = @(
                "functionapp", "config", "appsettings", "set",
                "--name", $FunctionAppName,
                "--resource-group", $ResourceGroupName,
                "--settings"
            ) + $settingsToUpdate
            
            & az @azArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Function App settings updated successfully!" "Green"
            } else {
                Write-ColorOutput "Warning: Failed to update Function App settings" "Yellow"
                Write-ColorOutput "You may need to update them manually in the Azure portal" "Yellow"
            }
        } catch {
            Write-ColorOutput "Warning: Error updating Function App settings: $($_.Exception.Message)" "Yellow"
            Write-ColorOutput "You may need to update them manually in the Azure portal" "Yellow"
        }
    } else {
        Write-ColorOutput "No agent configuration provided - Function App settings unchanged" "Yellow"
        Write-ColorOutput "Use -AgentId, -AgentName, and -AiFoundryEndpoint parameters to update agent configuration" "Cyan"
    }
    
} else {
    Write-ColorOutput "Deployment failed!" "Red"
    Write-ColorOutput "Check the Azure portal for detailed error information" "Yellow"
    exit 1
}

# Test the health endpoint if not skipped
if (-not $SkipTest) {
    Write-ColorOutput "`nTesting health endpoint..." "Yellow"
    $healthUrl = "https://$FunctionAppName.azurewebsites.net/api/health"
    Write-ColorOutput "Health URL: $healthUrl" "Cyan"
    
    # Wait a moment for the deployment to settle
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30
        if ($response.status -eq "healthy") {
            Write-ColorOutput "✅ Health check passed!" "Green"
            if ($response.aiFoundryConnection) {
                Write-ColorOutput "✅ AI Foundry connection: $($response.aiFoundryConnection.status)" "Green"
            }
        } else {
            Write-ColorOutput "⚠️ Health check returned non-healthy status" "Yellow"
            Write-ColorOutput "Response: $($response | ConvertTo-Json)" "Yellow"
        }
    } catch {
        Write-ColorOutput "⚠️ Health check failed: $($_.Exception.Message)" "Yellow"
        Write-ColorOutput "The Function App may still be starting up - try again in a few minutes" "Cyan"
        Write-ColorOutput "Manual test: $healthUrl" "Cyan"
    }
} else {
    Write-ColorOutput "Skipping health endpoint test (as requested)" "Yellow"
    Write-ColorOutput "Manual test: https://$FunctionAppName.azurewebsites.net/api/health" "Cyan"
}

Write-ColorOutput "`nBackend deployment script completed!" "Green"
