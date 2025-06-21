# Frontend Environment Definition

This folder contains the Azure Deployment Environment (ADE) definition for the AI Foundry SPA frontend infrastructure.

## 📁 Contents

- **`environment.yaml`** - ADE manifest defining the frontend environment
- **`manifest.schema.json`** - Local copy of the official ADE schema for validation
- **`README.md`** - This documentation file

## 🔧 Schema Validation

The `environment.yaml` file includes schema validation to ensure compliance with Azure Deployment Environment standards:

```yaml
# yaml-language-server: $schema=./manifest.schema.json
```

This provides:
- ✅ **IntelliSense** in VS Code for property names and values
- ✅ **Real-time validation** of YAML syntax and structure
- ✅ **Error highlighting** for invalid properties or values
- ✅ **Offline support** - no internet connection required for validation

## 🏗️ Infrastructure Resources

This environment definition deploys:

- **Azure Static Web App** - Modern SPA hosting with built-in CI/CD
- **Application Insights** - Frontend monitoring and analytics
- **Integration** with existing Log Analytics Workspace

## 🚀 Deployment

### Using Azure Deployment Environments Portal

1. Navigate to your Azure Deployment Environment project
2. Select this catalog definition
3. Provide required parameters:
   - `applicationName` - Name for resource naming
   - `environmentName` - Environment identifier (dev/staging/prod)
   - `location` - Azure region
   - `logAnalyticsWorkspaceName` - Existing Log Analytics workspace
   - `logAnalyticsResourceGroupName` - Resource group containing workspace

### Using Azure CLI

```bash
# Deploy the environment
az deployment group create \
  --resource-group myResourceGroup \
  --template-file ../../modules/frontend.bicep \
  --parameters applicationName=aibox \
              environmentName=dev \
              location=eastus2 \
              logAnalyticsWorkspaceName=myLogWorkspace \
              logAnalyticsResourceGroupName=myLogWorkspaceRG
```

## 📝 Parameters

| Parameter | Type | Required | Description | Default | Allowed Values |
|-----------|------|----------|-------------|---------|----------------|
| `applicationName` | string | ✅ | Name for resource naming | - | - |
| `environmentName` | string | ✅ | Environment identifier | - | `dev`, `staging`, `prod` |
| `location` | string | ✅ | Azure region | - | `centralus`, `eastus`, `eastus2`, `westus`, `westus2` |
| `logAnalyticsWorkspaceName` | string | ✅ | Log Analytics workspace name | - | - |
| `logAnalyticsResourceGroupName` | string | ✅ | Log Analytics workspace RG | - | - |

**Note**: Required parameters (✅) do not have default values - users must provide these values when creating the environment.

## 🔍 Validation

To validate the environment definition:

1. **VS Code Validation**: Open `environment.yaml` in VS Code with YAML extension
2. **Manual Check**: Ensure all required parameters are present
3. **Schema Compliance**: Verify no additional properties outside the schema

## 🔗 Related Documentation

- [Azure Deployment Environments Guide](../../documentation/AZURE_DEPLOYMENT_ENVIRONMENTS.md)
- [Infrastructure Guide](../../documentation/INFRASTRUCTURE.md)
- [Frontend Bicep Module](../../modules/frontend.bicep)
