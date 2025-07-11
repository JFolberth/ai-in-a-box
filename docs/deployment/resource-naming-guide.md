# Resource Naming Convention Guide

This document provides comprehensive guidance on the naming conventions used throughout the AI in A Box infrastructure, with examples and patterns to ensure consistent and predictable resource naming.

## 🎯 Overview

The AI in A Box infrastructure uses **systematic naming conventions** that provide:
- ✅ **Predictable Resource Names**: Easy to find and manage resources
- ✅ **Environment Separation**: Clear distinction between dev/staging/prod
- ✅ **Component Identification**: Immediately understand resource purpose
- ✅ **Region Awareness**: Quick identification of resource location
- ✅ **Uniqueness**: Avoid naming conflicts across deployments

## 📋 Core Naming Patterns

### Base Pattern Structure

All resource names follow this structure:
```
{resource-type-prefix}-{application-name}-{component}-{environment}-{region-code}
```

### Parameters Used in Naming

| Parameter | Description | Example | Notes |
|-----------|-------------|---------|-------|
| `applicationName` | Your application identifier | `conspiracy-bot` | Lowercase, hyphens allowed |
| `environmentName` | Environment designation | `dev`, `staging`, `prod` | Lowercase |
| `location` | Azure region | `eastus2` | Full Azure region name |
| `regionReference[location]` | Abbreviated region code | `eus2` | Mapped from full region name |

### Component Identifiers

| Component | Identifier | Purpose |
|-----------|------------|---------|
| Frontend | `frontend` | Static Web App and related resources |
| Backend | `backend` | Function App and related resources |
| AI Foundry | `aifoundry` | AI Foundry infrastructure |
| Logging | `logging` | Log Analytics workspace |

## 🏗️ Resource Group Naming

### Naming Pattern
```
rg-{applicationName}-{component}-{environmentName}-{regionCode}
```

### Examples

| Component | Full Name | Breakdown |
|-----------|-----------|-----------|
| **Frontend** | `rg-conspiracy-bot-frontend-dev-eus2` | rg + conspiracy-bot + frontend + dev + eus2 |
| **Backend** | `rg-conspiracy-bot-backend-dev-eus2` | rg + conspiracy-bot + backend + dev + eus2 |
| **AI Foundry** | `rg-conspiracy-bot-aifoundry-dev-eus2` | rg + conspiracy-bot + aifoundry + dev + eus2 |
| **Logging** | `rg-conspiracy-bot-logging-dev-eus2` | rg + conspiracy-bot + logging + dev + eus2 |

### Implementation

```bicep
// Bicep variables for consistent naming
var backendNameSuffix = toLower('${applicationName}-backend-${environmentName}-${regionReference[location]}')
var frontendNameSuffix = toLower('${applicationName}-frontend-${environmentName}-${regionReference[location]}')
var aiFoundryNameSuffix = toLower('${applicationName}-aifoundry-${environmentName}-${regionReference[location]}')
var logAnalyticsNameSuffix = toLower('${applicationName}-logging-${environmentName}-${regionReference[location]}')

var backendResourceGroupName = 'rg-${backendNameSuffix}'
var frontendResourceGroupName = 'rg-${frontendNameSuffix}'
var newAiFoundryResourceGroupName = 'rg-${aiFoundryNameSuffix}'
var newLogAnalyticsResourceGroupName = 'rg-${logAnalyticsNameSuffix}'
```

## 📦 Individual Resource Naming

### Frontend Resources

| Resource Type | Azure Type | Prefix | Pattern | Example |
|---------------|------------|--------|---------|---------|
| **Static Web App** | Microsoft.Web/staticSites | `stapp` | `stapp-{nameSuffix}` | `stapp-conspiracy-bot-frontend-dev-eus2` |
| **Application Insights** | Microsoft.Insights/components | `appi` | `appi-{nameSuffix}` | `appi-conspiracy-bot-frontend-dev-eus2` |

### Backend Resources

| Resource Type | Azure Type | Prefix | Pattern | Example |
|---------------|------------|--------|---------|---------|
| **Function App** | Microsoft.Web/sites | `func` | `func-{nameSuffix}` | `func-conspiracy-bot-backend-dev-eus2` |
| **Storage Account** | Microsoft.Storage/storageAccounts | `st` | `st{nameSuffixShort}` | `stconspiracybotbackenddeveus2` |
| **App Service Plan** | Microsoft.Web/serverfarms | `asp` | `asp-{nameSuffix}` | `asp-conspiracy-bot-backend-dev-eus2` |
| **Application Insights** | Microsoft.Insights/components | `appi` | `appi-{nameSuffix}` | `appi-conspiracy-bot-backend-dev-eus2` |

