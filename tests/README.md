# AI Foundry SPA Testing Suite

This directory contains a comprehensive and organized test suite to verify Azure Function App functionality, AI Foundry integration, and deployment readiness.

## 📁 Reorganized Structure

The tests have been reorganized for better maintainability and clear separation of concerns:

```
tests/
├── README.md                           # This comprehensive testing guide
├── core/                              # Primary test scripts (daily use)
│   ├── Test-FunctionEndpoints.ps1    # 🎯 Main endpoint and AI integration testing
│   ├── Test-AzuriteSetup.ps1         # 🔧 Local development environment setup
│   ├── Test-FunctionAppRbac.ps1      # 🔒 RBAC diagnostic and validation
│   └── simulate-ci-workflow.sh       # 🚀 CI/CD workflow simulation
├── integration/                       # Integration and validation tests
│   ├── test-ade-workflows.sh         # 📋 ADE parameter extraction workflows
│   ├── test-backend-validation.sh    # 🧪 Backend build, test, and package validation
│   └── test-bicep-validation.sh      # 🏗️ Bicep template validation
├── utilities/                         # Helper and utility scripts
│   ├── extract-ade-parameters.sh     # 🔍 ADE parameter extraction utility
│   ├── extract-ade-outputs.sh        # 📤 ADE output extraction utility
│   └── test-function-access.sh       # 🔒 Cross-platform RBAC validation
└── archive/                          # Legacy and deprecated scripts
    └── [previous versions and deprecated scripts]
```

## 🎯 Core Test Scripts (Primary Usage)

### `Test-FunctionEndpoints.ps1` - **Primary Comprehensive Testing**
**The main test script for endpoint validation and AI Foundry integration**

#### Usage Examples
```powershell
# Test local development endpoints (standard mode)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test deployed Azure Function App
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"

# Health endpoint only (fast check for CI/CD)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -HealthOnly

# AI Foundry integration validation only
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -AiFoundryOnly

# Comprehensive testing (includes threading tests)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -Comprehensive
```

#### Test Modes and Exit Codes

| Mode | Description | Exit Code on Failure |
|------|-------------|----------------------|
| **Standard** | Health check, createThread, and basic chat tests | 1-3 |
| **HealthOnly** | Only tests `/api/health` endpoint | 1 |
| **AiFoundryOnly** | Health + AI Foundry integration validation | 1-2 |
| **SkipChat** | Health and createThread tests, no chat | 1-2 |
| **Comprehensive** | All tests including conversation threading | 1-4 |

### `Test-AzuriteSetup.ps1` - **Local Development Environment**
**Validates Azurite emulator setup for local Function App development**

```powershell
# Test Azurite connectivity and configuration
./tests/core/Test-AzuriteSetup.ps1
```

### `simulate-ci-workflow.sh` - **CI/CD Pipeline Simulation**
**Simulates the GitHub Actions CI workflow locally**

```bash
# Run complete CI simulation
./tests/core/simulate-ci-workflow.sh

# Full absolute path (recommended)
/home/runner/work/ai-in-a-box/ai-in-a-box/tests/core/simulate-ci-workflow.sh
```

## 🔧 Integration Test Scripts

### `test-ade-workflows.sh` - **ADE Parameter Workflows**
**Consolidated ADE parameter extraction and workflow testing**

```bash
# Run complete ADE workflow tests
./tests/integration/test-ade-workflows.sh

# From repository root
bash tests/integration/test-ade-workflows.sh
```

**What it tests:**
- Original jq-based parameter extraction (backward compatibility)
- Enhanced helper script functionality
- Error handling (invalid JSON, missing parameters)
- CI workflow integration simulation
- Parameter sourcing capabilities
- Multiple output formats (env, json, export)

### `test-backend-validation.sh` - **Backend Build and Package Validation**
**Comprehensive backend testing, building, and deployment package validation**

```bash
# Complete backend validation (build + test + package + validate)
./tests/integration/test-backend-validation.sh

# Validate existing package only (skip build and tests)
./tests/integration/test-backend-validation.sh --package-only /path/to/backend-deployment.zip
```

**What it tests:**
- Backend project compilation
- Complete test suite execution with detailed output
- Deployment package creation
- Package structure validation (.azurefunctions directory, required files)
- Application assembly verification
- Deployment readiness assessment

### `test-bicep-validation.sh` - **Infrastructure Template Validation**
**Validates Bicep templates using Azure CLI what-if commands**

