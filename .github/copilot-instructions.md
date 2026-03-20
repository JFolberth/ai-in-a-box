<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# AI Foundry SPA Project Instructions

This is a JavaScript SPA project that integrates with a single AI Foundry endpoint and deploys to Azure Storage Static Websites using Azure CLI.

## ⚠️ ⚠️ CRITICAL REQUIREMENT - PATH MANAGEMENT ⚠️ ⚠️

**🚨 ABSOLUTE PATHS FOR USER INSTRUCTIONS ONLY - RELATIVE PATHS IN SOURCE CONTROL 🚨**

### WHEN TO USE ABSOLUTE PATHS:
**✅ USER INSTRUCTIONS & COPILOT CHAT RESPONSES:**
- When providing commands for users to run manually
- In troubleshooting guidance and examples
- In documentation that references specific user scenarios

```powershell
# ✅ CORRECT - In user instructions/chat responses:
"Run this command: dotnet build /workspaces/ai-in-a-box/src/backend/AIFoundryProxy.csproj"
"Navigate to: /workspaces/ai-in-a-box/deploy-scripts/"
"Set-Location /workspaces/ai-in-a-box/src/backend"
```

### WHEN TO USE RELATIVE PATHS:
**✅ SOURCE CONTROL FILES (scripts, configs, etc.):**
- All checked-in scripts and configuration files
- Task definitions and workflow files
- Any file that will be used across different environments

```powershell
# ✅ CORRECT - In source control files:
az deployment sub create --template-file "infra/main-orchestrator.bicep" --parameters "infra/dev-orchestrator.parameters.bicepparam" --location "northcentralus"
& "./deploy-scripts/deploy-backend-func-code.ps1"
Set-Location "src/backend"
dotnet build "src/backend/AIFoundryProxy.csproj"
```

**WHY THIS DISTINCTION MATTERS:**
- ✅ **User instructions**: Work from any directory, clear and unambiguous
- ✅ **Source control**: Portable across different workspace locations
- ✅ **Flexibility**: Code works in devcontainers, DevBox, local machines, CI/CD
- ✅ **Maintainability**: No hardcoded paths that break in different environments

---

## 🚨 CRITICAL REQUIREMENT - CROSS-PLATFORM POWERSHELL COMPATIBILITY 🚨

**🔴 ALL POWERSHELL SCRIPTS MUST WORK ON BOTH WINDOWS AND LINUX/MACOS 🔴**

### MANDATORY CROSS-PLATFORM PATTERNS:

#### 1. PATH Environment Variable Handling
```powershell
# ❌ WRONG - Windows-only PATH manipulation:
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

# ✅ CORRECT - Cross-platform PATH handling:
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    # Windows: Merge Machine and User PATH variables
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathSeparator = [System.IO.Path]::PathSeparator
    if ($machinePath -and $userPath) {
        $env:PATH = $machinePath + $pathSeparator + $userPath
    } elseif ($machinePath) {
        $env:PATH = $machinePath
    } elseif ($userPath) {
        $env:PATH = $userPath
    }
}
# On Linux/macOS, $env:PATH is already properly set by the shell
```

#### 2. PATH Separator Usage
```powershell
# ❌ WRONG - Hardcoded Windows separator:
$env:PATH = "$newPath;" + $env:PATH

# ✅ CORRECT - Cross-platform separator:
$pathSeparator = [System.IO.Path]::PathSeparator
$env:PATH = "$newPath$pathSeparator" + $env:PATH
```

#### 3. Platform Detection
```powershell
# ✅ ALWAYS use built-in platform detection:
if ($IsWindows) {
    # Windows-specific code
} elseif ($IsLinux) {
    # Linux-specific code  
} elseif ($IsMacOS) {
    # macOS-specific code
}
```

#### 4. Command Existence Checking
```powershell
# ✅ ALWAYS use this pattern for command detection:
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}
```

### CROSS-PLATFORM TESTING REQUIREMENTS:
- **🧪 EVERY PowerShell script MUST be tested on both Windows and Linux**
- **🚀 CI/CD MUST validate PowerShell scripts on both platforms**
- **📝 Use `#!/usr/bin/env pwsh` shebang for cross-platform scripts**
- **🔍 Test scripts in devcontainers (Linux) AND local Windows environments**

### ANTI-PATTERNS TO AVOID:
- ❌ **Windows-only environment variable access**: `[System.Environment]::GetEnvironmentVariable("PATH", "Machine")`
- ❌ **Hardcoded path separators**: Using `;` instead of `[System.IO.Path]::PathSeparator`
- ❌ **Platform-specific commands**: Without proper platform detection
- ❌ **Untested cross-platform assumptions**: Always test on both Windows and Linux

---

## Project Context

- **Frontend Framework**: Vanilla JavaScript with Vite build system
- **Security**: Public mode (no authentication) with backend proxy for AI Foundry integration
- **Infrastructure**: Azure Bicep templates using Azure Verified Modules (AVM)
- **Hosting**: Azure Storage Static Website
- **Deployment**: Azure CLI with Bicep ONLY (no azd/Azure Developer CLI dependencies). Note: Azure Deployment Environments (ADE) is used for CI/CD validation but is separate from the azd CLI tool.
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

#### Absolute Paths for User Guidance - REQUIRED
- **🚨 USER INSTRUCTIONS MUST USE CURRENT WORKSPACE ABSOLUTE PATHS 🚨**
- **✅ ALWAYS for user commands**: `/workspaces/ai-in-a-box/src/frontend/index.html`
- **✅ SOURCE CONTROL files**: Use relative paths like `src/frontend/index.html`
- **✅ Tasks**: Use `${workspaceFolder}` when available in VS Code tasks
- **✅ Scripts**: Validate paths exist before operations, use relative paths in checked-in files
- **🎯 DISTINCTION**: Absolute for user guidance, relative for source control portability

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
   - **Note**: When providing user instructions, use absolute paths for clarity

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

### 📝 Documentation Guidelines

- **NO automatic summary files**: Do not create summary markdown files (.md) after making changes unless explicitly requested
- **Inline documentation**: Update existing documentation files when relevant
- **Code comments**: Add appropriate comments in code for complex logic
- **README updates**: Update README files when functionality changes significantly
- **Only when prompted**: Create summary/documentation files only when the user specifically asks for them
````
