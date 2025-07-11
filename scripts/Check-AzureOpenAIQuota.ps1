# Check-AzureOpenAIQuota.ps1
# 
# SYNOPSIS
#     Checks Azure OpenAI quota usage for a specified subscription and region
#
# DESCRIPTION
#     This script retrieves and displays current Azure OpenAI quota usage, including
#     TPM (Tokens Per Minute) and RPM (Requests Per Minute) for all models in the
#     specified region. Helps identify available capacity before deploying new models.
#
# PARAMETERS
#     -SubscriptionId: Azure subscription ID to check quota for
#     -Location: Azure region to check (default: eastus2)
#
# EXAMPLES
#     # Basic usage - check eastus2 region
#     .\Check-AzureOpenAIQuota.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
#
#     # Check specific region
#     .\Check-AzureOpenAIQuota.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -Location "westus2"
#
#     # With full absolute path (recommended)
#     & "C:\Users\BicepDeveloper\repo\ai-in-a-box\scripts\Check-AzureOpenAIQuota.ps1" -SubscriptionId "12345678-1234-1234-1234-123456789012"
#
# PREREQUISITES
#     - Azure CLI installed and authenticated (az login)
#     - PowerShell 5.1 or later
#     - Reader permissions on the subscription
#
# EXPECTED OUTPUT
#     Displays quota usage for each Azure OpenAI model with color-coded status:
#     🟢 LOW (0-49% usage)
#     🟠 MEDIUM (50-74% usage) 
#     🟡 HIGH (75-89% usage)
#     🔴 CRITICAL (90-100% usage)

param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID to check quota for")]
    [ValidatePattern("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Azure region to check quota for")]
    [ValidateSet("eastus", "eastus2", "westus", "westus2", "centralus", "northcentralus", "southcentralus", 
        "westeurope", "northeurope", "uksouth", "ukwest", "francecentral", "germanywestcentral",
        "norwayeast", "switzerlandnorth", "swedencentral", "australiaeast", "southeastasia",
        "eastasia", "japaneast", "japanwest", "koreacentral", "southafricanorth", "uaenorth",
        "brazilsouth", "canadacentral", "canadaeast", "westus3")]
    [string]$Location = "eastus2"
)

# Function to get colored output based on usage percentage
function Get-UsageStatus {
    param([int]$Percentage)
    
    if ($Percentage -ge 90) { return "🔴 CRITICAL", "Red" }
    elseif ($Percentage -ge 75) { return "🟡 HIGH", "Yellow" }
    elseif ($Percentage -ge 50) { return "🟠 MEDIUM", "DarkYellow" }
    else { return "🟢 LOW", "Green" }
}

