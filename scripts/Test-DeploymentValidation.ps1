#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Post-Deployment Validation Script for AI in A Box Infrastructure

.DESCRIPTION
    This script validates that all expected Azure resources have been correctly deployed
    according to the AI in A Box infrastructure specifications. It verifies resource
    existence, naming conventions, configurations, and RBAC assignments.

.PARAMETER ApplicationName
    The application name used during deployment (e.g., "conspiracy-bot")

.PARAMETER Environment
    The environment name (e.g., "dev", "staging", "prod")

.PARAMETER Location
    The Azure region where resources were deployed (e.g., "eastus2")

.PARAMETER CreateAiFoundryResourceGroup
    Whether AI Foundry resources were created (true) or existing resources used (false)

.PARAMETER CreateLogAnalyticsWorkspace
    Whether Log Analytics workspace was created (true) or existing workspace used (false)

.PARAMETER AiFoundryResourceGroupName
    Name of existing AI Foundry resource group (when CreateAiFoundryResourceGroup is false)

.PARAMETER LogAnalyticsResourceGroupName
    Name of existing Log Analytics resource group (when CreateLogAnalyticsWorkspace is false)

.PARAMETER Detailed
    Show detailed validation results for each resource

.PARAMETER OutputFormat
    Output format: Table, JSON, or Summary (default: Summary)

.EXAMPLE
    ./Test-DeploymentValidation.ps1 -ApplicationName "conspiracy-bot" -Environment "dev" -Location "eastus2" -CreateAiFoundryResourceGroup $true -CreateLogAnalyticsWorkspace $true

.EXAMPLE
    ./Test-DeploymentValidation.ps1 -ApplicationName "myapp" -Environment "prod" -Location "westus3" -CreateAiFoundryResourceGroup $false -CreateLogAnalyticsWorkspace $false -AiFoundryResourceGroupName "rg-existing-ai-foundry" -LogAnalyticsResourceGroupName "rg-existing-logging" -Detailed

.NOTES
    Requirements:
    - Azure CLI installed and authenticated
    - PowerShell 7.0 or later
    - Appropriate permissions to read Azure resources and role assignments
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

    [Parameter(HelpMessage = "Name of existing AI Foundry resource group")]
    [string]$AiFoundryResourceGroupName = "",

    [Parameter(HelpMessage = "Name of existing Log Analytics resource group")]
    [string]$LogAnalyticsResourceGroupName = "",

    [Parameter(HelpMessage = "Show detailed validation results")]
    [switch]$Detailed,

    [Parameter(HelpMessage = "Output format: Table, JSON, or Summary")]
    [ValidateSet("Table", "JSON", "Summary")]
    [string]$OutputFormat = "Summary"
)

# Region reference mapping
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

# Initialize validation results
$validationResults = @()
$totalChecks = 0
$passedChecks = 0

# Helper function to add validation result
function Add-ValidationResult {
    param(
        [string]$Component,
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Check,
        [bool]$Passed,
        [string]$Details = "",
        [string]$ExpectedValue = "",
        [string]$ActualValue = ""
    )

    $script:totalChecks++
    if ($Passed) { $script:passedChecks++ }

    $result = [PSCustomObject]@{
        Component = $Component
        ResourceType = $ResourceType
        ResourceName = $ResourceName
        Check = $Check
        Status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
        Details = $Details
        ExpectedValue = $ExpectedValue
        ActualValue = $ActualValue
    }

    $script:validationResults += $result

    if ($Detailed -or -not $Passed) {
        Write-Host "$($result.Status) [$($result.Component)] $($result.Check)" -ForegroundColor $(if ($Passed) { "Green" } else { "Red" })
        if ($Details) {
            Write-Host "    $Details" -ForegroundColor Gray
        }
    }
}

