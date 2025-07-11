#!/usr/bin/env pwsh

<#
.SYNOPSIS
    RBAC Assignment Validation Script for AI in A Box

.DESCRIPTION
    This script validates that all required RBAC assignments are correctly configured
    for the AI in A Box Function App managed identity to access Azure AI Foundry and
    storage resources.

.PARAMETER FunctionAppName
    Name of the Function App to validate RBAC for

.PARAMETER FunctionAppResourceGroup
    Resource group containing the Function App

.PARAMETER AiFoundryResourceGroup
    Resource group containing the AI Foundry Cognitive Services account

.PARAMETER AiFoundryResourceName
    Name of the AI Foundry Cognitive Services account

.PARAMETER Detailed
    Show detailed validation results and role assignment information

.EXAMPLE
    ./Test-RbacAssignments.ps1 -FunctionAppName "func-myapp-backend-dev-eus2" -FunctionAppResourceGroup "rg-myapp-backend-dev-eus2" -AiFoundryResourceGroup "rg-myapp-aifoundry-dev-eus2" -AiFoundryResourceName "cs-myapp-aifoundry-dev-eus2"

.EXAMPLE
    ./Test-RbacAssignments.ps1 -FunctionAppName "func-myapp-backend-dev-eus2" -FunctionAppResourceGroup "rg-myapp-backend-dev-eus2" -AiFoundryResourceGroup "rg-existing-ai-foundry" -AiFoundryResourceName "existing-cs-account" -Detailed

.NOTES
    Requirements:
    - Azure CLI installed and authenticated
    - PowerShell 7.0 or later
    - Appropriate permissions to read role assignments
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Function App name")]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $true, HelpMessage = "Function App resource group")]
    [string]$FunctionAppResourceGroup,

    [Parameter(Mandatory = $true, HelpMessage = "AI Foundry resource group")]
    [string]$AiFoundryResourceGroup,

    [Parameter(Mandatory = $true, HelpMessage = "AI Foundry Cognitive Services account name")]
    [string]$AiFoundryResourceName,

    [Parameter(HelpMessage = "Show detailed validation results")]
    [switch]$Detailed
)

# Required role assignments
$requiredRoles = @(
    @{
        RoleName = "Storage Blob Data Contributor"
        RoleId = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
        Scope = "ResourceGroup"
        ScopeResourceGroup = $FunctionAppResourceGroup
        Purpose = "Function App storage access for Flex Consumption model"
        Required = $true
    },
    @{
        RoleName = "Azure AI User"
        RoleId = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
        Scope = "ResourceGroup"
        ScopeResourceGroup = $AiFoundryResourceGroup
        Purpose = "AI project access for reading and calling AI Foundry agents"
        Required = $true
    },
    @{
        RoleName = "Cognitive Services OpenAI User"
        RoleId = "a97b65f3-24c7-4388-baec-2e87135dc908"
        Scope = "ResourceGroup"
        ScopeResourceGroup = $AiFoundryResourceGroup
        Purpose = "OpenAI API access for creating threads, sending messages, and reading responses"
        Required = $true
    }
)

