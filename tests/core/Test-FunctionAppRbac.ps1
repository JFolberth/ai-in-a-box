#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Diagnose RBAC assignments for AI Foundry Function App access

.DESCRIPTION
    This script checks the current RBAC assignments for the Function App
    and verifies if it has the correct permissions to access AI Foundry agents.

.PARAMETER FunctionAppName
    Name of the Function App to check

.PARAMETER ResourceGroupName
    Resource group containing the Function App

.PARAMETER AiFoundryResourceName
    Name of the AI Foundry Cognitive Services resource

.PARAMETER AiFoundryResourceGroup
    Resource group containing the AI Foundry resource

.EXAMPLE
    .\Test-FunctionAppRbac.ps1 -FunctionAppName "func-foundrytst-bk-dev-eus2" -ResourceGroupName "rg-foundrytst-backend-dev-eus2" -AiFoundryResourceName "cs-foundrytst-dev-eus2" -AiFoundryResourceGroup "rg-foundrytst-aifoundry-dev-eus2"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AiFoundryResourceName,
    
    [Parameter(Mandatory = $true)]
    [string]$AiFoundryResourceGroup
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $colorMap = @{
        "Red" = "Red"; "Green" = "Green"; "Yellow" = "Yellow"
        "Cyan" = "Cyan"; "Magenta" = "Magenta"; "Blue" = "Blue"
        "White" = "White"
    }
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

Write-ColorOutput "🔐 Function App RBAC Diagnostic Tool" "Magenta"
Write-ColorOutput "===================================" "Magenta"

# Check Azure CLI access
Write-ColorOutput "`n🔍 Checking Azure CLI access..." "Cyan"
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Not logged into Azure CLI. Please run 'az login'" "Red"
    exit 1
}

$accountInfo = $account | ConvertFrom-Json
Write-ColorOutput "✅ Logged in as: $($accountInfo.user.name)" "Green"
Write-ColorOutput "   Subscription: $($accountInfo.name)" "Cyan"

# Get Function App managed identity
Write-ColorOutput "`n👤 Getting Function App managed identity..." "Cyan"
$functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json

if (-not $functionApp) {
    Write-ColorOutput "❌ Function App '$FunctionAppName' not found in resource group '$ResourceGroupName'" "Red"
    exit 1
}

$principalId = $functionApp.identity.principalId
Write-ColorOutput "✅ Function App found" "Green"
Write-ColorOutput "   Name: $($functionApp.name)" "Cyan"
Write-ColorOutput "   Principal ID: $principalId" "Cyan"
Write-ColorOutput "   Identity Type: $($functionApp.identity.type)" "Cyan"

# Get AI Foundry resource details
Write-ColorOutput "`n🤖 Getting AI Foundry resource details..." "Cyan"
$aiFoundryResource = az cognitiveservices account show --name $AiFoundryResourceName --resource-group $AiFoundryResourceGroup 2>$null | ConvertFrom-Json

if (-not $aiFoundryResource) {
    Write-ColorOutput "❌ AI Foundry resource '$AiFoundryResourceName' not found in resource group '$AiFoundryResourceGroup'" "Red"
    exit 1
}

Write-ColorOutput "✅ AI Foundry resource found" "Green"
Write-ColorOutput "   Name: $($aiFoundryResource.name)" "Cyan"
Write-ColorOutput "   Resource ID: $($aiFoundryResource.id)" "Cyan"
Write-ColorOutput "   Kind: $($aiFoundryResource.kind)" "Cyan"

# Check RBAC assignments on the AI Foundry resource
Write-ColorOutput "`n🔑 Checking RBAC assignments for Function App on AI Foundry resource..." "Yellow"

$roleAssignments = az role assignment list --assignee $principalId --scope $aiFoundryResource.id 2>$null | ConvertFrom-Json

