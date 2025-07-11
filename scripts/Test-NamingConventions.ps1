#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Resource Naming Convention Validation Script for AI in A Box

.DESCRIPTION
    This script validates that all deployed Azure resources follow the established
    naming conventions for the AI in A Box infrastructure. It checks resource
    names, patterns, and consistency across deployments.

.PARAMETER ApplicationName
    The application name used during deployment

.PARAMETER Environment
    The environment name (dev, staging, prod)

.PARAMETER Location
    The Azure region where resources were deployed

.PARAMETER CreateAiFoundryResourceGroup
    Whether AI Foundry resources were created (affects validation scope)

.PARAMETER CreateLogAnalyticsWorkspace
    Whether Log Analytics workspace was created (affects validation scope)

.PARAMETER ShowExpected
    Show expected resource names even if resources don't exist

.EXAMPLE
    ./Test-NamingConventions.ps1 -ApplicationName "conspiracy-bot" -Environment "dev" -Location "eastus2" -CreateAiFoundryResourceGroup $true -CreateLogAnalyticsWorkspace $true

.EXAMPLE
    ./Test-NamingConventions.ps1 -ApplicationName "myapp" -Environment "prod" -Location "westus3" -CreateAiFoundryResourceGroup $false -CreateLogAnalyticsWorkspace $false -ShowExpected

.NOTES
    Requirements:
    - Azure CLI installed and authenticated
    - PowerShell 7.0 or later
    - Read permissions on Azure resources
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Application name used during deployment")]
    [string]$ApplicationName,

    [Parameter(Mandatory = $true, HelpMessage = "Environment name (dev, staging, prod)")]
    [string]$Environment,

    [Parameter(Mandatory = $true, HelpMessage = "Azure region where resources were deployed")]
    [string]$Location,

    [Parameter(Mandatory = $true, HelpMessage = "Whether AI Foundry resources were created")]
    [bool]$CreateAiFoundryResourceGroup,

    [Parameter(Mandatory = $true, HelpMessage = "Whether Log Analytics workspace was created")]
    [bool]$CreateLogAnalyticsWorkspace,

    [Parameter(HelpMessage = "Show expected resource names even if resources don't exist")]
    [switch]$ShowExpected
)

# Region reference mapping (matches Bicep template)
$regionReference = @{
    'australiaeast' = 'ause'
    'brazilsouth' = 'brs'
    'canadacentral' = 'cac'
    'canadaeast' = 'cae'
    'eastus' = 'eus'
    'eastus2' = 'eus2'
    'francecentral' = 'frc'
    'germanywestcentral' = 'gwc'
    'italynorth' = 'itn'
    'japaneast' = 'jpe'
    'koreacentral' = 'krc'
    'northcentralus' = 'ncus'
    'norwayeast' = 'noe'
    'polandcentral' = 'poc'
    'southafricanorth' = 'san'
    'southcentralus' = 'scus'
    'southeastasia' = 'sea'
    'southindia' = 'ins'
    'spaincentral' = 'spc'
    'swedencentral' = 'swc'
    'switzerlandnorth' = 'swn'
    'switzerlandwest' = 'sww'
    'uaenorth' = 'uaen'
    'uksouth' = 'uks'
    'westeurope' = 'weu'
    'westus' = 'wus'
    'westus3' = 'wus3'
}

# Resource naming patterns
$namingPatterns = @{
    'ResourceGroup' = @{
        'Frontend' = 'rg-{applicationName}-frontend-{environment}-{regionCode}'
        'Backend' = 'rg-{applicationName}-backend-{environment}-{regionCode}'
        'AiFoundry' = 'rg-{applicationName}-aifoundry-{environment}-{regionCode}'
        'Logging' = 'rg-{applicationName}-logging-{environment}-{regionCode}'
    }
    'Frontend' = @{
        'StaticWebApp' = 'stapp-{applicationName}-frontend-{environment}-{regionCode}'
        'ApplicationInsights' = 'appi-{applicationName}-frontend-{environment}-{regionCode}'
    }
    'Backend' = @{
        'FunctionApp' = 'func-{applicationName}-backend-{environment}-{regionCode}'
        'StorageAccount' = 'st{applicationNameBackendEnvironmentRegionCode}' # No hyphens, max 24 chars
        'AppServicePlan' = 'asp-{applicationName}-backend-{environment}-{regionCode}'
        'ApplicationInsights' = 'appi-{applicationName}-backend-{environment}-{regionCode}'
    }
    'AiFoundry' = @{
        'CognitiveServices' = 'cs-{applicationName}-aifoundry-{environment}-{regionCode}'
        'AiProject' = 'aiproj-{applicationName}-aifoundry-{environment}-{regionCode}'
    }
    'Logging' = @{
        'LogAnalyticsWorkspace' = 'la-{applicationName}-logging-{environment}-{regionCode}'
    }
}

