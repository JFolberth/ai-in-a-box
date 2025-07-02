# AI Foundry SPA Testing Suite

This directory contains comprehensive test scripts to verify Azure Function App functionality, AI Foundry integration, and deployment workflows.

## 📁 Folder Structure

```
tests/
├── README.md                                    # This comprehensive testing guide
├── core/                                       # Primary test scripts for daily development
│   ├── Test-FunctionEndpoints.ps1            # Main endpoint testing with multiple modes
│   ├── Test-AzuriteSetup.ps1                 # Local development setup validation
│   └── simulate-ci-workflow.sh               # CI workflow simulation
├── integration/                               # Integration and validation tests
│   ├── test-ade-workflows.sh                 # Consolidated ADE parameter testing
│   ├── Test-FunctionAppAccess.ps1           # RBAC and resource access validation
│   ├── validate-backend-package.sh           # Backend deployment package validation
│   └── run-backend-tests.sh                  # Backend test suite runner
├── utilities/                                 # Helper scripts and utilities
│   ├── extract-ade-parameters.sh             # Reusable ADE parameter extraction
│   └── extract-ade-outputs.sh                # ADE deployment output extraction
└── archive/                                   # Deprecated/legacy test scripts
    ├── test-ade-parameter-extraction.sh      # Original ADE test (replaced)
    ├── test-ade-parameter-extraction-enhanced.sh  # Enhanced ADE test (replaced)
    ├── test-function-access.sh               # Bash version of function access test
    ├── Test-UrlExtraction.sh                 # URL extraction testing
    └── Test-BicepValidation.sh               # Bicep validation testing
```

## 🚀 Core Test Scripts

### 1. Test-FunctionEndpoints.ps1
**Primary comprehensive endpoint and conversation testing with multiple test modes**

#### Usage
```powershell
# Test local development endpoints (standard mode)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test deployed Azure Function App
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net"

# Health endpoint only (fast check for CI/CD)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -HealthOnly

# AI Foundry integration validation only
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -AiFoundryOnly

# Skip chat endpoint tests (useful for basic connectivity)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -SkipChat

# Comprehensive testing (includes threading tests)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -Comprehensive
```

#### Test Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Standard** | Health check, createThread, and basic chat tests | Regular development testing |
| **HealthOnly** | Only tests `/api/health` endpoint | CI/CD health validation |
| **AiFoundryOnly** | Health check + AI Foundry integration validation | AI connectivity testing |
| **SkipChat** | Health and createThread tests, no chat endpoints | Basic connectivity testing |
| **Comprehensive** | All tests including conversation threading | Full feature validation |

#### Exit Codes for CI Integration

| Exit Code | Meaning | Description |
|-----------|---------|-------------|
| `0` | All tests passed | Success - all selected tests completed successfully |
| `1` | Health endpoint failed | Health check endpoint is not responding or unhealthy |
| `2` | AI Foundry connection failed | AI Foundry integration is not working |
| `3` | Chat functionality failed | Chat endpoints are not working properly |

### 2. Test-AzuriteSetup.ps1
**Local development environment validation**

#### Usage
```powershell
# Validate Azurite setup for local development
./tests/core/Test-AzuriteSetup.ps1

# Check Azurite connection and storage setup
& "/home/runner/work/ai-in-a-box/ai-in-a-box/tests/core/Test-AzuriteSetup.ps1"
```

### 3. simulate-ci-workflow.sh
**CI workflow simulation for local testing**

#### Usage
```bash
# Simulate complete CI workflow locally
./tests/core/simulate-ci-workflow.sh

# Full absolute path (recommended)
/home/runner/work/ai-in-a-box/ai-in-a-box/tests/core/simulate-ci-workflow.sh
```

## 🔗 Integration Test Scripts

### 1. test-ade-workflows.sh
**Consolidated ADE parameter extraction and workflow testing**

Replaces both `test-ade-parameter-extraction.sh` and `test-ade-parameter-extraction-enhanced.sh` to eliminate duplication while maintaining all functionality.

#### Usage
```bash
# Run comprehensive ADE workflow tests
./tests/integration/test-ade-workflows.sh

# Quick validation mode (faster for CI)
./tests/integration/test-ade-workflows.sh --quick

# Full absolute path (recommended)
/home/runner/work/ai-in-a-box/ai-in-a-box/tests/integration/test-ade-workflows.sh
```

#### What This Script Tests
- Original jq-based parameter extraction logic (backward compatibility)
- New reusable helper script functionality
- Error handling (invalid JSON, missing parameters, non-existent files)
- Parameter sourcing capability for CI workflows
- Cross-reference validation (frontend reading backend AI Foundry config)

### 2. Test-FunctionAppAccess.ps1
**RBAC and resource access validation**

#### Usage
```powershell
# Test Function App access to required resources
./tests/integration/Test-FunctionAppAccess.ps1 -ResourceGroupName "rg-backend" -FunctionAppName "func-app-001" -StorageAccountName "storage001"

# Include AI Foundry resource testing
./tests/integration/Test-FunctionAppAccess.ps1 -ResourceGroupName "my-rg" -FunctionAppName "my-func-app" -StorageAccountName "mystorageaccount" -AIFoundryResourceId "/subscriptions/12345/resourceGroups/ai-rg/providers/Microsoft.CognitiveServices/accounts/my-ai-foundry"
```

