# AGENTS.md

AI Foundry SPA - A JavaScript Single Page Application that integrates with AI Foundry through a backend proxy, deployed to Azure Storage Static Websites using Azure CLI and Bicep templates.

## Quick Start

### Development Setup
```bash
# Clone and setup
git clone https://github.com/JFolberth/ai-in-a-box.git
cd ai-in-a-box

# Install frontend dependencies
cd src/frontend
npm install
cd ../..

# Start local development (in order)
# 1. Start Azurite emulator
npm run azurite

# 2. Start Function App (in new terminal)
cd src/backend
func start --port 7071

# 3. Start frontend (in new terminal)
cd src/frontend  
npm run dev
```

### Deploy to Azure
```bash
# Quick deployment (requires Azure CLI login)
./deploy-scripts/deploy-quickstart.ps1
```

## Project Architecture

- **Frontend**: Vanilla JavaScript SPA with Vite build system → Azure Storage Static Website
- **Backend**: C# Azure Functions proxy for AI Foundry integration → Azure Function App
- **Infrastructure**: Azure Bicep templates with Azure Verified Modules (AVM)
- **Security**: Public mode (no authentication), backend uses Managed Identity for AI Foundry access
- **Deployment**: Azure CLI + Bicep (no azd dependency)

## Specialized Agent Instructions

This project uses specialized AGENTS.md files for different areas:

- **[Infrastructure](infra/AGENTS.md)**: Bicep templates, Azure deployments, AVM patterns
- **[Frontend](src/frontend/AGENTS.md)**: JavaScript SPA, Vite build, testing patterns  
- **[Documentation](docs/AGENTS.md)**: Writing standards, content organization, maintenance

## Critical Requirements

### Cross-Platform PowerShell Compatibility
```powershell
# ✅ ALWAYS use cross-platform patterns
if ($IsWindows) {
    # Windows-specific code
} elseif ($IsLinux) {
    # Linux-specific code
} elseif ($IsMacOS) {
    # macOS-specific code
}

# ✅ Use proper path separators
$pathSeparator = [System.IO.Path]::PathSeparator
```

### Path Management Rules
- **User Instructions**: Use absolute paths (`C:\repos\ai-in-a-box\...` or `/workspaces/ai-in-a-box/...`)
- **Source Control Files**: Use relative paths (`src/frontend/`, `infra/`)
- **VS Code Tasks**: Use `${workspaceFolder}` variable

### Microsoft Documentation Priority
Before generating Azure or C# code, ALWAYS search Microsoft Learn first:
- `mcp_microsoft_doc_microsoft_docs_search` for official guidance
- Verify CLI commands, parameters, and best practices
- Check regional availability and quota requirements

## Local Development Workflow

### Required Testing Sequence
1. **Start Azurite**: Required for Function App storage dependencies
2. **Launch Function App**: Backend proxy on `http://localhost:7071`
3. **Start Frontend**: Vite dev server on `http://localhost:5173`
4. **Verify Integration**: Test frontend → backend → AI Foundry flow
5. **Run Tests**: Execute test suites before deployment

### Test Script Execution
```powershell
# Local testing
./Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Azure testing  
./Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"
```

## Code Generation Guidelines

### JavaScript/Frontend
- Modern ES6+ features (async/await, arrow functions, destructuring)
- Functional programming patterns where appropriate
- Comprehensive error handling with try-catch blocks
- Clean, commented code with proper documentation

### Azure/Infrastructure
- Follow Azure best practices and naming conventions
- Use Managed Identity and RBAC (principle of least privilege)
- Implement proper resource tagging and organization
- Use Azure Verified Modules (AVM) when available

### PowerShell Scripts
- Cross-platform compatibility (Windows/Linux/macOS)
- Proper error handling and parameter validation
- Use approved verbs and consistent naming
- Include help documentation and examples

## Testing Requirements

### Frontend Testing
- Unit tests for all utility functions
- Integration tests for API client with mocks
- DOM testing for UI interactions
- Maintain >80% test coverage

### Infrastructure Testing
- Bicep template validation before deployment
- What-If deployments for change preview
- Resource validation after deployment
- End-to-end deployment testing

### PowerShell Testing
- Test scripts on both Windows and Linux
- Validate error handling and edge cases
- Test with different parameter combinations
- Verify cross-platform path handling

## Deployment Patterns

### Environment Strategy
- **Development**: Automatic deployment on main branch merge
- **Staging**: Manual deployment with approval gates
- **Production**: Manual deployment with extensive validation

### Infrastructure as Code
```bash
# Validate templates
az deployment sub validate --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam --location eastus2

# Deploy infrastructure
az deployment sub create --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam --location eastus2

# Deploy application code
./deploy-scripts/deploy-backend-func-code.ps1
./deploy-scripts/deploy-frontend-spa-code.ps1
```

## Security Considerations

### Azure Security
- Function App uses Azure AI Developer role (least privilege)
- All secrets stored in Azure Key Vault
- Managed Identity for service-to-service authentication
- Network security groups and private endpoints where applicable

### Development Security
- No secrets in source control (use .env files with .gitignore)
- Secure handling of API keys and connection strings
- Regular security scanning and dependency updates
- Follow Microsoft security best practices

## Troubleshooting

### Common Issues
- **Node.js compatibility**: Use Node.js 18 LTS or higher for SWA CLI alternatives
- **CORS errors**: Verify Function App CORS configuration
- **Quota limits**: Check Azure subscription quotas before deployment
- **PowerShell execution**: Ensure cross-platform compatibility

### Debug Commands
```bash
# Check Azure CLI version and login status
az version
az account show

# Validate Bicep templates
az bicep build --file infra/main-orchestrator.bicep

# Check Function App logs
az webapp log tail --name <function-app-name> --resource-group <resource-group>

# Test API endpoints
curl -X GET "https://your-function-app.azurewebsites.net/api/health"
```

## Documentation Guidelines

- **No automatic summary files**: Don't create .md files unless requested
- **Inline documentation**: Update existing docs when making changes
- **Code comments**: Document complex logic and integrations
- **README updates**: Update when functionality changes significantly
- **User-focused**: Write for specific audiences and use cases

## CI/CD Pipeline

### GitHub Actions Workflow
- **Build validation**: Bicep templates, frontend build, backend build
- **Testing**: Unit tests, integration tests, security scanning
- **Deployment**: Infrastructure first, then application code
- **Monitoring**: Health checks and deployment verification

### Environment Variables
Required for CI/CD:
- `AZURE_CLIENT_ID`: Service principal for Azure authentication
- `AZURE_TENANT_ID`: Azure tenant identifier
- `AZURE_SUBSCRIPTION_ID`: Target Azure subscription
- `AZURE_CLIENT_SECRET`: Service principal secret (GitHub Secrets)