### AI Foundry Resources

| Resource Type | Azure Type | Prefix | Pattern | Example |
|---------------|------------|--------|---------|---------|
| **Cognitive Services** | Microsoft.CognitiveServices/accounts | `cs` | `cs-{nameSuffix}` | `cs-conspiracy-bot-aifoundry-dev-eus2` |
| **AI Project** | Microsoft.CognitiveServices/accounts/projects | `aiproj` | `aiproj-{nameSuffix}` | `aiproj-conspiracy-bot-aifoundry-dev-eus2` |
| **Model Deployment** | Microsoft.CognitiveServices/accounts/deployments | *configurable* | `{modelDeploymentName}` | `gpt-4.1-mini` |

### Log Analytics Resources

| Resource Type | Azure Type | Prefix | Pattern | Example |
|---------------|------------|--------|---------|---------|
| **Log Analytics Workspace** | Microsoft.OperationalInsights/workspaces | `la` | `la-{nameSuffix}` | `la-conspiracy-bot-logging-dev-eus2` |

## 🗺️ Region Reference Mapping

### Supported Regions

The infrastructure only supports regions where Cognitive Services AIServices are available:

| Azure Region | Region Code | Example Usage |
|--------------|-------------|---------------|
| `australiaeast` | `ause` | `rg-myapp-frontend-dev-ause` |
| `brazilsouth` | `brs` | `rg-myapp-frontend-dev-brs` |
| `canadacentral` | `cac` | `rg-myapp-frontend-dev-cac` |
| `canadaeast` | `cae` | `rg-myapp-frontend-dev-cae` |
| `eastus` | `eus` | `rg-myapp-frontend-dev-eus` |
| `eastus2` | `eus2` | `rg-myapp-frontend-dev-eus2` |
| `francecentral` | `frc` | `rg-myapp-frontend-dev-frc` |
| `germanywestcentral` | `gwc` | `rg-myapp-frontend-dev-gwc` |
| `italynorth` | `itn` | `rg-myapp-frontend-dev-itn` |
| `japaneast` | `jpe` | `rg-myapp-frontend-dev-jpe` |
| `koreacentral` | `krc` | `rg-myapp-frontend-dev-krc` |
| `northcentralus` | `ncus` | `rg-myapp-frontend-dev-ncus` |
| `norwayeast` | `noe` | `rg-myapp-frontend-dev-noe` |
| `polandcentral` | `poc` | `rg-myapp-frontend-dev-poc` |
| `southafricanorth` | `san` | `rg-myapp-frontend-dev-san` |
| `southcentralus` | `scus` | `rg-myapp-frontend-dev-scus` |
| `southeastasia` | `sea` | `rg-myapp-frontend-dev-sea` |
| `southindia` | `ins` | `rg-myapp-frontend-dev-ins` |
| `spaincentral` | `spc` | `rg-myapp-frontend-dev-spc` |
| `swedencentral` | `swc` | `rg-myapp-frontend-dev-swc` |
| `switzerlandnorth` | `swn` | `rg-myapp-frontend-dev-swn` |
| `switzerlandwest` | `sww` | `rg-myapp-frontend-dev-sww` |
| `uaenorth` | `uaen` | `rg-myapp-frontend-dev-uaen` |
| `uksouth` | `uks` | `rg-myapp-frontend-dev-uks` |
| `westeurope` | `weu` | `rg-myapp-frontend-dev-weu` |
| `westus` | `wus` | `rg-myapp-frontend-dev-wus` |
| `westus3` | `wus3` | `rg-myapp-frontend-dev-wus3` |

### Implementation in Bicep

```bicep
var regionReference = {
  australiaeast: 'ause'
  brazilsouth: 'brs'
  canadacentral: 'cac'
  canadaeast: 'cae'
  eastus: 'eus'
  eastus2: 'eus2'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  italynorth: 'itn'
  japaneast: 'jpe'
  koreacentral: 'krc'
  northcentralus: 'ncus'
  norwayeast: 'noe'
  polandcentral: 'poc'
  southafricanorth: 'san'
  southcentralus: 'scus'
  southeastasia: 'sea'
  southindia: 'ins'
  spaincentral: 'spc'
  swedencentral: 'swc'
  switzerlandnorth: 'swn'
  switzerlandwest: 'sww'
  uaenorth: 'uaen'
  uksouth: 'uks'
  westeurope: 'weu'
  westus: 'wus'
  westus3: 'wus3'
}
```

## 🎯 Complete Examples by Environment

### Development Environment

