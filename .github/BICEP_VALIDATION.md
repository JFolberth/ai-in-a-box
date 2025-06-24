# Bicep CI Validation Setup

This document describes the CI pipeline Bicep validation setup and requirements.

## Overview

The CI pipeline includes a `bicep-validation` job that validates all Bicep infrastructure templates using Azure CLI `what-if` commands. This ensures infrastructure changes are validated before merging without actually deploying resources.

## Authentication Requirements

### Azure Service Principal

The CI workflow requires an Azure service principal with the following permissions:

1. **Subscription-level permissions** (for main orchestrator validation):
   - `Reader` role at subscription scope
   - `Microsoft.Resources/deployments/validate/action` permission

2. **Resource Group permissions** (for environment validation):
   - `Contributor` role on temporary resource groups (created and deleted during validation)

### GitHub Secrets Configuration

Add the following secret to your GitHub repository:

**Secret Name**: `AZURE_CREDENTIALS`
**Secret Value** (JSON format):
```json
{
  "clientId": "your-service-principal-client-id",
  "clientSecret": "your-service-principal-client-secret", 
  "subscriptionId": "your-azure-subscription-id",
  "tenantId": "your-azure-tenant-id"
}
```

### Creating the Service Principal

```bash
# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "ai-foundry-spa-ci" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
  --sdk-auth

# Copy the output JSON to AZURE_CREDENTIALS secret
```

## Validation Scope

The CI pipeline validates:

### 1. Main Orchestrator Template
- **File**: `infra/main-orchestrator.bicep`
- **Scope**: Subscription-level deployment
- **Parameters**: Uses `infra/dev-orchestrator.parameters.bicepparam`
- **What-if Command**: `az deployment sub what-if`

### 2. Backend Environment Template  
- **File**: `infra/environments/backend/main.bicep`
- **Scope**: Resource group deployment
- **Parameters**: Uses `infra/environments/backend/example-parameters.bicepparam`
- **What-if Command**: `az deployment group what-if`

### 3. Frontend Environment Template
- **File**: `infra/environments/frontend/main.bicep`  
- **Scope**: Resource group deployment
- **Parameters**: Uses `infra/environments/frontend/example-parameters.bicepparam`
- **What-if Command**: `az deployment group what-if`

## Validation Process

1. **Checkout**: Repository code is checked out
2. **Azure Login**: Authenticate using service principal credentials
3. **Main Orchestrator Validation**: Subscription-scoped what-if validation
4. **Temporary Resource Group**: Create temporary RG for environment validation
5. **Backend Validation**: Resource group-scoped what-if validation  
6. **Frontend Validation**: Resource group-scoped what-if validation
7. **Cleanup**: Delete temporary resource group
8. **Summary**: Generate validation report

## Local Validation

You can run similar validation locally:

```bash
# Authenticate to Azure
az login

# Validate main orchestrator
az deployment sub what-if \
  --location "eastus2" \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam"

# Create temporary resource group
az group create --name "rg-local-validation" --location "eastus2"

# Validate backend environment
az deployment group what-if \
  --resource-group "rg-local-validation" \
  --template-file "infra/environments/backend/main.bicep" \
  --parameters "infra/environments/backend/example-parameters.bicepparam"

# Validate frontend environment  
az deployment group what-if \
  --resource-group "rg-local-validation" \
  --template-file "infra/environments/frontend/main.bicep" \
  --parameters "infra/environments/frontend/example-parameters.bicepparam"

# Cleanup
az group delete --name "rg-local-validation" --yes
```

## Troubleshooting

### AVM Registry Access Issues

If you encounter errors accessing Azure Verified Modules (AVM) registry:

```
Error BCP192: Unable to restore the artifact with reference "br:mcr.microsoft.com/bicep/avm/..."
```

This is typically a network connectivity issue. The what-if validation will still validate:
- Template syntax and structure
- Parameter compatibility
- Resource dependencies
- RBAC assignments

### Parameter Validation

Ensure the example parameter files contain valid values:
- Subscription IDs should be valid GUIDs (can be dummy values for validation)
- Resource names should follow Azure naming conventions
- Resource groups should exist or be creatable during validation

### Permissions Issues

If validation fails with permission errors:
- Verify service principal has required permissions
- Check subscription ID in AZURE_CREDENTIALS matches parameter files
- Ensure service principal can create/delete resource groups

## Pipeline Integration

The Bicep validation job runs in parallel with frontend and backend build jobs:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ bicep-validation│    │ frontend-build   │    │ backend-build   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
           │                      │                       │
           └──────────────────────┼───────────────────────┘
                                  │
                          ┌───────────────┐
                          │ build-summary │
                          └───────────────┘
```

All three jobs must complete successfully for the pipeline to pass.