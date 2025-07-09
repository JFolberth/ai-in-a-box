# Troubleshooting Guide

This document provides solutions to common issues you may encounter when deploying the AI in a Box application.

## � Preflight Check Failures

The quickstart deployment script includes automatic preflight checks to validate Azure permissions and quota before deployment. These checks help catch common issues early.

### Azure OpenAI Quota Exceeded

**Error Message:**
```
(InsufficientQuota) This operation require 150 new capacity in quota Tokens Per Minute (thousands) - gpt-4.1-mini, which is bigger than the current available capacity 0. The current quota usage is 450 and the quota limit is 450 for quota Tokens Per Minute (thousands) - gpt-4.1-mini.
```

**Root Cause:**
You don't have sufficient Azure OpenAI quota available to deploy the requested model capacity. This is the **most common deployment failure** for new Azure subscriptions.

**Solutions:**

1. **Use Existing AI Foundry Resources** (Recommended for quota issues):
   ```powershell
   .\deploy-quickstart.ps1 -UseExistingAiFoundry
   ```
   Then provide existing AI Foundry resource details when prompted.

2. **Check Current Quota Usage**:
   ```bash
   # List all OpenAI accounts and their locations
   az cognitiveservices account list --query "[?kind=='OpenAI'].{name:name, location:location, sku:sku.name}" --output table
   
   # Check quota usage in specific region
   az cognitiveservices usage list --location eastus2 --output table
   ```