if ($roleAssignments.Count -eq 0) {
    Write-ColorOutput "❌ No role assignments found for Function App on AI Foundry resource" "Red"
} else {
    Write-ColorOutput "✅ Found $($roleAssignments.Count) role assignment(s):" "Green"
    foreach ($assignment in $roleAssignments) {
        $roleDef = az role definition show --id $assignment.roleDefinitionId 2>$null | ConvertFrom-Json
        Write-ColorOutput "   - Role: $($roleDef.roleName) ($($assignment.roleDefinitionId))" "Cyan"
        Write-ColorOutput "     Scope: $($assignment.scope)" "Cyan"
        Write-ColorOutput "     Principal: $($assignment.principalId)" "Cyan"
    }
}

# Check for specific required roles
Write-ColorOutput "`n🎯 Checking for required AI Foundry roles..." "Yellow"

$requiredRoles = @(
    @{ Name = "Azure AI User"; Id = "53ca6127-db72-4b80-b1b0-d745d6d5456d"; Description = "Required for reading and calling AI Foundry agents" },
    @{ Name = "Cognitive Services OpenAI User"; Id = "a97b65f3-24c7-4388-baec-2e87135dc908"; Description = "Required for chat completion service" }
)

foreach ($role in $requiredRoles) {
    $hasRole = $roleAssignments | Where-Object { $_.roleDefinitionId -eq $role.Id }
    if ($hasRole) {
        Write-ColorOutput "   ✅ $($role.Name): ASSIGNED" "Green"
    } else {
        Write-ColorOutput "   ❌ $($role.Name): MISSING" "Red"
        Write-ColorOutput "      $($role.Description)" "Yellow"
    }
}

# Check RBAC assignments at resource group level
Write-ColorOutput "`n📋 Checking RBAC assignments at resource group level..." "Yellow"
$rgAssignments = az role assignment list --assignee $principalId --resource-group $AiFoundryResourceGroup 2>$null | ConvertFrom-Json

if ($rgAssignments.Count -gt 0) {
    Write-ColorOutput "Found $($rgAssignments.Count) resource group level assignment(s):" "Cyan"
    foreach ($assignment in $rgAssignments) {
        $roleDef = az role definition show --id $assignment.roleDefinitionId 2>$null | ConvertFrom-Json
        Write-ColorOutput "   - Role: $($roleDef.roleName)" "Cyan"
    }
} else {
    Write-ColorOutput "No resource group level assignments found" "Cyan"
}

# Test AI Foundry API access
Write-ColorOutput "`n🧪 Testing AI Foundry API access..." "Yellow"
Write-ColorOutput "   Function App Principal ID from error: a8e0aac3-0bdc-4377-bfd9-ce391bc8c2a5" "Cyan"
Write-ColorOutput "   Current Function App Principal ID: $principalId" "Cyan"

if ($principalId -eq "a8e0aac3-0bdc-4377-bfd9-ce391bc8c2a5") {
    Write-ColorOutput "   ✅ Principal IDs match - this is the correct Function App" "Green"
} else {
    Write-ColorOutput "   ⚠️ Principal IDs don't match - might be checking wrong Function App" "Yellow"
}

Write-ColorOutput "`n💡 Recommendations:" "Yellow"
if ($roleAssignments.Count -eq 0) {
    Write-ColorOutput "1. Run the backend deployment script to assign required RBAC roles" "White"
    Write-ColorOutput "2. Wait up to 30 minutes for RBAC propagation" "White"
}

$missingRoles = $requiredRoles | Where-Object { -not ($roleAssignments | Where-Object { $_.roleDefinitionId -eq $_.Id }) }
if ($missingRoles.Count -gt 0) {
    Write-ColorOutput "Missing roles need to be assigned:" "White"
    foreach ($role in $missingRoles) {
        Write-ColorOutput "   - $($role.Name) ($($role.Id))" "White"
    }
}

Write-ColorOutput "`n✅ Diagnostic complete!" "Green"
