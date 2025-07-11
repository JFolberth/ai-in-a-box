# Environment Variables Reference

*Complete reference for all configuration options in the AI Foundry SPA.*

## 🎯 Overview

The AI Foundry SPA uses environment variables to configure everything from AI service endpoints to monitoring settings. This guide covers all available configuration options and their usage.

## 📱 Frontend Configuration

### Environment Files Location

The frontend uses different environment files based on the deployment mode:

```
src/frontend/
├── .env                    # Default settings (not committed)
├── .env.local             # Local development overrides
├── .env.development       # Development environment
├── .env.production        # Production environment
└── environments/
    ├── dev.js            # Development config object
    └── index.js          # Production config object
```

### Core Frontend Variables

#### **VITE_BACKEND_URL**
- **Purpose**: Backend API base URL
- **Type**: String (URL)
- **Required**: Yes
- **Examples**:
  ```env
  # Local development
  VITE_BACKEND_URL=http://localhost:7071/api
  
  # Production
  VITE_BACKEND_URL=https://func-ai-foundry-spa-backend-prod-abc123.azurewebsites.net/api
  
  # Same origin (Static Web App with proxied functions)
  VITE_BACKEND_URL=/api
  ```

#### **VITE_AI_FOUNDRY_ENDPOINT**
- **Purpose**: Azure AI Foundry service endpoint
- **Type**: String (URL)
- **Required**: Yes (for frontend display/validation)
- **Format**: `https://{service-name}.cognitiveservices.azure.com/`
- **Example**: `https://my-ai-foundry.cognitiveservices.azure.com/`

#### **VITE_AI_FOUNDRY_DEPLOYMENT**
- **Purpose**: AI model deployment name
- **Type**: String
- **Required**: Yes
- **Common Values**: `gpt-4`, `gpt-35-turbo`, custom deployment names
- **Example**: `gpt-4`

#### **VITE_AI_FOUNDRY_AGENT_NAME**
- **Purpose**: Display name for the AI agent
- **Type**: String
- **Required**: Yes
- **Default**: `AI in A Box`
- **Example**: `AI in A Box`

#### **VITE_USE_BACKEND**
- **Purpose**: Enable/disable backend API calls
- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Usage**: Set to `false` for frontend-only testing

#### **VITE_PUBLIC_MODE**
- **Purpose**: Enable public mode (no authentication)
- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Usage**: Controls authentication flow

#### **VITE_DEBUG_LOGGING**
- **Purpose**: Enable detailed console logging
- **Type**: Boolean
- **Required**: No
- **Default**: `false` (production), `true` (development)
- **Usage**: Helpful for development and debugging

### Frontend Environment Examples

**Local Development (`.env.local`):**
```env
# Backend Configuration
VITE_BACKEND_URL=http://localhost:7071/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# AI Foundry Configuration
VITE_AI_FOUNDRY_ENDPOINT=https://dev-ai-foundry.cognitiveservices.azure.com/
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box

# Development Settings
VITE_DEBUG_LOGGING=true
```

**Production (`.env.production`):**
```env
# Backend Configuration (same origin)
VITE_BACKEND_URL=/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# AI Foundry Configuration
VITE_AI_FOUNDRY_ENDPOINT=https://prod-ai-foundry.cognitiveservices.azure.com/
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box

# Production Settings
VITE_DEBUG_LOGGING=false
```

## ⚙️ Backend Configuration

### Configuration Files Location

The backend uses Azure Functions configuration:

```
src/backend/
├── local.settings.json           # Local development (not committed)
├── local.settings.json.example   # Template for local settings
└── appsettings.json              # Additional app settings
```

### Azure Functions App Settings

In production, these are configured as **Application Settings** in the Azure Function App.

#### **AI_FOUNDRY_ENDPOINT**
- **Purpose**: Azure AI Foundry service endpoint
- **Type**: String (URL)
- **Required**: Yes
- **Format**: `https://{service-name}.cognitiveservices.azure.com/`
- **Example**: `https://prod-ai-foundry.cognitiveservices.azure.com/`
- **Security**: Uses managed identity for authentication

