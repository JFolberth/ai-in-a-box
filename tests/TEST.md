⚠️ **DEPRECATED** - This file has been replaced by the comprehensive [README.md](./README.md)

# AI Foundry SPA Testing Suite

**🔄 This directory has been reorganized for better maintainability. Please see [README.md](./README.md) for the complete testing guide.**

## Quick Reference

### New Folder Structure
- **📁 core/** - Primary test scripts (Test-FunctionEndpoints.ps1, Test-AzuriteSetup.ps1, simulate-ci-workflow.sh)
- **📁 integration/** - Integration and validation tests 
- **📁 utilities/** - Helper scripts and utilities
- **📁 archive/** - Deprecated/legacy test scripts

### Updated Script Locations

#### Primary Test Script: `core/Test-FunctionEndpoints.ps1`
**Comprehensive endpoint and conversation testing with multiple test modes**

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

The script returns specific exit codes for automated CI/CD integration:

| Exit Code | Meaning | Description |
|-----------|---------|-------------|
| `0` | All tests passed | Success - all selected tests completed successfully |
| `1` | Health endpoint failed | Health check endpoint is not responding or unhealthy |
| `2` | AI Foundry connection failed | AI Foundry integration is not working |
| `3` | Chat functionality failed | Chat endpoints are not working properly |

**📚 For complete documentation, all test scripts, utilities, and detailed examples, please see [README.md](./README.md).**
