# AI Foundry SPA

A modern single-page application (SPA) built with JavaScript that integrates with AI Foundry endpoints and can be hosted on Azure Storage Static Websites.

## 🏗2. **The container will automatically:**
   - Install Node.js 20, .NET 8 SDK, Azure CLI, and Azure Functions Core Tools
   - Configure VS Code extensions for Bicep, Azure Functions, and C#
   - Set up port forwarding for development servers (5173, 4173, 7071)
   - Run `npm install` in the frontend directory and configure Azure toolinghitecture

This project uses a **modular, multi-resource group architecture**:
- **Frontend**: Vanilla JavaScript SPA with Vite build system
- **Backend**: C# Azure Function App for AI Foundry proxy
- **Authentication**: **Public mode** - Function App uses system-assigned managed identity for secure AI Foundry access
- **Infrastructure**: Azure Verified Modules (AVM) Bicep templates with orchestrator pattern
- **Monitoring**: Separate Application Insights instances for frontend and backend
- **AI Integration**: CancerBot agent through AI Foundry endpoints with Azure AI Developer role
- **Load Testing**: PowerShell test suite for performance validation
- **Development**: DevContainer and DevBox configurations for consistent development environments

### Resource Groups
- **Frontend RG**: Storage Account for static website hosting + Application Insights
- **Backend RG**: Function App + Storage + App Service Plan + Application Insights
- **Cross-RG RBAC**: Function App has Azure AI Developer access to AI Foundry resource

## 🚀 Features

- Interactive chat interface with AI Foundry endpoints
- **CancerBot Agent Integration** - Specialized AI agent for cancer-related queries
- Multi-environment support (dev, staging, production)
- **Public mode deployment** with **system-assigned managed identity** for secure backend AI access
- Real-time conversation history
- Modern, responsive UI
- Static website hosting on Azure Storage
- **Azure Verified Modules (AVM)** for infrastructure as code
- Application Insights monitoring with consolidated Log Analytics
- PowerShell test suite for endpoint validation

## 📋 Prerequisites

### Core Requirements
- **Node.js 20+** and npm (for frontend development)
- **.NET 8 SDK** (for backend Function App development)
- **Azure CLI** with Bicep extension
- **Azure Functions Core Tools v4** (for local Function App development)
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