**Parameters**:
- `applicationName`: `"conspiracy-bot"`
- `environmentName`: `"dev"`
- `location`: `"eastus2"`

**Resource Names**:

| Component | Resource Type | Resource Name |
|-----------|---------------|---------------|
| **Resource Groups** | | |
| Frontend | Resource Group | `rg-conspiracy-bot-frontend-dev-eus2` |
| Backend | Resource Group | `rg-conspiracy-bot-backend-dev-eus2` |
| AI Foundry | Resource Group | `rg-conspiracy-bot-aifoundry-dev-eus2` |
| Logging | Resource Group | `rg-conspiracy-bot-logging-dev-eus2` |
| **Frontend Resources** | | |
| | Static Web App | `stapp-conspiracy-bot-frontend-dev-eus2` |
| | Application Insights | `appi-conspiracy-bot-frontend-dev-eus2` |
| **Backend Resources** | | |
| | Function App | `func-conspiracy-bot-backend-dev-eus2` |
| | Storage Account | `stconspiracybotbackenddeveus2` |
| | App Service Plan | `asp-conspiracy-bot-backend-dev-eus2` |
| | Application Insights | `appi-conspiracy-bot-backend-dev-eus2` |
| **AI Foundry Resources** | | |
| | Cognitive Services | `cs-conspiracy-bot-aifoundry-dev-eus2` |
| | AI Project | `aiproj-conspiracy-bot-aifoundry-dev-eus2` |
| | Model Deployment | `gpt-4.1-mini` |
| **Logging Resources** | | |
| | Log Analytics Workspace | `la-conspiracy-bot-logging-dev-eus2` |

### Production Environment

**Parameters**:
- `applicationName`: `"conspiracy-bot"`
- `environmentName`: `"prod"`
- `location`: `"westus3"`

**Resource Names**:

| Component | Resource Type | Resource Name |
|-----------|---------------|---------------|
| **Resource Groups** | | |
| Frontend | Resource Group | `rg-conspiracy-bot-frontend-prod-wus3` |
| Backend | Resource Group | `rg-conspiracy-bot-backend-prod-wus3` |
| AI Foundry | Resource Group | `rg-conspiracy-bot-aifoundry-prod-wus3` |
| Logging | Resource Group | `rg-conspiracy-bot-logging-prod-wus3` |
| **Frontend Resources** | | |
| | Static Web App | `stapp-conspiracy-bot-frontend-prod-wus3` |
| | Application Insights | `appi-conspiracy-bot-frontend-prod-wus3` |
| **Backend Resources** | | |
| | Function App | `func-conspiracy-bot-backend-prod-wus3` |
| | Storage Account | `stconspiracybotbackendprodwus3` |
| | App Service Plan | `asp-conspiracy-bot-backend-prod-wus3` |
| | Application Insights | `appi-conspiracy-bot-backend-prod-wus3` |
| **AI Foundry Resources** | | |
| | Cognitive Services | `cs-conspiracy-bot-aifoundry-prod-wus3` |
| | AI Project | `aiproj-conspiracy-bot-aifoundry-prod-wus3` |
| | Model Deployment | `gpt-4.1-mini` |
| **Logging Resources** | | |
| | Log Analytics Workspace | `la-conspiracy-bot-logging-prod-wus3` |

## ⚙️ Special Naming Considerations

### Storage Account Naming

Storage accounts have special requirements:
- **Length**: 3-24 characters
- **Characters**: Lowercase letters and numbers only
- **No Special Characters**: No hyphens, underscores, or dots

**Implementation**:
```bicep
// Remove hyphens from name suffix for storage account
var nameSuffixShort = replace(nameSuffix, '-', '')
var storageAccountName = 'st${nameSuffixShort}'
```

**Example Transformation**:
- Full suffix: `conspiracy-bot-backend-dev-eus2`
- Storage suffix: `conspiracybotbackenddeveus2`
- Storage name: `stconspiracybotbackenddeveus2`

### Model Deployment Naming

Model deployments use configurable names:
- **Default**: `gpt-4.1-mini`
- **Configurable**: Via `aiFoundryModelDeploymentName` parameter
- **Purpose**: Allows different model versions per environment

### AI Project Naming

AI projects include the full naming suffix for uniqueness:
- **Pattern**: `aiproj-{nameSuffix}`
- **Purpose**: Ensures project names are unique across environments
- **Example**: `aiproj-conspiracy-bot-aifoundry-dev-eus2`

## 🔍 Naming Validation

### Built-in Validation

The Bicep templates include naming validation:

