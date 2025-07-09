<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# AI Foundry SPA Project Instructions

This is a JavaScript SPA project that integrates with a single AI Foundry endpoint and deploys to Azure Storage Static Websites using Azure CLI.

## ⚠️ ⚠️ CRITICAL REQUIREMENT - ABSOLUTE PATHS ONLY ⚠️ ⚠️

**🚨 ALL COMMANDS AND FILE OPERATIONS MUST USE ABSOLUTE PATHS 🚨**

### MANDATORY ABSOLUTE PATH PATTERNS:
```powershell
# ✅ CORRECT - Always use these patterns:
az deployment sub create --template-file "C:\Users\BicepDeveloper\ai-in-a-box\infra\main-orchestrator.bicep"
& "C:\Users\BicepDeveloper\ai-in-a-box\deploy-scripts\deploy-backend-func-code.ps1"
Set-Location "C:\Users\BicepDeveloper\ai-in-a-box\src\backend"
dotnet build "C:\Users\BicepDeveloper\ai-in-a-box\src\backend\AIFoundryProxy.csproj"

# ❌ FORBIDDEN - Never use relative paths:
az deployment sub create --template-file infra/main-orchestrator.bicep
.\deploy-scripts\deploy-backend-func-code.ps1
cd src/backend
```

**WHY THIS MATTERS:**
- ✅ Commands work from any directory
- ✅ No ambiguity about file locations  
- ✅ Consistent results across environments
- ✅ Easier debugging and troubleshooting

---

## Project Context

- **Frontend Framework**: Vanilla JavaScript with Vite build system
- **Security**: Public mode (no authentication) with backend proxy for AI Foundry integration
- **Infrastructure**: Azure Bicep templates using Azure Verified Modules (AVM)
- **Hosting**: Azure Storage Static Website
- **Deployment**: Azure CLI with Bicep ONLY (no azd/Azure Developer CLI dependencies)
- **Development**: DevContainer and DevBox ready with full Bicep support
- **AI Integration**: Single AI in A Box agent endpoint (not user-switchable)
- **Monitoring**: Application Insights with consolidated Log Analytics Workspace
- **Architecture**: Multi-resource group deployment (frontend and backend separated)

## Code Generation Guidelines

### 🎯 PRIORITIZE MICROSOFT OFFICIAL DOCUMENTATION - MANDATORY

**🔍 ALWAYS consult Microsoft Learn first for Azure and C# guidance:**

- **🚨 BEFORE generating any Azure code**: Use `mcp_microsoft_doc_microsoft_docs_search` to find current best practices
- **🚨 BEFORE implementing C# features**: Search Microsoft Learn for official patterns and recommendations
- **🚨 BEFORE suggesting Azure services**: Verify capabilities and limitations in official documentation
- **🚨 BEFORE troubleshooting Azure issues**: Check Microsoft Learn for known issues and solutions
- **🚨 BEFORE providing Azure CLI commands**: Verify command syntax, parameters, and examples in Microsoft documentation
- **🚨 BEFORE recommending PowerShell scripts**: Check Microsoft Learn for official PowerShell patterns and Azure integration

**Examples of when to search Microsoft Learn:**
- Azure Function development patterns
- Bicep template best practices
- Azure Storage configuration options
- Cognitive Services integration methods
- C# async/await patterns
- Azure security and authentication
- Deployment and monitoring strategies
- Azure CLI command reference and examples
- PowerShell Azure module documentation

**Search Query Examples:**
```
"Azure Functions C# best practices"
"Bicep template security patterns"
"Azure Storage static website configuration"
"Cognitive Services authentication methods"
"Azure Application Insights setup"
"Azure CLI cognitiveservices account commands"
"PowerShell Azure Functions deployment"
"Azure quota management CLI commands"
```

**Benefits:**
- ✅ **Current information**: Always get the latest Azure features and recommendations
- ✅ **Official guidance**: Avoid deprecated patterns or unofficial workarounds
- ✅ **Security focus**: Follow Microsoft's security best practices
- ✅ **Performance optimization**: Use Microsoft-recommended performance patterns
- ✅ **Compatibility**: Ensure code works with current Azure platform versions
- ✅ **Accurate CLI syntax**: Use verified Azure CLI commands and parameters
- ✅ **Best practice scripts**: Follow Microsoft's recommended PowerShell patterns

