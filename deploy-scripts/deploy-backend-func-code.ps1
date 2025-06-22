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
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-001" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-001"

.EXAMPLE
./deploy-backend-func-code.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-001" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-001" -SkipBuild

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

Write-ColorOutput "🚀 AI Foundry SPA - Backend Function App Deployment Script" "Green"
Write-ColorOutput "================================================================" "Green"
Write-ColorOutput ""

# Validate Azure CLI
Write-ColorOutput "🔍 Validating Azure CLI..." "Yellow"
if (-not (Test-Command "az")) {
    Write-ColorOutput "❌ Azure CLI not found. Please install Azure CLI first." "Red"
    exit 1
}

# Check Azure login status
Write-ColorOutput "🔑 Checking Azure authentication..." "Yellow"
try {
    $null = az account show 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Not logged into Azure. Please run 'az login' first." "Red"
        exit 1
    }
    Write-ColorOutput "✅ Azure CLI authenticated" "Green"
} catch {
    Write-ColorOutput "❌ Azure authentication check failed. Please run 'az login' first." "Red"
    exit 1
}

# Validate Function App exists
Write-ColorOutput "🔍 Validating Function App exists..." "Yellow"
try {
    $functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $null -eq $functionApp) {
        Write-ColorOutput "❌ Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'" "Red"
        Write-ColorOutput "   Please verify the Function App name and resource group are correct." "Red"
        exit 1
    }
    Write-ColorOutput "✅ Function App '$FunctionAppName' found in resource group '$ResourceGroupName'" "Green"
    $functionAppUrl = "https://$($functionApp.defaultHostName)"
    Write-ColorOutput "📍 Function App URL: $functionAppUrl" "Cyan"
} catch {
    Write-ColorOutput "❌ Failed to validate Function App. Please check your parameters." "Red"
    exit 1
}

# Navigate to backend directory
$backendPath = Join-Path $PSScriptRoot ".." "src" "backend"
if (-not (Test-Path $backendPath)) {
    Write-ColorOutput "❌ Backend directory not found at: $backendPath" "Red"
    exit 1
}

Write-ColorOutput "📁 Navigating to backend directory: $backendPath" "Yellow"
Set-Location $backendPath

# Validate .NET SDK
Write-ColorOutput "🔍 Validating .NET SDK..." "Yellow"
if (-not (Test-Command "dotnet")) {
    Write-ColorOutput "❌ .NET SDK not found. Please install .NET 8 SDK." "Red"
    exit 1
}

try {
    $dotnetVersion = dotnet --version
    Write-ColorOutput "✅ .NET SDK found: $dotnetVersion" "Green"
} catch {
    Write-ColorOutput "❌ Failed to get .NET version." "Red"
    exit 1
}

# Build the Function App (unless skipped)
if (-not $SkipBuild) {
    Write-ColorOutput "🔨 Building Function App..." "Yellow"
    try {
        dotnet clean > $null 2>&1
        dotnet build --configuration Release
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Build failed!" "Red"
            exit 1
        }
        Write-ColorOutput "✅ Build completed successfully" "Green"
    } catch {
        Write-ColorOutput "❌ Build process failed!" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "⏭️ Skipping build (as requested)" "Yellow"
}

