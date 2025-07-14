# Troubleshooting Guide

*Solutions to common issues when deploying and running the AI Foundry SPA.*

## 🎯 Quick Diagnosis

**Start here to identify your issue:**

### 🔍 Is the problem with...?

- **[Preflight Checks](#-preflight-check-failures)** - Azure permissions, quota, and service availability validation
- **[Deployment](#-deployment-issues)** - Infrastructure creation, resource provisioning, or deployment scripts
- **[Frontend](#-frontend-issues)** - Website loading, UI problems, or browser errors  
- **[Backend](#-backend-issues)** - API endpoints, Function App, or Azure Functions
- **[AI Integration](#-ai-foundry-integration-issues)** - AI responses, conversation memory, or AI Foundry connection
- **[Authentication](#-authentication-and-permissions)** - Azure login, permissions, or access issues
- **[Performance](#-performance-issues)** - Slow responses, timeouts, or resource limits

---

## 🔍 Preflight Check Failures

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

---

## 🚀 Deployment Issues

### AI Foundry Resource Not Found or Missing

**Symptoms:**
- Deployment fails with "resource not found" errors for AI Foundry
- Cannot find Cognitive Services or AI Foundry project
- RBAC assignment failures for AI Foundry resources

**Root Cause:**
AI Foundry resources don't exist in the specified location or the deployment script is configured to use existing resources that aren't available.

**Solutions:**

**1. For Brownfield Deployment (Using Existing Resources)**
You can use existing resources in two ways:
- **Command-line flags**: Use `-UseExistingAiFoundry` and/or `-UseExistingLogAnalytics` flags
- **Interactive prompting**: Run script without flags and it will ask if you want to use existing resources

If you choose to use existing AI Foundry resources, ensure you have:
- **Resource Group Name** where your AI Foundry resource exists
- **AI Foundry Resource Name** (Cognitive Services account name)
- **AI Foundry Project Name** within that resource
- **Agent Name** (if you have an existing agent to use)

Similarly, for existing Log Analytics resources, ensure you have:
- **Resource Group Name** where your Log Analytics workspace exists
- **Log Analytics Workspace Name**

Verify your resources exist:
```bash
# Check if your AI Foundry Cognitive Services account exists
az cognitiveservices account show \
  --name "your-ai-foundry-resource-name" \
  --resource-group "your-ai-foundry-rg"

# List all AI Foundry resources in your subscription
az cognitiveservices account list --query "[?kind=='AIServices']" -o table
```

**2. Create AI Foundry Resources**
If you want to use existing resources but don't have them:
- Follow the [AI Foundry Setup Guide](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstart/)
- Create the Cognitive Services account and AI project manually
- Create the "AI in A Box" agent
- Then use `-UseExistingAiFoundry` and provide the resource details when prompted

**3. Use Automated Creation (Greenfield)**
Alternatively, run the script without flags to let it create all AI Foundry resources automatically.

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
   az deployment sub create --template-file infra/main-orchestrator.bicep --parameters applicationName=myapp location=eastus2 --name my-deployment --debug
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
   az deployment sub create --name "deployment-$(date +%Y%m%d-%H%M%S)" --template-file infra/main-orchestrator.bicep --parameters applicationName=myapp location=eastus2
   ```

4. **Wait and retry**:
   - Sometimes this is a transient Azure API issue
   - Wait 5-10 minutes and retry the deployment

5. **Use PowerShell instead of Bash**:
   ```powershell
   # PowerShell tends to handle Azure CLI responses more reliably
   az deployment sub create --template-file "infra/main-orchestrator.bicep" --parameters applicationName=myapp location=eastus2 --name "my-deployment"
   ```

### Issue: Bicep Deployment Fails

**Symptoms:**
- `az deployment` commands fail
- Resource creation errors
- Permission denied errors

**Common Causes & Solutions:**

**1. Insufficient Permissions**
```bash
# Check your role assignments
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all

# Required: Contributor or Owner role
# Solution: Ask Azure admin for proper permissions
```

**2. Resource Name Conflicts**
```bash
# Check if resources already exist
az resource list --query "[?contains(name, 'ai-foundry-spa')]" -o table

# Solution: Use different resource names or delete conflicting resources
```

**3. Invalid Parameters**
```bash
# Validate deployment with current script approach
.\deploy-scripts\deploy-quickstart.ps1 -SkipValidation:$false
```

**4. Subscription Limits**
```bash
# Check subscription limits
az vm list-usage --location "eastus2" -o table

# Solution: Request limit increase or use different region
```

### Issue: Function App Deployment Package Error

**Symptoms:**
```
InvalidPackageContentException: Cannot find required .azurefunctions directory
```

**Root Cause:** Missing `.azurefunctions` directory in deployment package

**Solution:**
```bash
# Ensure proper build process
cd src/backend
dotnet clean
dotnet restore
dotnet publish -c Release -o publish

# Verify .azurefunctions directory exists
ls -la publish/.azurefunctions/

# Create deployment zip properly
cd publish
zip -r ../backend-deployment.zip .
```

### Issue: Static Web App Deployment Fails

**Symptoms:**
- Frontend deployment errors
- Build failures in CI/CD
- Missing static content

**Solutions:**

**1. Build Issues**
```bash
cd src/frontend

# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

# Build locally first
npm run build
```

**2. Environment Variables**
```bash
# Check environment file exists
ls -la .env.local .env.production

# Verify required variables
cat .env.local | grep VITE_
```

---

## 🔐 Authentication and Permissions

### Agent Deployment Fails in GitHub Codespaces

**Symptoms:**
- Agent deployment succeeds locally but fails in GitHub Codespaces
- Authentication errors when calling AI Foundry APIs
- "Insufficient permissions" or "Access denied" errors during agent operations
- Token scope or authentication method errors

**Root Cause:**
GitHub Codespaces uses **device code authentication** by default, which has different token scopes and authentication flows compared to browser-based authentication used in local development. This can cause issues with AI Foundry API calls that require specific token scopes.

**🚨 CRITICAL: Codespaces Limitation**
Agent deployment from GitHub Codespaces is **not recommended** and may fail due to authentication limitations. This is a known limitation of the Codespaces authentication model.

**Solutions:**

**1. Use Local Development Environment (Recommended)**
```bash
# Clone repository locally
git clone https://github.com/your-org/ai-in-a-box.git
cd ai-in-a-box

# Run deployment from local environment
.\deploy-scripts\deploy-quickstart.ps1
```

**2. Use Azure DevBox (Alternative)**
Azure DevBox provides a cloud-based development environment with proper Azure authentication:
```bash
# Set up DevBox from the devbox/ directory
# DevBox has proper Azure authentication configured
.\deploy-scripts\deploy-quickstart.ps1
```

**3. Hybrid Approach (Codespaces + Local)**
Deploy infrastructure from Codespaces, but deploy agent locally:
```bash
# In Codespaces: Deploy infrastructure only
.\deploy-scripts\deploy-quickstart.ps1  # Skip agent deployment when prompted

# Locally: Deploy agent with proper authentication
.\deploy-scripts\deploy-agent.ps1 -AiFoundryEndpoint "your-endpoint"
```

**Why This Happens:**
- **Device Code Auth**: Codespaces uses device code authentication which has limited token scopes
- **Token Scope Differences**: Different authentication methods provide different levels of access to Azure services
- **Conditional Access**: Some organizations have conditional access policies that restrict device code authentication
- **API Compatibility**: AI Foundry APIs may require specific authentication flows not available in device code authentication

**Best Practices:**
- ✅ **Use local development** for agent deployment and testing
- ✅ **Use Azure DevBox** for cloud-based development with proper authentication
- ✅ **Use Codespaces** for infrastructure deployment and code editing
- ❌ **Avoid agent deployment from Codespaces** due to authentication limitations

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

---

## 🌐 Frontend Issues

### Website Won't Load

**Symptoms:**
- Blank page or error messages
- "Site can't be reached" errors
- 404 Not Found errors

**Diagnosis Steps:**

**1. Check Static Web App Status**
```bash
# Get your Static Web App details
STATIC_APP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].name" -o tsv | head -1)
RESOURCE_GROUP=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].resourceGroup" -o tsv | head -1)

# Check status
az staticwebapp show --name "$STATIC_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "{status: properties.repositoryUrl, url: properties.defaultHostname}"
```

**2. Verify Deployment**
```bash
# Check recent deployments
az staticwebapp list-environments --name "$STATIC_APP_NAME" --resource-group "$RESOURCE_GROUP"
```

### Chat Interface Loads but No AI Responses

**Symptoms:**
- Messages send but no responses
- Loading indicators persist
- Console errors about backend connection

**Diagnosis:**

**1. Check Backend Connection**
```bash
# Test health endpoint
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
FUNCTION_RG=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)
BACKEND_URL=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "defaultHostName" -o tsv)

curl "https://$BACKEND_URL/api/health"
```

**2. Check Browser Console**
- Open Developer Tools (F12)
- Look for CORS errors or network failures
- Check if API calls reach the backend

**3. Verify CORS Configuration**
```bash
# Check CORS settings
az functionapp cors show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"

# Add frontend URL if missing
FRONTEND_URL=$(az staticwebapp show --name "$STATIC_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "defaultHostname" -o tsv)
az functionapp cors add --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --allowed-origins "https://$FRONTEND_URL"
```

---

## ⚙️ Backend Issues

### Function App Health Check Fails

**Symptoms:**
- Health endpoint returns errors
- "Service Unavailable" messages
- Backend not responding

**Diagnosis Steps:**

**1. Check Function App Status**
```bash
# Verify Function App is running
az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "{state: properties.state, hostName: properties.defaultHostName}"

# Check recent logs
az monitor activity-log list --resource-group "$FUNCTION_RG" --offset 1h
```

**2. Check Function App Settings**
```bash
# Verify configuration
az functionapp config appsettings list --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "[?contains(name, 'AI_FOUNDRY')]"
```

---

## 🧠 AI Foundry Integration Issues

### "AI Foundry Connection Failed"

**Symptoms:**
- Health endpoint shows connection errors
- AI responses never arrive
- Authentication failures

**Diagnosis:**

**1. Verify Managed Identity**
```bash
# Check if managed identity is enabled
az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"

# Enable if needed
az functionapp identity assign --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"
```

**2. Check Role Assignments**
```bash
# Get managed identity principal ID
PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv)

# Check Azure AI Developer role
az role assignment list --assignee "$PRINCIPAL_ID" --query "[?roleDefinitionName=='Azure AI Developer']"
```

### "Agent 'AI in A Box' Not Found"

**Symptoms:**
- Health check shows agent not accessible
- Specific error about agent not found

**Solutions:**

**1. Verify Agent Exists**
- Check Azure AI Foundry portal
- Confirm agent name matches exactly
- Ensure agent is deployed and accessible

**2. Check Agent Name Configuration**
```bash
# Update agent name if different
az functionapp config appsettings set --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --settings AI_FOUNDRY_AGENT_NAME="Your Actual Agent Name"
```

---

## 🔄 Performance Issues

### Slow Initial Response Times

**Symptoms:**
- First requests take 30+ seconds
- Good performance after warm-up
- Cold start issues

**Solutions:**

**1. Function App Warm-up**
The application includes automatic warm-up mechanisms. For production, consider:
- Premium App Service Plan for always-on functionality
- Custom warm-up strategies

**2. Monitor Performance**
```bash
# Check Application Insights for performance metrics
az monitor app-insights query \
  --app "$APP_INSIGHTS_NAME" \
  --analytics-query "requests | where timestamp > ago(1h) | summarize avg(duration) by name | order by avg_duration desc"
```

---

## 🚑 Emergency Recovery

### Complete Redeploy

If you encounter persistent issues, try a complete redeploy:

```bash
# 1. Clean up resources (optional)
az group delete --name "rg-ai-foundry-spa-frontend-dev-*" --yes --no-wait
az group delete --name "rg-ai-foundry-spa-backend-dev-*" --yes --no-wait

# 2. Wait for cleanup to complete (5-10 minutes)

# 3. Redeploy from scratch
.\deploy-scripts\deploy-quickstart.ps1
```

### Get Help

If issues persist:

1. **Check logs** in Azure Portal → Function App → Monitoring → Logs
2. **Review Application Insights** for detailed error tracking
3. **Run health checks** on all components
4. **Validate configuration** against working deployments
5. **Contact support** with specific error messages and deployment logs
