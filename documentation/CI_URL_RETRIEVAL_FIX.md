# CI Pipeline URL Retrieval Fix

## Problem Statement

The CI pipeline for endpoint testing was failing to retrieve Azure Deployment Environment (ADE) URL outputs, resulting in empty URL values during automated testing.

## Root Cause

The original CI workflow had three main issues:

1. **Incorrect Output Extraction**: The workflow tried to query individual Azure resources instead of using Bicep deployment outputs
2. **Missing Deployment Output Queries**: The workflow didn't properly query the ADE deployment outputs 
3. **Manual URL Construction**: The workflow manually constructed URLs from resource properties instead of using pre-defined outputs

### Example of the Problem

**Before (Broken Logic)**:
```bash
# This approach was unreliable
FUNCTION_APP_URL=$(az functionapp show \
  --name "$FUNCTION_APP" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultHostName" \
  --output tsv)
echo "FUNCTION_APP_URL=https://$FUNCTION_APP_URL" >> $GITHUB_ENV
```

**Result**: URLs like `https://` (empty hostname) or failed queries.

## Solution Implemented

### 1. Enhanced URL Extraction Logic

The fix implements a multi-step approach:

1. **Query ADE deployment outputs directly** using `az deployment group show`
2. **Use proper Bicep output names** (`functionAppUrl`, `staticWebsiteUrl`) 
3. **Fallback to resource queries** if deployment outputs are not available
4. **Comprehensive validation** for empty/malformed URLs
5. **Better error handling** with debugging information

### 2. Key Changes Made

**Backend URL Extraction**:
```bash
# 1. Find the most recent successful deployment
DEPLOYMENT_NAME=$(az deployment group list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[?provisioningState=='Succeeded'] | sort_by(@, &timestamp) | [-1].name" \
  --output tsv)

# 2. Get deployment outputs 
DEPLOYMENT_OUTPUTS=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.outputs" \
  --output json)

# 3. Extract URL from deployment outputs (primary method)
FUNCTION_APP_URL=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.functionAppUrl.value // empty')

# 4. Fallback to resource query if needed
if [ -z "$FUNCTION_APP_URL" ] || [ "$FUNCTION_APP_URL" = "null" ]; then
  # Resource query logic as fallback
fi

# 5. Validate URL before proceeding
if [ -z "$FUNCTION_APP_URL" ] || [ "$FUNCTION_APP_URL" = "https://" ]; then
  echo "❌ Invalid URL" && exit 1
fi
```

**Frontend URL Extraction**: Similar logic using `staticWebsiteUrl` output.

### 3. Robust Error Handling

The solution includes:
- **Deployment discovery**: Lists available deployments when extraction fails
- **Resource listing**: Shows available resources for debugging
- **URL validation**: Checks for empty, null, or malformed URLs
- **Clear error messages**: Provides actionable debugging information

### 4. Testing and Validation

Created test scripts to validate the extraction logic:

- **`Test-UrlExtraction.sh`**: Unit tests for URL extraction logic
- **`extract-ade-outputs.sh`**: Reusable helper script for ADE output extraction

## Usage

### In CI Workflow

The fix is automatically applied in the CI workflow (`ci.yml`). The enhanced extraction logic runs during:
- `deploy-ade-frontend` job (Static Web App URL extraction)
- `deploy-ade-backend` job (Function App URL extraction)

### Manual Testing

Test the URL extraction logic locally:

```bash
# Test extraction logic with mock data
./tests/Test-UrlExtraction.sh

# Test with real Azure resources (requires Azure CLI login)
./tests/extract-ade-outputs.sh "rg-my-resource-group" "backend"
./tests/extract-ade-outputs.sh "rg-my-resource-group" "frontend"
```

## Bicep Template Integration

The solution relies on proper Bicep template outputs. Ensure your templates define:

**Backend Template** (`infra/environments/backend/main.bicep`):
```bicep
@description('Function App URL')
output functionAppUrl string = 'https://${functionApp.outputs.defaultHostname}'

@description('Function App Name')
output functionAppName string = functionApp.outputs.name
```

**Frontend Template** (`infra/environments/frontend/main.bicep`):
```bicep
@description('Static Web App URL')
output staticWebsiteUrl string = 'https://${staticWebApp.outputs.defaultHostname}'

@description('Static Web App Name')  
output staticWebAppName string = staticWebApp.outputs.name
```

## Troubleshooting

### Common Issues

1. **"No deployment found"**
   - Check if ADE deployment completed successfully
   - Verify resource group name is correct
   - Check deployment logs in ADE portal

2. **"Invalid or empty URL"**
   - Verify Bicep template has proper outputs
   - Check if resources were created successfully
   - Review Azure CLI permissions

3. **"Deployment outputs not found"**
   - Ensure Bicep template defines required outputs
   - Check deployment status and logs
   - Verify ADE deployment parameters

### Debugging Steps

1. **Check deployment status**:
   ```bash
   az deployment group list --resource-group "your-rg" --output table
   ```

2. **Check deployment outputs**:
   ```bash
   az deployment group show --resource-group "your-rg" --name "deployment-name" --query "properties.outputs"
   ```

3. **List available resources**:
   ```bash
   az resource list --resource-group "your-rg" --output table
   ```

## Benefits

- ✅ **Reliable URL extraction** using Bicep deployment outputs
- ✅ **Fallback mechanism** for edge cases
- ✅ **Comprehensive validation** prevents CI failures
- ✅ **Better error messages** for faster troubleshooting
- ✅ **Tested solution** with unit tests
- ✅ **Reusable components** for future enhancements

## Related Files

- `.github/workflows/ci.yml` - Main CI workflow with URL extraction
- `infra/environments/backend/main.bicep` - Backend Bicep template with outputs
- `infra/environments/frontend/main.bicep` - Frontend Bicep template with outputs
- `tests/Test-UrlExtraction.sh` - Unit tests for URL extraction
- `tests/extract-ade-outputs.sh` - Reusable helper script
- `tests/core/Test-FunctionEndpoints.ps1` - Endpoint testing script