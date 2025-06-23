# Development Guide

This guide covers local development setup, workflows, and best practices for the AI Foundry SPA project.

## 🛠️ Development Setup

### Prerequisites
- **Node.js 20+** and npm (for frontend development)
- **.NET 8 SDK** (for backend Function App development)
- **Azure CLI** with Bicep extension
- **Azure Functions Core Tools v4** (for local Function App development)
- **Python 3.12+** (for development tooling and scripting, optional)
- **Azure subscription** with appropriate permissions

### Installation Commands

#### Windows
```powershell
# Node.js (using winget)
winget install OpenJS.NodeJS.LTS

# .NET 8 SDK
winget install Microsoft.DotNet.SDK.8

# Azure CLI
winget install Microsoft.AzureCLI

# Azure Functions Core Tools
winget install Microsoft.Azure.FunctionsCoreTools
# OR via npm
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Python (optional, for development tooling)
winget install Python.Python.3.12

# Install Bicep
az bicep install
az extension add --name bicep
```

#### macOS
```bash
# Node.js (using Homebrew)
brew install node@20

# .NET 8 SDK
brew install --cask dotnet-sdk

# Azure CLI
brew install azure-cli

# Azure Functions Core Tools
brew tap azure/functions
brew install azure-functions-core-tools@4

# Python (optional, for development tooling)
brew install python@3.12

# Install Bicep
az bicep install
az extension add --name bicep
```

#### Linux (Ubuntu/Debian)
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# .NET 8 SDK
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update && sudo apt-get install azure-functions-core-tools-4

# Python (optional, for development tooling)
sudo apt-get update && sudo apt-get install -y python3.12 python3.12-pip python3.12-venv

# Install Bicep
az bicep install
az extension add --name bicep
```

## 🚀 Available Scripts

### Frontend Scripts
```bash
cd src/frontend

# Development server with hot reload
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Clean build artifacts
npm run clean
```

### Backend Scripts
```bash
cd src/backend

# Build the Function App
dotnet build

# Run locally with hot reload
func start

# Clean build artifacts
dotnet clean
```

### Infrastructure Scripts
```bash
# Deploy to Azure (from root)
./deploy-scripts/deploy.ps1

# Deploy frontend only
./deploy-scripts/deploy-frontend-only.ps1

# Deploy backend only
./deploy-scripts/deploy-backend.ps1
```

## 🔧 Local Development Storage with Azurite

For local development, the backend Function App uses **Azurite** to emulate Azure Storage services.

### VS Code Tasks
Use the predefined VS Code tasks for streamlined development:

1. **Start Azurite**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start Azurite"
2. **Build and Start Function App**: `Ctrl+Shift+P` → "Tasks: Run Task" → "🔧 Manual Start Function App"
3. **Start Frontend**: `Ctrl+Shift+P` → "Tasks: Run Task" → "AI Foundry SPA: Build and Run"

### Manual Setup
```bash
# Install Azurite globally
npm install -g azurite

# Start Azurite in background
azurite --silent --location .azurite

# Start Function App
cd src/backend
func start --verbose

# Start Frontend (in new terminal)
cd src/frontend
npm run dev
```

## 🌐 Environment Variables

### Frontend Environment Variables
Create `src/frontend/environments/local.js` for local development:

```javascript
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:7071',
  aiFoundryEndpoint: 'your-ai-foundry-endpoint',
  agentName: 'AI in A Box'
};
```

### Backend Environment Variables
Update `src/backend/local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AI_FOUNDRY_ENDPOINT": "your-ai-foundry-endpoint-url",
    "AI_FOUNDRY_DEPLOYMENT": "your-deployment-name",
    "AI_FOUNDRY_AGENT_NAME": "AI in A Box"
  }
}
```

## 🔍 Debugging and Troubleshooting

### Common Issues

#### Function App Won't Start
1. Ensure Azurite is running
2. Check that .NET 8 SDK is installed
3. Verify `local.settings.json` configuration
4. Try cleaning and rebuilding: `dotnet clean && dotnet build`

#### Frontend Build Fails
1. Ensure Node.js 20+ is installed
2. Clear npm cache: `npm cache clean --force`
3. Delete node_modules and reinstall: `rm -rf node_modules && npm install`

#### CORS Issues
For local development, the backend Function App is configured to allow CORS from localhost:5173.

### Development Workflow

1. **Start Azurite** (storage emulator)
2. **Start Backend** (Function App on port 7071)
3. **Start Frontend** (Vite dev server on port 5173)
4. **Open Browser** to http://localhost:5173
5. **Make Changes** - both frontend and backend support hot reload

## 📱 DevContainer Support

The project includes a DevContainer configuration for consistent development environments:

```bash
# Open in DevContainer
code .
# VS Code will prompt to reopen in container
```

The DevContainer automatically:
- Installs Node.js 20, .NET 8 SDK, Azure CLI, and Azure Functions Core Tools
- Configures VS Code extensions for Bicep, Azure Functions, and C#
- Sets up port forwarding for development servers (5173, 4173, 7071)
- Runs `npm install` in the frontend directory and configures Azure tooling

## 🏗️ DevBox Support

For team development environments, use the DevBox configuration:

```powershell
# DevBox includes all tools and extensions automatically
# See devbox/README.md for detailed setup instructions

# Validate your DevBox setup
.\devbox\Test-DevBoxSetup.ps1

# Or run detailed validation
.\devbox\Test-DevBoxSetup.ps1 -Detailed
```

The DevBox configuration automatically installs:
- All required development tools (Node.js, .NET, Azure CLI, Python)
- VS Code with pre-configured extensions including GitHub Copilot
- Azure Functions Core Tools and Azurite
- Bicep extension and Azure AI Toolkit

See [DevBox README](../devbox/README.md) for detailed setup instructions and troubleshooting.

## 🧪 Testing

### Frontend Testing
```bash
# Navigate to frontend directory
cd src/frontend

# Install testing dependencies
npm install

# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode (for development)
npm run test:watch
```

### Manual Testing
```bash
# Test Function App endpoints
./tests/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test Azure deployment
./tests/Test-FunctionEndpoints.ps1 -BaseUrl "https://your-function-app.azurewebsites.net"
```

### Test Scripts
- `Test-FunctionEndpoints.ps1`: Validates Function App endpoints
- `Test-FunctionAppAccess.ps1`: Tests Function App accessibility
- `Test-AzuriteSetup.ps1`: Validates Azurite configuration

### Testing Best Practices
⚠️ **Important**: Always test locally before deployment. The test suite includes:
- **Unit Tests**: Test individual functions with mocks
- **Integration Tests**: Test workflows and data flow
- **Manual Tests**: Validate actual deployments

**Critical Testing Gap Addressed**: After discovering a runtime error where event handlers referenced non-existent methods, we've enhanced testing to include:
- Class instantiation validation
- Event binding verification  
- Method existence checks

See [Test Documentation](../tests/TEST.md) for comprehensive testing information.

## 🔗 Related Documentation

- [Setup Guide](SETUP.md) - Initial project setup
- [Public Mode Setup](PUBLIC_MODE_SETUP.md) - Authentication configuration
- [Multi-RG Architecture](MULTI_RG_ARCHITECTURE.md) - Infrastructure design
- [Thread Persistence Fix](THREAD_PERSISTENCE_FIX.md) - Conversation state handling
- [AI Foundry Browser Limitations](AI_FOUNDRY_BROWSER_LIMITATIONS.md) - Browser compatibility
