#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy ONLY the frontend of AI Foundry SPA to Azure Storage Static Website

.DESCRIPTION
This script deploys only the frontend portion of the AI Foundry SPA to Azure Storage.
It builds the frontend and uploads it to an existing Azure Storage account.

.PARAMETER StorageAccountName
The name of the Azure Storage account to deploy to (optional - will be detected from Bicep outputs)

.PARAMETER ResourceGroupName
The name of the resource group containing the storage account (optional - will be detected)

.PARAMETER BackendUrl
The backend Function App URL to configure (optional - will update .env for production)

.PARAMETER SkipBuild
Skip the npm build step if the application is already built

.EXAMPLE
./deploy-frontend-only.ps1

.EXAMPLE
./deploy-frontend-only.ps1 -BackendUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net/api"

.EXAMPLE
./deploy-frontend-only.ps1 -StorageAccountName "staifrontspa001" -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-001"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$BackendUrl,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 AI Foundry SPA - Frontend Only Deployment" -ForegroundColor Green -BackgroundColor Black
Write-Host "=============================================" -ForegroundColor Green

# Change to project root
Set-Location $PSScriptRoot

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

# If storage account details not provided, try to get them from deployment outputs
if (-not $StorageAccountName -or -not $ResourceGroupName) {
    Write-Host "🔍 Attempting to detect storage account from Bicep deployment..." -ForegroundColor Yellow
    
    # Try to get deployment outputs
    try {
        $subscriptionId = $account.id
        $deploymentName = "ai-foundry-spa-orchestrator-dev"
        
        $deploymentOutputs = az deployment sub show `
            --name $deploymentName `
            --query "properties.outputs" `
            --output json 2>$null | ConvertFrom-Json
            
        if ($deploymentOutputs) {
            $StorageAccountName = $deploymentOutputs.frontendStorageAccountName.value
            $ResourceGroupName = $deploymentOutputs.frontendResourceGroupName.value
            Write-Host "✅ Detected from deployment:" -ForegroundColor Green
            Write-Host "   Storage Account: $StorageAccountName" -ForegroundColor Cyan
            Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "⚠️ Could not auto-detect storage account. Please provide manually."
    }
}

# If still not found, prompt user or use defaults
if (-not $StorageAccountName) {
    Write-Host "📝 Storage account details needed. Based on your configuration:" -ForegroundColor Yellow
    $StorageAccountName = "staifrontspa001"  # From bicep naming convention
    $ResourceGroupName = "rg-ai-foundry-spa-frontend-dev-001"
    
    Write-Host "🔧 Using default names:" -ForegroundColor Cyan
    Write-Host "   Storage Account: $StorageAccountName" -ForegroundColor Cyan
    Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press Enter to continue or Ctrl+C to cancel and specify manually..." -ForegroundColor Yellow
    Read-Host
}

# Verify the storage account exists
Write-Host "🔍 Verifying storage account '$StorageAccountName' in resource group '$ResourceGroupName'..." -ForegroundColor Yellow
try {
    $storageAccount = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    Write-Host "✅ Storage account found: $($storageAccount.name)" -ForegroundColor Green
} catch {
    Write-Error "❌ Storage account '$StorageAccountName' not found in resource group '$ResourceGroupName'!"
    Write-Host "💡 To create the infrastructure first, run:" -ForegroundColor Yellow
    Write-Host "   az deployment sub create --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam --location eastus2" -ForegroundColor White
    exit 1
}

# Update environment configuration for production if BackendUrl is provided
if ($BackendUrl) {
    Write-Host "🔧 Updating frontend configuration for production deployment..." -ForegroundColor Yellow
    
    # Create production environment file
    $envContent = @"
# Production Configuration - Generated by deployment script
VITE_BACKEND_URL=$BackendUrl
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# AI Foundry Configuration (Single Instance)
VITE_AI_FOUNDRY_AGENT_NAME=CancerBot
VITE_AI_FOUNDRY_AGENT_ID=asst_dH7M0nbmdRblhSQO8nIGIYF4
VITE_AI_FOUNDRY_PROJECT_URL=https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject
VITE_AI_FOUNDRY_ENDPOINT=https://ai-foundry-dev-eus.azureml.net
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4

# Azure Storage Configuration
VITE_STORAGE_ACCOUNT_NAME=$StorageAccountName

# Environment Settings
VITE_ENV=production
NODE_ENV=production
"@
    
    Set-Content -Path "src/frontend/.env.production" -Value $envContent
    Write-Host "✅ Production environment configuration created" -ForegroundColor Green
}

# Build frontend if not skipped
if (-not $SkipBuild) {
    Write-Host "🔨 Building frontend application..." -ForegroundColor Yellow
    
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
        
        # Build the application
        Write-Host "🏗️ Building application..." -ForegroundColor Cyan
        if ($BackendUrl) {
            # Use production environment
            $env:NODE_ENV = "production"
            npm run build -- --mode production
        } else {
            npm run build
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Frontend build failed!"
            exit 1
        }
        
        Write-Host "✅ Frontend build completed!" -ForegroundColor Green
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

# Enable static website hosting
Write-Host "🌐 Enabling static website hosting..." -ForegroundColor Yellow
az storage blob service-properties update `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --static-website `
    --404-document "index.html" `
    --index-document "index.html"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to enable static website hosting!"
    exit 1
}

Write-Host "✅ Static website hosting enabled!" -ForegroundColor Green

# Deploy static website
Write-Host "🚀 Uploading frontend files to Azure Storage..." -ForegroundColor Yellow

# Upload built files to storage
az storage blob upload-batch `
    --account-name $StorageAccountName `
    --destination '$web' `
    --source $buildPath `
    --overwrite `
    --pattern "*"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to upload static website files!"
    exit 1
}

Write-Host "✅ Frontend files uploaded successfully!" -ForegroundColor Green

# Get the static website URL
Write-Host "🔗 Retrieving static website URL..." -ForegroundColor Yellow
$staticWebsiteUrl = az storage account show `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --query "primaryEndpoints.web" `
    --output tsv

# Clean up temporary production env file
if ($BackendUrl -and (Test-Path "src/frontend/.env.production")) {
    Remove-Item "src/frontend/.env.production" -Force
}

# Final summary
Write-Host ""
Write-Host "🎉 Frontend deployment completed successfully! 🎉" -ForegroundColor Green -BackgroundColor Black
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Storage Account: $StorageAccountName" -ForegroundColor White
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "   Static Website URL: $staticWebsiteUrl" -ForegroundColor White
Write-Host ""
Write-Host "🌍 Your AI Foundry SPA is now live at:" -ForegroundColor Green
Write-Host "   $staticWebsiteUrl" -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host ""

if (-not $BackendUrl) {
    Write-Host "⚠️  Important: Make sure your backend Function App is deployed and running!" -ForegroundColor Yellow
    Write-Host "   The frontend expects the backend at: http://localhost:7071/api (local) or your deployed Function App URL" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 To deploy with production backend URL, run:" -ForegroundColor Cyan
    Write-Host "   ./deploy-frontend-only.ps1 -BackendUrl 'https://your-function-app.azurewebsites.net/api'" -ForegroundColor White
}

Write-Host "✨ Deployment complete! ✨" -ForegroundColor Green