function Test-RbacValidation {
    Write-Host "🔐 AI in A Box - RBAC Assignment Validation" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Function App: $FunctionAppName" -ForegroundColor White
    Write-Host "Function App RG: $FunctionAppResourceGroup" -ForegroundColor White
    Write-Host "AI Foundry RG: $AiFoundryResourceGroup" -ForegroundColor White
    Write-Host "AI Foundry Resource: $AiFoundryResourceName" -ForegroundColor White
    Write-Host ""

    # Validate Azure CLI
    try {
        $azAccount = az account show 2>$null | ConvertFrom-Json
        if (-not $azAccount) {
            Write-Error "❌ Not logged in to Azure CLI. Please run 'az login'"
            return $false
        }
        Write-Host "✅ Azure CLI authenticated as $($azAccount.user.name)" -ForegroundColor Green
        $subscriptionId = $azAccount.id
    }
    catch {
        Write-Error "❌ Azure CLI not available or not authenticated"
        return $false
    }

    # Get Function App managed identity
    Write-Host "🔍 Getting Function App managed identity..." -ForegroundColor Yellow
    
    try {
        $functionApp = az functionapp show --name $FunctionAppName --resource-group $FunctionAppResourceGroup 2>$null | ConvertFrom-Json
        
        if (-not $functionApp) {
            Write-Error "❌ Function App '$FunctionAppName' not found in resource group '$FunctionAppResourceGroup'"
            return $false
        }

        if (-not $functionApp.identity -or $functionApp.identity.type -ne "SystemAssigned") {
            Write-Error "❌ Function App does not have system-assigned managed identity enabled"
            return $false
        }

        $principalId = $functionApp.identity.principalId
        Write-Host "✅ Function App managed identity found: $principalId" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Failed to get Function App information: $_"
        return $false
    }

    # Validate AI Foundry resource exists
    Write-Host "🤖 Validating AI Foundry resource..." -ForegroundColor Yellow
    
    try {
        $aiFoundryResource = az cognitiveservices account show --name $AiFoundryResourceName --resource-group $AiFoundryResourceGroup 2>$null | ConvertFrom-Json
        
        if (-not $aiFoundryResource) {
            Write-Error "❌ AI Foundry resource '$AiFoundryResourceName' not found in resource group '$AiFoundryResourceGroup'"
            return $false
        }

        Write-Host "✅ AI Foundry resource found: $($aiFoundryResource.name) (Kind: $($aiFoundryResource.kind))" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Failed to get AI Foundry resource information: $_"
        return $false
    }

    # Check each required role assignment
    Write-Host ""
    Write-Host "🔍 Validating RBAC assignments..." -ForegroundColor Yellow
    
    $allPassed = $true
    $roleResults = @()

    foreach ($role in $requiredRoles) {
        Write-Host ""
        Write-Host "Checking role: $($role.RoleName)" -ForegroundColor Cyan
        
        # Build scope based on type
        $scope = switch ($role.Scope) {
            "ResourceGroup" { 
                "/subscriptions/$subscriptionId/resourceGroups/$($role.ScopeResourceGroup)"
            }
            "Resource" {
                if ($role.ScopeResourceGroup -eq $AiFoundryResourceGroup) {
                    $aiFoundryResource.id
                } else {
                    "/subscriptions/$subscriptionId/resourceGroups/$($role.ScopeResourceGroup)"
                }
            }
            default { 
                "/subscriptions/$subscriptionId/resourceGroups/$($role.ScopeResourceGroup)"
            }
        }

        # Check if role assignment exists
        try {
            $assignments = az role assignment list --assignee $principalId --role $role.RoleName --scope $scope 2>$null | ConvertFrom-Json
            
            $roleAssigned = $assignments.Count -gt 0
            
            $result = [PSCustomObject]@{
                RoleName = $role.RoleName
                Scope = $scope
                ScopeType = $role.Scope
                Purpose = $role.Purpose
                Assigned = $roleAssigned
                AssignmentCount = $assignments.Count
                Assignments = $assignments
            }
            
            $roleResults += $result
            
            if ($roleAssigned) {
                Write-Host "  ✅ Assigned ($($assignments.Count) assignment(s))" -ForegroundColor Green
                if ($Detailed -and $assignments.Count -gt 0) {
                    $assignments | ForEach-Object {
                        Write-Host "    Assignment ID: $($_.name)" -ForegroundColor Gray
                        Write-Host "    Created: $($_.createdOn)" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "  ❌ NOT assigned" -ForegroundColor Red
                $allPassed = $false
            }
            
            if ($Detailed) {
                Write-Host "    Scope: $scope" -ForegroundColor Gray
                Write-Host "    Purpose: $($role.Purpose)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  ❌ Error checking assignment: $_" -ForegroundColor Red
            $allPassed = $false
        }
    }

    # Additional validation: Check for unexpected role assignments
    Write-Host ""
    Write-Host "🔍 Checking for all role assignments..." -ForegroundColor Yellow
    
    try {
        $allAssignments = az role assignment list --assignee $principalId 2>$null | ConvertFrom-Json
        
        if ($Detailed) {
            Write-Host ""
            Write-Host "📋 All role assignments for managed identity:" -ForegroundColor Cyan
            $allAssignments | ForEach-Object {
                $roleDefinition = az role definition show --name $_.roleDefinitionId 2>$null | ConvertFrom-Json
                Write-Host "  Role: $($roleDefinition.roleName)" -ForegroundColor White
                Write-Host "  Scope: $($_.scope)" -ForegroundColor Gray
                Write-Host "  Type: $($_.principalType)" -ForegroundColor Gray
                Write-Host ""
            }
        }

        # Check for overly broad permissions
        $broadRoles = $allAssignments | Where-Object { 
            $roleDefinition = az role definition show --name $_.roleDefinitionId 2>$null | ConvertFrom-Json
            $roleDefinition.roleName -in @("Owner", "Contributor", "User Access Administrator")
        }

        if ($broadRoles.Count -gt 0) {
            Write-Host "⚠️  Warning: Found potentially overly broad role assignments:" -ForegroundColor Yellow
            $broadRoles | ForEach-Object {
                $roleDefinition = az role definition show --name $_.roleDefinitionId 2>$null | ConvertFrom-Json
                Write-Host "  $($roleDefinition.roleName) on $($_.scope)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "⚠️  Could not retrieve all role assignments: $_" -ForegroundColor Yellow
    }

    # Test actual access
    Write-Host ""
    Write-Host "🧪 Testing actual access (optional)..." -ForegroundColor Yellow
    Write-Host "Note: Actual access testing requires running from within the Function App environment" -ForegroundColor Gray

    # Summary
    Write-Host ""
    Write-Host "📊 RBAC Validation Summary" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    $passedRoles = $roleResults | Where-Object { $_.Assigned }
    $failedRoles = $roleResults | Where-Object { -not $_.Assigned }
    
    Write-Host "Required roles: $($requiredRoles.Count)" -ForegroundColor White
    Write-Host "Assigned: $($passedRoles.Count)" -ForegroundColor Green
    Write-Host "Missing: $($failedRoles.Count)" -ForegroundColor Red
    
    if ($failedRoles.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ Missing role assignments:" -ForegroundColor Red
        $failedRoles | ForEach-Object {
            Write-Host "  $($_.RoleName) on $($_.ScopeType): $($_.Scope)" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "🔧 To fix missing assignments, ensure your Bicep templates include:" -ForegroundColor Yellow
        $failedRoles | ForEach-Object {
            Write-Host "  - Role '$($_.RoleName)' (ID: $($requiredRoles | Where-Object { $_.RoleName -eq $_.RoleName } | Select-Object -ExpandProperty RoleId))" -ForegroundColor Gray
            Write-Host "    Purpose: $($_.Purpose)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host ""
        Write-Host "🎉 All required RBAC assignments are configured correctly!" -ForegroundColor Green
    }

    # Troubleshooting tips
    if (-not $allPassed) {
        Write-Host ""
        Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "1. Ensure the deployment completed successfully" -ForegroundColor Gray
        Write-Host "2. RBAC assignments can take 5-10 minutes to propagate" -ForegroundColor Gray
        Write-Host "3. Check that the Bicep templates include all required role assignments" -ForegroundColor Gray
        Write-Host "4. Verify the deploying principal has 'User Access Administrator' role" -ForegroundColor Gray
        Write-Host "5. Re-run the deployment if assignments are missing" -ForegroundColor Gray
    }

    return $allPassed
}

# Execute validation
$validationPassed = Test-RbacValidation

# Exit with appropriate code
exit $(if ($validationPassed) { 0 } else { 1 })