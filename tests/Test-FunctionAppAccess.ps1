#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test Azure Function App resource access and RBAC permissions

.DESCRIPTION
This script verifies that the Function App has proper access to required Azure resources
including Storage Account and AI Foundry resources. It validates managed identity configuration,
RBAC role assignments, and Function App settings to ensure proper deployment configuration.

.PARAMETER ResourceGroupName
The name of the resource group containing the Function App. Required.

.PARAMETER FunctionAppName  
The name of the Azure Function App to test. Required.

.PARAMETER StorageAccountName
The name of the Storage Account that the Function App should have access to. Required.

.PARAMETER AIFoundryResourceId
The full resource ID of the AI Foundry resource (optional). If provided, tests AI Foundry access permissions.

.EXAMPLE
./Test-FunctionAppAccess.ps1 -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2" -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -StorageAccountName "staifoundryspabackdeveus2"

.EXAMPLE
./Test-FunctionAppAccess.ps1 -ResourceGroupName "my-rg" -FunctionAppName "my-func-app" -StorageAccountName "mystorageaccount" -AIFoundryResourceId "/subscriptions/12345/resourceGroups/ai-rg/providers/Microsoft.CognitiveServices/accounts/my-ai-foundry"

.EXAMPLE
& "/home/runner/work/ai-in-a-box/ai-in-a-box/tests/Test-FunctionAppAccess.ps1" -ResourceGroupName "rg-backend" -FunctionAppName "func-app-eus2" -StorageAccountName "storageeus2"

.EXAMPLE
./Test-FunctionAppAccess.ps1 -ResourceGroupName "rg-prod" -FunctionAppName "func-prod-app" -StorageAccountName "prodstorageacct" -AIFoundryResourceId "/subscriptions/abcd/resourceGroups/ai-prod/providers/Microsoft.CognitiveServices/accounts/ai-prod-foundry"

.NOTES
Prerequisites:
- Azure CLI installed and authenticated (az login)
- PowerShell 7+ or Windows PowerShell 5.1
- Sufficient Azure permissions to read resource information and role assignments
- Function App must exist and have system-assigned managed identity enabled

Expected Output:
- Managed identity validation results
- Storage Account access permissions analysis
- AI Foundry access permissions (if resource ID provided)
- Function App configuration validation
- Function App status and runtime information
- Recommendations for fixing any permission issues

The script checks for optimal role assignments (least privilege) and warns about over-privileged assignments.
#>

# Azure Function App Resource Access Test
# This script verifies that the Function App has proper access to required resources

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter()]
    [string]$AIFoundryResourceId
)

Write-Host "🔍 Testing Azure Function App Resource Access" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

# Test 1: Check if Function App exists and has system-assigned managed identity
Write-Host "`n1️⃣ Testing Function App Managed Identity..." -ForegroundColor Cyan

