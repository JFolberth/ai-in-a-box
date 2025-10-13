# AGENTS.md - Testing

This directory contains a comprehensive test suite for validating the AI Foundry SPA project across all components: infrastructure, backend, frontend, and deployment workflows.

## Testing Strategy

### Test Organization
- **`core/`**: Primary test scripts for daily development and CI/CD validation
- **`integration/`**: Cross-component integration tests and workflow validation
- **`utilities/`**: Reusable helper scripts for parameter extraction and validation
- **`archive/`**: Legacy and deprecated test scripts (maintained for reference)

### Test Levels
1. **Unit Tests**: Component-specific validation (Function endpoints, Bicep templates)
2. **Integration Tests**: Cross-component workflows (ADE, backend packaging, CI simulation)
3. **End-to-End Tests**: Full deployment and validation workflows
4. **Utility Tests**: Helper script validation and parameter extraction

## Core Test Scripts (`core/`)

### Primary Testing Entry Points

#### `Test-FunctionEndpoints.ps1` - **Main Endpoint Validation**
**The primary test script for Function App and AI Foundry integration testing**

```powershell
# Local development testing
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Azure deployment testing
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"

# Health check only (CI/CD fast validation)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -HealthOnly

# AI Foundry integration only
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -AiFoundryOnly

# Comprehensive testing (includes threading)
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -Comprehensive
```

**Test Modes and Coverage:**
- **Standard**: Health check, createThread, basic chat tests
- **HealthOnly**: `/api/health` endpoint validation only
- **AiFoundryOnly**: Health + AI Foundry integration validation
- **SkipChat**: Health and createThread tests, no chat
- **Comprehensive**: All tests including conversation threading

#### `Test-AzuriteSetup.ps1` - **Local Development Environment**
**Validates Azurite emulator setup for local Function App development**

```powershell
# Test Azurite connectivity and storage configuration
./tests/core/Test-AzuriteSetup.ps1

# Validate storage account connection strings
./tests/core/Test-AzuriteSetup.ps1 -Verbose
```

#### `simulate-ci-workflow.sh` - **CI/CD Pipeline Simulation**
**Simulates GitHub Actions CI workflow for local validation**

```bash
# Run complete CI simulation
./tests/core/simulate-ci-workflow.sh

# CI simulation with detailed output
./tests/core/simulate-ci-workflow.sh --verbose
```

### RBAC and Security Testing

#### `Test-FunctionAppRbac.ps1` - **RBAC Diagnostic and Validation**
**Validates Azure Function App RBAC configuration and permissions**

```powershell
# Test RBAC configuration for deployment
./tests/core/Test-FunctionAppRbac.ps1 -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"

# Test with specific managed identity
./tests/core/Test-FunctionAppRbac.ps1 -FunctionAppName "func-app" -ResourceGroupName "rg-name" -ManagedIdentityId "identity-id"
```

### Cross-Platform Testing

#### `Test-CrossPlatformCompatibility.ps1` - **PowerShell Cross-Platform Validation**
**Ensures PowerShell scripts work across Windows, Linux, and macOS**

```powershell
# Test current platform compatibility
./tests/core/Test-CrossPlatformCompatibility.ps1

# Test all deployment scripts for cross-platform compatibility
./tests/core/Test-CrossPlatformCompatibility.ps1 -TestAllScripts
```

## Integration Tests (`integration/`)

### Workflow Integration Testing

#### `test-ade-workflows.sh` - **Azure Deployment Environment Workflows**
**Tests ADE parameter extraction and workflow integration**

```bash
# Complete ADE workflow validation
./tests/integration/test-ade-workflows.sh

# Test specific ADE parameter extraction
./tests/integration/test-ade-workflows.sh --parameters-only

# Test ADE output extraction
./tests/integration/test-ade-workflows.sh --outputs-only
```

**Coverage:**
- jq-based parameter extraction (backward compatibility)
- Enhanced helper script functionality
- Error handling (invalid JSON, missing parameters)
- CI workflow integration simulation
- Multiple output formats (env, json, export)

#### `test-backend-validation.sh` - **Backend Build and Package Validation**
**Comprehensive backend testing, building, and deployment validation**

```bash
# Complete backend validation (build + test + package + validate)
./tests/integration/test-backend-validation.sh

# Validate existing package only
./tests/integration/test-backend-validation.sh --package-only /path/to/backend-deployment.zip

# Test with specific .NET version
./tests/integration/test-backend-validation.sh --dotnet-version 8.0
```

**Coverage:**
- Backend project compilation
- Complete test suite execution
- Deployment package creation and structure validation
- Application assembly verification
- Deployment readiness assessment

#### `test-bicep-validation.sh` - **Infrastructure Template Validation**
**Validates Bicep templates using Azure CLI what-if commands**

```bash
# Validate main orchestrator template
./tests/integration/test-bicep-validation.sh

# Validate specific template file
./tests/integration/test-bicep-validation.sh --template infra/modules/ai-foundry.bicep

# Validate with specific parameters
./tests/integration/test-bicep-validation.sh --parameters infra/dev-orchestrator.parameters.bicepparam
```

