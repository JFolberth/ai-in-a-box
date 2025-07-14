# Quick Start: Deploy Your AI App in 15 Minutes

*Get your AI Foundry SPA running in Azure from zero to production in 15 minutes.*

## 🚨 Important Notice: Local Development Deployment Only

**This quick-start guide is for local development and getting-started```bash
# Deploy frontend application
.\deploy-scripts\deploy-frontend-spa-code.ps1 `
  -StaticWebAppName "$staticWebAppName" `
  -ResourceGroupName "$staticWebAppResourceGroup" `
  -BackendUrl "https://$functionAppName.azurewebsites.net/api"
```es only.**

### Recommended Deployment Methods:
- **🚀 Production**: Use [GitHub Actions CI/CD pipeline](../deployment/deployment-guide.md) (preferred)
- **🧪 Development**: Use this quick-start for local testing and exploration

### What This Guide Provides:
- **Automated local deployment script** that orchestrates all components
- **Step-by-step manual process** for understanding the deployment flow
- **Optional AI Foundry and Log Analytics creation** for complete setup

## 🎯 What You'll Accomplish

This guide supports **flexible deployment options**:

### Option A: Complete New Setup
- ✅ **New AI Foundry resources** (Cognitive Services + AI Project)
- ✅ **New Log Analytics workspace** for centralized monitoring
- ✅ **AI agent deployment** from YAML configuration
- ✅ **Backend Function App** with secure AI Foundry integration
- ✅ **Frontend Static Web App** with modern chat interface

### Option B: Use Existing Resources
- ✅ **Connect to existing AI Foundry** (if you have one)
- ✅ **Use existing Log Analytics** (if you have one)
- ✅ **Deploy only the SPA components** (frontend + backend)

**Time commitment**: 10-20 minutes (depending on options chosen)  
**Cost**: $0-10/month for development usage

## 🚀 Option 1: Automated Quick Deployment (Recommended)

### Use the Automated Deployment Script

We've created an automated script that orchestrates the entire deployment process:

**Complete New Setup (Greenfield):**
```powershell
# Navigate to the project directory
cd ai-in-a-box

# Run the automated deployment script (creates everything)
.\deploy-scripts\deploy-quickstart.ps1
```

**Use Existing Resources (Brownfield):**
```powershell
# Option 1: Use command-line flags to specify what you want to reuse
.\deploy-scripts\deploy-quickstart.ps1 -UseExistingAiFoundry
.\deploy-scripts\deploy-quickstart.ps1 -UseExistingLogAnalytics
.\deploy-scripts\deploy-quickstart.ps1 -UseExistingAiFoundry -UseExistingLogAnalytics

# Option 2: Interactive prompting - script will ask what you want to reuse
.\deploy-scripts\deploy-quickstart.ps1

# For both approaches, if you choose to use existing resources, script will prompt for:
# AI Foundry: Resource Group Name, AI Foundry Resource Name, Project Name, Agent Name
# Log Analytics: Resource Group Name, Log Analytics Workspace Name
```

**What the automated script does:**
1. **Validates prerequisites** (Azure CLI, .NET SDK, Node.js)
2. **Prompts for configuration** (AI Foundry options, location, etc.)
3. **Prompts for existing resource details** (if using brownfield options)
4. **Deploys infrastructure** using Bicep templates
5. **Deploys AI agent** from YAML configuration (if creating new or updating existing)
6. **Deploys backend code** to Function App
7. **Deploys frontend code** to Static Web App
8. **Provides final URLs** and validation steps

**Advantages of automated deployment:**
- ✅ **Zero manual parameter passing** between steps
- ✅ **Interactive prompts** for existing resource details
- ✅ **Automatic output extraction** from each deployment phase
- ✅ **Error handling** with clear failure points
- ✅ **Final validation** of all endpoints

**Time commitment**: 10-15 minutes with automated script

---

## 🔧 Option 2: Manual Step-by-Step Deployment

*Choose this option if you want to understand each deployment step or customize the process.*

### Prerequisites Setup

### Prerequisites Setup

Before starting, ensure you have:
- **Azure CLI** installed and authenticated
- **.NET 8 SDK** for backend development
- **Node.js 20+** for frontend development
- **Azure subscription** with appropriate permissions

### Get the Code

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

## ⚙️ Step 1: Configure Your Deployment Options

### Choose Your Deployment Configuration

Edit the deployment parameters file to match your preferences:

```bash
# Edit the parameters file
code infra/dev-orchestrator.parameters.bicepparam
# or use any text editor: nano, vim, etc.
```

### Configuration Options

**Option A: Create New AI Foundry Resources**
```bicep
// Create new AI Foundry resources
param createAiFoundryResourceGroup = true
param aiFoundryProjectDisplayName = 'My AI Project'
param aiFoundryResourceName = 'cs-my-ai-foundry-dev-eus2'
param aiFoundryResourceGroupName = 'rg-my-ai-foundry-dev-eus2'
param aiFoundryProjectName = 'aiproj-my-ai-foundry-dev-eus2'

