<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# AI Foundry SPA Project Instructions

This is a JavaScript SPA project that integrates with a single AI Foundry endpoint and deploys to Azure Storage Static Websites using Azure CLI.

## Project Context

- **Frontend Framework**: Vanilla JavaScript with Vite build system
- **Security**: Public mode (no authentication) with backend proxy for AI Foundry integration
- **Infrastructure**: Azure Bicep templates using Azure Verified Modules (AVM)
- **Hosting**: Azure Storage Static Website
- **Deployment**: Azure CLI with Bicep ONLY (no azd/Azure Developer CLI dependencies)
- **Development**: DevContainer and DevBox ready with full Bicep support
- **AI Integration**: Single CancerBot agent endpoint (not user-switchable)
- **Monitoring**: Application Insights with consolidated Log Analytics Workspace
- **Architecture**: Multi-resource group deployment (frontend and backend separated)

## Code Generation Guidelines

### ⚠️ CRITICAL - Path Management and Local Testing

#### Absolute Paths - REQUIRED
- **✅ ALWAYS use absolute paths** for all file operations
- **✅ Example**: `C:\Users\BicepDeveloper\ai-in-a-box\src\frontend\index.html`
- **❌ NEVER use relative paths** like `./src/frontend` or `../backend`
- **✅ Use workspace root**: `${workspaceFolder}` when available in tasks
- **✅ Verify paths exist** before operations

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
   - For Azure testing: `.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net"`
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

### RBAC and Security Best Practices ⚠️ CRITICAL

#### Core Security Principles
- **⛔ NEVER assign highly privileged roles** like Owner, Contributor, or User Access Administrator unless absolutely necessary
- **🔒 Use least privilege principle** - assign the MINIMUM role required for the specific task
- **🎯 Scope role assignments to the RESOURCE LEVEL** when possible, not subscription or resource group level
- **📋 Use built-in roles** before creating custom roles
- **🔑 Service-specific roles**: Use specialized roles like Azure AI Developer, Storage Blob Data Reader, Key Vault Secrets User
- **❌ Avoid broad permissions**: Don't use Contributor when specific data plane roles suffice
- **📝 Document role assignments**: Always comment WHY specific roles are needed

#### ✅ Example Good Practices (Resource-Scoped)
- Function App → Azure AI Developer role → scoped to specific AI Foundry resource
- Web App → Storage Blob Data Reader → scoped to specific storage account  
- Logic App → Key Vault Secrets User → scoped to specific Key Vault
- Container App → Azure Container Registry Reader → scoped to specific ACR
- API Management → Azure OpenAI User → scoped to specific OpenAI resource

#### ❌ Anti-Patterns to Avoid
- **DON'T**: Assign Contributor at subscription level for simple data access
- **DON'T**: Use Owner role when service-specific roles exist
- **DON'T**: Scope to resource group when resource-level scoping is possible
- **DON'T**: Use User Access Administrator unless managing RBAC itself
- **DON'T**: Create custom roles without exploring all built-in options first

### Bicep Infrastructure
- Use Azure Verified Modules (AVM) when available
- Follow naming conventions with resource tokens
- Implement proper tagging strategy
- Use .bicepparam files for parameters (avoid JSON parameter files)
- Include comprehensive outputs for integration
- Use existing resource lookups for Log Analytics workspace
- **Modular Design**: Use orchestrator pattern with separate modules for frontend and backend
- **Multi-Resource Group**: Deploy frontend and backend to separate resource groups
- **Cross-Resource Group RBAC**: Use dedicated RBAC modules for permissions across resource groups
- Deploy using Azure CLI commands ONLY - never use azd (Azure Developer CLI)
- System-assigned managed identity only (no user-assigned)
- **🏗️ Azure Deployment Environment (ADE) Schema - CRITICAL**:
  - **✅ Follow official schema**: https://learn.microsoft.com/en-us/azure/deployment-environments/concept-environment-yaml
  - **✅ Required properties**: `name`, `templatePath` (all other properties are optional)
  - **✅ Supported root properties**: `name`, `version`, `summary`, `description`, `runner`, `templatePath`, `parameters`
  - **✅ Add schema validation**: Include `# yaml-language-server: $schema=https://github.com/Azure/deployment-environments/releases/download/2022-11-11-preview/manifest.schema.json`
  - **✅ Parameter structure**: Use `id`, `name`, `description`, `type`, `required`, `default`, `allowed` properties
  - **✅ Supported runners**: `ARM`, `Bicep`, `Terraform`
  - **✅ Parameter types**: `string`, `boolean`, `integer`, `number`, `object`, `array`
  - **❌ NO outputs section**: ADE schema does not support outputs - outputs are handled by the underlying Bicep/ARM template
  - **❌ NO custom metadata**: Only use officially supported properties
  - **❌ NO quoted strings**: Use unquoted strings for parameter IDs and simple values
  - **✅ Relative templatePath**: Use relative paths from catalog root (e.g., `../../modules/frontend.bicep`)
  - **📋 Validation**: Always validate YAML syntax and schema compliance before deployment