#### **AI_FOUNDRY_DEPLOYMENT**
- **Purpose**: AI model deployment name
- **Type**: String
- **Required**: Yes
- **Example**: `gpt-4`

#### **AI_FOUNDRY_AGENT_NAME**
- **Purpose**: Name of the AI agent to use
- **Type**: String
- **Required**: Yes
- **Default**: `AI in A Box`
- **Example**: `AI in A Box`

#### **AzureWebJobsStorage**
- **Purpose**: Azure Functions runtime storage
- **Type**: String (Connection String)
- **Required**: Yes
- **Local Development**: `UseDevelopmentStorage=true` (Azurite)
- **Production**: Automatically configured by Azure
- **Example**: `DefaultEndpointsProtocol=https;AccountName=storageaccount;...`

#### **FUNCTIONS_WORKER_RUNTIME**
- **Purpose**: Azure Functions runtime language
- **Type**: String
- **Required**: Yes
- **Value**: `dotnet-isolated`
- **Fixed**: Should not be changed

#### **APPLICATIONINSIGHTS_CONNECTION_STRING**
- **Purpose**: Application Insights telemetry
- **Type**: String (Connection String)
- **Required**: Recommended
- **Format**: `InstrumentationKey={guid};IngestionEndpoint=https://...`
- **Production**: Automatically configured during deployment

#### **WEBSITE_RUN_FROM_PACKAGE**
- **Purpose**: Azure Functions deployment mode
- **Type**: String
- **Required**: No (Production optimization)
- **Value**: `1`
- **Usage**: Enables running from deployment package

### Backend Environment Examples

**Local Development (`local.settings.json`):**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AI_FOUNDRY_ENDPOINT": "https://dev-ai-foundry.cognitiveservices.azure.com/",
    "AI_FOUNDRY_DEPLOYMENT": "gpt-4",
    "AI_FOUNDRY_AGENT_NAME": "AI in A Box",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-local-key-here"
  }
}
```

**Production (Azure Function App Settings):**
```bash
# Set via Azure CLI
az functionapp config appsettings set \
  --name "func-ai-foundry-spa-backend-prod-abc123" \
  --resource-group "rg-ai-foundry-spa-backend-prod-eus2" \
  --settings \
    "AI_FOUNDRY_ENDPOINT=https://prod-ai-foundry.cognitiveservices.azure.com/" \
    "AI_FOUNDRY_DEPLOYMENT=gpt-4" \
    "AI_FOUNDRY_AGENT_NAME=AI in A Box" \
    "WEBSITE_RUN_FROM_PACKAGE=1"
```

## 🏗️ Infrastructure Configuration

### Bicep Parameters

Infrastructure is configured via `.bicepparam` files:

```
infra/
├── dev-orchestrator.parameters.bicepparam     # Development environment
├── staging-orchestrator.parameters.bicepparam # Staging environment
└── prod-orchestrator.parameters.bicepparam    # Production environment
```

#### **aiFoundryEndpoint**
- **Purpose**: AI Foundry service endpoint for infrastructure
- **Type**: String (URL)
- **Required**: Yes
- **Example**: `'https://prod-ai-foundry.cognitiveservices.azure.com/'`

#### **aiFoundryDeployment**
- **Purpose**: AI model deployment name
- **Type**: String
- **Required**: Yes
- **Example**: `'gpt-4'`

#### **aiFoundryAgentName**
- **Purpose**: AI agent name
- **Type**: String
- **Required**: Yes
- **Example**: `'AI in A Box'`

#### **userPrincipalId**
- **Purpose**: User principal ID for RBAC assignments
- **Type**: String (GUID)
- **Required**: Yes
- **Usage**: Assigns permissions to deploy user
- **Get Value**: `az ad signed-in-user show --query id -o tsv`

#### **environmentName**
- **Purpose**: Environment identifier
- **Type**: String
- **Required**: Yes
- **Valid Values**: `dev`, `staging`, `prod`
- **Example**: `'prod'`

#### **location**
- **Purpose**: Azure region for deployment
- **Type**: String
- **Required**: Yes
- **Example**: `'eastus2'`

#### **applicationName**
- **Purpose**: Application name for resource naming
- **Type**: String
- **Required**: No
- **Default**: `'ai-foundry-spa'`

### Infrastructure Parameter Example

**Production (`prod-orchestrator.parameters.bicepparam`):**
```bicep
using 'main-orchestrator.bicep'

