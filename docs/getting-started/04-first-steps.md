# First Steps: Test and Verify Your Deployment

*Validate that your AI Foundry SPA is working correctly and explore its features.*

## 🎯 What We'll Test

Now that your AI app is deployed, let's make sure everything works correctly:

- ✅ Frontend loads and displays correctly
- ✅ Backend API responds to health checks
- ✅ AI Foundry integration works end-to-end
- ✅ Conversation memory persists across messages
- ✅ Monitoring and logging capture data

**Time needed**: 10 minutes

## 🌐 Step 1: Access Your Application

### Find Your Application URLs

If you don't have them from the previous step:

```bash
# Get Static Web App URL
STATIC_APP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].name" -o tsv | head -1)
STATIC_RG=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].resourceGroup" -o tsv | head -1)
FRONTEND_URL=$(az staticwebapp show --name "$STATIC_APP_NAME" --resource-group "$STATIC_RG" --query "defaultHostname" -o tsv)

# Get Function App URL
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
FUNCTION_RG=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)
BACKEND_URL=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "defaultHostName" -o tsv)

echo "📱 Frontend: https://$FRONTEND_URL"
echo "🔧 Backend: https://$BACKEND_URL"
echo "❤️ Health: https://$BACKEND_URL/api/health"
```

### Open Your Application

1. **Open the frontend URL** in your web browser
2. You should see a clean chat interface with:
   - Welcome message
   - Text input box at the bottom
   - Send button or Enter key functionality

## 🔍 Step 2: Test Backend Health

### Check Basic Health

```bash
# Test basic health endpoint
curl "https://$BACKEND_URL/api/health" | jq .

# Expected response structure:
# {
#   "Status": "Healthy",
#   "Timestamp": "2024-01-15T10:30:00Z",
#   "Version": "1.0.0.0",
#   "Environment": "Development",
#   "AiFoundryEndpoint": "https://your-ai-foundry...",
#   "AgentName": "AI in A Box",
#   "ConnectionStatus": "Connected - Agent 'AI in A Box' accessible"
# }
```

### Validate Response Details

**✅ Healthy Response Indicators:**
- `"Status": "Healthy"`
- `"ConnectionStatus"` contains "Connected"
- `"AgentName": "AI in A Box"`
- `"AiFoundryEndpoint"` shows your correct endpoint

**🚨 Warning Signs:**
- `"Status": "Unhealthy"`
- `"ConnectionStatus"` contains "Failed" or "Error"
- Missing `AgentId` field
- Empty or incorrect endpoint

### Advanced Health Test

```bash
# Test with verbose output
curl -v "https://$BACKEND_URL/api/health" 2>&1 | grep -E "(HTTP|Status|ConnectionStatus)"
```

## 💬 Step 3: Test AI Conversations

### First Conversation Test

1. **Open your frontend URL** in the browser
2. **Type a simple message**: "Hello, can you introduce yourself?"
3. **Press Enter** or click Send
4. **Wait for response** (should take 2-5 seconds)

**Expected behavior:**
- Message appears in chat history immediately
- Loading indicator shows while waiting
- AI response appears with proper formatting
- Response mentions "AI in A Box" or similar introduction

### Test Conversation Memory

Continue the conversation to test persistent memory:

1. **Second message**: "What was my first question?"
2. **Wait for response**
3. **Verify**: AI should reference your first question about introduction

**Expected behavior:**
- AI remembers previous messages in the conversation
- Responses build on previous context
- No errors or "I don't recall" responses

### Test Complex Interactions

Try some advanced scenarios:

```
Test Message: "Can you help me understand Azure AI Foundry?"
Expected: Detailed explanation of AI Foundry concepts

Test Message: "What can I build with this technology?"
Expected: Examples of AI applications and use cases

Test Message: "How does conversation memory work?"
Expected: Explanation referencing this current conversation
```

## 🔄 Step 4: Test Technical Features

### Test Message Threading

**Browser Developer Tools Test:**
1. **Open browser dev tools** (F12)
2. **Go to Network tab**
3. **Send a message** in the chat
4. **Look for API calls** to your backend URL
5. **Check response** includes thread information

**Expected API behavior:**
- First message creates a new thread
- Subsequent messages use the same thread ID
- Responses include message history context

### Test Error Handling

**Intentional Error Test:**
1. **Disconnect internet** briefly
2. **Send a message**
3. **Reconnect internet**
4. **Verify error handling** shows user-friendly message

### Test Performance

**Response Time Test:**
```bash
# Time the health endpoint
time curl -s "https://$BACKEND_URL/api/health" > /dev/null

# Should typically be under 2 seconds
```

**Load Test (Optional):**
```bash
# Simple load test (requires 'ab' tool)
ab -n 10 -c 2 "https://$BACKEND_URL/api/health"
```

