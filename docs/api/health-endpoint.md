# Health Endpoint API Reference

## Overview

The AI Foundry SPA Function App includes a comprehensive health endpoint that provides detailed information about the application's status, AI Foundry connectivity, and system health.

## Endpoint Specification

### GET `/api/health`

Returns the current health status of the Function App and its dependencies.

**Authentication:** Anonymous (no authentication required)
**Method:** GET
**Content-Type:** application/json

### Response Format

#### Healthy Response (200 OK)

```json
{
  "Status": "Healthy",
  "Timestamp": "2025-06-26T03:15:00Z",
  "Version": "1.0.0.0",
  "Environment": "Development",
  "AiFoundryEndpoint": "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject",
  "AgentName": "AI in A Box",
  "AgentId": "asst_dH7M0nbmdRblhSQO8nIGIYF4",
  "ConnectionStatus": "Connected - Agent 'AI in A Box' accessible",
  "Details": {
    "ManagedIdentity": "Active - System-assigned managed identity available",
    "AiFoundryAccess": "Authorized - Agent access confirmed",
    "LastHealthCheck": "2025-06-26T03:15:00Z"
  }
}
```

#### Unhealthy Response (503 Service Unavailable)

```json
{
  "Status": "Unhealthy",
  "Timestamp": "2025-06-26T03:15:00Z",
  "Error": "Health check failed",
  "Details": {
    "Exception": "InvalidOperationException",
    "Message": "Failed to initialize AI Foundry client"
  }
}
```

## Response Fields

### Root Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `Status` | string | Overall health status: "Healthy", "Degraded", or "Unhealthy" |
| `Timestamp` | string (ISO 8601) | UTC timestamp when health check was performed |
| `Version` | string | Assembly version of the Function App |
| `Environment` | string | Azure Functions environment (Development, Production, etc.) |
| `AiFoundryEndpoint` | string | AI Foundry project endpoint URL |
| `AgentName` | string | Name of the AI agent being used |
| `AgentId` | string | Unique identifier of the AI agent |
| `ConnectionStatus` | string | AI Foundry connection status with details |
| `Error` | string | Error message (only present when unhealthy) |

### Details Object

| Field | Type | Description |
|-------|------|-------------|
| `ManagedIdentity` | string | Status of Azure Managed Identity |
| `AiFoundryAccess` | string | AI Foundry access permission status |
| `LastHealthCheck` | string (ISO 8601) | Timestamp of the health check |
| `Exception` | string | Exception type (only present when unhealthy) |
| `Message` | string | Exception message (only present when unhealthy) |

## Connection Status Values

### AI Foundry Connection Status

- **"Connected - Agent '{AgentName}' accessible"**: Successfully connected and agent is accessible
- **"Disconnected - Client initialization failed"**: Failed to initialize AI Foundry client
- **"Disconnected - Agent not found"**: Agent ID not found in AI Foundry
- **"Disconnected - {ExceptionType}: {Message}"**: Connection failed with specific error

### Managed Identity Status

- **"Active - System-assigned managed identity available"**: System-assigned MI is active
- **"Active - User-assigned managed identity configured"**: User-assigned MI is configured
- **"Local Development - Azure CLI credentials"**: Running locally with Azure CLI auth
- **"Inactive - No identity detected"**: No managed identity or credentials found
- **"Error - {Message}"**: Error checking managed identity status

### AI Foundry Access Status

- **"Authorized - Agent access confirmed"**: Successfully accessed the agent
- **"Unauthorized - Cannot initialize client"**: Failed to create AI Foundry client
- **"Unauthorized - Agent not accessible"**: Agent exists but not accessible
- **"Unauthorized - Authentication failed"**: Authentication to AI Foundry failed
- **"Error - {ExceptionType}: {Message}"**: Access check failed with specific error

## Usage Examples

### Basic Health Check

```bash
curl -X GET "https://your-function-app.azurewebsites.net/api/health"
```

### Health Check with PowerShell

```powershell
$response = Invoke-RestMethod -Uri "https://your-function-app.azurewebsites.net/api/health" -Method Get
Write-Host "Status: $($response.Status)"
Write-Host "AI Foundry: $($response.ConnectionStatus)"
```

### CI/CD Integration

```bash
# Health check with retry logic
max_attempts=10
attempt=1
health_passed=false

while [ $attempt -le $max_attempts ]; do
  if curl -f -s "https://your-function-app.azurewebsites.net/api/health" -o /dev/null; then
    echo "✅ Health endpoint responding!"
    health_passed=true
    break
  else
    echo "⏳ Health endpoint not ready yet (attempt $attempt/$max_attempts)..."
    sleep 30
  fi
  attempt=$((attempt + 1))
done
```

## CORS Support

The health endpoint supports Cross-Origin Resource Sharing (CORS) for browser-based applications:

- **Access-Control-Allow-Origin**: `*`
- **Access-Control-Allow-Methods**: `GET, POST, OPTIONS`
- **Access-Control-Allow-Headers**: `Content-Type, Authorization`

## Monitoring Integration

The health endpoint is designed for integration with monitoring systems:

### Azure Application Insights

The endpoint automatically logs health check results to Application Insights when configured.

### Load Balancer Health Probes

Configure your load balancer to use `/api/health` as the health probe endpoint:

- **Path**: `/api/health`
- **Method**: GET
- **Expected Status**: 200
- **Timeout**: 30 seconds
- **Interval**: 30 seconds

### Azure Monitor

Create custom alerts based on health endpoint responses:

```kusto
// Alert when health endpoint returns non-200 status
requests
| where name == "health"
| where resultCode != 200
| project timestamp, resultCode, customDimensions
```

## Troubleshooting

### Common Issues

#### Health Endpoint Returns 404

- Verify the Function App is deployed correctly
- Check that the health endpoint function is included in the deployment
- Ensure the route is `/api/health` (case-sensitive)

#### Connection Status Shows "Disconnected"

- **Client initialization failed**: Check AI Foundry endpoint URL and permissions
- **Agent not found**: Verify the agent ID is correct and exists in AI Foundry
- **Authentication failed**: Check managed identity configuration and RBAC permissions

#### Managed Identity Shows "Inactive"

- Verify system-assigned managed identity is enabled on the Function App
- Check that required environment variables are set (MSI_ENDPOINT, MSI_SECRET)
- Ensure proper RBAC roles are assigned to the managed identity

### Diagnostic Steps

1. **Check Function App logs** in Azure Portal or Application Insights
2. **Verify AI Foundry configuration** in environment variables
3. **Test managed identity** using Azure CLI: `az account show`
4. **Validate RBAC permissions** for the Function App's managed identity
5. **Test local development** using Azure CLI credentials

## Security Considerations

- The health endpoint provides system information that could be useful for attackers
- Consider restricting access in production environments if sensitive information is exposed
- Monitor health endpoint access patterns for unusual activity
- The endpoint does not expose secrets or connection strings directly

## Implementation Notes

- Health checks include actual AI Foundry connectivity tests (not just configuration validation)
- Managed identity status is checked using environment variables and Azure metadata
- The endpoint uses async operations to avoid blocking the Function App
- Comprehensive error handling ensures the endpoint remains responsive even during failures
- CORS headers are included to support browser-based monitoring dashboards

## Related Documentation

- [Configuration Reference](../configuration/configuration-reference.md) - Complete configuration guide
- [Troubleshooting Guide](../operations/troubleshooting.md) - Common issues and solutions
- [Local Development](../development/local-development.md) - Development setup and testing