// Required: AI Foundry Configuration
param aiFoundryEndpoint = 'https://prod-ai-foundry.cognitiveservices.azure.com/'
param aiFoundryDeployment = 'gpt-4'
param aiFoundryAgentName = 'AI in A Box'

// Required: User Configuration
param userPrincipalId = 'your-user-principal-id-here'

// Environment Configuration
param environmentName = 'prod'
param location = 'eastus2'
param applicationName = 'ai-foundry-spa'

// Optional: Production-specific settings
param enableAdvancedSecurity = true
param logRetentionDays = 365
param skuName = 'P1V2'
```

## 🌍 Environment-Specific Configurations

### Development Environment

**Characteristics:**
- Shared resources for cost optimization
- Minimal monitoring and retention
- Development-friendly settings

**Frontend Configuration:**
```env
VITE_BACKEND_URL=http://localhost:7071/api
VITE_DEBUG_LOGGING=true
VITE_AI_FOUNDRY_ENDPOINT=https://dev-ai-foundry.cognitiveservices.azure.com/
```

**Backend Configuration:**
```json
{
  "Values": {
    "AI_FOUNDRY_ENDPOINT": "https://dev-ai-foundry.cognitiveservices.azure.com/",
    "AI_FOUNDRY_DEPLOYMENT": "gpt-35-turbo"
  }
}
```

### Staging Environment

**Characteristics:**
- Production-like configuration
- Extended monitoring and testing
- Performance testing suitable

**Frontend Configuration:**
```env
VITE_BACKEND_URL=https://func-ai-foundry-spa-backend-staging-xyz.azurewebsites.net/api
VITE_DEBUG_LOGGING=false
VITE_AI_FOUNDRY_ENDPOINT=https://staging-ai-foundry.cognitiveservices.azure.com/
```

### Production Environment

**Characteristics:**
- High availability and performance
- Maximum security and monitoring
- Custom domains and SSL

**Frontend Configuration:**
```env
VITE_BACKEND_URL=/api
VITE_DEBUG_LOGGING=false
VITE_AI_FOUNDRY_ENDPOINT=https://prod-ai-foundry.cognitiveservices.azure.com/
```

## 🔒 Security Considerations

### Sensitive Information

**Never commit these to source control:**
- `local.settings.json` (backend local config)
- `.env.local` (frontend local config)
- Any files containing real API keys or secrets

**Use Azure Key Vault for production secrets:**
```bash
# Store sensitive configuration in Key Vault
az keyvault secret set \
  --vault-name "kv-ai-foundry-spa-prod" \
  --name "AIFoundryEndpoint" \
  --value "https://prod-ai-foundry.cognitiveservices.azure.com/"
```

### Managed Identity Configuration

**Production backend uses managed identity:**
```csharp
// No explicit credentials needed
var credential = new DefaultAzureCredential();
var client = new AzureOpenAIClient(new Uri(endpoint), credential);
```

**Required RBAC:**
```bash
# Assign Azure AI Developer role to Function App managed identity
az role assignment create \
  --assignee "$FUNCTION_APP_PRINCIPAL_ID" \
  --role "Azure AI Developer" \
  --scope "$AI_FOUNDRY_RESOURCE_ID"