### ⚠️ CRITICAL - Path Management and Local Testing

#### Absolute Paths - REQUIRED (REINFORCED)
- **🚨 EVERY FILE OPERATION MUST USE ABSOLUTE PATHS 🚨**
- **✅ ALWAYS**: `C:\Users\BicepDeveloper\ai-in-a-box\src\frontend\index.html`
- **❌ NEVER**: `./src/frontend` or `../backend` or any relative path
- **✅ Tasks**: Use `${workspaceFolder}` when available in VS Code tasks
- **✅ Scripts**: Always verify absolute paths exist before operations
- **🎯 NO EXCEPTIONS**: This applies to ALL commands, file operations, and scripts

#### Local Testing - MANDATORY
1. **Local Testing Sequence**:
   - Start Azurite emulator first
   - Launch backend Function App locally
   - Start frontend Vite dev server
   - Verify local endpoints work
   - Test all features locally
   - ONLY then proceed to deployment

2. **Required Local Tests**:
   - Function App endpoints respond correctly
   - Frontend can call backend successfully
   - AI Foundry integration functions properly

3. **Task Execution Order**:
   ```powershell
   # 1. Start Azurite (required for Function App)
   Run-VSCodeTask "Start Azurite"
   
   # 2. Launch Function App
   Run-VSCodeTask "Build and Start Function App"
   
   # 3. Start frontend
   Run-VSCodeTask "AI Foundry SPA: Build and Run"
   ```

4. **Test Script Execution**:
   - **ALWAYS pass the function URL** when running test scripts
   - For local testing: `.\Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"`
   - For Azure testing: `.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"`
   - **Never assume default URLs** - always provide the specific endpoint being tested
   - Test scripts should validate the exact environment being tested (local vs Azure)

### JavaScript/Frontend
- Use modern ES6+ features
- Follow functional programming patterns where appropriate
- Implement proper error handling with try-catch blocks
- Use async/await for asynchronous operations
- Maintain clean, readable code with proper comments

### Azure Integration
- Follow Azure best practices for security
- Use Managed Identity where possible
- Implement proper error handling for Azure API calls
- Follow Azure naming conventions
- Use secure connection strings and avoid hardcoded secrets
- Function App uses Azure AI Developer role for AI Foundry access (least privilege)

### 🔧 Azure CLI Command Verification - MANDATORY

**🚨 BEFORE providing any Azure CLI commands, ALWAYS verify with Microsoft Learn:**

#### Required Verification Process:
1. **Search Microsoft Learn** for the specific Azure service and command
2. **Verify command syntax** and required parameters
3. **Check for current limitations** and regional availability
4. **Confirm best practices** for the specific use case
5. **Test command format** with example scenarios

#### Example Verification Queries:
```
"Azure CLI cognitiveservices commands"
"az cognitiveservices account list-skus parameters"
"Azure quota management CLI commands"
"Azure resource group CLI commands"
"Azure deployment CLI best practices"
```

#### Command Categories Requiring Verification:
- **🧠 Cognitive Services**: `az cognitiveservices` commands (quota, regions, SKUs)
- **📊 Resource Management**: `az resource`, `az group` commands
- **🚀 Deployment**: `az deployment` commands and parameters
- **🔍 Query Operations**: Complex `--query` filters and JMESPath expressions
- **🌍 Region/Location**: Commands that depend on regional availability
- **📈 Quota/Limits**: Commands that check service limits and quotas

#### Anti-Patterns to Avoid:
- ❌ **Don't assume command parameters** without verification
- ❌ **Don't use deprecated command formats** 
- ❌ **Don't provide region-specific commands** without checking availability
- ❌ **Don't suggest complex queries** without testing the syntax
- ❌ **Don't recommend quota commands** without understanding current limits

**Why This Matters:**
- Azure CLI syntax and parameters change frequently
- Regional availability varies for different services
- Quota limits and SKU availability differ by subscription type
- Deprecated commands can cause deployment failures
- Incorrect query syntax leads to empty or wrong results
````