### 3. validate-backend-package.sh
**Backend deployment package validation**

#### Usage
```bash
# Validate backend deployment package
./tests/integration/validate-backend-package.sh

# Validate specific package
./tests/integration/validate-backend-package.sh /path/to/backend-deployment.zip
```

### 4. run-backend-tests.sh
**Backend test suite runner**

#### Usage
```bash
# Build and run backend tests
./tests/integration/run-backend-tests.sh

# Full absolute path (recommended)
/home/runner/work/ai-in-a-box/ai-in-a-box/tests/integration/run-backend-tests.sh
```

## 🛠️ Utility Scripts

### 1. extract-ade-parameters.sh
**Reusable ADE parameter extraction helper**

#### Usage
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

# Custom parameter file
./tests/utilities/extract-ade-parameters.sh --file custom-params.json --output json
```

### 2. extract-ade-outputs.sh
**ADE deployment output extraction utility**

#### Usage
```bash
# Extract backend outputs
./tests/utilities/extract-ade-outputs.sh <resource-group> backend

# Extract frontend outputs
./tests/utilities/extract-ade-outputs.sh <resource-group> frontend
```

## 📁 Archive Folder

The `archive/` folder contains deprecated scripts that have been replaced or are no longer actively maintained:

- **test-ade-parameter-extraction.sh** - Replaced by consolidated `test-ade-workflows.sh`
- **test-ade-parameter-extraction-enhanced.sh** - Replaced by consolidated `test-ade-workflows.sh`
- **test-function-access.sh** - Bash version, replaced by PowerShell version for consistency
- **Test-UrlExtraction.sh** - URL extraction testing (legacy)
- **Test-BicepValidation.sh** - Bicep validation testing (legacy)

These scripts are preserved for reference but should not be used in new development.

## 🚀 Quick Start Guide

### For Local Development
1. **Start Azurite**: `./tests/core/Test-AzuriteSetup.ps1`
2. **Test Function App**: `./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"`
3. **Simulate CI**: `./tests/core/simulate-ci-workflow.sh`

### For CI/CD Integration
1. **Health Check**: `./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl $FUNCTION_URL -HealthOnly`
2. **AI Foundry Test**: `./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl $FUNCTION_URL -AiFoundryOnly`
3. **ADE Validation**: `./tests/integration/test-ade-workflows.sh --quick`

### For Deployment Validation
1. **Package Validation**: `./tests/integration/validate-backend-package.sh`
2. **Access Testing**: `./tests/integration/Test-FunctionAppAccess.ps1 -ResourceGroupName $RG -FunctionAppName $FUNC -StorageAccountName $STORAGE`
3. **Backend Tests**: `./tests/integration/run-backend-tests.sh`

## 📊 Test Coverage Summary

| Component | Test Script | Coverage |
|-----------|-------------|----------|
| **Function Endpoints** | Test-FunctionEndpoints.ps1 | Health, createThread, chat, AI Foundry integration |
| **Local Development** | Test-AzuriteSetup.ps1 | Azurite setup and storage connectivity |
| **CI Workflow** | simulate-ci-workflow.sh | Complete build and deployment simulation |
| **ADE Integration** | test-ade-workflows.sh | Parameter extraction and workflow validation |
| **RBAC Permissions** | Test-FunctionAppAccess.ps1 | Function App access to Storage and AI Foundry |
| **Deployment Packages** | validate-backend-package.sh | Package structure and Azure Function requirements |
| **Backend Code** | run-backend-tests.sh | Unit tests and integration tests |

## 🔧 Prerequisites

- **PowerShell 7+** or **Windows PowerShell 5.1**
- **Azure CLI** installed and authenticated (`az login`)
- **jq** utility for JSON processing
- **.NET SDK 8.0+** for backend tests
- **Node.js and npm** for frontend components
- **Azurite** for local storage emulation

## 📈 Best Practices

1. **Always use absolute paths** when calling scripts from CI/CD or other directories
2. **Test locally first** before running CI/CD pipelines
3. **Use appropriate test modes** (HealthOnly for quick checks, Comprehensive for full validation)
4. **Check exit codes** in automation to properly handle failures
5. **Review test output** for warnings and recommendations
6. **Keep tests fast** by using quick modes when full testing isn't needed

## 🆘 Troubleshooting

### Common Issues

1. **PowerShell execution policy**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
2. **Azure CLI not authenticated**: Run `az login` and verify subscription context
3. **Missing dependencies**: Install required tools (jq, Azure CLI, .NET SDK, Node.js)
4. **Path issues**: Always use absolute paths when calling scripts from different directories
5. **Permission errors**: Ensure proper RBAC permissions for resources being tested

### Getting Help

- Check script help: Most scripts support `--help` or have comprehensive header documentation
- Review test output: Scripts provide detailed error messages and troubleshooting guidance
- Examine prerequisites: Ensure all required tools and permissions are in place
- Test incrementally: Start with simple health checks before running comprehensive tests