// Agent configuration (will be deployed automatically)
param aiFoundryAgentId = ''  // Will be set after agent deployment
param aiFoundryAgentName = 'AI in A Box'
```

**Option B: Use Existing AI Foundry Resources**
```bicep
// Use existing AI Foundry resources
param createAiFoundryResourceGroup = false
param aiFoundryResourceName = 'your-existing-ai-foundry'
param aiFoundryResourceGroupName = 'your-existing-rg'
param aiFoundryProjectName = 'your-existing-project'
param aiFoundryAgentId = 'asst_your_existing_agent_id'
param aiFoundryAgentName = 'Your Agent Name'
```

### Log Analytics Configuration

**Option A: Create New Log Analytics Workspace**
```bicep
// Create new centralized logging
param createLogAnalyticsWorkspace = true
// Uses automatic naming: rg-ai-foundry-spa-logging-dev-eus2 and la-ai-foundry-spa-logging-dev-eus2
```

**Option B: Use Existing Log Analytics Workspace**
```bicep
// Use existing Log Analytics workspace
param createLogAnalyticsWorkspace = false
param logAnalyticsResourceGroupName = 'your-existing-logging-rg'
param logAnalyticsWorkspaceName = 'your-existing-workspace'
```

### Other Configuration Options

```bicep
// Environment and location
param location = 'eastus2'  // Change to your preferred region
param tags = {
  Environment: 'dev'
  Application: 'ai-foundry-spa'
  Purpose: 'LocalDevelopment'
}
```

## 🏗️ Step 2: Deploy Infrastructure

### Deploy Everything with Bicep

```bash
# Deploy complete infrastructure (this takes 8-12 minutes)
az deployment sub create \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam" \
  --location "eastus2"
```

**What's happening during deployment:**
- ⏳ Creating resource groups (1-2 min)
- ⏳ Deploying AI Foundry resources (if createAiFoundryResourceGroup=true) (3-5 min)
- ⏳ Deploying Log Analytics workspace (if createLogAnalyticsWorkspace=true) (1-2 min)
- ⏳ Deploying Azure Function App (2-3 min)
- ⏳ Deploying Azure Static Web App (1-2 min)
- ⏳ Setting up managed identity and RBAC (1-2 min)

### Monitor Deployment Progress

```bash
# Watch the deployment status
az deployment sub list --query '[0].{Status:properties.provisioningState, Timestamp:properties.timestamp}' -o table
```

### Extract Deployment Outputs

After deployment completes, extract the outputs for the next steps:

```bash
# Get deployment outputs
$outputs = az deployment sub show --name "main-orchestrator" --query "properties.outputs" | ConvertFrom-Json

# Extract key values
$functionAppName = $outputs.functionAppName.value
$functionAppResourceGroup = $outputs.backendResourceGroupName.value
$staticWebAppName = $outputs.staticWebAppName.value
$staticWebAppResourceGroup = $outputs.frontendResourceGroupName.value
$aiFoundryEndpoint = $outputs.aiFoundryEndpoint.value

