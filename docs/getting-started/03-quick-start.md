# Quick Start: Deploy Your AI App in 15 Minutes

*Get your AI Foundry SPA running in Azure from zero to production in 15 minutes.*

## 🎯 What You'll Accomplish

⚠️ **PREREQUISITE**: This guide assumes you have an existing Azure AI Foundry resource with an "AI in A Box" agent. If you don't have one, complete the [Prerequisites](02-prerequisites.md) first.

By the end of this guide, you'll have:
- ✅ A working AI chat application deployed to Azure
- ✅ A secure backend powered by your existing Azure AI Foundry
- ✅ A modern web interface accessible from anywhere
- ✅ Real AI conversations with persistent memory
- ✅ Complete monitoring and logging setup

**Time commitment**: 15 minutes  
**Cost**: $0-5/month for development usage

## 🚀 Step 1: Get the Code (2 minutes)

### Clone the Repository

```bash
# Clone the project
git clone https://github.com/JFolberth/ai-in-a-box.git
cd ai-in-a-box
```

### Login to Azure

```bash
# Login to your Azure account
az login

# Verify you're in the right subscription
az account show

# Set subscription if needed
# az account set --subscription "Your Subscription Name"
```

## ⚙️ Step 2: Configure Your Deployment (3 minutes)

### Update Configuration Parameters

Edit the deployment parameters file with your AI Foundry details:

```bash
# Edit the parameters file
code infra/dev-orchestrator.parameters.bicepparam
# or use any text editor: nano, vim, etc.
```

**Update these key values:**

```bicep
// Required: Your existing AI Foundry configuration (must exist before deployment)
param aiFoundryResourceGroupName = 'rg-your-ai-foundry-rg'
param aiFoundryResourceName = 'your-ai-foundry-resource'
param aiFoundryProjectName = 'firstProject'
param aiFoundryEndpoint = 'https://your-ai-foundry.cognitiveservices.azure.com/'
param aiFoundryModelDeploymentName = 'gpt-4o-mini'  // or your deployment name
param aiFoundryAgentName = 'AI in A Box'

// Required: Your user principal ID for RBAC
param userPrincipalId = 'your-user-principal-id'

// Optional: Environment and location
param environmentName = 'dev'
param location = 'eastus2'
```

### Find Your User Principal ID

```bash
# Get your user principal ID
az ad signed-in-user show --query id -o tsv
```

Copy this ID and paste it into the `userPrincipalId` parameter above.

### Find Your AI Foundry Information

