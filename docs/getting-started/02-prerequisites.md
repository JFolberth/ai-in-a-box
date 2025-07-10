# Prerequisites: What You Need to Get Started

*Everything you need before deploying your AI Foundry SPA.*

## 🎯 Overview

Before you can deploy and run the AI Foundry SPA, you'll need access to a few Azure services and some development tools. Don't worry - most of these are free to get started, and we'll walk you through exactly what you need.

## ☁️ Azure Requirements

### 1. **Azure Subscription** (Required)
You need an active Azure subscription to deploy the application.

**If you don't have one:**
- **Free Account**: Get [12 months free + $200 credit](https://azure.microsoft.com/free/)
- **Student Account**: [Azure for Students](https://azure.microsoft.com/free/students/) (no credit card required)
- **Pay-as-you-go**: Standard [Azure subscription](https://azure.microsoft.com/pricing/purchase-options/pay-as-you-go/)

**Permissions needed:**
- Ability to create resource groups
- Permission to deploy Azure resources (Functions, Static Web Apps, Storage)
- Access to create managed identities and role assignments

### 2. **Azure AI Foundry Resource** (Required - Must Exist Before Deployment)

⚠️ **CRITICAL REQUIREMENT**: You need an existing Azure AI Foundry service with an "AI in A Box" agent **before** running the orchestrator deployment, OR you can let the orchestrator create new AI Foundry resources by setting `createAiFoundryResourceGroup` to `true`.

**If you don't have one:**
1. **Check with your organization** - Many companies already have AI Foundry set up
2. **Use the orchestrator** - Set `createAiFoundryResourceGroup: true` to create new AI Foundry resources automatically
3. **Create manually** - Follow the [AI Foundry Setup Guide](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstart/)
4. **Ask for access** - If your organization has AI Foundry, request access to the "AI in A Box" agent

**What you'll need to know:**
- **AI Foundry Endpoint URL** (e.g., `https://your-ai-foundry.cognitiveservices.azure.com/`)
- **Resource Group Name** containing the AI Foundry resource
- **Resource Name** of the Cognitive Services account
- **Project Name** (e.g., `firstProject`)
- **Deployment Name** (e.g., `gpt-4.1-mini`)
- **Agent Name** (should be `AI in A Box`)

### 3. **Resource Permissions** (Important)
Make sure you have these permissions in your Azure subscription:
- **Contributor** or **Owner** role on the subscription or resource group
- Ability to create and assign **managed identities**
- Permission to assign **Azure AI Developer** role

## 💻 Development Tools

### Required Tools:

**1. Azure CLI** (Required for deployment)
- **Purpose**: Deploy infrastructure and manage Azure resources
- **Install**: [Download from Microsoft](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Verify**: Run `az --version` (should be 2.50+ or later)

**2. Git** (Required for getting the code)
- **Purpose**: Clone the repository and manage code
- **Install**: [Download from git-scm.com](https://git-scm.com/downloads)
- **Verify**: Run `git --version`

### Optional Tools (for local development):

**3. Node.js 20+** (Optional - for local frontend development)
- **Purpose**: Run the frontend locally during development
- **Install**: [Download from nodejs.org](https://nodejs.org/) (choose LTS version)
- **Verify**: Run `node --version` (should be 20.0+ or later)

**4. .NET 8 SDK** (Optional - for local backend development)
- **Purpose**: Run Azure Functions locally during development
- **Install**: [Download from Microsoft](https://dotnet.microsoft.com/download/dotnet/8.0)
- **Verify**: Run `dotnet --version` (should be 8.0+ or later)

**5. Azure Functions Core Tools** (Optional - for local backend development)
- **Purpose**: Run and debug Azure Functions locally
- **Install**: `npm install -g azure-functions-core-tools@4`
- **Verify**: Run `func --version` (should be 4.0+ or later)

**6. VS Code** (Recommended)
- **Purpose**: Code editing with Azure extensions
- **Install**: [Download from Microsoft](https://code.visualstudio.com/)
- **Extensions**: Azure Account, Azure Functions, Azure Static Web Apps

## 🧠 Knowledge Prerequisites

### Required Knowledge:
- **Basic command line usage** - Running commands in terminal/PowerShell
- **Basic Git usage** - Cloning repositories, basic commands
- **Azure Portal navigation** - Finding resources, viewing resource groups

### Helpful (but not required):
- **JavaScript basics** - For customizing the frontend
- **Azure services familiarity** - Understanding of cloud concepts
- **Infrastructure as Code** - Experience with Azure Bicep or ARM templates

## 🔍 Pre-Deployment Checklist

Before starting the deployment, verify you have:

### Azure Setup:
- [ ] Active Azure subscription with sufficient permissions
- [ ] **EXISTING Azure AI Foundry resource with "AI in A Box" agent** (REQUIRED - must exist before deployment)
- [ ] AI Foundry endpoint URL, resource group, resource name, and project name
- [ ] AI Foundry deployment name and agent name
- [ ] Azure CLI installed and working (`az --version`)

### Development Environment:
- [ ] Git installed and working (`git --version`)
- [ ] Code editor of your choice (VS Code recommended)
- [ ] Terminal/command line access

### For Local Development (Optional):
- [ ] Node.js 20+ installed (`node --version`)
- [ ] .NET 8 SDK installed (`dotnet --version`)
- [ ] Azure Functions Core Tools installed (`func --version`)

## 💰 Cost Estimates

### Typical Monthly Costs (for development/testing):

**Azure Static Web Apps**
- **Free tier**: $0/month (includes custom domains, SSL)
- **Standard tier**: ~$9/month (if you need advanced features)

**Azure Functions**
- **Consumption plan**: ~$0-5/month (first 1M executions free)
- **Premium plan**: ~$50+/month (if you need always-on)

**Application Insights**
- **First 5GB free** per month
- **Additional data**: ~$2.30/GB

**Azure AI Foundry**
- **Varies by usage** - typically $0.10-1.00 per 1000 tokens
- **Development usage**: Usually under $10/month

**Total estimated cost for development**: **$0-20/month**

### Cost Optimization Tips:
- Use **consumption-based** pricing for development
- Set up **budget alerts** in Azure Portal
- Use **free tiers** where available
- **Delete resources** when not needed for testing

## 🚨 Common Setup Issues

### Issue: "Az command not found"
**Solution**: Install Azure CLI and restart your terminal
```bash
# Verify installation
az --version
# If not working, download from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

### Issue: "Insufficient permissions"
**Solution**: Contact your Azure administrator for proper role assignments
- Need **Contributor** or **Owner** role
- Need ability to create managed identities

### Issue: "Can't find AI Foundry resource"
**Solution**: 
1. **For Greenfield Deployment**: No action needed - the deployment script will create AI Foundry resources automatically
2. **For Brownfield Deployment**: The script will ask if you want to use existing AI Foundry resources. If yes, ensure you have:
   - Resource Group Name containing your AI Foundry resource
   - AI Foundry Resource Name (Cognitive Services account)
   - AI Foundry Project Name within that resource
   - Agent Name (if using an existing agent)
3. Check Azure Portal for existing AI Foundry resources in your subscription
4. Ask your organization's Azure admin about centralized AI Foundry resources

### Issue: "Node/npm commands not working"
**Solution**: Install Node.js and restart terminal
```bash
# Verify installation
node --version
npm --version
```

## 🚦 Next Steps

Once you have all prerequisites ready:

1. **[Quick Start](03-quick-start.md)** - Deploy your AI app in 15 minutes
2. **[First Steps](04-first-steps.md)** - Test and verify your deployment

### If You Need Help:
- **Azure CLI Setup**: [Installation Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **AI Foundry Setup**: [Quickstart Guide](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstart/)
- **Azure Free Account**: [Sign up guide](https://azure.microsoft.com/free/)

---

**Got everything ready?** → Continue to [Quick Start](03-quick-start.md)