echo "Function App: $functionAppName in $functionAppResourceGroup"
echo "Static Web App: $staticWebAppName in $staticWebAppResourceGroup"
echo "AI Foundry Endpoint: $aiFoundryEndpoint"
```

## 🤖 Step 3: Deploy AI Agent (Optional)

*Skip this step if you're using an existing AI Foundry agent with a known agent ID.*

### Deploy Agent from YAML Configuration

```bash
# Deploy the AI agent to your AI Foundry project
.\deploy-scripts\deploy-agent.ps1 -AiFoundryEndpoint "$aiFoundryEndpoint"
```

**What this step does:**
- 📄 Reads agent configuration from `src/agent/ai_in_a_box.yaml`
- 🤖 Creates or updates the "AI in A Box" agent in AI Foundry
- 🆔 Returns the agent ID for backend configuration

### 🎯 Want to Customize Your AI Agent?

The deployed agent uses the configuration in `src/agent/ai_in_a_box.yaml`. To customize the agent's personality, expertise, or behavior:

**Quick Customization:**
1. Edit `src/agent/ai_in_a_box.yaml` - update the `instructions` field
2. Re-run: `.\deploy-scripts\deploy-agent.ps1 -AiFoundryEndpoint "$aiFoundryEndpoint" -Force`
3. Test the changes in your deployed SPA

**📖 Complete Customization Guide:** See **[AI Agent Customization Guide](../configuration/customization.md)** for:
- YAML schema reference and all available properties
- Prompt engineering best practices and examples
- 5 ready-to-use agent templates (DevOps, Customer Support, Security, etc.)
- Advanced configuration options and troubleshooting

### Capture Agent ID

```bash
# The deploy-agent script will output the agent ID
# Copy this ID for the next step
$agentId = "asst_generated_agent_id_here"
```

## 📦 Step 4: Deploy Application Code

### Deploy Backend Function App

```bash
# Deploy backend with agent configuration
.\deploy-scripts\deploy-backend-func-code.ps1 `
  -FunctionAppName "$functionAppName" `
  -ResourceGroupName "$functionAppResourceGroup" `
  -AgentId "$agentId" `
  -AgentName "AI in A Box" `
  -AiFoundryEndpoint "$aiFoundryEndpoint"
```

**What this step does:**
- 🔨 Builds the .NET Function App
- 📦 Creates deployment package
- 🚀 Deploys to Azure Functions
- ⚙️ Updates Function App settings with agent configuration
- 🏥 Tests health endpoint

### Deploy Frontend Static Web App

```bash
# Deploy frontend application
& "C:\Users\BicepDeveloper\ai-in-a-box\deploy-scripts\deploy-frontend-spa-code.ps1" `
  -StaticWebAppName "$staticWebAppName" `
  -ResourceGroupName "$staticWebAppResourceGroup" `
  -BackendApiUrl "https://$functionAppName.azurewebsites.net/api"
```

**What this step does:**
- 📱 Builds the frontend SPA with Vite
- 🔧 Configures backend API endpoint
- 📤 Deploys to Azure Static Web Apps
- 🌐 Provides the final application URL

## ✅ Step 5: Verify Your Deployment

### Get Your Application URLs

```bash
# Get the Static Web App URL
$frontendUrl = az staticwebapp show \
  --name "$staticWebAppName" \
  --resource-group "$staticWebAppResourceGroup" \
  --query "defaultHostname" -o tsv

# Get the Function App URL  
$backendUrl = az functionapp show \
  --name "$functionAppName" \
  --resource-group "$functionAppResourceGroup" \
  --query "defaultHostName" -o tsv

echo "🎉 Deployment Complete!"
echo "Frontend URL: https://$frontendUrl"
echo "Backend URL: https://$backendUrl"
echo "Health Check: https://$backendUrl/api/health"
```

### Test Your Application

1. **Open the Frontend URL** in your browser
2. **Start a conversation** with the AI assistant
3. **Test the health endpoint** to verify backend connectivity

### Quick Health Check

```bash
# Test the backend health endpoint
curl "https://$backendUrl/api/health"

# Expected response: {"status":"healthy","aiFoundryConnection":{"status":"connected"}}
```

---

## 🎉 Success! Your AI App is Live

If everything worked correctly, you now have:

### ✅ Working Application
- **Frontend**: Modern chat interface at your Static Web App URL
- **Backend**: Secure API proxy connecting to AI Foundry
- **AI Integration**: Real conversations with persistent memory
- **Monitoring**: Application Insights for telemetry and logging

### ✅ Azure Resources Created
Based on your configuration choices, you now have:

**Always Created:**
- **Function App**: Backend API with managed identity
- **Static Web App**: Frontend hosting with CDN
- **Storage Account**: Function App storage
- **App Service Plan**: Consumption-based hosting
- **Application Insights**: Backend monitoring

**Conditionally Created (if opted in):**
- **AI Foundry Resources**: Cognitive Services + AI Hub/Project
- **Log Analytics Workspace**: Centralized logging
- **AI Agent**: Deployed from YAML configuration

### ✅ Security Configuration
- **Managed Identity**: Secure AI Foundry access (no stored credentials)
- **RBAC**: Least-privilege roles (Azure AI Developer, Cognitive Services OpenAI User)
- **CORS**: Restricted to your frontend domain
- **HTTPS**: End-to-end encryption
- **Resource Isolation**: Multi-resource group architecture

## 🔧 Quick Customization

Want to make it your own? Here are some quick customizations:

### Change the Agent Prompt
Edit the AI agent behavior in your AI Foundry resource (instructions in [Configuration Guide](../configuration/ai-foundry-setup.md))

### Update the UI
Modify colors, layout, and branding in `src/frontend/` (see [Development Guide](../development/local-development.md))

### Add Features
Extend functionality with additional API endpoints (see [Customization Guide](../configuration/customization.md))

## 🚨 Troubleshooting Quick Fixes

### Issue: Infrastructure Deployment Failed
```bash
# Check deployment status and errors
az deployment sub show --name "main-orchestrator" --query "properties.error" -o table

