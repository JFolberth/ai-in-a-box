#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy the frontend of AI Foundry SPA to Azure Static Web App

.DESCRIPTION
This script deploys the frontend portion of the AI Foundry SPA to an existing Azure Static Web App.
Both StaticWebAppName and ResourceGroupName are required parameters.

This script uses the same deployment method as the CI pipeline: first tries az staticwebapp create
with --source, then falls back to SWA CLI if that fails (because the app already exists).

For local development, use 'npm run dev' instead.

.PARAMETER StaticWebAppName
The name of the Azure Static Web App to deploy to. Required.

.PARAMETER ResourceGroupName
The name of the resource group containing the Static Web App. Required.

.PARAMETER BackendUrl
The backend Function App URL to configure (optional - will update .env for dev environment)

.PARAMETER SkipBuild
Skip the npm build step if the application is already built

.EXAMPLE
./deploy-frontend-spa-code.ps1 -StaticWebAppName "stapp-aibox-fd-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2"

.EXAMPLE
./deploy-frontend-spa-code.ps1 -StaticWebAppName "stapp-aibox-fd-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2" -BackendUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net/api"

.EXAMPLE
./deploy-frontend-spa-code.ps1 -StaticWebAppName "my-custom-static-web-app" -ResourceGroupName "my-rg" -SkipBuild
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$StaticWebAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$BackendUrl,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Refresh environment variables to ensure PATH is updated (cross-platform compatible)
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    # Windows: Merge Machine and User PATH variables
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathSeparator = [System.IO.Path]::PathSeparator
    if ($machinePath -and $userPath) {
        $env:PATH = $machinePath + $pathSeparator + $userPath
    } elseif ($machinePath) {
        $env:PATH = $machinePath
    } elseif ($userPath) {
        $env:PATH = $userPath
    }
}
# On Linux/macOS, $env:PATH is already properly set by the shell

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
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box
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

# Deploy to Static Web App using Azure CLI (same method as CI)
Write-Host "🚀 Deploying frontend files to Azure Static Web App using Azure CLI..." -ForegroundColor Yellow

# Try deploying using az staticwebapp create with --source (same as CI)
Write-Host "📦 Attempting deployment with az staticwebapp create..." -ForegroundColor Cyan
Write-Host "   Static Web App: $StaticWebAppName" -ForegroundColor Gray
Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "   Source Path: $buildPath" -ForegroundColor Gray

try {
    # First try: Use az staticwebapp create with --source (this will fail if it exists, but might work for deployment)
    az staticwebapp create --name $StaticWebAppName --resource-group $ResourceGroupName --source $buildPath --location $ResourceGroupName --branch "main" --token "$env:GITHUB_TOKEN" 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment completed successfully with az staticwebapp create!" -ForegroundColor Green
        $deploymentSuccess = $true
    } else {
        Write-Host "ℹ️  az staticwebapp create failed (likely because app exists), trying deployment to existing app..." -ForegroundColor Yellow
        $deploymentSuccess = $false
    }
} catch {
    Write-Host "ℹ️  az staticwebapp create failed, trying deployment to existing app..." -ForegroundColor Yellow
    $deploymentSuccess = $false
}

# If create failed (because app exists), deploy to existing using SWA CLI
if (-not $deploymentSuccess) {
    Write-Host "📦 Deploying to existing Static Web App using SWA CLI..." -ForegroundColor Cyan
    
    # Get deployment token for the Static Web App
    Write-Host "🔑 Getting deployment token..." -ForegroundColor Cyan
    $deploymentToken = az staticwebapp secrets list --name $StaticWebAppName --resource-group $ResourceGroupName --query "properties.apiKey" --output tsv
    
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($deploymentToken)) {
        Write-Error "❌ Failed to get deployment token for Static Web App!"
        exit 1
    }
    
    try {
        # Ensure npm global packages are in PATH (cross-platform compatible)
        $npmGlobalPath = npm config get prefix
        if ($npmGlobalPath -and -not $env:PATH.Contains($npmGlobalPath)) {
            $pathSeparator = [System.IO.Path]::PathSeparator
            $env:PATH = "$npmGlobalPath$pathSeparator" + $env:PATH
            Write-Host "✅ Added npm global path to PATH: $npmGlobalPath" -ForegroundColor Green
        }
        
        # Check if SWA CLI is already installed
        Write-Host "🔍 Checking for SWA CLI..." -ForegroundColor Cyan
        
        $swaInstalled = $false
        try {
            $swaVersion = swa --version 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($swaVersion)) {
                Write-Host "✅ SWA CLI already installed (version: $swaVersion)" -ForegroundColor Green
                $swaInstalled = $true
            }
        } catch {
            # SWA CLI not found, will install below
        }
        
        if (-not $swaInstalled) {
            # Install SWA CLI if not found
            Write-Host "📦 Installing SWA CLI..." -ForegroundColor Cyan
            npm install -g @azure/static-web-apps-cli
            
            if ($LASTEXITCODE -ne 0) {
                Write-Error "❌ Failed to install SWA CLI!"
                exit 1
            }
            
            # Verify SWA CLI is accessible after installation
            try {
                $swaVersion = swa --version 2>$null
                if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($swaVersion)) {
                    Write-Host "✅ SWA CLI installed successfully (version: $swaVersion)" -ForegroundColor Green
                } else {
                    Write-Error "❌ SWA CLI installed but not accessible!"
                    exit 1
                }
            } catch {
                Write-Error "❌ SWA CLI installed but not accessible!"
                exit 1
            }
        }
        
        # Deploy using SWA CLI (same as CI)
        Write-Host "🚀 Deploying with SWA CLI..." -ForegroundColor Cyan
        swa deploy --app-location $buildPath --deployment-token $deploymentToken --env "default"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deployment completed successfully with SWA CLI!" -ForegroundColor Green
            $deploymentSuccess = $true
        } else {
            Write-Error "❌ SWA CLI deployment failed!"
            $deploymentSuccess = $false
        }
    } catch {
        Write-Host "❌ SWA CLI deployment failed" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        $deploymentSuccess = $false
    }
}

if (-not $deploymentSuccess) {
    Write-Host ""
    Write-Host "❌ All deployment methods failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "🛠️  Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   1. Verify the Static Web App exists and is accessible" -ForegroundColor White
    Write-Host "   2. Check your permissions on the Static Web App resource" -ForegroundColor White
    Write-Host "   3. Ensure the build output exists at: $buildPath" -ForegroundColor White
    Write-Host "   4. Check Azure CLI authentication: az account show" -ForegroundColor White
    Write-Host "   5. Verify Node.js is installed for SWA CLI" -ForegroundColor White
    Write-Host "   6. Try deploying via Azure Portal as an alternative" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Alternative deployment options:" -ForegroundColor Yellow
    Write-Host "   • Use GitHub Actions for CI/CD deployment" -ForegroundColor White
    Write-Host "   • Deploy via Visual Studio Code Azure Static Web Apps extension" -ForegroundColor White
    Write-Host "   • Use Azure Portal manual upload" -ForegroundColor White
    Write-Host ""
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