# Helper function to check if resource exists
function Test-AzureResource {
    param(
        [string]$ResourceGroupName,
        [string]$ResourceName,
        [string]$ResourceType
    )

    try {
        $resource = switch ($ResourceType) {
            "ResourceGroup" {
                az group show --name $ResourceName 2>$null | ConvertFrom-Json
            }
            "StaticWebApp" {
                az staticwebapp show --name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "FunctionApp" {
                az functionapp show --name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "StorageAccount" {
                az storage account show --name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "AppServicePlan" {
                az appservice plan show --name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "ApplicationInsights" {
                az monitor app-insights component show --app $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "CognitiveServices" {
                az cognitiveservices account show --name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            "LogAnalyticsWorkspace" {
                az monitor log-analytics workspace show --workspace-name $ResourceName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
            }
            default {
                $null
            }
        }

        return $resource -ne $null, $resource
    }
    catch {
        return $false, $null
    }
}

# Helper function to check RBAC assignment
function Test-RbacAssignment {
    param(
        [string]$PrincipalId,
        [string]$RoleName,
        [string]$Scope
    )

    try {
        $assignments = az role assignment list --assignee $PrincipalId --role $RoleName --scope $Scope 2>$null | ConvertFrom-Json
        return $assignments.Count -gt 0
    }
    catch {
        return $false
    }
}

# Main validation function
function Start-DeploymentValidation {
    Write-Host "🚀 AI in A Box - Post-Deployment Validation" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Application: $ApplicationName" -ForegroundColor White
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Location: $Location" -ForegroundColor White
    Write-Host "Create AI Foundry RG: $CreateAiFoundryResourceGroup" -ForegroundColor White
    Write-Host "Create Log Analytics: $CreateLogAnalyticsWorkspace" -ForegroundColor White
    Write-Host ""

    # Validate Azure CLI
    Write-Host "🔍 Validating Prerequisites..." -ForegroundColor Yellow

    try {
        $azAccount = az account show 2>$null | ConvertFrom-Json
        if (-not $azAccount) {
            Write-Error "❌ Not logged in to Azure CLI. Please run 'az login'"
            return
        }
        Write-Host "✅ Azure CLI authenticated as $($azAccount.user.name)"
    }
    catch {
        Write-Error "❌ Azure CLI not available or not authenticated"
        return
    }

    # Validate region
    if (-not $regionReference.ContainsKey($Location.ToLower())) {
        Write-Error "❌ Unsupported region: $Location"
        return
    }

    $regionCode = $regionReference[$Location.ToLower()]
    Write-Host "✅ Region code: $regionCode"

    # Calculate expected resource names
    $frontendSuffix = "$ApplicationName-frontend-$Environment-$regionCode".ToLower()
    $backendSuffix = "$ApplicationName-backend-$Environment-$regionCode".ToLower()
    $aiFoundrySuffix = "$ApplicationName-aifoundry-$Environment-$regionCode".ToLower()
    $loggingSuffix = "$ApplicationName-logging-$Environment-$regionCode".ToLower()
    $backendSuffixShort = $backendSuffix -replace '-', ''

    $expectedResources = @{
        'FrontendRG' = "rg-$frontendSuffix"
        'BackendRG' = "rg-$backendSuffix"
        'AiFoundryRG' = if ($CreateAiFoundryResourceGroup) { "rg-$aiFoundrySuffix" } else { $AiFoundryResourceGroupName }
        'LogAnalyticsRG' = if ($CreateLogAnalyticsWorkspace) { "rg-$loggingSuffix" } else { $LogAnalyticsResourceGroupName }
        'StaticWebApp' = "stapp-$frontendSuffix"
        'FrontendAppInsights' = "appi-$frontendSuffix"
        'FunctionApp' = "func-$backendSuffix"
        'StorageAccount' = "st$backendSuffixShort"
        'AppServicePlan' = "asp-$backendSuffix"
        'BackendAppInsights' = "appi-$backendSuffix"
        'CognitiveServices' = "cs-$aiFoundrySuffix"
        'LogAnalyticsWorkspace' = "la-$loggingSuffix"
    }

    Write-Host ""
    Write-Host "🔍 Starting Resource Validation..." -ForegroundColor Yellow

    # Validate Resource Groups
    Write-Host "📂 Validating Resource Groups..." -ForegroundColor Cyan

    $frontendRgExists, $frontendRg = Test-AzureResource -ResourceName $expectedResources.FrontendRG -ResourceType "ResourceGroup"
    Add-ValidationResult -Component "Infrastructure" -ResourceType "Resource Group" -ResourceName $expectedResources.FrontendRG -Check "Frontend RG Exists" -Passed $frontendRgExists

    $backendRgExists, $backendRg = Test-AzureResource -ResourceName $expectedResources.BackendRG -ResourceType "ResourceGroup"
    Add-ValidationResult -Component "Infrastructure" -ResourceType "Resource Group" -ResourceName $expectedResources.BackendRG -Check "Backend RG Exists" -Passed $backendRgExists

    if ($CreateAiFoundryResourceGroup) {
        $aiFoundryRgExists, $aiFoundryRg = Test-AzureResource -ResourceName $expectedResources.AiFoundryRG -ResourceType "ResourceGroup"
        Add-ValidationResult -Component "Infrastructure" -ResourceType "Resource Group" -ResourceName $expectedResources.AiFoundryRG -Check "AI Foundry RG Exists" -Passed $aiFoundryRgExists
    }

    if ($CreateLogAnalyticsWorkspace) {
        $logAnalyticsRgExists, $logAnalyticsRg = Test-AzureResource -ResourceName $expectedResources.LogAnalyticsRG -ResourceType "ResourceGroup"
        Add-ValidationResult -Component "Infrastructure" -ResourceType "Resource Group" -ResourceName $expectedResources.LogAnalyticsRG -Check "Log Analytics RG Exists" -Passed $logAnalyticsRgExists
    }

    # Validate Frontend Resources
    Write-Host "🌐 Validating Frontend Resources..." -ForegroundColor Cyan

    if ($frontendRgExists) {
        $staticWebAppExists, $staticWebApp = Test-AzureResource -ResourceGroupName $expectedResources.FrontendRG -ResourceName $expectedResources.StaticWebApp -ResourceType "StaticWebApp"
        Add-ValidationResult -Component "Frontend" -ResourceType "Static Web App" -ResourceName $expectedResources.StaticWebApp -Check "Static Web App Exists" -Passed $staticWebAppExists

        if ($staticWebAppExists) {
            $httpsUrl = "https://$($staticWebApp.defaultHostname)"
            Add-ValidationResult -Component "Frontend" -ResourceType "Static Web App" -ResourceName $expectedResources.StaticWebApp -Check "HTTPS Enabled" -Passed ($staticWebApp.defaultHostname -ne $null) -ActualValue $httpsUrl
        }

        $frontendAppInsightsExists, $frontendAppInsights = Test-AzureResource -ResourceGroupName $expectedResources.FrontendRG -ResourceName $expectedResources.FrontendAppInsights -ResourceType "ApplicationInsights"
        Add-ValidationResult -Component "Frontend" -ResourceType "Application Insights" -ResourceName $expectedResources.FrontendAppInsights -Check "App Insights Exists" -Passed $frontendAppInsightsExists
    }

    # Validate Backend Resources
    Write-Host "⚙️ Validating Backend Resources..." -ForegroundColor Cyan

    if ($backendRgExists) {
        $functionAppExists, $functionApp = Test-AzureResource -ResourceGroupName $expectedResources.BackendRG -ResourceName $expectedResources.FunctionApp -ResourceType "FunctionApp"
        Add-ValidationResult -Component "Backend" -ResourceType "Function App" -ResourceName $expectedResources.FunctionApp -Check "Function App Exists" -Passed $functionAppExists

        if ($functionAppExists) {
            # Check managed identity
            $hasManagedIdentity = $functionApp.identity -and $functionApp.identity.type -eq "SystemAssigned"
            Add-ValidationResult -Component "Backend" -ResourceType "Function App" -ResourceName $expectedResources.FunctionApp -Check "Managed Identity Enabled" -Passed $hasManagedIdentity -ActualValue $functionApp.identity.type

            # Check HTTPS only
            $httpsOnly = $functionApp.httpsOnly -eq $true
            Add-ValidationResult -Component "Backend" -ResourceType "Function App" -ResourceName $expectedResources.FunctionApp -Check "HTTPS Only" -Passed $httpsOnly -ActualValue $functionApp.httpsOnly.ToString()
        }

        $storageAccountExists, $storageAccount = Test-AzureResource -ResourceGroupName $expectedResources.BackendRG -ResourceName $expectedResources.StorageAccount -ResourceType "StorageAccount"
        Add-ValidationResult -Component "Backend" -ResourceType "Storage Account" -ResourceName $expectedResources.StorageAccount -Check "Storage Account Exists" -Passed $storageAccountExists

        if ($storageAccountExists) {
            $httpsTrafficOnly = $storageAccount.supportsHttpsTrafficOnly -eq $true
            Add-ValidationResult -Component "Backend" -ResourceType "Storage Account" -ResourceName $expectedResources.StorageAccount -Check "HTTPS Traffic Only" -Passed $httpsTrafficOnly -ActualValue $storageAccount.supportsHttpsTrafficOnly.ToString()
        }

        $appServicePlanExists, $appServicePlan = Test-AzureResource -ResourceGroupName $expectedResources.BackendRG -ResourceName $expectedResources.AppServicePlan -ResourceType "AppServicePlan"
        Add-ValidationResult -Component "Backend" -ResourceType "App Service Plan" -ResourceName $expectedResources.AppServicePlan -Check "App Service Plan Exists" -Passed $appServicePlanExists

        if ($appServicePlanExists) {
            $isFlexConsumption = $appServicePlan.sku.tier -eq "FlexConsumption"
            Add-ValidationResult -Component "Backend" -ResourceType "App Service Plan" -ResourceName $expectedResources.AppServicePlan -Check "Flex Consumption SKU" -Passed $isFlexConsumption -ExpectedValue "FlexConsumption" -ActualValue $appServicePlan.sku.tier
        }

        $backendAppInsightsExists, $backendAppInsights = Test-AzureResource -ResourceGroupName $expectedResources.BackendRG -ResourceName $expectedResources.BackendAppInsights -ResourceType "ApplicationInsights"
        Add-ValidationResult -Component "Backend" -ResourceType "Application Insights" -ResourceName $expectedResources.BackendAppInsights -Check "App Insights Exists" -Passed $backendAppInsightsExists
    }

    # Validate AI Foundry Resources (if created)
    if ($CreateAiFoundryResourceGroup) {
        Write-Host "🤖 Validating AI Foundry Resources..." -ForegroundColor Cyan

        if ($aiFoundryRgExists) {
            $cognitiveServicesExists, $cognitiveServices = Test-AzureResource -ResourceGroupName $expectedResources.AiFoundryRG -ResourceName $expectedResources.CognitiveServices -ResourceType "CognitiveServices"
            Add-ValidationResult -Component "AI Foundry" -ResourceType "Cognitive Services" -ResourceName $expectedResources.CognitiveServices -Check "Cognitive Services Exists" -Passed $cognitiveServicesExists

            if ($cognitiveServicesExists) {
                $isAiServices = $cognitiveServices.kind -eq "AIServices"
                Add-ValidationResult -Component "AI Foundry" -ResourceType "Cognitive Services" -ResourceName $expectedResources.CognitiveServices -Check "AIServices Kind" -Passed $isAiServices -ExpectedValue "AIServices" -ActualValue $cognitiveServices.kind
            }
        }
    }

    # Validate Log Analytics Resources (if created)
    if ($CreateLogAnalyticsWorkspace) {
        Write-Host "📊 Validating Log Analytics Resources..." -ForegroundColor Cyan

        if ($logAnalyticsRgExists) {
            $logAnalyticsExists, $logAnalytics = Test-AzureResource -ResourceGroupName $expectedResources.LogAnalyticsRG -ResourceName $expectedResources.LogAnalyticsWorkspace -ResourceType "LogAnalyticsWorkspace"
            Add-ValidationResult -Component "Logging" -ResourceType "Log Analytics Workspace" -ResourceName $expectedResources.LogAnalyticsWorkspace -Check "Log Analytics Exists" -Passed $logAnalyticsExists
        }
    }

    # Validate RBAC Assignments
    if ($functionAppExists -and $functionApp.identity -and $functionApp.identity.principalId) {
        Write-Host "🔐 Validating RBAC Assignments..." -ForegroundColor Cyan

        $principalId = $functionApp.identity.principalId

        # Storage Blob Data Contributor (within backend RG)
        $backendRgScope = "/subscriptions/$($azAccount.id)/resourceGroups/$($expectedResources.BackendRG)"
        $storageBlobRbac = Test-RbacAssignment -PrincipalId $principalId -RoleName "Storage Blob Data Contributor" -Scope $backendRgScope
        Add-ValidationResult -Component "RBAC" -ResourceType "Role Assignment" -ResourceName "Storage Blob Data Contributor" -Check "Backend Storage Access" -Passed $storageBlobRbac

        # AI Foundry RBAC (if using AI Foundry)
        if ($expectedResources.AiFoundryRG) {
            $aiFoundryRgScope = "/subscriptions/$($azAccount.id)/resourceGroups/$($expectedResources.AiFoundryRG)"
            
            $azureAiUserRbac = Test-RbacAssignment -PrincipalId $principalId -RoleName "Azure AI User" -Scope $aiFoundryRgScope
            Add-ValidationResult -Component "RBAC" -ResourceType "Role Assignment" -ResourceName "Azure AI User" -Check "AI Foundry Project Access" -Passed $azureAiUserRbac

            $openAiUserRbac = Test-RbacAssignment -PrincipalId $principalId -RoleName "Cognitive Services OpenAI User" -Scope $aiFoundryRgScope
            Add-ValidationResult -Component "RBAC" -ResourceType "Role Assignment" -ResourceName "Cognitive Services OpenAI User" -Check "AI Foundry API Access" -Passed $openAiUserRbac
        }
    }

    # Generate summary
    Write-Host ""
    Write-Host "📊 Validation Summary" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan

    $successRate = if ($totalChecks -gt 0) { [math]::Round(($passedChecks / $totalChecks) * 100, 2) } else { 0 }
    
    Write-Host "Total Checks: $totalChecks" -ForegroundColor White
    Write-Host "Passed: $passedChecks" -ForegroundColor Green
    Write-Host "Failed: $($totalChecks - $passedChecks)" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

    # Output results based on format
    switch ($OutputFormat) {
        "Table" {
            Write-Host ""
            Write-Host "📋 Detailed Results" -ForegroundColor Cyan
            $validationResults | Format-Table -AutoSize
        }
        "JSON" {
            $validationResults | ConvertTo-Json -Depth 3
        }
        "Summary" {
            $failedChecks = $validationResults | Where-Object { $_.Status -eq "❌ FAIL" }
            if ($failedChecks.Count -gt 0) {
                Write-Host ""
                Write-Host "❌ Failed Checks:" -ForegroundColor Red
                $failedChecks | ForEach-Object {
                    Write-Host "  [$($_.Component)] $($_.Check) - $($_.ResourceName)" -ForegroundColor Red
                    if ($_.Details) {
                        Write-Host "    $($_.Details)" -ForegroundColor Gray
                    }
                }
            }
        }
    }

    # Recommendations
    if ($passedChecks -lt $totalChecks) {
        Write-Host ""
        Write-Host "🔧 Recommendations:" -ForegroundColor Yellow
        Write-Host "- Review failed checks above"
        Write-Host "- Ensure all required resources are deployed"
        Write-Host "- Verify RBAC assignments are configured correctly"
        Write-Host "- Check resource naming conventions"
        Write-Host "- Run deployment again if necessary"
    } else {
        Write-Host ""
        Write-Host "🎉 All validations passed! Your deployment is ready." -ForegroundColor Green
    }

    return $successRate -eq 100
}

# Execute validation
$validationPassed = Start-DeploymentValidation

# Exit with appropriate code
exit $(if ($validationPassed) { 0 } else { 1 })