```bash
# Test Bicep template validation
./tests/integration/test-bicep-validation.sh
```

## 🛠️ Utility Scripts

### `extract-ade-parameters.sh` - **ADE Parameter Extraction**
**Reusable utility for extracting AI Foundry parameters from ADE files**

```bash
# Validation only
./tests/utilities/extract-ade-parameters.sh --validate-only

# Extract as environment variables
./tests/utilities/extract-ade-parameters.sh --output env

# Extract as JSON
./tests/utilities/extract-ade-parameters.sh --output json

# Source into current shell
source <(./tests/utilities/extract-ade-parameters.sh --output export --quiet)
echo $AI_FOUNDRY_ENDPOINT
```

### `extract-ade-outputs.sh` - **ADE Output Extraction**
**Utility for extracting deployment outputs from ADE result files**

### `test-function-access.sh` - **Cross-Platform RBAC Validation**
**Validates Function App resource access and RBAC permissions (bash version)**

```bash
# Test Function App access permissions
./tests/utilities/test-function-access.sh -g "rg-backend" -f "func-app" -s "storageaccount"

# With AI Foundry resource testing
./tests/utilities/test-function-access.sh -g "rg-backend" -f "func-app" -s "storage" -a "/subscriptions/.../providers/Microsoft.CognitiveServices/accounts/ai-foundry"
```

## 🎯 What These Scripts Test

### 1. Endpoint Functionality ✅ (Test-FunctionEndpoints.ps1)
- **createThread endpoint**: Thread creation and ID generation
- **sendMessage endpoint**: Message processing and AI response generation
- **Conversation persistence**: Thread continuity across multiple messages
- **Response uniqueness**: Each message gets distinct AI responses
- **Error handling**: Invalid inputs and timeout scenarios
- **Performance**: Response times and reliability

### 2. AI Foundry Integration ✅ (Multiple Scripts)
- **Real AI Integration**: Actual AI Foundry AI in A Box agent responses
- **Connection Validation**: AI Foundry client initialization
- **Agent Access**: Configured agent accessibility verification
- **Authentication**: Managed identity permissions validation
- **Conversation Threading**: Context retention across messages

### 3. Resource Access & Security ✅ (test-function-access.sh)
- **Managed Identity**: System-assigned identity configuration
- **Storage Access**: RBAC permissions for Function App storage
- **AI Foundry Access**: Azure AI Developer role verification
- **Cross-Resource Access**: Function App access to AI Foundry in different resource groups
- **Least Privilege Validation**: Appropriate role assignments

### 4. Build & Deployment ✅ (test-backend-validation.sh)
- **Backend Compilation**: .NET project build validation
- **Test Suite Execution**: Complete unit and integration tests
- **Package Creation**: Azure Function deployment package generation
- **Package Validation**: Structure and content verification
- **Deployment Readiness**: Size limits and file count checks

### 5. Infrastructure ✅ (test-bicep-validation.sh)
- **Template Validation**: Bicep template syntax and logic
- **Parameter File Validation**: ADE parameter file structure
- **Deployment Simulation**: What-if analysis for infrastructure changes

### 6. Development Environment ✅ (Test-AzuriteSetup.ps1)
- **Local Storage Emulation**: Azurite connectivity
- **Function App Integration**: Local development configuration
- **Storage Services**: Blob, queue, and table service validation

## 🚀 Quick Start Guide

### For Daily Development
```powershell
# 1. Test local development setup
./tests/core/Test-AzuriteSetup.ps1

# 2. Test local Function App endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# 3. Test deployed Function App
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://your-function-app.azurewebsites.net"
```

### For CI/CD Validation
```bash
# 1. Simulate complete CI workflow
./tests/core/simulate-ci-workflow.sh

# 2. Validate backend build and packaging
./tests/integration/test-backend-validation.sh

# 3. Test ADE parameter workflows
./tests/integration/test-ade-workflows.sh
```

### For Deployment Troubleshooting
```bash
# 1. Validate RBAC permissions
./tests/utilities/test-function-access.sh -g "rg-name" -f "func-name" -s "storage-name"

# 2. Extract and validate ADE parameters
./tests/utilities/extract-ade-parameters.sh --validate-only

# 3. Validate infrastructure templates
./tests/integration/test-bicep-validation.sh
```

## 🏁 Exit Codes for CI Integration

All scripts return specific exit codes for automated CI/CD integration:

