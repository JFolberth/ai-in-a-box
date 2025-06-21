#!/usr/bin/env pwsh
# Deploy Backend Function App to Azure
# This script deploys the infrastructure and then deploys the Function App code

param(
    [string]$SubscriptionId = "",
    [string]$ResourceToken = "001",
    [string]$Location = "eastus2",
    [switch]$InfrastructureOnly,
    [switch]$CodeOnly,
    [switch]$WhatIf
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Backend Function App Deployment" -ForegroundColor Green

# Get current directory paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptPath
$infraPath = Join-Path $workspaceRoot "infra"
$backendPath = Join-Path $workspaceRoot "src\backend"

Write-Host "📁 Workspace Root: $workspaceRoot" -ForegroundColor Gray
Write-Host "📁 Infrastructure Path: $infraPath" -ForegroundColor Gray
Write-Host "📁 Backend Code Path: $backendPath" -ForegroundColor Gray

# Check if we're already logged in to Azure
try {
    $account = az account show --query "user.name" -o tsv 2>$null
    if ($account) {
        Write-Host "✅ Already logged in to Azure as: $account" -ForegroundColor Green
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "🔑 Please log in to Azure..." -ForegroundColor Yellow
    az login
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "🎯 Setting subscription: $SubscriptionId" -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
}

# Get current subscription info
$subscription = az account show --query "{id:id, name:name}" -o json | ConvertFrom-Json
Write-Host "📊 Current Subscription: $($subscription.name) ($($subscription.id))" -ForegroundColor Cyan

# Define deployment parameters
$deploymentName = "ai-foundry-spa-backend-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templateFile = Join-Path $infraPath "main-orchestrator.bicep"
$parametersFile = Join-Path $infraPath "dev-orchestrator.parameters.bicepparam"

# Validate files exist
if (!(Test-Path $templateFile)) {
    throw "❌ Template file not found: $templateFile"
}
if (!(Test-Path $parametersFile)) {
    throw "❌ Parameters file not found: $parametersFile"
}

Write-Host "📋 Deployment Configuration:" -ForegroundColor Cyan
Write-Host "   Template: $templateFile" -ForegroundColor Gray
Write-Host "   Parameters: $parametersFile" -ForegroundColor Gray
Write-Host "   Deployment Name: $deploymentName" -ForegroundColor Gray

if (!$CodeOnly) {
    Write-Host "`n🏗️ Deploying Infrastructure..." -ForegroundColor Yellow
    
    if ($WhatIf) {
        Write-Host "🔍 Running What-If analysis..." -ForegroundColor Yellow
        az deployment sub what-if `
            --name $deploymentName `
            --location $Location `
            --template-file $templateFile `
            --parameters $parametersFile
    } else {
        Write-Host "🚀 Deploying infrastructure to Azure..." -ForegroundColor Yellow
        $deployment = az deployment sub create `
            --name $deploymentName `
            --location $Location `
            --template-file $templateFile `
            --parameters $parametersFile `
            --query "properties.outputs" `
            -o json
        
        if ($LASTEXITCODE -ne 0) {
            throw "❌ Infrastructure deployment failed"
        }
        
        $outputs = $deployment | ConvertFrom-Json
        Write-Host "✅ Infrastructure deployment completed!" -ForegroundColor Green
        
        # Display key outputs
        Write-Host "`n📊 Deployment Outputs:" -ForegroundColor Cyan
        Write-Host "   Backend Function App Name: $($outputs.backendFunctionAppName.value)" -ForegroundColor Gray
        Write-Host "   Backend Function App URL: $($outputs.backendFunctionAppUrl.value)" -ForegroundColor Gray
        Write-Host "   Backend Resource Group: $($outputs.backendResourceGroupName.value)" -ForegroundColor Gray
        
        # Store outputs for code deployment
        $global:functionAppName = $outputs.backendFunctionAppName.value
        $global:resourceGroupName = $outputs.backendResourceGroupName.value
        $global:functionAppUrl = $outputs.backendFunctionAppUrl.value
    }
}

if (!$InfrastructureOnly -and !$WhatIf) {
    Write-Host "`n📦 Deploying Function App Code..." -ForegroundColor Yellow
    
    # If CodeOnly, we need to get the Function App info
    if ($CodeOnly) {
        Write-Host "🔍 Getting Function App information..." -ForegroundColor Gray
        $resourceGroupName = "rg-ai-foundry-spa-backend-dev-$ResourceToken"
        $functionAppName = "func-ai-foundry-spa-backend-dev-$ResourceToken"
        
        # Verify the Function App exists
        $functionApp = az functionapp show --name $functionAppName --resource-group $resourceGroupName --query "name" -o tsv 2>$null
        if (!$functionApp) {
            throw "❌ Function App not found: $functionAppName in resource group: $resourceGroupName"
        }
        
        Write-Host "✅ Found Function App: $functionAppName" -ForegroundColor Green
    } else {
        $functionAppName = $global:functionAppName
        $resourceGroupName = $global:resourceGroupName
    }
    
    # Build the Function App
    Write-Host "🔨 Building Function App..." -ForegroundColor Yellow
    Push-Location $backendPath
    try {
        dotnet clean
        dotnet build --configuration Release
        if ($LASTEXITCODE -ne 0) {
            throw "❌ Function App build failed"
        }
        Write-Host "✅ Function App build completed!" -ForegroundColor Green
        
        # Publish the Function App
        Write-Host "📤 Publishing Function App..." -ForegroundColor Yellow
        dotnet publish --configuration Release --output ./publish
        if ($LASTEXITCODE -ne 0) {
            throw "❌ Function App publish failed"
        }
        Write-Host "✅ Function App publish completed!" -ForegroundColor Green
        
        # Create deployment package
        Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
        $publishPath = Join-Path $backendPath "publish"
        $zipPath = Join-Path $backendPath "deploy.zip"
        
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        # Create zip package
        Compress-Archive -Path "$publishPath\*" -DestinationPath $zipPath -Force
        Write-Host "✅ Deployment package created: $zipPath" -ForegroundColor Green
        
        # Deploy to Azure Function App
        Write-Host "🚀 Deploying to Azure Function App..." -ForegroundColor Yellow
        az functionapp deployment source config-zip `
            --name $functionAppName `
            --resource-group $resourceGroupName `
            --src $zipPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "❌ Function App deployment failed"
        }
        
        Write-Host "✅ Function App code deployment completed!" -ForegroundColor Green
        
        # Wait for deployment to complete
        Write-Host "⏳ Waiting for Function App to restart..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        # Test the Function App
        Write-Host "🧪 Testing Function App endpoints..." -ForegroundColor Yellow
        $functionAppUrl = "https://$functionAppName.azurewebsites.net"
        
        try {
            $response = Invoke-RestMethod -Uri "$functionAppUrl/api/createThread" -Method Post -TimeoutSec 30
            Write-Host "✅ Function App is responding correctly!" -ForegroundColor Green
            Write-Host "   Test Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
        } catch {
            Write-Host "⚠️ Function App test failed, but deployment completed. It may take a few minutes to fully start." -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
        
    } finally {
        Pop-Location
    }
}

Write-Host "`n🎉 Deployment Process Completed!" -ForegroundColor Green

if (!$WhatIf -and !$InfrastructureOnly) {
    Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Function App URL: $functionAppUrl" -ForegroundColor Gray
    Write-Host "2. Test endpoints: $functionAppUrl/api/chat" -ForegroundColor Gray
    Write-Host "3. Update frontend .env file with the new backend URL" -ForegroundColor Gray
    Write-Host "4. Monitor logs: az functionapp logs tail --name $functionAppName --resource-group $resourceGroupName" -ForegroundColor Gray
}