3. **Request Quota Increase**:
   - Visit [Azure OpenAI Quota Management](https://aka.ms/azure-openai-quota)
   - Submit a quota increase request for your required region
   - Typical approval time: 1-3 business days

4. **Free Up Existing Quota**:
   ```bash
   # List existing model deployments
   az cognitiveservices account deployment list --name "your-openai-account" --resource-group "your-rg"
   
   # Delete unused deployments to free quota
   az cognitiveservices account deployment delete --name "your-openai-account" --resource-group "your-rg" --deployment-name "unused-deployment"
   ```

5. **Deploy with Lower Capacity**:
   Modify `dev-orchestrator.parameters.bicepparam`:
   ```bicep
   param aiFoundryDeploymentCapacity = 50  // Reduced from 150
   ```

**Microsoft Learn Resources:**
- [Azure OpenAI Quota and Limits](https://learn.microsoft.com/azure/ai-services/openai/quotas-limits)
- [Request quota increases](https://learn.microsoft.com/azure/ai-services/openai/quotas-limits#how-to-request-increases-to-the-default-quotas-and-limits)

### Insufficient Azure Permissions

**Error Message:**
```
The client 'user@domain.com' with object id 'xxx' does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write'
```

**Root Cause:**
Your Azure account lacks the necessary permissions to create resources or assign RBAC roles.

**Required Permissions:**
- **Subscription-level roles**: Owner, Contributor, or User Access Administrator
- **Resource-specific permissions**: 
  - Create resource groups
  - Deploy ARM/Bicep templates  
  - Assign RBAC roles to managed identities
  - Register resource providers

**Solutions:**

1. **Check Current Permissions**:
   ```bash
   # View your role assignments
   az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
   
   # Check subscription-level roles
   az role assignment list --assignee $(az account show --query user.name -o tsv) --scope /subscriptions/$(az account show --query id -o tsv) --output table
   ```

2. **Request Access from Administrator**:
   Contact your Azure subscription administrator to assign:
   - **Contributor** role at subscription level (minimum)
   - **User Access Administrator** role if RBAC assignment errors occur

3. **Use Service Principal (CI/CD)**:
   For automated deployments, create a service principal:
   ```bash
   az ad sp create-for-rbac --name "ai-foundry-spa-deploy" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

**Microsoft Learn Resources:**
- [Azure RBAC roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Troubleshoot RBAC](https://learn.microsoft.com/azure/role-based-access-control/troubleshooting)

### Resource Provider Not Registered

**Error Message:**
```
The subscription is not registered to use namespace 'Microsoft.CognitiveServices'
```

**Root Cause:**
Required Azure resource providers are not registered in your subscription.

**Solution:**
The preflight checks will identify unregistered providers. Register them manually:

```bash
# Register all required providers
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.CognitiveServices  
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Authorization

# Check registration status
az provider list --query "[?namespace=='Microsoft.CognitiveServices'].{Namespace:namespace, State:registrationState}" --output table
```

**Microsoft Learn Resources:**
- [Azure resource providers](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types)

## �🚨 Azure Function App Deployment Issues

### Missing .azurefunctions Directory Error

**Error Message:**
```
InvalidPackageContentException: Package content validation failed: Cannot find required .azurefunctions directory at root level in the .zip package.
```

**Root Cause:**
The `.azurefunctions` directory was missing from the deployment package. This commonly occurs when:
1. GitHub Actions artifacts don't preserve directories starting with `.` (dot directories)
2. The build process doesn't properly include all required Function App files
3. Manual zip creation excludes hidden directories

**Solution:**
This issue has been resolved in the CI/CD pipeline by:
1. Creating the deployment zip during the build process (before artifact upload)
2. Using the pre-packaged zip file for deployment instead of creating it on-demand
3. Adding verification steps to ensure the `.azurefunctions` directory is present

**Verification Steps:**
To verify a deployment package is valid:
```bash
# Check if .azurefunctions directory is present in the zip
unzip -l deployment-package.zip | grep -E "\.azurefunctions|azurefunctions/"

# Expected output should show:
#         0  DATE TIME   .azurefunctions/
#    102136  DATE TIME   .azurefunctions/function.deps.json
#      4096  DATE TIME   .azurefunctions/Microsoft.Azure.Functions.Worker.Extensions.dll
#    777696  DATE TIME   .azurefunctions/Microsoft.WindowsAzure.Storage.dll
#     24064  DATE TIME   .azurefunctions/Microsoft.Azure.WebJobs.Extensions.FunctionMetadataLoader.dll
#     83832  DATE TIME   .azurefunctions/Microsoft.Azure.WebJobs.Host.Storage.dll

# Or use the validation script
./tests/validate-backend-package.sh path/to/backend-deployment.zip
```

**Manual Fix (if needed):**
If you encounter this issue with manual deployments:
1. Ensure you're using `dotnet publish` to create the deployment package
2. Use `Compress-Archive` (PowerShell) or `zip -r` (Linux/Mac) to create the zip file
3. Verify the `.azurefunctions` directory is included before deployment

### ZIP Deploy Package Path Error

**Error Message:**
```
Error: Failed to deploy web package to Function App.
Error: Execution Exception (state: PublishContent) (step: Invocation)
Error: When request Azure resource at PublishContent, oneDeploy : Failed to use /path/to/temp_web_package.zip as OneDeploy content
Error: Package deployment using ZIP Deploy failed.
```

**Root Cause:**
The Azure Functions action was receiving a directory path instead of a zip file path, or the zip file was corrupted/malformed.

**Solution:**
Fixed in CI/CD pipeline by:
1. Ensuring the Functions action receives the correct zip file path
2. Adding validation of the deployment package before deployment
3. Verifying package contents include all required components

**Related Files:**
- `.github/workflows/shared-backend-build.yml` - Package creation and validation
- `.github/workflows/ci.yml` - Deployment process
- `tests/validate-backend-package.sh` - Package validation script
- `deploy-scripts/deploy-backend-func-code.ps1` - Manual deployment script

## 🌐 Static Web App Deployment Issues

### SWA CLI Authentication Failures

**Error Message:**
```
Error: Unable to authenticate. Please check your credentials.
```

**Solution:**
Ensure you're logged into Azure CLI before deploying:
```bash
az login
az account show  # Verify you're logged in with the correct account
```

### Build Output Missing

**Error Message:**
```
Build output not found. Please run 'npm run build' first
```

**Solution:**
Run the frontend build before deployment:
```bash
cd src/frontend
npm install
npm run build
```

## 🔐 Authentication and Permissions Issues

### Azure CLI Not Authenticated

**Error Message:**
```
Please run 'az login' to authenticate with Azure CLI
```

**Solution:**
```bash
az login
```

### Insufficient Permissions

**Error Message:**
```
Forbidden: User does not have permission to perform this action
```

**Solution:**
Ensure your account has the required RBAC roles:
- **Function App**: Contributor or Website Contributor
- **Static Web App**: Contributor or Static Web App Contributor
- **Resource Group**: Contributor (if creating resources)

## 📋 Build and Test Issues

### .NET Build Failures

**Common Issues:**
1. **Missing .NET SDK**: Install .NET 8 SDK
2. **Package restore failures**: Run `dotnet restore` first
3. **Configuration issues**: Ensure you're building in Release configuration

**Solution:**
```bash
cd src/backend
dotnet restore
dotnet build --configuration Release
dotnet test --configuration Release
```

### Frontend Build Failures

**Common Issues:**
1. **Missing Node.js**: Install Node.js 18+ and npm
2. **Package installation failures**: Clear npm cache and reinstall
3. **Build script errors**: Check package.json scripts

**Solution:**
```bash
cd src/frontend
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
npm run build
```

## 🚨 Azure OpenAI Quota Issues

### Insufficient Quota Error During Deployment

**Error Message:**
```
(InsufficientQuota) This operation require 150 new capacity in quota Tokens Per Minute (thousands) - gpt-4.1-mini, which is bigger than the current available capacity 0. The current quota usage is 450 and the quota limit is 450 for quota Tokens Per Minute (thousands) - gpt-4.1-mini.
```

**Root Cause:**
Azure OpenAI models require quota allocation in units of **Tokens Per Minute (TPM)**. Each subscription has a quota limit per region per model. When deploying new AI Foundry resources with model deployments, you need sufficient available quota to allocate TPM to the new deployment.

**Understanding the Error:**
- **Required**: 150,000 TPM (150 capacity units × 1,000 TPM per unit)
- **Available**: 0 TPM remaining 
- **Current Usage**: 450,000 TPM out of 450,000 TPM limit
- **Model**: gpt-4.1-mini in the specified region

**Immediate Solutions:**
#### 1. **Reduce Model Capacity** (Quickest Fix)
Modify your deployment parameters to use less TPM:
```bicep
// In your .bicepparam file, reduce the capacity:
param aiFoundryDeploymentCapacity = 30  // Reduced from 150 to 30 (30K TPM)
```

#### 2. **Skip Model Deployment** (Test Infrastructure Only)
Set capacity to 0 to deploy infrastructure without model:
```bicep
// Deploy infrastructure only, add models later via portal
param aiFoundryDeploymentCapacity = 0
```

#### 3. **Use Existing AI Foundry Resources**
Point to existing resources instead of creating new ones:
```bicep
// Use existing AI Foundry resources
param createAiFoundryResourceGroup = false
param aiFoundryResourceName = 'your-existing-ai-foundry-resource'
param aiFoundryResourceGroupName = 'your-existing-rg'
param aiFoundryProjectName = 'your-existing-project'
```

**Checking Your Quota Usage:**
Use this PowerShell script to check your current quota allocation:
```powershell
# Check-AzureOpenAIQuota.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus2"
)

# Get access token
$accessToken = az account get-access-token --query accessToken --output tsv

# Check quota usage
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CognitiveServices/locations/$Location/usages?api-version=2023-05-01"

$headers = @{
    Authorization = "Bearer $accessToken"
    'Content-Type' = 'application/json'
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    
    Write-Host "=== Azure OpenAI Quota Usage in $Location ===" -ForegroundColor Green
    Write-Host ""
    
    foreach ($usage in $response.value) {
        if ($usage.name.value -like "*TPM*" -or $usage.name.value -like "*RPM*") {
            $percentage = if ($usage.limit -gt 0) { 
                [math]::Round(($usage.currentValue / $usage.limit) * 100, 2) 
            } else { 0 }
            
            $status = if ($percentage -ge 90) { "🔴 CRITICAL" } 
                     elseif ($percentage -ge 75) { "🟡 HIGH" }
                     elseif ($percentage -ge 50) { "🟠 MEDIUM" }
                     else { "🟢 LOW" }
            
            Write-Host "Model: $($usage.name.localizedValue)" -ForegroundColor White
            Write-Host "  Current: $($usage.currentValue)" -ForegroundColor Cyan
            Write-Host "  Limit: $($usage.limit)" -ForegroundColor Cyan
            Write-Host "  Available: $($usage.limit - $usage.currentValue)" -ForegroundColor $(if (($usage.limit - $usage.currentValue) -gt 0) { "Green" } else { "Red" })
            Write-Host "  Usage: $percentage% $status" -ForegroundColor $(if ($percentage -ge 90) { "Red" } elseif ($percentage -ge 75) { "Yellow" } else { "Green" })
            Write-Host ""
        }
    }
    
} catch {
    Write-Error "Failed to retrieve quota information: $($_.Exception.Message)"
    Write-Host "Please ensure you have proper permissions and the Azure CLI is authenticated." -ForegroundColor Yellow
}
```

**Usage Example:**
```powershell
# Save the script above as Check-AzureOpenAIQuota.ps1
& "C:\Users\BicepDeveloper\repo\ai-in-a-box\scripts\Check-AzureOpenAIQuota.ps1" -SubscriptionId "your-subscription-id" -Location "eastus2"
```

**Alternative: Azure CLI Method**
```bash
# Check your subscription's quota ID and offer type
az rest --method GET --uri "https://management.azure.com/subscriptions/{subscription-id}?api-version=2020-01-01" --query "quotaId"

# Check usage in a specific region
az rest --method GET --uri "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.CognitiveServices/locations/eastus2/usages?api-version=2023-05-01"
```

**Requesting Quota Increases:**
If you need more quota, submit a request through the official channels:
1. **Azure Portal Method:**
   - Go to [Azure AI Foundry Portal](https://ai.azure.com/)
   - Navigate to **Management** → **Model quota**
   - Select **Request quota increase**
2. **Direct Request Form:**
   - Submit via [Official Quota Increase Form](https://aka.ms/oai/stuquotarequest)
   - Priority given to customers with traffic that consumes existing quota
   - Requests processed in order received
3. **What to Include in Request:**
   - Business justification for increased quota
   - Expected usage patterns and traffic volume
   - Model and region requirements
   - Timeline for deployment

**Managing Existing Deployments:**
To free up quota from existing deployments:
```powershell
# List all Azure OpenAI deployments in your subscription
az cognitiveservices account deployment list --name "your-openai-resource-name" --resource-group "your-rg"

# Update deployment capacity (reduce TPM allocation)
az cognitiveservices account deployment create \
  --name "your-openai-resource-name" \
  --resource-group "your-rg" \
  --deployment-name "gpt-4.1-mini" \
  --model-name "gpt-4.1-mini" \
  --model-version "2025-04-14" \
  --sku-capacity 30 \
  --sku-name "Standard"
```

**Model-Specific Quota Requirements:**
| Model | Capacity Unit | TPM per Unit | RPM per Unit |
|-------|---------------|--------------|--------------|
| GPT-4.1-mini | 1 | 1,000 | 6 |
| GPT-4o | 1 | 1,000 | 6 |
| GPT-4 | 1 | 1,000 | 6 |
| o1-mini | 1 | 10,000 | 1 |
| o1-preview | 1 | 6,000 | 1 |

**Prevention Tips:**
- Always check quota availability before deploying new AI resources
- Start with smaller capacity allocations and scale up as needed
- Monitor quota usage regularly in production environments
- Consider using existing AI Foundry resources for development/testing

**Microsoft Learn Resources:**
- [Manage Azure OpenAI Quota](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/quota)
- [Azure OpenAI Quotas and Limits](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/quotas-limits)
- [Request Quota Increases](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/deploy-models-openai#quota-for-deploying-and-inferencing-a-model)

## 🔧 Deployment Errors

### "The content for this response was already consumed" Error

**Error Message:**
```
Error: The content for this response was already consumed.
```

**Root Cause:**
This is an Azure CLI error that occurs when the HTTP response stream is consumed multiple times. This commonly happens during deployment commands when the CLI attempts to read the same response multiple times.

**Solutions:**

1. **Use --debug flag for detailed error information**:
   ```bash
   az deployment sub create --template-file infra/main-orchestrator.bicep --parameters @infra/dev-orchestrator.parameters.bicepparam --location eastus2 --name my-deployment --debug
   ```

2. **Clear Azure CLI cache**:
   ```bash
   az cache purge
   az account clear
   az login
   ```

3. **Use a different deployment name**:
   ```bash
   # Generate unique deployment name
   az deployment sub create --name "deployment-$(date +%Y%m%d-%H%M%S)" --template-file infra/main-orchestrator.bicep --parameters @infra/dev-orchestrator.parameters.bicepparam --location eastus2
   ```

4. **Wait and retry**:
   - Sometimes this is a transient Azure API issue
   - Wait 5-10 minutes and retry the deployment

5. **Use PowerShell instead of Bash**:
   ```powershell
   # PowerShell tends to handle Azure CLI responses more reliably
   az deployment sub create --template-file "infra/main-orchestrator.bicep" --parameters "@infra/dev-orchestrator.parameters.bicepparam" --location "eastus2" --name "my-deployment"
   ```

## 📋 Preflight Check Failures