- **🎯 Resource References vs Names - CRITICAL**:
  - **✅ ALWAYS use resource references**: `scope: myResourceGroup` (direct resource reference)
  - **❌ NEVER use resource names**: `scope: resourceGroup(myResourceGroupName)` (string-based lookup)
  - **✅ Resource properties**: `myResource.id`, `myResource.name`, `myResource.properties.primaryEndpoints`
  - **❌ String interpolation**: Avoid `'${myResourceName}'` when resource reference available
  - **✅ Dependencies**: Bicep automatically handles dependencies with resource references
  - **❌ Manual dependsOn**: Usually unnecessary when using proper resource references
  - **Exception**: External resources (existing resources in other RGs) may require string-based lookups
  - **Example Good Practice**: `output rgName string = myResourceGroup.name` (not `myResourceGroupName`)
- **🔒 RBAC in Bicep**: 
  - Always use least privilege roles (Azure AI Developer, not Contributor)
  - Scope assignments to specific resources, not resource groups
  - Document each role assignment with comments explaining necessity
  - Use resource IDs for scoping: `scope: aiFoundryResource.id`
  - Never use subscription or resource group scope unless absolutely required

### Deployment Guidelines
- **NEVER use azd (Azure Developer CLI)** - this project is azd-free by design
- **ALWAYS test locally before deploying to Azure**
- Use only `az deployment sub create` for orchestrator deployment at subscription scope
- Use Azure CLI for all resource management operations
- **ALWAYS use absolute paths** in all operations and commands
- Infrastructure deployment: `az deployment sub create --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam`
- No azure.yaml file or azd configuration files
- All deployment scripts use Azure CLI + Bicep exclusively

### Security
- Never expose secrets in client-side code
- Use environment variables for configuration
- Implement proper CORS policies
- Use HTTPS only
- Use system-assigned managed identity for Azure resources
- Store sensitive configuration in Azure Key Vault or parameter files

### 🧹 Debugging and Logging Cleanup - CRITICAL

When debugging issues, it's important to clean up verbose logging after problems are resolved to maintain performance and security.

#### After Fixing Issues - ALWAYS Clean Up:
- **🗑️ Remove verbose console.log statements** added for debugging
- **🔇 Reduce backend logging verbosity** back to production levels
- **⚡ Remove performance-impacting logs** (frequent polling logs, status updates)
- **🔒 Remove logs that might expose sensitive data** (full responses, tokens, detailed errors)
- **📊 Keep essential logs only** (errors, key status changes, completion notifications)

#### Frontend Cleanup Checklist:
- ❌ Remove `console.log('Sending message:', message)`
- ❌ Remove `console.log('Response:', response)` (could expose AI responses)
- ❌ Remove `console.log('Current thread ID:', threadId)`
- ❌ Remove `console.log('updateResponseContainer called with:')`
- ❌ Remove DOM debugging logs
- ✅ Keep error handling console.error statements
- ✅ Keep essential state change logs

#### Backend Cleanup Checklist:
- ❌ Remove verbose polling logs (`⏳ Run status every 2 seconds`)
- ❌ Remove milestone checkpoint logs (`📊 Checkpoint: 10 seconds elapsed`)
- ❌ Remove detailed response content logs
- ❌ Remove status change emoji logs (`🔄 Status change detected`)
- ❌ Remove verbose message counting logs
- ✅ Keep error logs (`_logger.LogError`)
- ✅ Keep essential completion logs (`Run completed in Xs`)
- ✅ Keep connection logs

