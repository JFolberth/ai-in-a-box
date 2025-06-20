# Setup Instructions

## Quick Start Guide

### 1. Prerequisites Setup

#### Azure Setup
1. **Azure Subscription**: Ensure you have an active Azure subscription
2. **Azure CLI**: Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
3. **AI Foundry Resource**: Ensure you have access to an AI Foundry resource with a CancerBot agent

#### Development Tools
1. **Node.js 20+**: For frontend development
2. **.NET 8 SDK**: For backend Function App development
3. **Azure Functions Core Tools v4**: For local Function App development

### 2. Environment Configuration

1. **Frontend environment setup:**
   ```bash
   cd src/frontend
   cp .env.example .env
   ```

2. **Update `src/frontend/.env` with your values:**
   ```env
   # Backend Function App Configuration
   VITE_BACKEND_URL=http://localhost:7071/api
   VITE_USE_BACKEND=true
   VITE_PUBLIC_MODE=true

   # AI Foundry Configuration (Single Instance)
   VITE_AI_FOUNDRY_AGENT_NAME=CancerBot
   VITE_AI_FOUNDRY_ENDPOINT=https://your-ai-foundry-endpoint.azureml.net
   VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4
   ```

3. **Backend configuration:**
   ```bash
   cd src/backend
   # Edit local.settings.json with your AI Foundry configuration
   ```

4. **Update Bicep parameters:**
   ```bash
   # Edit infra/dev-orchestrator.parameters.bicepparam
   # Update AI Foundry endpoint and deployment information
   ```

### 3. Development Environment

#### Option A: Local Development
```bash
# Install frontend dependencies
cd src/frontend
npm install

# Start Azurite emulator (in a separate terminal)
azurite --silent --location .azurite

# Start Function App (in a separate terminal)
cd src/backend
dotnet build
func start

# Start frontend development server (in a separate terminal)
cd src/frontend
npm run dev
```

#### Option B: VS Code Tasks (Recommended)
Use the built-in VS Code tasks for automated setup:
1. **Start Azurite**: Run task "Start Azurite"
2. **Start Function App**: Run task "🔧 Manual Start Function App"
3. **Start Frontend**: Run task "AI Foundry SPA: Build and Run"

#### Option C: DevContainer (Recommended for consistent environment)
1. Install Docker Desktop
2. Install VS Code Dev Containers extension
3. Open project in VS Code
4. Click "Reopen in Container" when prompted
5. Use VS Code tasks to start services

#### Option D: DevBox
1. Create a DevBox in Azure
2. Use the provided `imageDefinition.yaml`
3. Clone this repository in the DevBox
4. Use VS Code tasks to start services

### 4. Azure Deployment

#### Using Azure CLI (Recommended)
```bash
# Login to Azure CLI
az login

# Deploy infrastructure using subscription-level orchestrator
az deployment sub create \
  --location eastus \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam

# Deploy Function App
cd src/backend
func azure functionapp publish func-ai-foundry-spa-backend-dev-001

# Deploy Frontend
cd ../frontend
npm run build:dev
az storage blob upload-batch \
  --destination '$web' \
  --source ./dist \
  --account-name staifrontspa001 \
  --auth-mode login
```

#### Using PowerShell Deployment Script
```powershell
# Login to Azure CLI
az login

# Run deployment script
./deploy.ps1
```

### 5. Post-Deployment Configuration

1. **Update Frontend Environment for Production:**
   - Create `src/frontend/.env.production` with production backend URL
   - Rebuild and redeploy frontend with production configuration

2. **Configure AI Foundry Access:**
   - Verify Function App has Azure AI Developer role on AI Foundry resource
   - Confirm AI Foundry endpoint configuration in Function App settings

3. **Enable Static Website Hosting:**
   ```bash
   az storage blob service-properties update \
     --account-name staifrontspa001 \
     --resource-group rg-ai-foundry-spa-frontend-dev-001 \
     --static-website \
     --index-document index.html \
     --404-document index.html
   ```

### 6. Verification

1. **Test local development:**
   ```bash
   # Frontend should be available at:
   http://localhost:5173 (or 5174 if 5173 is in use)
   
   # Function App should be available at:
   http://localhost:7071
   ```

2. **Test production deployment:**
   - Visit your Azure Static Website URL
   - Test AI conversation functionality
   - Verify Function App endpoints respond correctly

3. **Run endpoint tests:**
   ```bash
   # Test local endpoints
   ./tests/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"
   
   # Test Azure endpoints
   ./tests/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net"
   ```

### 7. Troubleshooting

#### Common Issues

**Function App Connection Failed:**
- Verify Function App is running locally or deployed to Azure
- Check CORS configuration allows frontend domain
- Ensure AI Foundry configuration is correct in Function App settings

**AI Foundry Connection Failed:**
- Verify AI Foundry endpoint URLs and deployment names
- Check Function App has Azure AI Developer role on AI Foundry resource
- Ensure network connectivity from Function App to AI Foundry

**Build Failed:**
- Verify Node.js version (20+ required)
- Clear npm cache: `npm cache clean --force`
- Delete node_modules and reinstall: `rm -rf node_modules && npm install`

**Deployment Failed:**
- Check Azure CLI authentication: `az account show`
- Verify subscription permissions
- Check resource naming conflicts
- Ensure Bicep file is valid: `az bicep build --file infra/main-orchestrator.bicep`

**Azurite Issues:**
- Check ports 10000, 10001, 10002 are not in use
- Delete `.azurite` folder and restart
- Install Azurite globally: `npm install -g azurite`

### 8. Development URLs

**Local Development:**
- Frontend: http://localhost:5173
- Function App: http://localhost:7071
- Function Admin: http://localhost:7071/admin/functions
- Azurite Blob: http://127.0.0.1:10000
- Azurite Queue: http://127.0.0.1:10001
- Azurite Table: http://127.0.0.1:10002

**Production URLs:**
- Frontend: https://staifrontspa001.z13.web.core.windows.net/
- Function App: https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net

### 9. Next Steps

- **Configure monitoring**: Application Insights is pre-configured
- **Security**: Review CORS settings and Function App access controls
- **Scaling**: Consider Azure CDN for global distribution
- **Testing**: Use the PowerShell test scripts to validate functionality

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Azure documentation links in README.md
3. Use the provided test scripts to diagnose issues
4. Check Function App logs in Azure Portal
