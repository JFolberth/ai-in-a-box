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

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2" -SkipBuild

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "my-custom-function-app" -ResourceGroupName "my-rg" -SkipBuild -SkipTest
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTest
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
    $functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $null -eq $functionApp) {
        Write-ColorOutput "Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'" "Red"
        Write-ColorOutput "   Please verify the Function App name and resource group are correct." "Red"
        exit 1
    }
    Write-ColorOutput "Function App '$FunctionAppName' found in resource group '$ResourceGroupName'" "Green"
    $functionAppUrl = "https://$($functionApp.defaultHostName)"
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
    
    Compress-Archive -Path "./bin/publish/*" -DestinationPath $zipPath
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
} else {
    Write-ColorOutput "Deployment failed!" "Red"
    Write-ColorOutput "Check the Azure portal for detailed error information" "Yellow"
    exit 1
}

Write-ColorOutput "`nBackend deployment script completed!" "Green"