try {
    $functionApp = az functionapp identity show --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    
    if ($functionApp.type -eq "SystemAssigned") {
        Write-Host "✅ System-assigned managed identity is enabled" -ForegroundColor Green
        Write-Host "   Principal ID: $($functionApp.principalId)" -ForegroundColor Gray
        $principalId = $functionApp.principalId
    } else {
        Write-Host "❌ System-assigned managed identity is NOT enabled" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Failed to get Function App identity: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check Storage Account access
Write-Host "`n2️⃣ Testing Storage Account Access..." -ForegroundColor Cyan

try {
    # Get storage account resource ID
    $storageResourceId = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query id -o tsv
    
    # Check direct role assignments on storage account
    $directRoleAssignments = az role assignment list --assignee $principalId --scope $storageResourceId 2>$null | ConvertFrom-Json
    
    # Check inherited role assignments from parent scopes (RG, subscription)
    $rgScope = "/subscriptions/$((az account show --query id -o tsv))/resourceGroups/$ResourceGroupName"
    $subscriptionScope = "/subscriptions/$((az account show --query id -o tsv))"
    
    $rgRoleAssignments = az role assignment list --assignee $principalId --scope $rgScope 2>$null | ConvertFrom-Json
    $subscriptionRoleAssignments = az role assignment list --assignee $principalId --scope $subscriptionScope 2>$null | ConvertFrom-Json
    
    # Combine all role assignments
    $allRoleAssignments = @()
    $allRoleAssignments += $directRoleAssignments
    $allRoleAssignments += $rgRoleAssignments
    $allRoleAssignments += $subscriptionRoleAssignments
    
    # Check for specific storage roles (in order of preference)
    $storageBlobDataOwner = $allRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Storage Blob Data Owner" }
    $storageBlobDataContributor = $allRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Storage Blob Data Contributor" }
    $storageAccountContributor = $allRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Storage Account Contributor" }
    $contributor = $allRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Contributor" }
    $owner = $allRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Owner" }
    
    $hasStorageAccess = $false
    $accessType = ""
    $accessScope = ""
    
    if ($storageBlobDataOwner) {
        $hasStorageAccess = $true
        $accessType = "Storage Blob Data Owner (✅ Optimal)"
        $accessScope = $storageBlobDataOwner.scope
    } elseif ($storageBlobDataContributor) {
        $hasStorageAccess = $true
        $accessType = "Storage Blob Data Contributor (✅ Good)"
        $accessScope = $storageBlobDataContributor.scope
    } elseif ($storageAccountContributor) {
        $hasStorageAccess = $true
        $accessType = "Storage Account Contributor (⚠️ Over-privileged)"
        $accessScope = $storageAccountContributor.scope
    } elseif ($contributor) {
        $hasStorageAccess = $true
        $accessType = "Contributor (⚠️ Over-privileged)"
        $accessScope = $contributor.scope
    } elseif ($owner) {
        $hasStorageAccess = $true
        $accessType = "Owner (⚠️ Over-privileged)"
        $accessScope = $owner.scope
    }
    
    if ($hasStorageAccess) {
        Write-Host "✅ Storage access available via: $accessType" -ForegroundColor Green
        Write-Host "   Scope: $accessScope" -ForegroundColor Gray
        
        # Determine if it's inherited
        if ($accessScope -eq $storageResourceId) {
            Write-Host "   📍 Direct assignment to storage account" -ForegroundColor Gray
        } elseif ($accessScope -eq $rgScope) {
            Write-Host "   📍 Inherited from resource group" -ForegroundColor Gray
        } elseif ($accessScope -eq $subscriptionScope) {
            Write-Host "   📍 Inherited from subscription" -ForegroundColor Gray
        } else {
            Write-Host "   📍 Inherited from parent scope: $accessScope" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ No storage access roles found" -ForegroundColor Red
        Write-Host "   Checked scopes:" -ForegroundColor Yellow
        Write-Host "   - Storage Account: $storageResourceId" -ForegroundColor Gray
        Write-Host "   - Resource Group: $rgScope" -ForegroundColor Gray
        Write-Host "   - Subscription: $subscriptionScope" -ForegroundColor Gray
        
        if ($allRoleAssignments.Count -gt 0) {
            Write-Host "   Available roles (all scopes):" -ForegroundColor Yellow
            $allRoleAssignments | Sort-Object scope, roleDefinitionName | ForEach-Object { 
                $scopeType = if ($_.scope -eq $storageResourceId) { "Storage" } 
                            elseif ($_.scope -eq $rgScope) { "RG" }
                            elseif ($_.scope -eq $subscriptionScope) { "Sub" }
                            else { "Other" }
                Write-Host "   - $($_.roleDefinitionName) [$scopeType]" -ForegroundColor Gray 
            }
        }
    }
} catch {
    Write-Host "❌ Failed to check storage account access: $_" -ForegroundColor Red
}

# Test 3: Check AI Foundry access (if provided)
if ($AIFoundryResourceId) {
    Write-Host "`n3️⃣ Testing AI Foundry Access..." -ForegroundColor Cyan
    
    try {
        # Check direct role assignments on AI Foundry resource
        $directAIRoleAssignments = az role assignment list --assignee $principalId --scope $AIFoundryResourceId 2>$null | ConvertFrom-Json
        
        # Check inherited role assignments from parent scopes
        $aiFoundryRG = ($AIFoundryResourceId -split '/')[4]  # Extract RG name from resource ID
        $aiFoundryRGScope = "/subscriptions/$((az account show --query id -o tsv))/resourceGroups/$aiFoundryRG"
        $subscriptionScope = "/subscriptions/$((az account show --query id -o tsv))"
        
        $aiRGRoleAssignments = az role assignment list --assignee $principalId --scope $aiFoundryRGScope 2>$null | ConvertFrom-Json
        $aiSubscriptionRoleAssignments = az role assignment list --assignee $principalId --scope $subscriptionScope 2>$null | ConvertFrom-Json
        
        # Combine all AI-related role assignments
        $allAIRoleAssignments = @()
        $allAIRoleAssignments += $directAIRoleAssignments
        $allAIRoleAssignments += $aiRGRoleAssignments
        $allAIRoleAssignments += $aiSubscriptionRoleAssignments
        
        # Check for AI-related roles (in order of preference)
        $azureAIDeveloper = $allAIRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Azure AI Developer" }
        $azureAIAdministrator = $allAIRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Azure AI Administrator" }
        $cognitiveServicesContributor = $allAIRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Cognitive Services Contributor" }
        $contributor = $allAIRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Contributor" }
        $owner = $allAIRoleAssignments | Where-Object { $_.roleDefinitionName -eq "Owner" }
        
        $hasAIAccess = $false
        $aiAccessType = ""
        $aiAccessScope = ""
        
        if ($azureAIDeveloper) {
            $hasAIAccess = $true
            $aiAccessType = "Azure AI Developer (✅ Optimal)"
            $aiAccessScope = $azureAIDeveloper.scope
        } elseif ($azureAIAdministrator) {
            $hasAIAccess = $true
            $aiAccessType = "Azure AI Administrator (✅ Good but elevated)"
            $aiAccessScope = $azureAIAdministrator.scope
        } elseif ($cognitiveServicesContributor) {
            $hasAIAccess = $true
            $aiAccessType = "Cognitive Services Contributor (✅ Legacy but works)"
            $aiAccessScope = $cognitiveServicesContributor.scope
        } elseif ($contributor) {
            $hasAIAccess = $true
            $aiAccessType = "Contributor (⚠️ Over-privileged)"
            $aiAccessScope = $contributor.scope
        } elseif ($owner) {
            $hasAIAccess = $true
            $aiAccessType = "Owner (⚠️ Over-privileged)"
            $aiAccessScope = $owner.scope
        }
        
        if ($hasAIAccess) {
            Write-Host "✅ AI Foundry access available via: $aiAccessType" -ForegroundColor Green
            Write-Host "   Scope: $aiAccessScope" -ForegroundColor Gray
            
            # Determine if it's inherited
            if ($aiAccessScope -eq $AIFoundryResourceId) {
                Write-Host "   📍 Direct assignment to AI Foundry resource" -ForegroundColor Gray
            } elseif ($aiAccessScope -eq $aiFoundryRGScope) {
                Write-Host "   📍 Inherited from AI Foundry resource group" -ForegroundColor Gray
            } elseif ($aiAccessScope -eq $subscriptionScope) {
                Write-Host "   📍 Inherited from subscription" -ForegroundColor Gray
            } else {
                Write-Host "   📍 Inherited from parent scope: $aiAccessScope" -ForegroundColor Gray
            }
        } else {
            Write-Host "❌ No AI Foundry access roles found" -ForegroundColor Red
            Write-Host "   Checked scopes:" -ForegroundColor Yellow
            Write-Host "   - AI Foundry Resource: $AIFoundryResourceId" -ForegroundColor Gray
            Write-Host "   - AI Foundry RG: $aiFoundryRGScope" -ForegroundColor Gray
            Write-Host "   - Subscription: $subscriptionScope" -ForegroundColor Gray
            
            if ($allAIRoleAssignments.Count -gt 0) {
                Write-Host "   Available roles (all scopes):" -ForegroundColor Yellow
                $allAIRoleAssignments | Sort-Object scope, roleDefinitionName | ForEach-Object { 
                    $scopeType = if ($_.scope -eq $AIFoundryResourceId) { "AI" } 
                                elseif ($_.scope -eq $aiFoundryRGScope) { "RG" }
                                elseif ($_.scope -eq $subscriptionScope) { "Sub" }
                                else { "Other" }
                    Write-Host "   - $($_.roleDefinitionName) [$scopeType]" -ForegroundColor Gray 
                }
            }
        }
    } catch {
        Write-Host "❌ Failed to check AI Foundry access: $_" -ForegroundColor Red
    }
} else {
    Write-Host "`n3️⃣ Skipping AI Foundry Access Test (no resource ID provided)" -ForegroundColor Yellow
}

# Test 4: Check Function App settings
Write-Host "`n4️⃣ Testing Function App Configuration..." -ForegroundColor Cyan

try {
    $appSettings = az functionapp config appsettings list --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    
    # Check for storage configuration
    $hasStorageAccountName = $appSettings | Where-Object { $_.name -eq "AzureWebJobsStorage__accountName" }
    $hasOldStorageConnectionString = $appSettings | Where-Object { $_.name -eq "AzureWebJobsStorage" }
    
    if ($hasStorageAccountName) {
        Write-Host "❌ Found AzureWebJobsStorage__accountName setting (conflicts with AVM managed identity)" -ForegroundColor Red
        Write-Host "   Value: $($hasStorageAccountName.value)" -ForegroundColor Gray
        Write-Host "   💡 Remove this setting to use AVM managed identity configuration" -ForegroundColor Yellow
    } elseif ($hasOldStorageConnectionString) {
        Write-Host "❌ Found old AzureWebJobsStorage connection string" -ForegroundColor Red
        Write-Host "   💡 Remove this setting to use managed identity" -ForegroundColor Yellow
    } else {
        Write-Host "✅ No conflicting storage settings found (using AVM managed identity)" -ForegroundColor Green
    }
    
    # Check for required settings
    $requiredSettings = @("APPLICATIONINSIGHTS_CONNECTION_STRING", "AI_FOUNDRY_PROJECT_URL", "AI_FOUNDRY_AGENT_ID")
    foreach ($setting in $requiredSettings) {
        $found = $appSettings | Where-Object { $_.name -eq $setting }
        if ($found) {
            Write-Host "✅ $setting is configured" -ForegroundColor Green
        } else {
            Write-Host "❌ $setting is missing" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ Failed to check Function App settings: $_" -ForegroundColor Red
}

# Test 5: Check Function App status
Write-Host "`n5️⃣ Testing Function App Status..." -ForegroundColor Cyan

try {
    $functionAppInfo = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    
    Write-Host "✅ Function App State: $($functionAppInfo.state)" -ForegroundColor Green
    Write-Host "✅ Runtime Version: $($functionAppInfo.siteConfig.netFrameworkVersion)" -ForegroundColor Green
    Write-Host "✅ HTTPS Only: $($functionAppInfo.httpsOnly)" -ForegroundColor Green
    
    if ($functionAppInfo.state -ne "Running") {
        Write-Host "⚠️ Function App is not in Running state" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Failed to get Function App status: $_" -ForegroundColor Red
}

Write-Host "`n🏁 Resource Access Test Completed" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

Write-Host "`n💡 If you're still seeing MSI token errors:" -ForegroundColor Cyan
Write-Host "   1. Wait 5-10 minutes for RBAC propagation" -ForegroundColor White
Write-Host "   2. Restart the Function App: az functionapp restart --name $FunctionAppName --resource-group $ResourceGroupName" -ForegroundColor White
Write-Host "   3. Ensure no conflicting storage settings are present" -ForegroundColor White
Write-Host "   4. Check that the storage account allows the Function App's managed identity" -ForegroundColor White