# Install Bicep
az bicep install
az extension add --name bicep
```

### Development Environment Options

#### Option A: DevContainer (Recommended for cross-platform)
- **VS Code** with Dev Containers extension
- **Docker Desktop**
- Automatically installs all tools and extensions

#### Option B: DevBox (Windows only)
- **Windows 11** with DevBox access
- **Visual Studio 2022 Enterprise** included
- Pre-configured with all development tools

#### Option C: Local Development
- Manual installation of all prerequisites above
- Requires individual tool management

## 🛠️ Development Setup

### Option 1: Local Development

1. **Clone and install dependencies:**
   ```bash
   git clone <repository-url>
   cd ai-in-a-box
   npm install
   ```

2. **Set up backend Function App:**
   ```bash
   # Build the Function App
   cd src/backend
   dotnet build
   
   # Create local settings file
   cp local.settings.json.example local.settings.json
   # Edit local.settings.json with your AI Foundry configuration
   
   # Start Function App locally (runs on http://localhost:7071)
   func start
   ```

3. **Configure frontend environment variables:**
   ```bash
   # Return to root directory and navigate to frontend
   cd src/frontend
   cp .env.example .env
   ```
   Update the `.env` file with your AI Foundry configuration and backend URL.

4. **Start frontend development server:**
   ```bash
   # From src/frontend directory
   npm run dev
   ```

5. **Access the application:**
   - **Frontend**: http://localhost:5173 (or http://localhost:5174 if 5173 is in use)
   - **Backend API**: http://localhost:7071
   - **Function Admin**: http://localhost:7071/admin/functions

### Option 2: DevContainer

1. **Open in VS Code:**
   ```bash
   code .
   ```

2. **Reopen in container** when prompted, or use Command Palette:
   ```
   Dev Containers: Reopen in Container
   ```

3. **The container will automatically:**
   - Install Node.js 20, .NET 8 SDK, Azure CLI, and Azure Functions Core Tools
   - Configure VS Code extensions for Bicep, Azure Functions, and C#
   - Set up port forwarding for development servers (3000, 4173, 7071)
   - Run `npm install` and configure Azure tooling

### Option 3: DevBox

1. **Create DevBox** using the provided image definition:
   ```yaml
   # Uses imageDefinition.yaml configuration
   ```

2. **The DevBox includes:**
   - Visual Studio 2022 Enterprise
   - All development tools pre-installed
   - Pre-configured VS Code settings
   - Azure Functions Core Tools via WinGet

### Option 2: DevContainer (Codespaces/Docker)

1. Open in GitHub Codespaces or VS Code with Dev Containers extension
2. The container will automatically set up the development environment with:
   - Node.js 20+
   - Azure CLI with Bicep extension
   - Bicep CLI and VS Code extension
   - All necessary development tools
3. Run `npm install` and `npm run dev`

### Option 3: DevBox

1. Create a DevBox using the `devbox/imageDefinition.yaml`
2. The DevBox will pre-install all required tools including:
   - Node.js LTS
   - Azure CLI with Bicep support
   - Visual Studio Code with Bicep extension
   - PowerShell and Git
3. Clone the repository and start developing

## ☁️ Azure Infrastructure

### Modular Deployment with Azure CLI

The infrastructure uses an **orchestrator pattern** that deploys frontend and backend to separate resource groups.

1. **Login to Azure:**
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

2. **Deploy infrastructure (creates resource groups automatically):**
   ```bash
   az deployment sub create \
     --location eastus \
     --template-file infra/main-orchestrator.bicep \
     --parameters infra/dev-orchestrator.parameters.bicepparam
   ```

   Or use the deployment scripts:
   ```bash
   # PowerShell
   ./deploy.ps1 -SubscriptionId "your-subscription-id" -Location "eastus"
   
   # Bash
   ./deploy.sh -s "your-subscription-id" -l "eastus"
   ```

3. **Infrastructure created:**
   - Frontend Resource Group: `rg-ai-foundry-spa-frontend-dev-{token}`
   - Backend Resource Group: `rg-ai-foundry-spa-backend-dev-{token}`
   - Cross-resource group RBAC for AI Foundry access

4. **Build and deploy .NET Function App backend:**
   ```bash
   # Build the Function App
   cd src/backend
   dotnet build --configuration Release
   
   # Deploy to Azure Function App
   func azure functionapp publish <function-app-name>
   cd ../..
   ```

5. **Build and upload frontend website:**
   ```bash
   # Navigate to frontend directory
   cd src/frontend
   npm run build:dev
   
   # Enable static website hosting (if not already enabled)
   az storage blob service-properties update \
     --account-name staifrontspa001 \
     --resource-group rg-ai-foundry-spa-frontend-dev-001 \
     --static-website \
     --index-document index.html \
     --404-document index.html
   
   # Upload files
   az storage blob upload-batch \
     --destination '$web' \
     --source ./dist \
     --account-name staifrontspa001 \
     --auth-mode login
   ```

### Alternative: Deployment Scripts

#### PowerShell (Windows)
```powershell
./deploy.ps1 -ResourceGroupName "rg-ai-foundry-spa-dev" -Location "eastus"
```

#### Bash (Linux/macOS/WSL)
```bash
./deploy.sh -g "rg-ai-foundry-spa-dev" -l "eastus"
```

Both scripts support additional options:
- `-SkipBuild` (PowerShell) or `--skip-build` (Bash): Skip the npm build step
- `-ParametersFile` (PowerShell) or `-p` (Bash): Use a different parameters file

1. **Deploy infrastructure:**
   ```bash
   az deployment sub create \\
     --location eastus \\
     --template-file infra/main-orchestrator.bicep \\
     --parameters infra/dev-orchestrator.parameters.bicepparam
   ```

2. **Build and deploy Function App backend:**
   ```bash
   cd src/backend
   dotnet build --configuration Release
   func azure functionapp publish <function-app-name>
   cd ../..
   ```

3. **Build and upload frontend website:**
   ```bash
   npm run build
   az storage blob upload-batch \\
     --destination $web \\
     --source ./dist \\
     --account-name <storage-account-name>
   ```

## 🔧 Configuration

### AI Foundry Endpoints

Configure your AI Foundry endpoints in `infra/dev-orchestrator.parameters.bicepparam`:

```bicep
using 'main-orchestrator.bicep'