try {
    Write-Host "=== Azure OpenAI Quota Checker ===" -ForegroundColor Cyan
    Write-Host "Subscription: $SubscriptionId" -ForegroundColor Gray
    Write-Host "Region: $Location" -ForegroundColor Gray
    Write-Host ""

    # Verify Azure CLI authentication
    Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
    $currentAccount = az account show --query "id" --output tsv 2>$null
    
    if (-not $currentAccount) {
        throw "Azure CLI not authenticated. Please run 'az login' first."
    }
    
    if ($currentAccount -ne $SubscriptionId) {
        Write-Host "Setting subscription context..." -ForegroundColor Yellow
        az account set --subscription $SubscriptionId
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set subscription context. Please verify subscription ID and permissions."
        }
    }

    # Get access token
    Write-Host "Retrieving access token..." -ForegroundColor Yellow
    $accessToken = az account get-access-token --query accessToken --output tsv
    
    if (-not $accessToken) {
        throw "Failed to retrieve access token. Please ensure Azure CLI is properly authenticated."
    }

    # Prepare REST API request
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CognitiveServices/locations/$Location/usages?api-version=2023-05-01"
    
    $headers = @{
        Authorization  = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }

    Write-Host "Fetching quota information..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    Write-Host ""
    Write-Host "=== Azure OpenAI Quota Usage in $Location ===" -ForegroundColor Green
    Write-Host ""
    
    $quotaFound = $false
    $availableModels = @()
    
    foreach ($usage in $response.value | Sort-Object { $_.name.localizedValue }) {
        # Filter for OpenAI-related quota (TPM and RPM)
        if ($usage.name.value -like "*TPM*" -or $usage.name.value -like "*RPM*") {
            $quotaFound = $true
            
            $percentage = if ($usage.limit -gt 0) { 
                [math]::Round(($usage.currentValue / $usage.limit) * 100, 2) 
            }
            else { 0 }
            
            $available = $usage.limit - $usage.currentValue
            $status, $color = Get-UsageStatus -Percentage $percentage
            
            # Clean up model name for display
            $modelName = $usage.name.localizedValue -replace "Tokens Per Minute \(thousands\) - ", "" -replace "Requests Per Minute - ", ""
            
            Write-Host "Model: $modelName" -ForegroundColor White
            Write-Host "  Current: $($usage.currentValue.ToString('N0'))" -ForegroundColor Cyan
            Write-Host "  Limit: $($usage.limit.ToString('N0'))" -ForegroundColor Cyan
            Write-Host "  Available: $($available.ToString('N0'))" -ForegroundColor $(if ($available -gt 0) { "Green" } else { "Red" })
            Write-Host "  Usage: $percentage% $status" -ForegroundColor $color
            Write-Host ""
            
            if ($available -gt 0) {
                $availableModels += [PSCustomObject]@{
                    Model     = $modelName
                    Available = $available
                    Unit      = if ($usage.name.value -like "*TPM*") { "TPM" } else { "RPM" }
                }
            }
        }
    }
    
    if (-not $quotaFound) {
        Write-Host "⚠️  No Azure OpenAI quota found in this region." -ForegroundColor Yellow
        Write-Host "   This could mean:" -ForegroundColor Yellow
        Write-Host "   • Azure OpenAI is not available in $Location" -ForegroundColor Yellow
        Write-Host "   • Your subscription doesn't have Azure OpenAI access" -ForegroundColor Yellow
        Write-Host "   • The region name is incorrect" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "💡 To request Azure OpenAI access:" -ForegroundColor Cyan
        Write-Host "   https://aka.ms/oai/stuquotarequest" -ForegroundColor Cyan
    }
    else {
        # Summary of models with available capacity
        $modelsWithCapacity = $availableModels | Where-Object { $_.Available -gt 0 -and $_.Unit -eq "TPM" }
        
        if ($modelsWithCapacity.Count -gt 0) {
            Write-Host "=== Models with Available Capacity (TPM) ===" -ForegroundColor Green
            foreach ($model in $modelsWithCapacity | Sort-Object Available -Descending) {
                $capacityUnits = [math]::Floor($model.Available / 1000)
                Write-Host "✅ $($model.Model): $($model.Available.ToString('N0')) TPM available ($capacityUnits capacity units)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "⚠️  No models have available TPM capacity in this region" -ForegroundColor Yellow
            Write-Host "   Consider:" -ForegroundColor Yellow
            Write-Host "   • Using a different region" -ForegroundColor Yellow
            Write-Host "   • Reducing capacity on existing deployments" -ForegroundColor Yellow
            Write-Host "   • Requesting quota increase" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "💡 Helpful Links:" -ForegroundColor Cyan
        Write-Host "   • Request quota increase: https://aka.ms/oai/stuquotarequest" -ForegroundColor Cyan
        Write-Host "   • Manage quotas: https://ai.azure.com/" -ForegroundColor Cyan
        Write-Host "   • Quota documentation: https://learn.microsoft.com/azure/ai-foundry/openai/how-to/quota" -ForegroundColor Cyan
    }
    
}
catch {
    Write-Error "Failed to retrieve quota information: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify Azure CLI is installed and authenticated:" -ForegroundColor Yellow
    Write-Host "   az login" -ForegroundColor Gray
    Write-Host "2. Check subscription access:" -ForegroundColor Yellow
    Write-Host "   az account list --output table" -ForegroundColor Gray
    Write-Host "3. Verify permissions (Reader role required on subscription)" -ForegroundColor Yellow
    Write-Host "4. Try a different region if the current one doesn't support Azure OpenAI" -ForegroundColor Yellow
    
    exit 1
}
