# Troubleshooting Guide

*Solutions to common issues when deploying and running the AI Foundry SPA.*

## 🎯 Quick Diagnosis

**Start here to identify your issue:**

### 🔍 Is the problem with...?

- **[Deployment](#-deployment-issues)** - Infrastructure creation, resource provisioning, or deployment scripts
- **[Frontend](#-frontend-issues)** - Website loading, UI problems, or browser errors  
- **[Backend](#-backend-issues)** - API endpoints, Function App, or Azure Functions
- **[AI Integration](#-ai-foundry-integration-issues)** - AI responses, conversation memory, or AI Foundry connection
- **[Authentication](#-authentication-and-permissions)** - Azure login, permissions, or access issues
- **[Performance](#-performance-issues)** - Slow responses, timeouts, or resource limits

---

## 🚀 Deployment Issues

### Issue: AI Foundry Resource Not Found or Missing

**Symptoms:**
- Deployment fails with "resource not found" errors for AI Foundry
- Cannot find Cognitive Services or AI Foundry project
- RBAC assignment failures for AI Foundry resources

**Root Cause:**
AI Foundry resources don't exist in the specified location or the orchestrator is configured to use existing resources that aren't available.

**Solutions:**

**1. Check Deployment Configuration**
Verify your `createAiFoundryResourceGroup` parameter setting:
- Set to `true` to create new AI Foundry resources automatically
- Set to `false` to use existing AI Foundry resources (must exist first)

**2. Verify Existing AI Foundry Resources (if using existing)**
```bash
# Check if your AI Foundry Cognitive Services account exists
az cognitiveservices account show \
  --name "your-ai-foundry-resource-name" \
  --resource-group "your-ai-foundry-rg"

# List all AI Foundry resources in your subscription
az cognitiveservices account list --query "[?kind=='AIServices']" -o table
```

**3. Create AI Foundry Resources**
If you want to use existing resources but don't have them:
- Follow the [AI Foundry Setup Guide](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstart/)
- Create the Cognitive Services account and AI project manually
- Create the "AI in A Box" agent
- Then update your deployment parameters with the correct resource names

**4. Use Automated Creation**
Alternatively, set `createAiFoundryResourceGroup: true` in your parameters to let the orchestrator create all AI Foundry resources automatically.

**3. Update Parameters with Correct Information**
```bicep
// In your .bicepparam file - use EXISTING resource details
param aiFoundryResourceGroupName = 'rg-your-actual-ai-foundry-rg'
param aiFoundryResourceName = 'your-actual-cognitive-services-name'
param aiFoundryProjectName = 'your-actual-project-name'
param aiFoundryEndpoint = 'https://your-actual-endpoint.cognitiveservices.azure.com/'
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
# Validate your parameters file
az deployment sub validate \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam" \
  --location "eastus2"
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

## 🌐 Frontend Issues

### Issue: Website Won't Load

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

### Issue: Chat Interface Loads but No AI Responses

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

### Issue: Function App Health Check Fails

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

**3. Check Application Insights**
```bash
# Query recent errors
az monitor app-insights query \
  --app "$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "customProperties.APPINSIGHTS_INSTRUMENTATIONKEY" -o tsv)" \
  --analytics-query "exceptions | where timestamp > ago(1h) | project timestamp, outerMessage, details"
```

### Issue: Function App Cold Start Issues

**Symptoms:**
- First requests are very slow (30+ seconds)
- Timeouts on initial API calls
- Good performance after warm-up

**Solutions:**

**1. Check Consumption Plan Settings**
```bash
# Verify App Service Plan
az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "serverFarmId"

# Consider Premium plan for production
az appservice plan create --name "premium-plan" --resource-group "$FUNCTION_RG" --sku P1V2
```

**2. Implement Keep-Alive (Optional)**
```bash
# Add keep-alive function for production
# This is handled in the codebase with timer triggers
```

---

## 🧠 AI Foundry Integration Issues

### Issue: "AI Foundry Connection Failed"

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

**3. Verify AI Foundry Configuration**
```bash
# Check AI Foundry settings
az functionapp config appsettings show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --setting-names AI_FOUNDRY_ENDPOINT AI_FOUNDRY_DEPLOYMENT AI_FOUNDRY_AGENT_NAME
```

### Issue: "Agent 'AI in A Box' Not Found"

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

### Issue: Conversation Memory Not Working

**Symptoms:**
- AI doesn't remember previous messages
- Each message treated as new conversation
- Thread ID errors

**Solutions:**

**1. Check Thread Management**
- Verify browser stores thread ID correctly
- Check browser localStorage or sessionStorage
- Clear browser cache and try again

**2. Backend Thread Handling**
```bash
# Check logs for thread creation/management
az monitor app-insights query \
  --app "$APP_INSIGHTS_NAME" \
  --analytics-query "traces | where message contains 'thread' | order by timestamp desc | take 20"
```

---

## 🔐 Authentication and Permissions

### Issue: "Access Denied" Errors

**Symptoms:**
- Permission denied when accessing resources
- Role assignment failures
- Cannot create or modify resources

**Solutions:**

**1. Check Your Azure Permissions**
```bash
# List your role assignments
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all --query "[].{Role:roleDefinitionName, Scope:scope}"

# Required roles:
# - Contributor or Owner (for resource management)
# - User Access Administrator (for role assignments)
```

**2. Check Subscription Context**
```bash
# Verify correct subscription
az account show --query "{subscriptionId: id, name: name, state: state}"

# Switch if needed
az account set --subscription "Your Subscription Name"
```

### Issue: Managed Identity Role Assignment Fails

**Symptoms:**
- Cannot assign Azure AI Developer role
- Permission errors during deployment
- Role assignment commands fail

**Solutions:**

**1. Manual Role Assignment**
```bash
# Get resource IDs
AI_FOUNDRY_RESOURCE_ID="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/YOUR_AI_FOUNDRY_RG/providers/Microsoft.CognitiveServices/accounts/YOUR_AI_FOUNDRY_NAME"
PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv)

# Assign role manually
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Azure AI Developer" \
  --scope "$AI_FOUNDRY_RESOURCE_ID"
```

**2. Check Role Definition**
```bash
# Verify Azure AI Developer role exists
az role definition list --name "Azure AI Developer" --query "[0].{Name:roleName, Id:id}"
```

---

## ⚡ Performance Issues

### Issue: Slow Response Times

**Symptoms:**
- API calls take more than 10 seconds
- Frontend feels sluggish
- Timeouts in production

**Analysis:**

**1. Check Function App Performance**
```bash
# Monitor metrics
az monitor metrics list \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$FUNCTION_RG/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME" \
  --metric "AverageResponseTime" \
  --interval PT1M
```

**2. AI Foundry Response Times**
```bash
# Check Application Insights for AI calls
az monitor app-insights query \
  --app "$APP_INSIGHTS_NAME" \
  --analytics-query "dependencies | where name contains 'AI_Foundry' | summarize avg(duration) by bin(timestamp, 5m)"
```

**Solutions:**

**1. Optimize Function App**
- Consider Premium hosting plan
- Increase memory allocation
- Enable Application Insights profiling

**2. Frontend Optimization**
- Implement request caching
- Add loading indicators
- Use request debouncing

---

## 🛠️ Diagnostic Commands

### Complete Health Check Script

```bash
#!/bin/bash
# Complete diagnostic script

echo "=== AI Foundry SPA Diagnostics ==="

# Get resource names
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
FUNCTION_RG=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)
STATIC_APP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].name" -o tsv | head -1)
STATIC_RG=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].resourceGroup" -o tsv | head -1)

echo "Function App: $FUNCTION_APP_NAME (RG: $FUNCTION_RG)"
echo "Static App: $STATIC_APP_NAME (RG: $STATIC_RG)"

# Test backend health
echo "=== Backend Health ==="
BACKEND_URL=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "defaultHostName" -o tsv)
curl -s "https://$BACKEND_URL/api/health" | jq .

# Test frontend
echo "=== Frontend Status ==="
FRONTEND_URL=$(az staticwebapp show --name "$STATIC_APP_NAME" --resource-group "$STATIC_RG" --query "defaultHostname" -o tsv)
curl -s -o /dev/null -w "%{http_code}" "https://$FRONTEND_URL"
echo " - Frontend HTTP Status"

# Check managed identity
echo "=== Managed Identity ==="
PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv)
echo "Principal ID: $PRINCIPAL_ID"

# Check role assignments
echo "=== Role Assignments ==="
az role assignment list --assignee "$PRINCIPAL_ID" --query "[].{Role:roleDefinitionName, Scope:scope}" -o table

echo "=== Diagnostics Complete ==="
```

## 📞 When to Seek Help

### Create a GitHub Issue When:
- You've tried the solutions above
- Error persists after following troubleshooting steps
- You found a potential bug in the codebase
- Documentation needs clarification

### Include in Your Issue:
- **Error messages** (full text)
- **Steps to reproduce** the problem
- **Your environment** (Azure region, resource names)
- **Diagnostic output** from commands above
- **What you've already tried**

---

## 🔗 Related Documentation

- **[Configuration Guide](../configuration/environment-variables.md)** - Fix configuration issues
- **[Deployment Guide](../deployment/deployment-guide.md)** - Deployment troubleshooting
- **[Local Development](../development/local-development.md)** - Development environment issues
- **[GitHub Issues](https://github.com/JFolberth/ai-in-a-box/issues)** - Report new problems

---

**Still having issues?** Create a detailed [GitHub Issue](https://github.com/JFolberth/ai-in-a-box/issues/new) with the diagnostic information above.