**Option 1: Azure Portal**
1. Go to [Azure Portal](https://portal.azure.com)
2. Find your AI Foundry resource
3. Copy the endpoint URL from the overview page
4. Note the deployment name (usually `gpt-4` or similar)

**Option 2: Azure CLI**
```bash
# List AI Foundry resources
az cognitiveservices account list --query "[?kind=='AIServices'].[name,properties.endpoint]" -o table
```

## 🏗️ Step 3: Deploy Infrastructure (8 minutes)

### Deploy Everything with One Command

```bash
# Deploy complete infrastructure (this takes 5-8 minutes)
az deployment sub create \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam" \
  --location "eastus2"
```

**What's happening during deployment:**
- ⏳ Creating resource groups (1 min)
- ⏳ Deploying Azure Static Web Apps (2 min)
- ⏳ Deploying Azure Functions (2 min)
- ⏳ Setting up Application Insights (1 min)
- ⏳ Configuring managed identity and RBAC (2 min)

### Monitor Deployment Progress

```bash
# In another terminal, watch the deployment status
watch -n 10 "az deployment sub list --query '[0].{Status:properties.provisioningState, Timestamp:properties.timestamp}' -o table"
```

## 📦 Step 4: Deploy Application Code (2 minutes)

After infrastructure deployment completes, deploy the application code:

### Deploy Backend Code

```bash
# Navigate to backend
cd src/backend

# Build and publish
dotnet publish -c Release -o publish

# Create deployment package
cd publish
zip -r ../backend-deployment.zip .
cd ..

# Deploy to Azure Functions (replace with your actual Function App name)
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
RESOURCE_GROUP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$FUNCTION_APP_NAME" \
  --src "backend-deployment.zip"

cd ../..
```

### Deploy Frontend Code

```bash
# Navigate to frontend
cd src/frontend

# Install dependencies and build
npm install
npm run build

# Deploy to Static Web Apps (replace with your actual Static Web App name)
STATIC_APP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].name" -o tsv | head -1)
RESOURCE_GROUP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].resourceGroup" -o tsv | head -1)

# Create deployment package
cd dist
zip -r ../frontend-deployment.zip .
cd ..

# Deploy (Note: Static Web Apps deployment varies by setup)
echo "Frontend built successfully. Upload 'frontend-deployment.zip' via Azure Portal if needed."

cd ../..
```

## ✅ Step 5: Verify Your Deployment (2 minutes)

### Get Your Application URLs

```bash
# Get the Static Web App URL
FRONTEND_URL=$(az staticwebapp show \
  --name "$STATIC_APP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query "defaultHostname" -o tsv)

# Get the Function App URL  
BACKEND_URL=$(az functionapp show \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query "defaultHostName" -o tsv)

echo "🎉 Deployment Complete!"
echo "Frontend URL: https://$FRONTEND_URL"
echo "Backend URL: https://$BACKEND_URL"
echo "Health Check: https://$BACKEND_URL/api/health"
```

### Test Your Application

1. **Open the Frontend URL** in your browser
2. **Start a conversation** with the AI assistant
3. **Test the health endpoint** to verify backend connectivity

### Quick Health Check

```bash
# Test the backend health endpoint
curl "https://$BACKEND_URL/api/health"

# Expected response: {"Status":"Healthy",...}
```

## 🎉 Success! Your AI App is Live

If everything worked correctly, you now have:

### ✅ Working Application
- **Frontend**: Modern chat interface at your Static Web App URL
- **Backend**: Secure API proxy connecting to AI Foundry
- **AI Integration**: Real conversations with persistent memory

### ✅ Azure Resources Created
- **Resource Groups**: Organized infrastructure
- **Static Web App**: Frontend hosting with CDN
- **Function App**: Backend API with managed identity
- **Application Insights**: Monitoring and telemetry
- **Storage Account**: Function App storage
- **App Service Plan**: Consumption-based hosting

### ✅ Security Configuration
- **Managed Identity**: Secure AI Foundry access (no stored credentials)
- **RBAC**: Least-privilege Azure AI Developer role
- **CORS**: Restricted to your frontend domain
- **HTTPS**: End-to-end encryption

## 🔧 Quick Customization

Want to make it your own? Here are some quick customizations:

### Change the Agent Prompt
Edit the AI agent behavior in your AI Foundry resource (instructions in [Configuration Guide](../configuration/ai-foundry-setup.md))

### Update the UI
Modify colors, layout, and branding in `src/frontend/` (see [Development Guide](../development/local-development.md))

### Add Features
Extend functionality with additional API endpoints (see [Customization Guide](../configuration/customization.md))

## 🚨 Troubleshooting Quick Fixes

### Issue: Deployment Failed
```bash
# Check deployment status
az deployment sub list --query '[0].properties.error' -o table

# Common fix: Check your user permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all
```

### Issue: Frontend Can't Connect to Backend
```bash
# Verify Function App is running
az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "state"

# Check CORS settings
az functionapp cors show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME"
```

### Issue: AI Foundry Connection Failed
```bash
# Test health endpoint
curl "https://$BACKEND_URL/api/health"

# Check managed identity role assignment
az role assignment list --scope "/subscriptions/$(az account show --query id -o tsv)" --query "[?principalType=='ServicePrincipal' && roleDefinitionName=='Azure AI Developer']"
```

## 🚦 Next Steps

Now that your AI app is running:

1. **[First Steps](04-first-steps.md)** - Test and verify all features work
2. **[Configuration Guide](../configuration/)** - Customize your setup
3. **[Development Guide](../development/)** - Set up local development
4. **[Troubleshooting](../operations/troubleshooting.md)** - Fix common issues

## 📞 Need Help?

### Common Issues:
- **[Troubleshooting Guide](../operations/troubleshooting.md)** - Solutions to common problems
- **[Configuration Issues](../configuration/environment-variables.md)** - Fix configuration problems

### Community Support:
- **[GitHub Issues](https://github.com/JFolberth/ai-in-a-box/issues)** - Report bugs or ask questions
- **[Azure AI Community](https://techcommunity.microsoft.com/t5/azure-ai/ct-p/AzureAI)** - Connect with other developers

---

**🎉 Congratulations!** Your AI Foundry SPA is now live and ready to use. → Continue to [First Steps](04-first-steps.md) to test all features.