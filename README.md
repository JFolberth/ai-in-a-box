# AI Foundry SPA

A modern single-page application (SPA) that provides an interactive chat interface with AI Foundry endpoints. Built with JavaScript and deployed on Azure using infrastructure as code.


## 🚀 Quick Start

1. **Prerequisites**: Node.js 20+, .NET 8 SDK, Azure CLI
2. **Setup**: Follow the [Setup Guide](documentation/SETUP.md) for detailed instructions
3. **Deploy**: Use the deployment scripts in `deploy-scripts/`
4. **Develop**: See [Development Guide](documentation/DEVELOPMENT.md) for local development

```bash
# Quick local development
npm install -g azure-functions-core-tools@4
cd src/frontend && npm install
cd ../backend && func start
```

## 🏗 Architecture

**Multi-resource group architecture** with security and scalability in mind:

- **Frontend**: Vanilla JavaScript SPA hosted on Azure Static Web Apps
- **Backend**: C# Azure Function App with system-assigned managed identity  
- **AI Integration**: CancerBot agent through AI Foundry with least-privilege access
- **Infrastructure**: Azure Verified Modules (AVM) Bicep templates
- **Monitoring**: Application Insights with consolidated Log Analytics

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Setup Guide](documentation/SETUP.md) | Initial deployment and configuration |
| [Development Guide](documentation/DEVELOPMENT.md) | Local development workflow and tools |
| [Configuration Guide](documentation/CONFIGURATION.md) | Environment variables and service configuration |
| [Infrastructure Guide](documentation/INFRASTRUCTURE.md) | Architecture details and deployment patterns |
| [Multi-RG Architecture](documentation/MULTI_RG_ARCHITECTURE.md) | Resource group design decisions |
| [Public Mode Setup](documentation/PUBLIC_MODE_SETUP.md) | Authentication and security configuration |
| [Thread Persistence](documentation/THREAD_PERSISTENCE_FIX.md) | Conversation state management |
| [Browser Limitations](documentation/AI_FOUNDRY_BROWSER_LIMITATIONS.md) | Browser compatibility notes |
| [Testing Guide](tests/TEST.md) | Test scripts and validation procedures |
| [Frontend Testing](src/frontend/TESTING.md) | Frontend unit tests and CI integration |

## 🛠 Development Environments

- **DevContainer**: VS Code development containers with pre-configured tools
- **DevBox**: Microsoft DevBox configuration for team development
- **Local**: Manual setup with Node.js, .NET 8, and Azure CLI

See [Development Guide](documentation/DEVELOPMENT.md) for detailed setup instructions.

## 🧪 Testing

The project includes comprehensive unit tests for both frontend and backend components:

### Frontend Testing
- **72 unit tests** covering core functionality, UI interactions, and data management
- **Jest + jsdom** testing environment with comprehensive mocking
- **CI integration** with automated test execution
- See [Frontend Testing Guide](src/frontend/TESTING.md) for details

### Backend Testing  
- **C# unit tests** for Function App endpoints and business logic
- **xUnit framework** with mock testing patterns
- Coverage of AI Foundry integration and error handling

### Running Tests
```bash
# Frontend tests
cd src/frontend
npm test                    # Run all tests
npm run test:coverage      # Run with coverage
npm run test:ci           # CI mode

# Backend tests  
cd src/tests/AIFoundryProxy.Tests
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