param aiFoundryEndpoint = 'https://your-ai-foundry-dev.azureml.net'
param aiFoundryDeployment = 'gpt-4'
param aiFoundryAgentName = 'CancerBot'
```

## ✅ Verify Installation

Run these commands to verify all tools are installed correctly:

```bash
# Check Node.js version
node --version  # Should be 20.x or higher

# Check npm version
npm --version

# Check .NET version
dotnet --version  # Should be 8.0.x

# Check Azure CLI
az --version

# Check Bicep
az bicep version

# Check Azure Functions Core Tools
func --version  # Should be 4.x

# Check if all tools work together
az account show  # Should show your Azure account
```

### Expected Output Examples:
```bash
$ node --version
v20.11.0

$ dotnet --version
8.0.204

$ func --version
4.0.5530

$ az bicep version
Bicep CLI version 0.24.166
```

If any command fails, refer to the [Prerequisites](#📋-prerequisites) section for installation instructions.

## 📁 Project Structure

```
ai-in-a-box/
├── src/                          # Source code
│   ├── frontend/                 # Frontend SPA (Vanilla JS + Vite)
│   │   ├── main.js              # Application entry point
│   │   ├── ai-foundry-client-backend.js # AI Foundry backend proxy client
│   │   ├── style.css            # Styles
│   │   ├── index.html           # Main HTML file
│   │   ├── package.json         # Node.js dependencies
│   │   ├── .env                 # Local development environment
│   │   ├── .env.production      # Production environment
│   │   └── environments/        # Environment configurations
│   └── backend/                  # Backend Function App (C# .NET 8)
│       ├── AIFoundryProxyFunction.cs # HTTP trigger function
│       ├── Program.cs           # Function App startup
│       ├── AIFoundryProxy.csproj # Project file
│       ├── host.json           # Function App configuration
│       └── local.settings.json # Local development settings
├── infra/                        # Bicep infrastructure (modular design)
│   ├── main-orchestrator.bicep  # Subscription-level orchestrator
│   ├── dev-orchestrator.parameters.bicepparam # Development parameters
│   └── modules/                 # Infrastructure modules
│       ├── frontend.bicep       # Frontend resources (Storage, App Insights)
│       ├── backend.bicep        # Backend resources (Function App, App Insights)
│       └── rbac.bicep          # Cross-resource group RBAC
├── devbox/                      # DevBox configuration
│   └── imageDefinition.yaml    # DevBox image definition
├── .devcontainer/               # DevContainer configuration
│   └── devcontainer.json
├── tests/                       # Testing scripts
│   ├── Test-FunctionEndpoints.ps1 # PowerShell endpoint tests
│   └── README.md               # Testing documentation
├── deploy-frontend-only.ps1     # Frontend-only deployment script
├── deploy.ps1                   # Full deployment script
├── vite.config.js              # Vite build configuration (root level)
└── ai-in-a-box.sln             # Visual Studio solution file
```

## 🔒 Security

- All credentials managed via Azure Managed Identity (no client-side secrets)
- HTTPS-only communication
- CORS properly configured for frontend domain
- **Public mode** - no user authentication required
- **Backend proxy pattern** - AI Foundry credentials never exposed to browser
- Minimum TLS 1.2

## 🚀 Available Scripts

### Frontend (from root directory)
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run deploy` - Deploy to Azure Storage (requires environment setup)