| Exit Code | Meaning | Scripts |
|-----------|---------|---------|
| `0` | All tests passed | All scripts |
| `1` | Health/connectivity failed | Test-FunctionEndpoints.ps1, test-function-access.sh |
| `2` | AI Foundry integration failed | Test-FunctionEndpoints.ps1 |
| `3` | Chat functionality failed | Test-FunctionEndpoints.ps1 |
| `4` | Threading tests failed | Test-FunctionEndpoints.ps1 |

## 📋 Troubleshooting Guide

### MSI Token Errors
If you see "MSI token request failed" errors:

1. **Wait for RBAC propagation** (5-10 minutes)
2. **Restart Function App**: `az functionapp restart --name $FunctionAppName --resource-group $ResourceGroupName`
3. **Remove conflicting settings** (scripts will detect these)
4. **Verify storage account allows managed identity access**

### Missing RBAC Assignments
Use the utility scripts to diagnose:

```bash
# Check all RBAC assignments and scopes
./tests/utilities/test-function-access.sh -g "rg-name" -f "func-name" -s "storage-name"
```

### Package Deployment Issues
Validate packages before deployment:

```bash
# Validate existing deployment package
./tests/integration/test-backend-validation.sh --package-only /path/to/package.zip
```

## 🔗 Integration with CI/CD

Example GitHub Actions integration:

```yaml
- name: Test Function App Endpoints
  run: |
    pwsh -File tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "${{ env.FUNCTION_APP_URL }}" -HealthOnly
  shell: pwsh

- name: Validate Backend Package
  run: |
    bash tests/integration/test-backend-validation.sh
  shell: bash

- name: Test Resource Access
  run: |
    bash tests/utilities/test-function-access.sh -g "${{ env.RESOURCE_GROUP }}" -f "${{ env.FUNCTION_APP }}" -s "${{ env.STORAGE_ACCOUNT }}"
  shell: bash
```

## 📊 Benefits of Reorganization

### Before (14 scripts, mixed organization)
- Duplicate functionality between scripts
- Inconsistent naming conventions
- Mixed purposes in same directory
- Difficult to find the right script
- Legacy scripts alongside current ones

### After (8-10 scripts, organized structure)
- **Clear separation of concerns**: Core, Integration, Utilities
- **Consolidated functionality**: No more duplicates
- **Consistent naming**: Standardized conventions
- **Better maintainability**: Easier to find and update scripts
- **Cleaner archive**: Legacy scripts preserved but separated

### Usage Improvements
- ✅ **Faster navigation**: Know exactly where to find the right script
- ✅ **Clearer purpose**: Each script has a well-defined role
- ✅ **Better documentation**: Comprehensive usage examples
- ✅ **Easier maintenance**: Fewer scripts to keep updated
- ✅ **Reduced confusion**: No more wondering which script to use

This reorganization reduces maintenance overhead while improving usability and ensuring comprehensive test coverage for the AI Foundry SPA project.

## 🧹 Recent Cleanup (July 2025)

**Removed One-off Debugging Scripts:**
The following debugging scripts were created for specific troubleshooting sessions and have been removed after the issues were resolved:

- `Debug-AgentResultParsing.ps1` - Agent result parsing debugging
- `Test-AgentResultParsing.ps1` - Agent deployment result logic testing  
- `Test-QuickStartAgentLogic.ps1` - Quick-start agent ID logic debugging
- `Test-AgentDeploymentLogic.ps1` - Agent deployment logic validation
- `Test-AgentIdFlow.ps1` - Dynamic agent ID flow testing
- `Test-DeploymentOutputs.ps1` - Deployment output extraction debugging
- `Test-OutputExtraction.ps1` - Output extraction logic testing

**Rationale:**
- These were temporary debugging tools for specific issues that have been resolved
- They provided no ongoing value for development or CI/CD processes  
- The core functionality they tested is now validated by the remaining production scripts
- Keeping them would clutter the test suite and confuse developers

**Remaining Scripts:**
All remaining scripts provide ongoing value for:
- ✅ Production troubleshooting (`Test-FunctionAppRbac.ps1`)
- ✅ Local development validation (`Test-AzuriteSetup.ps1`) 
- ✅ Endpoint testing (`Test-FunctionEndpoints.ps1`)
- ✅ CI/CD integration (`simulate-ci-workflow.sh`
- ✅ Reusable utilities (`utilities/extract-*.sh`)