# Common fixes:
# 1. Check user permissions for resource creation
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all

# 2. Verify subscription quota for the selected region
az vm list-usage --location "eastus2" -o table
```

### Issue: Agent Deployment Failed
```bash
# Verify AI Foundry endpoint accessibility
curl "$aiFoundryEndpoint/health"

# Check authentication and permissions
az cognitiveservices account show --name "$aiFoundryResourceName" --resource-group "$aiFoundryResourceGroupName"
```

### Issue: Backend Code Deployment Failed
```bash
# Verify Function App is running
az functionapp show --name "$functionAppName" --resource-group "$functionAppResourceGroup" --query "state"

# Check for build errors
dotnet build "C:\Users\BicepDeveloper\ai-in-a-box\src\backend\AIFoundryProxy.csproj"

# Verify managed identity permissions
az role assignment list --scope "/subscriptions/$(az account show --query id -o tsv)" --query "[?principalType=='ServicePrincipal' && contains(roleDefinitionName, 'AI')]"
```

### Issue: Frontend Can't Connect to Backend
```bash
# Check Function App CORS settings
az functionapp cors show --name "$functionAppName" --resource-group "$functionAppResourceGroup"

# Verify backend API is responding
curl "https://$functionAppName.azurewebsites.net/api/health"

# Check Static Web App configuration
az staticwebapp show --name "$staticWebAppName" --resource-group "$staticWebAppResourceGroup" --query "customDomains"
```

## 🚦 Next Steps

Now that your AI app is running:

1. **[First Steps](04-first-steps.md)** - Test and verify all features work
2. **[Development Guide](../development/local-development.md)** - Set up local development environment
3. **[Configuration Guide](../configuration/)** - Customize your setup and add features
4. **[Production Deployment](../deployment/deployment-guide.md)** - Set up GitHub Actions CI/CD for production
5. **[Troubleshooting](../operations/troubleshooting.md)** - Fix common issues

## 📞 Production Deployment

**⚠️ Important**: This quick-start creates a development environment. For production:

### Recommended Production Workflow:
1. **Fork this repository** to your GitHub account
2. **Set up GitHub Actions** following the [Deployment Guide](../deployment/deployment-guide.md)
3. **Configure environment-specific parameters** for staging/production
4. **Use Azure Deployment Environments** for team collaboration
5. **Implement proper CI/CD pipeline** with testing and approval gates

### Why GitHub Actions for Production:
- ✅ **Automated testing** before deployment
- ✅ **Environment promotion** (dev → staging → prod)
- ✅ **Secret management** with GitHub secrets
- ✅ **Rollback capabilities** if issues occur
- ✅ **Audit trail** of all deployments
- ✅ **Team collaboration** with pull request reviews

## 📞 Need Help?

### Common Issues:
- **[Troubleshooting Guide](../operations/troubleshooting.md)** - Solutions to common problems
- **[Configuration Issues](../configuration/environment-variables.md)** - Fix configuration problems
- **[Local Development](../development/local-development.md)** - Set up your dev environment

### Community Support:
- **[GitHub Issues](https://github.com/JFolberth/ai-in-a-box/issues)** - Report bugs or ask questions
- **[Azure AI Community](https://techcommunity.microsoft.com/t5/azure-ai/ct-p/AzureAI)** - Connect with other developers

---

**🎉 Congratulations!** Your AI Foundry SPA is now live and ready to use. → Continue to [First Steps](04-first-steps.md) to test all features, or set up [Production Deployment](../deployment/deployment-guide.md) for your team.