```bicep
// Validate AI Foundry resource group naming standard
var aiFoundryRgNameValid = startsWith(aiFoundryResourceGroupName, 'rg-') && (
  contains(aiFoundryResourceGroupName, '-ai') || 
  contains(aiFoundryResourceGroupName, '-foundry') || 
  contains(aiFoundryResourceGroupName, '-aifoundry')
)

// Validate Log Analytics resource group naming standard  
var logAnalyticsRgNameValid = startsWith(logAnalyticsResourceGroupName, 'rg-') && contains(
  logAnalyticsResourceGroupName,
  '-log'
)

// Display warnings for non-standard naming
var aiFoundryNamingWarning = aiFoundryRgNameValid
  ? ''
  : 'WARNING: AI Foundry resource group name does not follow standard: rg-*-ai*|foundry*|aifoundry*'
  
var logAnalyticsNamingWarning = logAnalyticsRgNameValid
  ? ''
  : 'WARNING: Log Analytics resource group name does not follow standard: rg-*-log*'
```

### Naming Validation Script

```powershell
# Validate resource naming conventions
param(
    [Parameter(Mandatory=$true)]
    [string]$ApplicationName,
    
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$Location
)

# Define expected patterns
$regionMap = @{
    'eastus' = 'eus'
    'eastus2' = 'eus2'
    'westus' = 'wus'
    'westus3' = 'wus3'
    'centralus' = 'cus'
}

$regionCode = $regionMap[$Location]
if (-not $regionCode) {
    Write-Error "Unsupported region: $Location"
    exit 1
}

$suffix = "$ApplicationName-{component}-$Environment-$regionCode".ToLower()

# Expected resource group names
$expectedRGs = @(
    "rg-$($suffix -replace '{component}', 'frontend')"
    "rg-$($suffix -replace '{component}', 'backend')"
    "rg-$($suffix -replace '{component}', 'aifoundry')"
    "rg-$($suffix -replace '{component}', 'logging')"
)

Write-Host "Expected Resource Groups:"
$expectedRGs | ForEach-Object { Write-Host "  $_" }

# Validate names exist
foreach ($rgName in $expectedRGs) {
    $rg = az group show --name $rgName 2>$null | ConvertFrom-Json
    if ($rg) {
        Write-Host "✅ Found: $rgName"
    } else {
        Write-Warning "❌ Missing: $rgName"
    }
}
```

## 📏 Naming Best Practices

### Do's ✅

- **Use Consistent Prefixes**: Follow established prefix patterns for each resource type
- **Include Environment**: Always include environment in resource names
- **Use Region Codes**: Use abbreviated region codes for brevity
- **Follow Azure Limits**: Respect character limits and allowed characters per resource type
- **Be Descriptive**: Names should clearly indicate purpose and ownership

### Don'ts ❌

- **Don't Use Random Suffixes**: Avoid unpredictable or meaningless suffixes
- **Don't Exceed Length Limits**: Stay within Azure resource name limits
- **Don't Use Special Characters**: Avoid characters not supported by resource types
- **Don't Skip Components**: Always include component identification in names
- **Don't Use Hardcoded Values**: Use parameter-driven naming for flexibility

### Troubleshooting Naming Issues

**Problem**: "Resource name already exists"
**Solution**: Check uniqueness of `applicationName` parameter or use different environment/region

**Problem**: "Invalid resource name format"
**Solution**: Verify resource type naming requirements (length, characters, etc.)

**Problem**: "Deployment conflict in different regions"
**Solution**: Ensure region code is included in resource names

## 🔗 Implementation References

### Bicep Implementation

Full naming implementation can be found in:
- **Main Orchestrator**: `infra/main-orchestrator.bicep` (lines 99-165)
- **Frontend Module**: `infra/environments/frontend/main.bicep` (lines 36-78)
- **Backend Module**: `infra/environments/backend/main.bicep` (lines 48-90)

### Parameter Examples

Example parameter files with naming:
- **Development**: `infra/dev-orchestrator.parameters.bicepparam`
- **Backend Example**: `infra/environments/backend/example-parameters.bicepparam`
- **Frontend Example**: `infra/environments/frontend/example-parameters.bicepparam`

## 📚 Related Documentation

- **[Resource Deployment Reference](resource-deployment-reference.md)** - Complete resource inventory and deployment scenarios
- **[Infrastructure Overview](infrastructure.md)** - Detailed architecture documentation
- **[Deployment Guide](deployment-guide.md)** - Step-by-step deployment instructions
- **[Configuration Reference](../configuration/environment-variables.md)** - Environment variable documentation

---

**Need to validate your naming conventions?** → Use the [Naming Validation Script](../../scripts/Test-NamingConventions.ps1) to verify all resources follow the established patterns.