# AI Foundry SPA

A beginner-friendly, production-ready single-page application (SPA) that demonstrates how to build AI-powered chat interfaces using [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/). Perfect for developers new to AI Foundry who want to see it in action and use it as a foundation for their own AI applications.


## 🚀 Quick Start

**⚠️ IMPORTANT: AI Foundry Required Dependency**

This application requires an **existing Azure AI Foundry resource** with an "AI in A Box" agent before deployment. Due to circular dependencies in Azure's resource model, the orchestrator cannot create AI Foundry resources automatically.

**New to Azure AI Foundry?** Start with our beginner-friendly guide:

### 15-Minute Getting Started Journey
1. **[What is AI Foundry?](docs/getting-started/00-what-is-ai-foundry.md)** - Understanding Azure AI Foundry (5 min read)
2. **[Project Overview](docs/getting-started/01-project-overview.md)** - What this app does (3 min read)
3. **[Prerequisites](docs/getting-started/02-prerequisites.md)** - What you need including AI Foundry setup (2 min setup)
4. **[Quick Start](docs/getting-started/03-quick-start.md)** - Deploy in 15 minutes
5. **[First Steps](docs/getting-started/04-first-steps.md)** - Verify and test (5 min)

### Already Familiar with AI Foundry?

**⚠️ Prerequisite**: Ensure you have an existing AI Foundry resource before deployment. See [Prerequisites](docs/getting-started/02-prerequisites.md) for setup instructions.

**Local Development:**
```bash
git clone https://github.com/JFolberth/ai-in-a-box.git
cd ai-in-a-box
# See docs/development/local-development.md for complete setup
```

**Quick Deploy to Azure:**
```bash
# First: Update infra/dev-orchestrator.parameters.bicepparam with your AI Foundry details
az deployment sub create \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam" \
  --location "eastus2"
```

## 🏗 Architecture

**Multi-resource group architecture** with security and scalability in mind:

- **Frontend**: Vanilla JavaScript SPA hosted on [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- **Backend**: C# [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) with system-assigned [managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)  
- **AI Integration**: AI in A Box agent through AI Foundry with least-privilege access
- **Infrastructure**: [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) Azure Bicep templates
- **Monitoring**: [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) with consolidated [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)

### 🔧 AI Foundry Dependency Constraint

**Important Technical Note**: Due to a circular dependency in Azure's resource model, AI Foundry resources (Cognitive Services + Project) cannot be created by the orchestrator and must exist before deployment. The `createAiFoundryResourceGroup` parameter exists for potential future automation when Azure resolves this platform limitation.

## 🔄 CI/CD Pipeline

**Fully automated** build, validation, and deployment pipeline for main branch:

- **Frontend Build**: Node.js build, testing, and artifact generation
- **Backend Build**: .NET build, testing, and publish artifacts  
- **Azure Bicep Validation**: Infrastructure what-if validation using Azure CLI
- **Infrastructure Deployment**: Automated deployment to dev environment on main branch
- **Backend Code Deployment**: Automatic deployment of Azure Functions code after infrastructure
- **Frontend Code Deployment**: Automatic deployment of Static Web App code after backend
- **Parallel Execution**: Build and validation jobs run simultaneously for fast feedback

### 🚀 Automated Deployment Flow (Main Branch)

1. **Build & Validate** - Frontend, backend, and infrastructure validation run in parallel
2. **Deploy Infrastructure** - Azure Bicep templates deploy Azure resources to dev environment  
3. **Deploy Backend Code** - Azure Functions code deployed automatically using infrastructure outputs
4. **Deploy Frontend Code** - Static Web App code deployed automatically with backend integration
5. **Ready to Use** - Complete application is deployed and accessible

**✅ Zero Manual Intervention**: Pushing to main branch triggers complete deployment automatically

### Azure Bicep Infrastructure Validation

The CI pipeline includes comprehensive Azure Bicep template validation:

```bash
# Validates all infrastructure templates using what-if commands
- Main orchestrator (subscription scope)
- Backend environment (resource group scope) 
- Frontend environment (resource group scope)
```

### Azure Deployment Environment (ADE) Testing

**ADE integration testing** ensures deployment environment compatibility:

- ✅ **Schema Validation**: Validates ADE catalog definitions and environment schema
- ✅ **Parameter Compliance**: Ensures parameter compatibility with ADE requirements  
- ✅ **Template Testing**: Available via workflow configuration for ADE deployment testing
- ✅ **Enterprise Ready**: Supports DevCenter and project-based deployments

**Configuration**: Uses `infra/environments/frontend/ade.parameters.json` and `infra/environments/backend/ade.parameters.json` for enterprise DevCenter setup.

**Setup Requirements**: Configure `AZURE_CREDENTIALS` secret for Azure authentication. See [Bicep Validation Guide](.github/BICEP_VALIDATION.md) for details.

## 📚 Documentation

**New to AI Foundry?** → Start with **[Getting Started Guide](docs/getting-started/00-what-is-ai-foundry.md)**

### Quick Navigation by Task:
| What do you want to do? | Guide |
|-------------------------|-------|
| **First time using AI Foundry** | [Getting Started](docs/getting-started/) |
| **Deploy the app quickly** | [Quick Start](docs/getting-started/03-quick-start.md) |
| **Set up local development** | [Local Development](docs/development/local-development.md) |
| **Customize the AI or UI** | [Customization Guide](docs/configuration/customization.md) |
| **Deploy to production** | [Deployment Guide](docs/deployment/deployment-guide.md) |
| **Fix issues** | [Troubleshooting](docs/operations/troubleshooting.md) |
| **Understand the architecture** | [Infrastructure Guide](docs/deployment/infrastructure.md) |

### Complete Documentation
📖 **[Full Documentation Hub](docs/README.md)** - Browse all guides organized by topic

### Legacy Documentation
The original documentation in the `documentation/` folder is still available but is being phased out in favor of the new organized structure in `docs/`.

## 🛠 Development Environments

- **[DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)**: VS Code development containers with pre-configured tools
- **[Azure DevBox](https://learn.microsoft.com/en-us/azure/dev-box/)**: Microsoft DevBox configuration for team development
- **Local**: Manual setup with Node.js, .NET 8, and Azure CLI

See **[Local Development Guide](docs/development/local-development.md)** for detailed setup instructions.

## 🧪 Testing

The project includes comprehensive unit tests for both frontend and backend components:

### Frontend Testing
- **72 unit tests** covering core functionality, UI interactions, and data management
- **[Jest](https://jestjs.io/) + jsdom** testing environment with comprehensive mocking
- **CI integration** with automated test execution
- See [Frontend Testing Guide](src/frontend/TESTING.md) for details

### Backend Testing  
- **C# unit tests** for Azure Functions endpoints and business logic
- **[xUnit framework](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-dotnet-test)** with mock testing patterns
- Coverage of AI Foundry integration and error handling

### Running Tests
```bash
# Frontend tests
cd src/frontend
npm test                    # Run all tests
npm run test:coverage      # Run with coverage
npm run test:ci           # CI mode

# Backend tests  
cd src/backend/tests/AIFoundryProxy.Tests
dotnet test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the coding standards in [.github/copilot-instructions.md](.github/copilot-instructions.md)
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🚦 Next Steps

**First time here?** → **[What is AI Foundry?](docs/getting-started/00-what-is-ai-foundry.md)**

**Ready to deploy?** → **[Quick Start Guide](docs/getting-started/03-quick-start.md)**

**Need help?** → **[Troubleshooting Guide](docs/operations/troubleshooting.md)**

For detailed information, explore the **[Complete Documentation Hub](docs/README.md)**.
