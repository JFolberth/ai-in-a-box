# AI Foundry SPA Testing Suite

This directory contains comprehensive test scripts to verify Azure Function App functionality and AI Foundry integration.

## Test Scripts

### Primary Test Script: `Test-FunctionEndpoints.ps1`
**Comprehensive endpoint and conversation testing with multiple test modes**

#### Usage
```powershell
# Test local development endpoints (standard mode)
.\Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test deployed Azure Function App
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net"

# Health endpoint only (fast check for CI/CD)
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -HealthOnly

# AI Foundry integration validation only
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -AiFoundryOnly

# Skip chat endpoint tests (useful for basic connectivity)
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -SkipChat

# Comprehensive testing (includes threading tests)
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-app.azurewebsites.net" -Comprehensive
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
| `4` | Threading tests failed | Conversation threading is not working |

#### What This Script Tests

**Health Endpoint Testing:**
- **Health Status**: Verifies `/api/health` endpoint responds with 200 OK
- **AI Foundry Connection**: Validates AI Foundry connectivity status
- **Managed Identity**: Checks managed identity configuration
- **Response Format**: Validates JSON response structure and required fields

**Core Functionality Testing:**
- **Thread Creation**: Verifies `/api/createThread` endpoint
- **Message Sending**: Tests `/api/chat` endpoint with various message types
- **Conversation Threading**: Validates thread persistence across multiple messages
- **Unique Responses**: Ensures each message gets a distinct AI response
- **Response Quality**: Checks response length and content validity
- **Error Handling**: Tests invalid inputs and error scenarios

**AI Foundry Integration Testing:**
- **Connection Validation**: Verifies AI Foundry client can be initialized
- **Agent Access**: Confirms the configured agent is accessible
- **Real AI Responses**: Tests actual AI message processing (not simulation)
- **Authentication**: Validates managed identity permissions for AI Foundry

#### Example Output

**Health-Only Mode:**
```
🔍 Testing Function App Endpoints...
🎯 Target URL: https://func-app.azurewebsites.net
🏥 Running HEALTH-ONLY tests

=== HEALTH ENDPOINT TESTING ===

🏥 Testing Health Endpoint: https://func-app.azurewebsites.net/api/health
✅ Health Status: Healthy
🕒 Timestamp: 2025-06-26T03:15:00Z
📋 Version: 1.0.0.0
🌍 Environment: Production
🤖 Agent: AI in A Box (asst_dH7M0nbmdRblhSQO8nIGIYF4)
🔗 AI Foundry: Connected - Agent 'AI in A Box' accessible
🔐 Managed Identity: Active - System-assigned managed identity available
🔑 AI Foundry Access: Authorized - Agent access confirmed

============================================================
🎯 TEST RESULTS SUMMARY
============================================================
✅ Health Endpoint: PASSED
============================================================
🎉 ALL TESTS PASSED!
🔢 Exit Code: 0
```

**Standard Mode:**
```
🔍 Testing Function App Endpoints...
🎯 Target URL: http://localhost:7071
📋 Running STANDARD test suite

=== HEALTH ENDPOINT TESTING ===
✅ Health Status: Healthy
🔗 AI Foundry: Connected - Agent 'AI in A Box' accessible

=== CREATE THREAD TESTING ===
✅ Thread Creation Test
   Thread ID: thread_abc123def456
   Response time: 234ms

=== CHAT ENDPOINT TESTING ===
✅ First Message Test  
   Question: What are my survival rates?
   Response length: 512 characters
   Response time: 4.2s

✅ Second Message Test
   Question: What treatment options are available?
   Response length: 487 characters  
   Response time: 3.8s

============================================================
🎯 TEST RESULTS SUMMARY
============================================================
✅ Health Endpoint: PASSED
✅ Create Thread: PASSED
✅ Chat Functionality: PASSED
============================================================
🎉 ALL TESTS PASSED!
🔢 Exit Code: 0
```

**AI Foundry Integration Mode:**
```
🔍 Testing Function App Endpoints...
🎯 Target URL: https://func-app.azurewebsites.net
🤖 Running AI FOUNDRY-ONLY tests

🤖 Testing AI Foundry Integration...
🏥 Testing Health Endpoint: https://func-app.azurewebsites.net/api/health
✅ Health Status: Healthy
🔗 AI Foundry: Connected - Agent 'AI in A Box' accessible
🧪 Testing AI chat functionality...
✅ AI Integration Test Successful
📝 Response Length: 127 characters
🧵 Thread ID: thread_xyz789