## Utility Scripts (`utilities/`)

### Parameter and Output Extraction

#### `extract-ade-parameters.sh` - **ADE Parameter Extraction**
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

#### `extract-ade-outputs.sh` - **ADE Output Extraction**
**Extracts deployment outputs from ADE result files**

```bash
# Extract all outputs
./tests/utilities/extract-ade-outputs.sh

# Extract specific output
./tests/utilities/extract-ade-outputs.sh --key "aiFoundryEndpoint"

# Extract as JSON
./tests/utilities/extract-ade-outputs.sh --format json
```

#### `test-function-access.sh` - **Cross-Platform RBAC Validation**
**Cross-platform validation of Function App access and permissions**

```bash
# Test Function App access
./tests/utilities/test-function-access.sh --function-url "https://func-app.azurewebsites.net"

# Test with specific credentials
./tests/utilities/test-function-access.sh --function-url "https://func-app.azurewebsites.net" --client-id "client-id"
```

## Testing Best Practices

### Test Execution Patterns

#### Local Development Testing Sequence
```powershell
# 1. Test Azurite setup
./tests/core/Test-AzuriteSetup.ps1

# 2. Test cross-platform compatibility
./tests/core/Test-CrossPlatformCompatibility.ps1

# 3. Test local endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# 4. Validate backend build
./tests/integration/test-backend-validation.sh
```

#### Pre-Deployment Validation
```powershell
# 1. Validate Bicep templates
./tests/integration/test-bicep-validation.sh

# 2. Simulate CI workflow
./tests/core/simulate-ci-workflow.sh

# 3. Test ADE workflows
./tests/integration/test-ade-workflows.sh

# 4. Validate deployment package
./tests/integration/test-backend-validation.sh --package-only
```

#### Post-Deployment Validation
```powershell
# 1. Test deployed endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net"

# 2. Test RBAC configuration
./tests/core/Test-FunctionAppRbac.ps1 -FunctionAppName "func-app" -ResourceGroupName "rg-name"

# 3. Validate function access
./tests/utilities/test-function-access.sh --function-url "https://func-app.azurewebsites.net"
```

### Error Handling and Exit Codes

#### PowerShell Test Exit Codes
- **0**: All tests passed
- **1**: Health endpoint failure
- **2**: AI Foundry integration failure
- **3**: Thread creation failure
- **4**: Chat functionality failure

#### Bash Test Exit Codes
- **0**: Success
- **1**: General failure
- **2**: Dependency missing
- **3**: Configuration error
- **4**: Network/connectivity failure

### Test Data Management

#### Test Environment Variables
```powershell
# Required for AI Foundry testing
$env:AI_FOUNDRY_ENDPOINT = "https://your-ai-foundry-endpoint"
$env:AZURE_CLIENT_ID = "your-client-id"
$env:AZURE_TENANT_ID = "your-tenant-id"

# Optional for enhanced testing
$env:TEST_USER_MESSAGE = "Custom test message"
$env:TEST_TIMEOUT = "30"  # seconds
```

#### Mock Data and Fixtures
- Use consistent test messages across all tests
- Implement proper cleanup of test threads and conversations
- Mock external dependencies when possible
- Validate test data against real API contracts

## CI/CD Integration

### GitHub Actions Integration
```yaml
# Example CI workflow step
- name: Run Function Endpoint Tests
  run: |
    ./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "${{ steps.deploy.outputs.function-url }}" -HealthOnly
  shell: pwsh
```

### Test Reporting
- All PowerShell tests support `-Verbose` for detailed output
- Bash scripts use consistent exit codes for CI integration
- Test results are logged to console and optionally to files
- Failed tests provide detailed error information

## Test Development Guidelines

### Creating New Tests

#### PowerShell Test Template
```powershell
#!/usr/bin/env pwsh
#Requires -PSEdition Core

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredParameter,
    
    [Parameter(Mandatory = $false)]
    [string]$OptionalParameter = "default-value"
)

# Test implementation
try {
    Write-Host "Starting test: $($MyInvocation.MyCommand.Name)" -ForegroundColor Cyan
    
    # Test logic here
    
    Write-Host "✅ All tests passed" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "❌ Test failed: $_"
    exit 1
}
```

#### Bash Test Template
```bash
#!/bin/bash
set -euo pipefail

# Test configuration
TEST_NAME="$(basename "$0")"
REQUIRED_TOOLS=("az" "jq" "curl")

# Validate dependencies
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "❌ Required tool not found: $tool"
        exit 2
    fi
done

# Test implementation
echo "🧪 Starting test: $TEST_NAME"

# Test logic here

echo "✅ All tests passed"
exit 0
```

### Test Maintenance

#### Regular Maintenance Tasks
- **Dependency Updates**: Keep test dependencies current
- **API Contract Validation**: Ensure tests match current API contracts
- **Cross-Platform Testing**: Validate on Windows, Linux, and macOS
- **Performance Monitoring**: Monitor test execution times

#### Test Documentation
- Include clear descriptions of what each test validates
- Document expected environment variables and dependencies
- Provide example usage commands
- Maintain changelog of test modifications