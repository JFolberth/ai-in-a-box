# AI Foundry SPA

A modern single-page application (SPA) that provides an interactive chat interface with [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) endpoints. Built with JavaScript and deployed on [Azure](https://learn.microsoft.com/en-us/azure/) using infrastructure as code.


## 🚀 Quick Start

### Infrastructure Deployment
1. **Deploy infrastructure** using [Azure Deployment Environments (ADE)](https://learn.microsoft.com/en-us/azure/deployment-environments/) or [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) directly
2. **Deploy application code** using the specialized code-only deployment scripts

### Local Development
1. **Prerequisites**: [Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-overview) 20+, [.NET 8 SDK](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8), [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/), [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
2. **Setup**: Follow the [Setup Guide](documentation/SETUP.md) for detailed instructions
3. **Develop**: See [Development Guide](documentation/DEVELOPMENT.md) for local development

```bash
# Quick local development
npm install -g azure-functions-core-tools@4
cd src/frontend && npm install && npm run dev
cd ../backend && func start
```

### Code Deployment to Existing Infrastructure
```powershell
# Deploy backend code to existing Function App
./deploy-scripts/deploy-backend-func-code.ps1 -FunctionAppName "func-name" -ResourceGroupName "rg-name"

# Deploy frontend code to existing Static Web App  
./deploy-scripts/deploy-frontend-spa-code.ps1 -StaticWebAppName "swa-name" -ResourceGroupName "rg-name"
```

## 🏗 Architecture

**Multi-resource group architecture** with security and scalability in mind:

- **Frontend**: Vanilla JavaScript SPA hosted on [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- **Backend**: C# [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) with system-assigned [managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)  
- **AI Integration**: AI in A Box agent through AI Foundry with least-privilege access
- **Infrastructure**: [Azure Verified Modules (AVM)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/avm/) Azure Bicep templates
- **Monitoring**: [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) with consolidated [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)

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

| Guide | Description |
|-------|-------------|
| [Setup Guide](documentation/SETUP.md) | Initial deployment and configuration |
| [Deployment Guide](documentation/DEPLOYMENT_GUIDE.md) | Comprehensive deployment scenarios and script usage |
| [Development Guide](documentation/DEVELOPMENT.md) | Local development workflow and tools |
| [Configuration Guide](documentation/CONFIGURATION.md) | Environment variables and service configuration |
| [Infrastructure Guide](documentation/INFRASTRUCTURE.md) | Architecture details and deployment patterns |
| [Multi-RG Architecture](documentation/MULTI_RG_ARCHITECTURE.md) | Resource group design decisions |
| [Azure Deployment Environments](documentation/AZURE_DEPLOYMENT_ENVIRONMENTS.md) | ADE catalog definitions and schema compliance |
| [Public Mode Setup](documentation/PUBLIC_MODE_SETUP.md) | Authentication and security configuration |
| [Thread Persistence](documentation/THREAD_PERSISTENCE_FIX.md) | Conversation state management |
| [Browser Limitations](documentation/AI_FOUNDRY_BROWSER_LIMITATIONS.md) | Browser compatibility notes |
| [Testing Guide](tests/TEST.md) | Test scripts and validation procedures |
| [Frontend Testing](src/frontend/TESTING.md) | Frontend unit tests and CI integration |

## 🛠 Development Environments

- **[DevContainers](https://learn.microsoft.com/en-us/devcontainers/)**: VS Code development containers with pre-configured tools
- **[Azure DevBox](https://learn.microsoft.com/en-us/azure/dev-box/)**: Microsoft DevBox configuration for team development
- **Local**: Manual setup with Node.js, .NET 8, and Azure CLI

See [Development Guide](documentation/DEVELOPMENT.md) for detailed setup instructions.

## 🧪 Testing

The project includes comprehensive unit tests for both frontend and backend components:

### Frontend Testing
- **72 unit tests** covering core functionality, UI interactions, and data management
- **[Jest](https://learn.microsoft.com/en-us/shows/beginners-series-to-node-js/testing-with-jest) + jsdom** testing environment with comprehensive mocking
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

For detailed information, start with the [Setup Guide](documentation/SETUP.md) or explore the [Documentation](documentation/) folder.