### Backend (from src/backend directory)
- `dotnet build` - Build the Function App
- `dotnet build --configuration Release` - Build for production
- `func start` - Start Function App locally (requires Azure Functions Core Tools)
- `func azure functionapp publish <function-app-name>` - Deploy to Azure

### Infrastructure
- `./deploy.ps1` - Deploy infrastructure and applications (PowerShell)
- `./deploy.sh` - Deploy infrastructure and applications (Bash)

### Verification & Debugging
- `node --version` - Check Node.js version
- `dotnet --version` - Check .NET SDK version
- `func --version` - Check Azure Functions Core Tools version
- `az --version` - Check Azure CLI version
- `az bicep version` - Check Bicep version
- `az account show` - Verify Azure authentication

### Testing & Validation
- `./tests/Test-FunctionEndpoints.ps1` - Test Function App endpoints and conversation threading (PowerShell)

### CI/CD Secrets

For GitHub Actions deployment, configure the following repository secrets:

| Secret | Description | Format |
|--------|-------------|---------|
| `AZURE_CREDENTIALS` | Azure service principal credentials | JSON object with clientId, clientSecret, subscriptionId, tenantId |

Example `AZURE_CREDENTIALS` format:
```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

To create the service principal:
```bash
az ad sp create-for-rbac \
  --name "ai-foundry-spa-github-actions" \
  --role "Contributor" \
  --scopes "/subscriptions/your-subscription-id" \
  --sdk-auth
```

## 🌐 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_BACKEND_URL` | Backend Function App URL | Yes |
| `VITE_USE_BACKEND` | Enable backend proxy mode | Yes (set to true) |
| `VITE_PUBLIC_MODE` | Enable public mode | Yes (set to true) |
| `VITE_AI_FOUNDRY_AGENT_NAME` | AI Foundry agent name | Yes |
| `VITE_AI_FOUNDRY_ENDPOINT` | AI Foundry endpoint URL | Yes |
| `VITE_AI_FOUNDRY_DEPLOYMENT` | AI model deployment name | Yes |
| `VITE_STORAGE_ACCOUNT_NAME` | Azure Storage account name | For deployment |