# Create deployment package
Write-ColorOutput "📦 Creating deployment package..." "Yellow"
try {
    dotnet publish --configuration Release --output ./bin/publish
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Publish failed!" "Red"
        exit 1
    }
    
    # Create ZIP file for deployment
    $zipPath = "./deploy.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "./bin/publish/*" -DestinationPath $zipPath
    Write-ColorOutput "✅ Deployment package created: $zipPath" "Green"
} catch {
    Write-ColorOutput "❌ Failed to create deployment package!" "Red"
    exit 1
}

# Deploy to Azure Function App
Write-ColorOutput "🚀 Deploying to Azure Function App..." "Yellow"
try {
    az functionapp deployment source config-zip --resource-group $ResourceGroupName --name $FunctionAppName --src $zipPath
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Deployment failed!" "Red"
        exit 1
    }
    Write-ColorOutput "✅ Deployment completed successfully!" "Green"
} catch {
    Write-ColorOutput "❌ Deployment process failed!" "Red"
    exit 1
}

# Test the Function App endpoint (unless skipped)
if (-not $SkipTest) {
    Write-ColorOutput "🧪 Testing Function App health endpoint..." "Yellow"
    try {
        # Wait a moment for deployment to complete
        Start-Sleep -Seconds 10
        
        $healthUrl = "$functionAppUrl/api/health"
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30
        Write-ColorOutput "✅ Function App is responding: $($response | ConvertTo-Json -Compress)" "Green"
    } catch {
        Write-ColorOutput "⚠️ Health check failed, but deployment may still be successful" "Yellow"
        Write-ColorOutput "   URL: $healthUrl" "Yellow"
        Write-ColorOutput "   Error: $($_.Exception.Message)" "Yellow"
    }
} else {
    Write-ColorOutput "⏭️ Skipping endpoint test (as requested)" "Yellow"
}

# Clean up
if (Test-Path "./deploy.zip") {
    Remove-Item "./deploy.zip" -Force
}

# Deployment summary
Write-ColorOutput ""
Write-ColorOutput "🎉 Deployment Summary" "Green"
Write-ColorOutput "===================" "Green"
Write-ColorOutput "✅ Function App: $FunctionAppName" "White"
Write-ColorOutput "✅ Resource Group: $ResourceGroupName" "White"
Write-ColorOutput "✅ Function App URL: $functionAppUrl" "White"
Write-ColorOutput "✅ Health Endpoint: $functionAppUrl/api/health" "White"
Write-ColorOutput "✅ AI Proxy Endpoint: $functionAppUrl/api/ai-proxy" "White"
Write-ColorOutput ""
Write-ColorOutput "🔗 Next Steps:" "Yellow"
Write-ColorOutput "1. Test the Function App endpoints manually" "White"
Write-ColorOutput "2. Deploy frontend with BackendUrl: $functionAppUrl/api" "White"
Write-ColorOutput "3. Run integration tests" "White"
Write-ColorOutput ""
Write-ColorOutput "✅ Backend deployment completed successfully!" "Green"

Write-Host "🚀 AI Foundry SPA - Frontend Deployment" -ForegroundColor Green -BackgroundColor Black
Write-Host "=======================================" -ForegroundColor Green

# Change to project root (go up one level from deploy-scripts)
Set-Location (Join-Path $PSScriptRoot "..")

# Check if Azure CLI is installed and logged in
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Yellow
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    Write-Host "✅ Azure CLI authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan
} catch {
    Write-Error "❌ Azure CLI not authenticated. Please run 'az login' first."
    exit 1
}

Write-Host "☁️ Deploying to Azure Static Web App" -ForegroundColor Yellow
Write-Host "   Target Static Web App: $StaticWebAppName" -ForegroundColor Cyan
Write-Host "   Target Resource Group: $ResourceGroupName" -ForegroundColor Cyan

# Verify the Static Web App exists
Write-Host "🔍 Verifying Static Web App '$StaticWebAppName' in resource group '$ResourceGroupName'..." -ForegroundColor Yellow
try {
    $staticWebApp = az staticwebapp show --name $StaticWebAppName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    Write-Host "✅ Static Web App found: $($staticWebApp.name)" -ForegroundColor Green
} catch {
    Write-Error "❌ Static Web App '$StaticWebAppName' not found in resource group '$ResourceGroupName'!"
    Write-Host "💡 To create the infrastructure first, run:" -ForegroundColor Yellow
    Write-Host "   az deployment sub create --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam --location eastus2" -ForegroundColor White
    exit 1
}

# Update environment configuration for dev environment
Write-Host "🔧 Updating frontend configuration for dev environment..." -ForegroundColor Yellow

# Create dev environment file with hardcoded dev values
$envContent = @"
# Dev Environment Configuration - Generated by deployment script
VITE_BACKEND_URL=$($BackendUrl -replace '^$', 'http://localhost:7071/api')
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=false

# AI Foundry Configuration (Dev Environment)
VITE_AI_FOUNDRY_AGENT_NAME=CancerBot
VITE_AI_FOUNDRY_AGENT_ID=asst_dH7M0nbmdRblhSQO8nIGIYF4
VITE_AI_FOUNDRY_PROJECT_URL=https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject
VITE_AI_FOUNDRY_ENDPOINT=https://ai-foundry-dev-eus.azureml.net
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4

# Azure Static Web App Configuration
VITE_STATIC_WEB_APP_NAME=$StaticWebAppName

# Environment Settings
VITE_ENV=dev
NODE_ENV=development
"@

Set-Content -Path "src/frontend/.env.dev" -Value $envContent
Write-Host "✅ Dev environment configuration created" -ForegroundColor Green

# Build frontend if not skipped
if (-not $SkipBuild) {
    Write-Host "🔨 Building frontend application for dev environment..." -ForegroundColor Yellow
    
    # Navigate to frontend directory
    Push-Location "src/frontend"
    try {
        # Install dependencies
        Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ npm install failed!"
            exit 1
        }
        
        # Build the application for dev environment
        Write-Host "🏗️ Building application for dev..." -ForegroundColor Cyan
        $env:NODE_ENV = "development"
        
        # Try the dev build script first, fall back to standard build if it fails
        npm run build:dev
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "⚠️ Dev build failed, trying standard build..."
            npm run build
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Frontend build failed!"
            exit 1
        }
        
        Write-Host "✅ Frontend build completed for dev environment!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
} else {
    Write-Host "⏭️ Skipping frontend build..." -ForegroundColor Yellow
}

# Verify the build output exists
$buildPath = "src/frontend/dist"
if (-not (Test-Path $buildPath)) {
    Write-Error "❌ Build output not found at '$buildPath'! Please build the application first."
    exit 1
}

Write-Host "📁 Using build output from: $buildPath" -ForegroundColor Cyan

# Deploy to Static Web App
Write-Host "🚀 Deploying frontend files to Azure Static Web App..." -ForegroundColor Yellow

# Get deployment token for the Static Web App
Write-Host "🔑 Getting deployment token..." -ForegroundColor Cyan
$deploymentToken = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroupName --query "properties.apiKey" --output tsv

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($deploymentToken)) {
    Write-Error "❌ Failed to get deployment token for Static Web App!"
    exit 1
}

# Install SWA CLI if not present
Write-Host "📦 Checking for SWA CLI..." -ForegroundColor Cyan
try {
    swa --version | Out-Null
    Write-Host "✅ SWA CLI is available" -ForegroundColor Green
} catch {
    Write-Host "📦 Installing SWA CLI..." -ForegroundColor Yellow
    npm install -g @azure/static-web-apps-cli
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to install SWA CLI!"
        exit 1
    }
    Write-Host "✅ SWA CLI installed" -ForegroundColor Green
}

# Deploy using SWA CLI
Write-Host "🚀 Deploying to Static Web App..." -ForegroundColor Yellow
swa deploy $buildPath --deployment-token $deploymentToken --env "dev"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to deploy to Static Web App!"
    exit 1
}

Write-Host "✅ Frontend files deployed successfully!" -ForegroundColor Green

# Get the static web app URL
Write-Host "🔗 Retrieving Static Web App URL..." -ForegroundColor Yellow
$staticWebsiteUrl = "https://$($staticWebApp.defaultHostname)"

# Clean up temporary dev env file
if (Test-Path "src/frontend/.env.dev") {
    Remove-Item "src/frontend/.env.dev" -Force
}

# Final summary
Write-Host ""
Write-Host "🎉 Frontend deployment completed successfully! 🎉" -ForegroundColor Green -BackgroundColor Black
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Static Web App: $StaticWebAppName" -ForegroundColor White
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "   Static Web App URL: $staticWebsiteUrl" -ForegroundColor White
Write-Host ""
Write-Host "🌍 Your AI Foundry SPA is now live at:" -ForegroundColor Green
Write-Host "   $staticWebsiteUrl" -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host ""

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "   Backend URL: $($BackendUrl -replace '^$', 'http://localhost:7071/api (local dev)')" -ForegroundColor White
Write-Host "   AI Foundry: ai-foundry-dev-eus (dev environment)" -ForegroundColor White
Write-Host ""

Write-Host "✨ Frontend deployment complete! ✨" -ForegroundColor Green