## 📊 Step 5: Verify Monitoring

### Check Application Insights

1. **Go to Azure Portal** → Your Resource Group
2. **Find Application Insights** resource
3. **Open "Live Metrics"** blade
4. **Send messages** in your chat app
5. **Watch metrics** update in real-time

**Expected metrics:**
- Request count increases
- Response times appear
- No failed requests (green indicators)
- Dependency calls to AI Foundry show up

### Review Logs

```bash
# Query Application Insights logs (requires az cli extension)
az monitor app-insights query \
  --app "$APP_INSIGHTS_NAME" \
  --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, resultCode, duration" \
  --output table
```

### Test Alerts (Optional)

If you want to set up basic monitoring alerts:

```bash
# Create a simple health check alert
az monitor metrics alert create \
  --name "Function App Health" \
  --resource-group "$FUNCTION_RG" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$FUNCTION_RG/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME" \
  --condition "count requests < 1" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## ✅ Step 6: Validation Checklist

Go through this checklist to confirm everything is working:

### Frontend Validation:
- [ ] Web page loads without errors
- [ ] Chat interface displays correctly
- [ ] Messages can be typed and sent
- [ ] Responses appear in chat history
- [ ] Page works on both desktop and mobile

### Backend Validation:
- [ ] Health endpoint returns "Healthy" status
- [ ] AI Foundry connection shows "Connected"
- [ ] API responds within reasonable time (< 5 seconds)
- [ ] No error messages in browser console

### AI Integration Validation:
- [ ] AI responds to simple questions
- [ ] Responses are relevant and helpful
- [ ] Conversation memory works across messages
- [ ] AI identifies itself correctly (AI in A Box)
- [ ] No "I can't access that" or connection errors

### Monitoring Validation:
- [ ] Application Insights shows live metrics
- [ ] Request telemetry appears in logs
- [ ] No critical errors in monitoring dashboards
- [ ] Response times are reasonable (< 5 seconds)

## 🚨 Common Issues and Quick Fixes

### Issue: Frontend Loads but No Response to Messages

**Check:**
```bash
# Verify backend is accessible
curl "https://$BACKEND_URL/api/health"

# Check CORS configuration
az functionapp cors show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG"
```

**Fix:**
```bash
# Add frontend URL to CORS if missing
az functionapp cors add --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --allowed-origins "https://$FRONTEND_URL"
```

### Issue: "AI Foundry Connection Failed"

**Check:**
```bash
# Verify managed identity has correct role
az role assignment list \
  --assignee $(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv) \
  --query "[?roleDefinitionName=='Azure AI Developer']"
```

**Fix:**
```bash
# Assign Azure AI Developer role if missing
PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query principalId -o tsv)
AI_FOUNDRY_SCOPE="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/YOUR_AI_FOUNDRY_RG/providers/Microsoft.CognitiveServices/accounts/YOUR_AI_FOUNDRY_NAME"

az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Azure AI Developer" \
  --scope "$AI_FOUNDRY_SCOPE"
```

### Issue: Slow Response Times

**Check:**
```bash
# Monitor function performance
az monitor metrics list \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$FUNCTION_RG/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME" \
  --metric "AverageResponseTime"
```

**Common causes:**
- Cold start (first request after idle period)
- AI Foundry latency (varies by model)
- Network connectivity issues

## 🎯 Performance Expectations

### Normal Performance Metrics:

**Response Times:**
- Health endpoint: < 1 second
- First AI message: 3-10 seconds (includes thread creation)
- Subsequent messages: 2-5 seconds
- Static content: < 500ms

**Availability:**
- Frontend: 99.9% (Static Web Apps SLA)
- Backend: 99.95% (Functions Consumption SLA)
- AI Foundry: 99.9% (Cognitive Services SLA)

## 🚦 Next Steps

Your AI Foundry SPA is now validated and working! Here's what to explore next:

### Immediate Next Steps:
1. **[Customization Guide](../configuration/customization.md)** - Make it your own
2. **[Local Development](../development/local-development.md)** - Set up development environment
3. **[Configuration Options](../configuration/environment-variables.md)** - Explore advanced settings

### Advanced Features:
1. **[Multi-Environment Setup](../deployment/multi-environment.md)** - Create staging/production environments
2. **[Monitoring Setup](../operations/monitoring.md)** - Advanced monitoring and alerting
3. **[Security Hardening](../advanced/security.md)** - Production security considerations

### Development:
1. **[Project Structure](../development/project-structure.md)** - Understand the codebase
2. **[Testing Guide](../development/testing-guide.md)** - Run automated tests
3. **[Debugging](../development/debugging.md)** - Troubleshoot development issues

---

**🎉 Congratulations!** Your AI Foundry SPA is fully validated and ready for use. Choose your next adventure from the guides above!