function Test-NamingConventions {
    Write-Host "📏 AI in A Box - Naming Convention Validation" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Application: $ApplicationName" -ForegroundColor White
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Location: $Location" -ForegroundColor White
    Write-Host ""

    # Validate prerequisites
    try {
        $azAccount = az account show 2>$null | ConvertFrom-Json
        if (-not $azAccount) {
            Write-Error "❌ Not logged in to Azure CLI. Please run 'az login'"
            return $false
        }
        Write-Host "✅ Azure CLI authenticated as $($azAccount.user.name)" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Azure CLI not available or not authenticated"
        return $false
    }

    # Validate region
    if (-not $regionReference.ContainsKey($Location.ToLower())) {
        Write-Error "❌ Unsupported region: $Location. Must be one of: $($regionReference.Keys -join ', ')"
        return $false
    }

    $regionCode = $regionReference[$Location.ToLower()]
    Write-Host "✅ Region code: $regionCode" -ForegroundColor Green

    # Generate expected names
    $namingSuffixes = @{
        'Frontend' = "$ApplicationName-frontend-$Environment-$regionCode".ToLower()
        'Backend' = "$ApplicationName-backend-$Environment-$regionCode".ToLower()
        'AiFoundry' = "$ApplicationName-aifoundry-$Environment-$regionCode".ToLower()
        'Logging' = "$ApplicationName-logging-$Environment-$regionCode".ToLower()
        'BackendShort' = "$ApplicationName-backend-$Environment-$regionCode".ToLower() -replace '-', ''
    }

    # Build expected resource names
    $expectedResources = @{}
    
    # Resource Groups (always expected)
    $expectedResources['ResourceGroups'] = @{
        'Frontend' = "rg-$($namingSuffixes.Frontend)"
        'Backend' = "rg-$($namingSuffixes.Backend)"
    }
    
    if ($CreateAiFoundryResourceGroup) {
        $expectedResources['ResourceGroups']['AiFoundry'] = "rg-$($namingSuffixes.AiFoundry)"
    }
    
    if ($CreateLogAnalyticsWorkspace) {
        $expectedResources['ResourceGroups']['Logging'] = "rg-$($namingSuffixes.Logging)"
    }

    # Frontend Resources (always expected)
    $expectedResources['Frontend'] = @{
        'StaticWebApp' = "stapp-$($namingSuffixes.Frontend)"
        'ApplicationInsights' = "appi-$($namingSuffixes.Frontend)"
    }

    # Backend Resources (always expected)
    $expectedResources['Backend'] = @{
        'FunctionApp' = "func-$($namingSuffixes.Backend)"
        'StorageAccount' = "st$($namingSuffixes.BackendShort)"
        'AppServicePlan' = "asp-$($namingSuffixes.Backend)"
        'ApplicationInsights' = "appi-$($namingSuffixes.Backend)"
    }

    # AI Foundry Resources (conditional)
    if ($CreateAiFoundryResourceGroup) {
        $expectedResources['AiFoundry'] = @{
            'CognitiveServices' = "cs-$($namingSuffixes.AiFoundry)"
            'AiProject' = "aiproj-$($namingSuffixes.AiFoundry)"
        }
    }

    # Logging Resources (conditional)
    if ($CreateLogAnalyticsWorkspace) {
        $expectedResources['Logging'] = @{
            'LogAnalyticsWorkspace' = "la-$($namingSuffixes.Logging)"
        }
    }

    # Validation results
    $validationResults = @()
    $totalChecks = 0
    $passedChecks = 0

    # Helper function to add validation result
    function Add-ValidationResult {
        param(
            [string]$Category,
            [string]$ResourceType,
            [string]$ExpectedName,
            [string]$ActualName,
            [bool]$Exists,
            [bool]$NameMatches,
            [string]$Issue = ""
        )

        $script:totalChecks++
        $passed = $Exists -and $NameMatches
        if ($passed) { $script:passedChecks++ }

        $result = [PSCustomObject]@{
            Category = $Category
            ResourceType = $ResourceType
            ExpectedName = $ExpectedName
            ActualName = $ActualName
            Exists = $Exists
            NameMatches = $NameMatches
            Status = if ($passed) { "✅ PASS" } elseif (-not $Exists) { "⚠️ MISSING" } else { "❌ FAIL" }
            Issue = $Issue
        }

        $script:validationResults += $result
        return $result
    }

    # Helper function to check if resource exists and get its name
    function Get-ResourceInfo {
        param(
            [string]$ResourceGroupName,
            [string]$ExpectedName,
            [string]$ResourceType
        )

        try {
            switch ($ResourceType) {
                "ResourceGroup" {
                    $resource = az group show --name $ExpectedName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "StaticWebApp" {
                    $resource = az staticwebapp show --name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "FunctionApp" {
                    $resource = az functionapp show --name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "StorageAccount" {
                    $resource = az storage account show --name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "AppServicePlan" {
                    $resource = az appservice plan show --name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "ApplicationInsights" {
                    $resource = az monitor app-insights component show --app $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "CognitiveServices" {
                    $resource = az cognitiveservices account show --name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                "LogAnalyticsWorkspace" {
                    $resource = az monitor log-analytics workspace show --workspace-name $ExpectedName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
                    return $resource -ne $null, $resource.name
                }
                default {
                    return $false, ""
                }
            }
        }
        catch {
            return $false, ""
        }
    }

    Write-Host "🔍 Validating Resource Naming Conventions..." -ForegroundColor Yellow
    Write-Host ""

    # Validate Resource Groups
    Write-Host "📂 Resource Groups:" -ForegroundColor Cyan
    foreach ($rgType in $expectedResources['ResourceGroups'].Keys) {
        $expectedName = $expectedResources['ResourceGroups'][$rgType]
        $exists, $actualName = Get-ResourceInfo -ExpectedName $expectedName -ResourceType "ResourceGroup"
        $nameMatches = $actualName -eq $expectedName
        
        $result = Add-ValidationResult -Category "Infrastructure" -ResourceType "Resource Group ($rgType)" -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
        
        Write-Host "  $($result.Status) $($result.ResourceType): $($result.ExpectedName)" -ForegroundColor $(if ($result.Status -eq "✅ PASS") { "Green" } elseif ($result.Status -eq "⚠️ MISSING") { "Yellow" } else { "Red" })
        if ($result.ActualName -and $result.ActualName -ne $result.ExpectedName) {
            Write-Host "    Actual: $($result.ActualName)" -ForegroundColor Gray
        }
    }

    # Validate Frontend Resources
    Write-Host ""
    Write-Host "🌐 Frontend Resources:" -ForegroundColor Cyan
    $frontendRgName = $expectedResources['ResourceGroups']['Frontend']
    foreach ($resourceType in $expectedResources['Frontend'].Keys) {
        $expectedName = $expectedResources['Frontend'][$resourceType]
        $exists, $actualName = Get-ResourceInfo -ResourceGroupName $frontendRgName -ExpectedName $expectedName -ResourceType $resourceType
        $nameMatches = $actualName -eq $expectedName
        
        $result = Add-ValidationResult -Category "Frontend" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
        
        Write-Host "  $($result.Status) $($result.ResourceType): $($result.ExpectedName)" -ForegroundColor $(if ($result.Status -eq "✅ PASS") { "Green" } elseif ($result.Status -eq "⚠️ MISSING") { "Yellow" } else { "Red" })
        if ($result.ActualName -and $result.ActualName -ne $result.ExpectedName) {
            Write-Host "    Actual: $($result.ActualName)" -ForegroundColor Gray
        }
    }

    # Validate Backend Resources
    Write-Host ""
    Write-Host "⚙️ Backend Resources:" -ForegroundColor Cyan
    $backendRgName = $expectedResources['ResourceGroups']['Backend']
    foreach ($resourceType in $expectedResources['Backend'].Keys) {
        $expectedName = $expectedResources['Backend'][$resourceType]
        $exists, $actualName = Get-ResourceInfo -ResourceGroupName $backendRgName -ExpectedName $expectedName -ResourceType $resourceType
        $nameMatches = $actualName -eq $expectedName
        
        # Special validation for storage account naming rules
        if ($resourceType -eq "StorageAccount") {
            $nameValid = $expectedName -match '^st[a-z0-9]{3,22}$' -and $expectedName.Length -le 24
            if (-not $nameValid) {
                $result = Add-ValidationResult -Category "Backend" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $false -Issue "Storage account name violates Azure naming rules"
            } else {
                $result = Add-ValidationResult -Category "Backend" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
            }
        } else {
            $result = Add-ValidationResult -Category "Backend" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
        }
        
        Write-Host "  $($result.Status) $($result.ResourceType): $($result.ExpectedName)" -ForegroundColor $(if ($result.Status -eq "✅ PASS") { "Green" } elseif ($result.Status -eq "⚠️ MISSING") { "Yellow" } else { "Red" })
        if ($result.ActualName -and $result.ActualName -ne $result.ExpectedName) {
            Write-Host "    Actual: $($result.ActualName)" -ForegroundColor Gray
        }
        if ($result.Issue) {
            Write-Host "    Issue: $($result.Issue)" -ForegroundColor Red
        }
    }

    # Validate AI Foundry Resources (if applicable)
    if ($CreateAiFoundryResourceGroup -and $expectedResources.ContainsKey('AiFoundry')) {
        Write-Host ""
        Write-Host "🤖 AI Foundry Resources:" -ForegroundColor Cyan
        $aiFoundryRgName = $expectedResources['ResourceGroups']['AiFoundry']
        foreach ($resourceType in $expectedResources['AiFoundry'].Keys) {
            $expectedName = $expectedResources['AiFoundry'][$resourceType]
            $exists, $actualName = Get-ResourceInfo -ResourceGroupName $aiFoundryRgName -ExpectedName $expectedName -ResourceType $resourceType
            $nameMatches = $actualName -eq $expectedName
            
            $result = Add-ValidationResult -Category "AI Foundry" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
            
            Write-Host "  $($result.Status) $($result.ResourceType): $($result.ExpectedName)" -ForegroundColor $(if ($result.Status -eq "✅ PASS") { "Green" } elseif ($result.Status -eq "⚠️ MISSING") { "Yellow" } else { "Red" })
            if ($result.ActualName -and $result.ActualName -ne $result.ExpectedName) {
                Write-Host "    Actual: $($result.ActualName)" -ForegroundColor Gray
            }
        }
    }

    # Validate Log Analytics Resources (if applicable)
    if ($CreateLogAnalyticsWorkspace -and $expectedResources.ContainsKey('Logging')) {
        Write-Host ""
        Write-Host "📊 Log Analytics Resources:" -ForegroundColor Cyan
        $loggingRgName = $expectedResources['ResourceGroups']['Logging']
        foreach ($resourceType in $expectedResources['Logging'].Keys) {
            $expectedName = $expectedResources['Logging'][$resourceType]
            $exists, $actualName = Get-ResourceInfo -ResourceGroupName $loggingRgName -ExpectedName $expectedName -ResourceType $resourceType
            $nameMatches = $actualName -eq $expectedName
            
            $result = Add-ValidationResult -Category "Logging" -ResourceType $resourceType -ExpectedName $expectedName -ActualName $actualName -Exists $exists -NameMatches $nameMatches
            
            Write-Host "  $($result.Status) $($result.ResourceType): $($result.ExpectedName)" -ForegroundColor $(if ($result.Status -eq "✅ PASS") { "Green" } elseif ($result.Status -eq "⚠️ MISSING") { "Yellow" } else { "Red" })
            if ($result.ActualName -and $result.ActualName -ne $result.ExpectedName) {
                Write-Host "    Actual: $($result.ActualName)" -ForegroundColor Gray
            }
        }
    }

    # Summary
    Write-Host ""
    Write-Host "📊 Naming Convention Validation Summary" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    $successRate = if ($totalChecks -gt 0) { [math]::Round(($passedChecks / $totalChecks) * 100, 2) } else { 0 }
    $missingResources = $validationResults | Where-Object { $_.Status -eq "⚠️ MISSING" }
    $failedChecks = $validationResults | Where-Object { $_.Status -eq "❌ FAIL" }
    
    Write-Host "Total Checks: $totalChecks" -ForegroundColor White
    Write-Host "Passed: $passedChecks" -ForegroundColor Green
    Write-Host "Missing Resources: $($missingResources.Count)" -ForegroundColor Yellow
    Write-Host "Failed: $($failedChecks.Count)" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

    # Show expected names if requested
    if ($ShowExpected) {
        Write-Host ""
        Write-Host "📋 Complete Expected Resource Names" -ForegroundColor Cyan
        Write-Host "===================================" -ForegroundColor Cyan
        
        foreach ($category in $expectedResources.Keys) {
            Write-Host ""
            Write-Host "$category Resources:" -ForegroundColor Yellow
            foreach ($resourceType in $expectedResources[$category].Keys) {
                Write-Host "  $resourceType`: $($expectedResources[$category][$resourceType])" -ForegroundColor White
            }
        }
    }

    # Recommendations
    if ($failedChecks.Count -gt 0) {
        Write-Host ""
        Write-Host "🔧 Issues Found:" -ForegroundColor Red
        $failedChecks | ForEach-Object {
            Write-Host "  ❌ $($_.Category) - $($_.ResourceType)" -ForegroundColor Red
            Write-Host "    Expected: $($_.ExpectedName)" -ForegroundColor Gray
            Write-Host "    Actual: $($_.ActualName)" -ForegroundColor Gray
            if ($_.Issue) {
                Write-Host "    Issue: $($_.Issue)" -ForegroundColor Red
            }
        }
    }

    if ($missingResources.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️ Missing Resources:" -ForegroundColor Yellow
        $missingResources | ForEach-Object {
            Write-Host "  $($_.Category) - $($_.ResourceType): $($_.ExpectedName)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "These resources may not have been deployed yet or deployment may have failed." -ForegroundColor Gray
    }

    return $successRate -eq 100 -and $missingResources.Count -eq 0
}

# Execute validation
$validationPassed = Test-NamingConventions

# Exit with appropriate code
exit $(if ($validationPassed) { 0 } else { 1 })