```

## 🔧 Configuration Validation

### Frontend Validation

**Check environment loading:**
```javascript
// In browser console
console.log('Environment:', import.meta.env);
console.log('Backend URL:', import.meta.env.VITE_BACKEND_URL);
console.log('AI Foundry Endpoint:', import.meta.env.VITE_AI_FOUNDRY_ENDPOINT);
```

### Backend Validation

**Health endpoint shows configuration:**
```bash
curl "https://your-function-app.azurewebsites.net/api/health" | jq .
```

**Expected response includes:**
```json
{
  "Status": "Healthy",
  "AiFoundryEndpoint": "https://prod-ai-foundry.cognitiveservices.azure.com/",
  "AgentName": "AI in A Box",
  "ConnectionStatus": "Connected - Agent 'AI in A Box' accessible"
}
```

### Configuration Check Script

```bash
#!/bin/bash
# config-check.sh

echo "=== AI Foundry SPA Configuration Check ==="

# Check frontend environment
echo "Frontend Environment Variables:"
if [ -f "src/frontend/.env.local" ]; then
    grep VITE_ src/frontend/.env.local | sed 's/=.*$/=***/'
else
    echo "No .env.local file found"
fi

# Check backend configuration
echo "Backend Configuration:"
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
if [ -n "$FUNCTION_APP_NAME" ]; then
    FUNCTION_RG=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)
    az functionapp config appsettings list \
      --name "$FUNCTION_APP_NAME" \
      --resource-group "$FUNCTION_RG" \
      --query "[?contains(name, 'AI_FOUNDRY')].{Name:name, Value:value}" \
      -o table
else
    echo "No Function App found"
fi

echo "=== Configuration Check Complete ==="
```

## 🚨 Common Configuration Issues

### Issue: Frontend Can't Connect to Backend

**Symptoms:** CORS errors, network failures in browser console

**Check:**
```bash
# Verify CORS configuration
az functionapp cors show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"

# Expected: Frontend URL in allowed origins
```

**Fix:**
```bash
# Add frontend URL to CORS
az functionapp cors add \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$FUNCTION_RG" \
  --allowed-origins "https://your-frontend-url.azurestaticapps.net"
```

### Issue: AI Foundry Connection Failed

**Symptoms:** Health endpoint shows connection errors

**Check:**
```bash
# Verify AI Foundry endpoint setting
az functionapp config appsettings show \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$FUNCTION_RG" \
  --setting-names AI_FOUNDRY_ENDPOINT

# Verify managed identity role
PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv)
az role assignment list --assignee "$PRINCIPAL_ID" --query "[?roleDefinitionName=='Azure AI Developer']"
```

### Issue: Environment Variables Not Loading

**Frontend:**
```bash
# Check build process includes environment
npm run build
# Look for VITE_ variables in dist/assets/*.js files
```

**Backend:**
```bash
# Restart Function App to reload settings
az functionapp restart --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"
```

## 📋 Configuration Checklist

### Pre-Deployment:
- [ ] AI Foundry endpoint URL configured
- [ ] Deployment/model name specified  
- [ ] User principal ID for RBAC permissions
- [ ] Environment name and location set
- [ ] No sensitive data in source control

### Post-Deployment:
- [ ] Function App responds to health checks
- [ ] Static website serves content correctly
- [ ] AI Foundry integration works
- [ ] Application Insights receiving telemetry
- [ ] CORS allows frontend to call backend

### Production:
- [ ] Custom domain configured (if applicable)
- [ ] SSL certificates valid
- [ ] Monitoring alerts configured
- [ ] Log retention policies set
- [ ] Backup and recovery documented

## 🔗 Related Documentation

- **[Deployment Guide](../deployment/deployment-guide.md)** - Using these configurations in deployment
- **[Local Development](../development/local-development.md)** - Setting up local configuration
- **[Troubleshooting](../operations/troubleshooting.md)** - Fixing configuration issues
- **[Security Guide](../advanced/security.md)** - Security best practices

---

**Need help with configuration?** → Check [Troubleshooting Guide](../operations/troubleshooting.md) for common configuration issues.