#### Performance and Security Reasons:
- **Performance**: Verbose logging can slow down applications, especially in tight loops (polling)
- **Security**: Detailed logs might expose sensitive data in production environments
- **Maintenance**: Clean code is easier to debug when real issues occur
- **User Experience**: Reduced console noise for end users and developers

#### Best Practice:
```csharp
// ❌ DON'T leave debugging logs like this:
_logger.LogInformation($"🔄 Poll {pollCount}: Status={status}, Time={elapsed}s, Details={detailedInfo}");

// ✅ DO use clean, essential logs:
_logger.LogInformation($"Run completed in {elapsed:F1}s");
```

### AI Foundry Integration
- Application connects to a single AI Foundry endpoint (not user-switchable)
- CancerBot agent is the designated AI assistant
- Endpoint configuration set via parameters and environment variables
- No multi-endpoint switching logic in the frontend
- Use environment variables for endpoint URL, deployment, and agent name

## File Patterns

- Source code: 
  ```
  C:\Users\BicepDeveloper\ai-in-a-box\src\frontend\ (JavaScript SPA)
  C:\Users\BicepDeveloper\ai-in-a-box\src\backend\ (C# Function App)
  ```
- Infrastructure:  ```
  C:\Users\BicepDeveloper\ai-in-a-box\infra\
    ├── main-orchestrator.bicep
    ├── dev-orchestrator.parameters.bicepparam
    └── modules\
        ├── frontend.bicep
        ├── backend.bicep
        └── rbac.bicep
  ```
- DevBox configuration: `C:\Users\BicepDeveloper\ai-in-a-box\devbox\`
- Configuration: Root level (package.json, vite.config.js, etc.)
- Documentation: `C:\Users\BicepDeveloper\ai-in-a-box\documentation\` with comprehensive guides
- Main documentation: README.md in root with project overview and quick start

## Dependencies

- axios for HTTP requests
- vite for build system
- Azure CLI and Bicep for infrastructure (NO azd dependencies)

## Important Notes

- **This project is azd-free by design** - never suggest or use Azure Developer CLI (azd)
- Use only Azure CLI and Bicep for all infrastructure operations
- No azure.yaml file or azd-related configuration
- All deployment scripts and documentation reflect Azure CLI + Bicep approach only
- **ALWAYS test locally before deploying to Azure**
- **ALWAYS use absolute paths** in all operations

### Workspace Management
- **🧹 Keep workspace clean**: Never leave empty files in the workspace
- **🗂️ Remove unused files**: Delete any placeholder, template, or temporary files that are no longer needed
- **📝 Meaningful content only**: Every file should serve a purpose and contain meaningful content
- **🔄 Clean up after refactoring**: When restructuring code, remove old unused files
- **🚫 No empty directories**: Remove empty directories unless they serve a structural purpose
- **✅ Verify file necessity**: Before creating new files, ensure they're actually needed and will contain content
- **⚠️ Check for duplicates**: Before creating files or folders, verify no duplicates exist with the same name in the project. If duplicates are detected, prompt for confirmation before proceeding

### 📝 GitHub Issue Creation Guidelines

When creating GitHub issues, consider who will be working on them:

#### For Personal Work (You will implement)
- **Keep issues concise and actionable**
- Focus on clear title and brief description
- Include only essential details needed as reminders
- Use simple checkboxes for sub-tasks if needed
- Example: "Add unit tests for Function App endpoints"

#### For Copilot Assignment (Handing off to AI)
- **Create detailed, comprehensive issues**
- Include extensive context, requirements, and acceptance criteria
- Provide code examples, file paths, and technical specifications
- Use @copilot assignment for complex implementation tasks
- Example: Detailed infrastructure issues with Bicep requirements

#### Issue Categories
- **Bug fixes**: Always detailed (regardless of assignee)
- **New features**: Detailed if complex, concise if straightforward
- **Refactoring**: Usually concise unless architectural changes
- **Documentation**: Concise with clear scope
- **Infrastructure**: Detailed due to complexity

#### Best Practices
- ✅ Create issues immediately when problems are identified
- ✅ Use consistent labeling (bug, enhancement, documentation, etc.)
- ✅ Reference related files and line numbers when relevant
- ✅ Update issues with progress and findings
- ❌ Don't over-engineer issues for simple personal tasks
- ❌ Don't create overly brief issues for complex handoffs