============================================================
🎯 TEST RESULTS SUMMARY
============================================================
✅ AI Foundry Integration: PASSED
============================================================
🎉 ALL TESTS PASSED!
🔢 Exit Code: 0
```

### Resource Access Test: `Test-FunctionAppAccess.ps1`
**RBAC and resource access validation**

#### Usage  
```powershell
.\Test-FunctionAppAccess.ps1 -ResourceGroupName "rg-ai-foundry-spa-backend-dev-001" -FunctionAppName "func-ai-foundry-spa-backend-dev-001" -StorageAccountName "stfnbackspa001"
```

## What These Scripts Test

### 1. Endpoint Functionality ✅ (Test-FunctionEndpoints.ps1)
- **createThread endpoint**: Thread creation and ID generation
- **sendMessage endpoint**: Message processing and AI response generation
- **Conversation persistence**: Thread continuity across multiple messages
- **Response uniqueness**: Each message gets distinct AI responses
- **Error handling**: Invalid inputs and timeout scenarios
- **Performance**: Response times and reliability

### 2. Function App Resource Access ✅ (Test-FunctionAppAccess.ps1)
- **Managed Identity**: System-assigned identity configuration
- **Storage Access**: RBAC permissions for Function App storage
- **AI Foundry Access**: Azure AI Developer role verification
- **Application Settings**: Required configuration validation
- **Function Status**: Runtime and HTTPS configuration

### 3. Azurite Setup ✅ (Test-AzuriteSetup.ps1)  
- **Local development**: Azurite emulator connectivity
- **Storage emulation**: Blob, queue, and table service testing
- **Function App integration**: Local development storage configuration

## Key Testing Features

### 🔄 **Real AI Integration Testing**
The endpoint tests verify:
- Real AI Foundry AI in A Box agent responses
- Proper conversation threading with context retention
- Robust polling mechanisms for run completion
- Message filtering to return only latest assistant responses

### 🔒 **Security & RBAC Validation**
- **Least Privilege**: Validates appropriate role assignments
- **Managed Identity**: Ensures secure, credential-free access
- **Cross-Resource Access**: Tests Function App access to AI Foundry in different resource groups

### � **Performance & Reliability**
- **Response Time Monitoring**: Tracks API response performance
- **Timeout Handling**: Validates robust error handling
- **Retry Mechanisms**: Tests failure recovery patterns
3. **Subscription-level** (inherited permissions, highest scope)

### 🧹 **Configuration Conflict Detection**
Identifies conflicting storage configuration that can cause MSI token errors:
- AVM managed identity vs. manual connection string configuration
- Provides actionable remediation steps

### 📊 **Comprehensive Reporting**
- Color-coded output for easy visual scanning
- Detailed scope and inheritance information
- Lists all available roles when expected roles are missing
- Actionable troubleshooting guidance

## Troubleshooting Guide

### MSI Token Errors
If you see "MSI token request failed" errors:

1. **Wait for RBAC propagation** (5-10 minutes)
2. **Restart Function App**:
   ```bash
   az functionapp restart --name $FunctionAppName --resource-group $ResourceGroupName
   ```
3. **Remove conflicting settings** (scripts will detect these):
   - `AzureWebJobsStorage__accountName`
   - `AzureWebJobsStorage`
4. **Verify storage account allows managed identity access**

### Missing RBAC Assignments
If roles are missing:

1. **Check all scopes** - the scripts check resource, RG, and subscription scopes
2. **Review inheritance** - permissions might be inherited from parent scopes
3. **Verify principal ID** - ensure the managed identity exists and is enabled
4. **Check role assignments in Azure Portal** for visual confirmation

### Role Assignment Best Practices
- ✅ **Use resource-scoped assignments** when possible
- ✅ **Prefer service-specific roles** (Storage Blob Data Owner vs. Contributor)
- ❌ **Avoid broad permissions** unless absolutely necessary
- ❌ **Don't use Owner/Contributor** for data plane access

## Example Output

```
🔍 Testing Azure Function App Resource Access
================================================

1️⃣ Testing Function App Managed Identity...
✅ System-assigned managed identity is enabled
   Principal ID: 12345678-1234-1234-1234-123456789012

2️⃣ Testing Storage Account Access...
✅ Storage access available via: Storage Blob Data Owner (✅ Optimal)
   Scope: /subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/...
   📍 Direct assignment to storage account

3️⃣ Testing AI Foundry Access...
✅ AI Foundry access available via: Azure AI Developer (✅ Optimal)
   Scope: /subscriptions/.../resourceGroups/.../providers/Microsoft.CognitiveServices/accounts/...
   📍 Direct assignment to AI Foundry resource

4️⃣ Testing Function App Configuration...
✅ No conflicting storage settings found (using AVM managed identity)
✅ APPLICATIONINSIGHTS_CONNECTION_STRING is configured
✅ AI_FOUNDRY_PROJECT_URL is configured
✅ AI_FOUNDRY_AGENT_ID is configured

5️⃣ Testing Function App Status...
✅ Function App State: Running
✅ Runtime Version: v8.0
✅ HTTPS Only: true

🏁 Resource Access Test Completed
```

## Integration with CI/CD

These scripts can be integrated into deployment pipelines to validate RBAC configuration:

```yaml
- name: Test Function App Access
  run: |
    ./tests/Test-FunctionAppAccess.ps1 -ResourceGroupName "${{ env.BACKEND_RESOURCE_GROUP }}" -FunctionAppName "${{ env.FUNCTION_APP_NAME }}" -StorageAccountName "${{ env.STORAGE_ACCOUNT_NAME }}" -AIFoundryResourceId "${{ env.AI_FOUNDRY_RESOURCE_ID }}"
  shell: pwsh
```

This ensures that deployments are validated for proper RBAC configuration before proceeding to subsequent stages.
