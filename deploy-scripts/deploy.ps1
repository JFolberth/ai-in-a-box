#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy AI Foundry SPA to Azure using Azure CLI with separate resource groups for frontend and backend

.DESCRIPTION
This script deploys the AI Foundry SPA infrastructure and application to Azure using Azure CLI and Bicep templates.
It creates separate resource groups for frontend and backend, each with their own Application Insights instance.
Frontend: Storage Account for static website hosting
Backend: Function App for AI Foundry proxy
NO Azure Developer CLI (azd) dependencies - uses pure Azure CLI commands.

.PARAMETER SubscriptionId
The Azure subscription ID to deploy to

.PARAMETER Location
The Azure region for deployment (default: eastus)

.PARAMETER EnvironmentName
The environment name (default: dev)

.PARAMETER ApplicationName
The application name for resource naming (default: ai-foundry-spa)

.PARAMETER SkipBuild
Skip the npm build step if the application is already built

.EXAMPLE
./deploy.ps1 -SubscriptionId "your-subscription-id" -Location "eastus"

.EXAMPLE
./deploy.ps1 -SubscriptionId "your-subscription-id" -Location "westus2" -SkipBuild
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
      
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApplicationName = "ai-foundry-spa",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild
)

# Error handling
$ErrorActionPreference = "Stop"

# Generate resource token for uniqueness
$ResourceToken = "rt$(Get-Random -Minimum 100 -Maximum 999)"

Write-Host "🚀 Starting deployment of AI Foundry SPA using Azure CLI..." -ForegroundColor Green
Write-Host "📋 Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "📋 Location: $Location" -ForegroundColor Cyan
Write-Host "📋 Resource Token: $ResourceToken" -ForegroundColor Cyan

# Verify Azure CLI is installed and logged in
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Not logged in"
    }
    Write-Host "✅ Azure CLI authenticated as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Error "❌ Azure CLI not installed or not logged in. Please run 'az login' first."
    exit 1
}

# Set the subscription
Write-Host "🔧 Setting Azure subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to set subscription: $SubscriptionId"
    exit 1
}

# Note: Resource groups will be created by the orchestrator template

# Validate Bicep deployment
Write-Host "🔍 Validating Bicep deployment..." -ForegroundColor Yellow
$deploymentName = "ai-foundry-spa-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

az deployment sub validate `
    --location $Location `
    --template-file "infra/main-orchestrator.bicep" `
    --parameters "infra/dev-orchestrator.parameters.bicepparam" `
    --parameters resourceToken=$ResourceToken `
    --verbose

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Bicep validation failed!"
    exit 1
}

Write-Host "✅ Bicep validation successful!" -ForegroundColor Green

# Deploy infrastructure
Write-Host "🏗️ Deploying infrastructure with Bicep orchestrator..." -ForegroundColor Yellow
$deploymentOutput = az deployment sub create `
    --location $Location `
    --name $deploymentName `
    --template-file "infra/main-orchestrator.bicep" `
    --parameters "infra/dev-orchestrator.parameters.bicepparam" `
    --parameters resourceToken=$ResourceToken `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Infrastructure deployment failed!"
    exit 1
}

$deployment = $deploymentOutput | ConvertFrom-Json
$outputs = $deployment.properties.outputs

Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "📦 Frontend Resource Group: $($outputs.frontendResourceGroupName.value)" -ForegroundColor Cyan
Write-Host "📦 Backend Resource Group: $($outputs.backendResourceGroupName.value)" -ForegroundColor Cyan
Write-Host "📦 Frontend Storage Account: $($outputs.frontendStorageAccountName.value)" -ForegroundColor Cyan
Write-Host "⚡ Backend Function App: $($outputs.backendFunctionAppName.value)" -ForegroundColor Cyan
Write-Host "🌐 Static Website URL: $($outputs.frontendStaticWebsiteUrl.value)" -ForegroundColor Cyan

# Build frontend if not skipped
if (-not $SkipBuild) {
    Write-Host "🔨 Building frontend application..." -ForegroundColor Yellow
    
    # Install dependencies
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ npm install failed!"
        exit 1
    }
    
    # Build the application
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Frontend build failed!"
        exit 1
    }
    
    Write-Host "✅ Frontend build completed!" -ForegroundColor Green
} else {
    Write-Host "⏭️ Skipping frontend build..." -ForegroundColor Yellow
}

# Deploy static website
Write-Host "🌐 Deploying static website to Azure Storage..." -ForegroundColor Yellow
$frontendStorageAccountName = $outputs.frontendStorageAccountName.value

# Enable static website hosting
az storage blob service-properties update `
    --account-name $frontendStorageAccountName `
    --static-website `
    --404-document "index.html" `
    --index-document "index.html"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to enable static website hosting!"
    exit 1
}

# Upload built files to storage
az storage blob upload-batch `
    --account-name $frontendStorageAccountName `
    --destination '$web' `
    --source "src/frontend/dist" `
    --overwrite

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to upload static website files!"
    exit 1
}

Write-Host "✅ Static website deployed successfully!" -ForegroundColor Green

# Build and deploy Function App
Write-Host "⚡ Building and deploying Function App..." -ForegroundColor Yellow
$backendFunctionAppName = $outputs.backendFunctionAppName.value

# Build the Function App
Push-Location "src/backend"
try {
    dotnet build AIFoundryProxy.csproj --configuration Release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Function App build failed!"
        exit 1
    }
    
    # Publish the Function App
    dotnet publish AIFoundryProxy.csproj --configuration Release --output "./bin/Release/net8.0/publish"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Function App publish failed!"
        exit 1
    }    
    # Create deployment package
    Compress-Archive -Path "./bin/Release/net8.0/publish/*" -DestinationPath "./bin/Release/net8.0/publish.zip" -Force
    
} finally {
    Pop-Location
}

# Deploy Function App using zip deployment
$backendResourceGroupName = $outputs.backendResourceGroupName.value
az functionapp deployment source config-zip `
    --resource-group $backendResourceGroupName `
    --name $backendFunctionAppName `
    --src "src/backend/bin/Release/net8.0/publish.zip"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Function App deployment failed!"
    exit 1
}

Write-Host "✅ Function App deployed successfully!" -ForegroundColor Green

# Final summary
Write-Host ""
Write-Host "🎉 Deployment completed successfully! 🎉" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   📦 Frontend Resource Group: $($outputs.frontendResourceGroupName.value)" -ForegroundColor White
Write-Host "   📦 Backend Resource Group: $($outputs.backendResourceGroupName.value)" -ForegroundColor White
Write-Host "   🌐 Frontend URL: $($outputs.frontendStaticWebsiteUrl.value)" -ForegroundColor White
Write-Host "   ⚡ Backend API URL: $($outputs.backendApiUrl.value)" -ForegroundColor White
Write-Host "   📊 Frontend App Insights: $($outputs.frontendApplicationInsightsConnectionString.value)" -ForegroundColor White
Write-Host "   📊 Backend App Insights: $($outputs.backendApplicationInsightsConnectionString.value)" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Update your .env file with the Backend API URL" -ForegroundColor White
Write-Host "   2. Test the application at the Frontend URL" -ForegroundColor White
Write-Host "   3. Monitor frontend and backend separately using their respective Application Insights" -ForegroundColor White
Write-Host ""