## 📚 Additional Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [AI Foundry Documentation](https://docs.microsoft.com/en-us/azure/machine-learning/)
- [DevBox Documentation](https://learn.microsoft.com/en-us/azure/dev-box/concept-what-are-team-customizations)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

### Backend Function App

The project includes a C# .NET 8 Azure Function App that serves as a proxy/backend for AI Foundry interactions. This provides several benefits:

- **Security**: Keeps AI Foundry credentials on the server side
- **CORS**: Eliminates browser CORS restrictions
- **Proxy Layer**: Secure backend-to-AI-Foundry communication
- **Rate Limiting**: Server-side request throttling capabilities
- **Logging**: Comprehensive request/response logging

#### Function App Configuration

The Function App is configured with:

- **System-assigned Managed Identity**: For secure AI Foundry access
- **Azure AI Developer Role**: Least-privilege RBAC scoped to AI Foundry resource
- **Application Insights**: Integrated logging and monitoring
- **CORS**: Configured to allow frontend domain access

#### AI Foundry Polling Mechanism

The Function App implements a robust polling mechanism to handle AI Foundry agent responses:

**How Polling Works:**

1. **Request Initiation**: When a chat message is received, the function creates a new thread (or uses existing) and starts an agent run
2. **Asynchronous Processing**: AI Foundry processes the request asynchronously - the run starts with status "queued"
3. **Intelligent Polling**: The function polls the run status every 500ms until completion:
   ```
   Status Flow: queued → inprogress → completed (success) or failed (error)
   ```

**Polling Configuration:**
- **Poll Interval**: 500ms between status checks
- **Maximum Timeout**: 120 seconds (240 polls)
- **Status Tracking**: Case-insensitive status comparison
- **Retry Logic**: 3 attempts with exponential backoff for failed runs

**Polling States:**
- **Running States**: `queued`, `inprogress`, `in_progress`, `running` (continues polling)
- **Completion States**: `completed` (success), `failed` (error), `cancelled` (stopped)

**Example Flow:**
```
[18:54:42] 🏃 Started run: run_ABC123
[18:54:42] 🔄 Starting to poll for run completion. Max timeout: 120 seconds
[18:54:42] 🔄 Initial run status: queued
[18:54:44] 🔄 Status change detected: inprogress at 2.1s
[18:54:46] 🔄 Status change detected: completed at 4.3s
[18:54:46] ✅ Run completed successfully in 4.3s
[18:54:46] 🎯 Returning AI response (length: 342): I understand you're asking about survival rates...
```

**Error Handling:**
- **Timeout Protection**: Prevents indefinite waiting if AI Foundry becomes unresponsive
- **Retry Mechanism**: Automatically retries failed runs up to 3 times
- **Graceful Degradation**: Returns helpful error messages instead of technical exceptions
- **Comprehensive Logging**: Detailed logs for troubleshooting polling issues

**Performance Optimizations:**
- **Efficient Polling**: Only polls while run is actively processing
- **Smart Logging**: Reduces log noise while maintaining visibility
- **Resource Management**: Proper cleanup of threads and connections

#### Local Development

> **Note**: For installation instructions, see the [Prerequisites section](#📋-prerequisites) above.

1. **Build and run the Function App locally**:
   ```bash
   cd src/backend
   dotnet build
   func start
   ```

2. **Configure local settings** (create `local.settings.json`):
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
       "AI_FOUNDRY_ENDPOINT": "your-ai-foundry-endpoint",
       "AI_FOUNDRY_DEPLOYMENT": "your-deployment-name",
       "AI_FOUNDRY_AGENT_NAME": "CancerBot"
     }
   }
   ```

## 🔧 Local Development Storage with Azurite

This project uses Azurite to emulate Azure Storage for local development of the Function App. Azurite is installed and configured automatically in both DevBox and DevContainer environments.

### 💫 Using Azurite

1. **Start Azurite**: When developing locally, Azurite will start automatically with your VS Code instance. The `.azurite` folder in your workspace will store emulator data.

2. **Function App Configuration**: The `local.settings.json` is pre-configured for Azurite with:
   ```json
   {
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true"
     }
   }
   ```

3. **Storage Emulator URLs**: When running locally, Azurite provides these endpoints:
   - Blob Service: http://127.0.0.1:10000
   - Queue Service: http://127.0.0.1:10001
   - Table Service: http://127.0.0.1:10002

4. **Debugging**: If needed, enable debug logging in VS Code settings:
   ```json
   {
     "azurite.debug": true,
     "azurite.silent": false
   }
   ```

💡 **Tip**: The Function App will automatically connect to Azurite when running locally - no additional configuration needed.

### 🚨 Troubleshooting

1. If Azurite fails to start:
   - Check port conflicts (10000, 10001, 10002)
   - Delete `.azurite` folder and restart VS Code
   - Run `npm install -g azurite` manually

2. If Function App can't connect:
   - Verify "UseDevelopmentStorage=true" in `local.settings.json`
   - Check Azurite logs in VS Code output panel (Channel: Azurite)
   - Ensure Azurite is running (look for info messages in Output)

3. If Function App deployment fails with 403 errors:
   - **Check storage account firewall settings**: The Function App's backend storage account may have network restrictions
   - Verify the storage account allows access from Azure services or your deployment location
   - Temporarily disable firewall restrictions during deployment:
     ```bash
     # Check current firewall rules
     az storage account show --name stfnbackspa001 --resource-group rg-ai-foundry-spa-backend-dev-001 --query networkRuleSet
     
     # Temporarily allow all access for deployment
     az storage account update --name stfnbackspa001 --resource-group rg-ai-foundry-spa-backend-dev-001 --default-action Allow
     
     # Deploy your function app
     func azure functionapp publish func-ai-foundry-spa-backend-dev-001
     
     # Re-enable firewall restrictions after deployment
     az storage account update --name stfnbackspa001 --resource-group rg-ai-foundry-spa-backend-dev-001 --default-action Deny
     ```
   - Alternative: Add your deployment source IP to the storage account's allowed IP ranges
