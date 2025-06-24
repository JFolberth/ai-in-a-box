# AI Foundry SPA Testing Suite

This directory contains comprehensive test scripts to verify Azure Function App functionality and AI Foundry integration.

## Test Scripts

### Primary Test Script: `Test-FunctionEndpoints.ps1`
**Comprehensive endpoint and conversation testing**

#### Usage
```powershell
# Test local development endpoints
.\Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test deployed Azure Function App
.\Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net"
```

#### What This Script Tests
- **Thread Creation**: Verifies `/api/createThread` endpoint
- **Message Sending**: Tests `/api/sendMessage` endpoint
- **Conversation Threading**: Validates thread persistence across multiple messages
- **Unique Responses**: Ensures each message gets a distinct AI response
- **Response Quality**: Checks response length and content validity
- **Error Handling**: Tests invalid inputs and error scenarios

#### Example Output
```
🧪 Testing Function App Endpoints: http://localhost:7071
================================================================

✅ Thread Creation Test
   Thread ID: thread_abc123def456
   Response time: 234ms

✅ First Message Test  
   Question: What is cancer treatment?
   Response length: 512 characters
   Response time: 4.2s

✅ Follow-up Message Test
   Question: What about side effects?
   Response length: 487 characters  
   Response time: 3.8s

✅ Conversation Threading Verification
   ✓ Both messages used same thread ID
   ✓ Responses are unique (different content)
   ✓ Context maintained across conversation

🎉 All endpoint tests passed!
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
