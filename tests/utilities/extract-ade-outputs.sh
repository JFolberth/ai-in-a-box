#!/bin/bash
# extract-ade-outputs.sh
# Reusable script to extract ADE deployment outputs

set -e

# Parameters
RESOURCE_GROUP="${1:-}"
OUTPUT_TYPE="${2:-backend}"  # backend or frontend

if [ -z "$RESOURCE_GROUP" ]; then
    echo "❌ Error: Resource group name is required"
    echo "Usage: $0 <resource-group> [backend|frontend]"
    exit 1
fi

echo "🔍 Extracting ADE outputs from resource group: $RESOURCE_GROUP"
echo "📋 Output type: $OUTPUT_TYPE"

# Function to find deployment with enhanced fallback logic
find_deployment() {
    local rg="$1"
    
    # Try to find successful deployment first
    local deployment_name
    deployment_name=$(az deployment group list \
        --resource-group "$rg" \
        --query "[?provisioningState=='Succeeded'] | sort_by(@, &timestamp) | [-1].name" \
        --output tsv 2>/dev/null || echo "")
    
    # If no succeeded deployment found, try any completed deployment
    if [ -z "$deployment_name" ] || [ "$deployment_name" = "null" ]; then
        echo "⚠️ No 'Succeeded' deployment found, checking for any completed deployments..."
        deployment_name=$(az deployment group list \
            --resource-group "$rg" \
            --query "sort_by(@, &timestamp) | [-1].name" \
            --output tsv 2>/dev/null || echo "")
    fi
    
    echo "$deployment_name"
}

# Function to get deployment outputs
get_deployment_outputs() {
    local rg="$1"
    local deployment_name="$2"
    
    az deployment group show \
        --resource-group "$rg" \
        --name "$deployment_name" \
        --query "properties.outputs" \
        --output json 2>/dev/null || echo "{}"
}

# Function to extract backend URLs
extract_backend_urls() {
    local outputs="$1"
    local rg="$2"
    
    # Try deployment outputs first
    local function_app_url
    local function_app_name
    function_app_url=$(echo "$outputs" | jq -r '.functionAppUrl.value // empty' 2>/dev/null)
    function_app_name=$(echo "$outputs" | jq -r '.functionAppName.value // empty' 2>/dev/null)
    
    # Fallback to resource query if outputs not available
    if [ -z "$function_app_url" ] || [ "$function_app_url" = "null" ]; then
        echo "⚠️ functionAppUrl not found in deployment outputs, falling back to resource query..."
        
        function_app_name=$(az functionapp list \
            --resource-group "$rg" \
            --query "[0].name" \
            --output tsv 2>/dev/null || echo "")
        
        if [ -n "$function_app_name" ] && [ "$function_app_name" != "null" ]; then
            local hostname
            hostname=$(az functionapp show \
                --name "$function_app_name" \
                --resource-group "$rg" \
                --query "defaultHostName" \
                --output tsv 2>/dev/null || echo "")
            
            if [ -n "$hostname" ] && [ "$hostname" != "null" ]; then
                function_app_url="https://$hostname"
            fi
        fi
    fi
    
    # Validate results
    if [ -z "$function_app_url" ] || [ "$function_app_url" = "https://" ] || [ "$function_app_url" = "null" ]; then
        echo "❌ Invalid or empty Function App URL: '$function_app_url'"
        return 1
    fi
    
    if [ -z "$function_app_name" ] || [ "$function_app_name" = "null" ]; then
        echo "❌ Invalid or empty Function App Name: '$function_app_name'"
        return 1
    fi
    
    # Output results
    echo "FUNCTION_APP_NAME=$function_app_name"
    echo "FUNCTION_APP_URL=$function_app_url"
    
    return 0
}

# Function to extract frontend URLs
extract_frontend_urls() {
    local outputs="$1"
    local rg="$2"
    
    # Try deployment outputs first
    local static_web_app_url
    local static_web_app_name
    static_web_app_url=$(echo "$outputs" | jq -r '.staticWebsiteUrl.value // empty' 2>/dev/null)
    static_web_app_name=$(echo "$outputs" | jq -r '.staticWebAppName.value // empty' 2>/dev/null)
    
    # Fallback to resource query if outputs not available
    if [ -z "$static_web_app_url" ] || [ "$static_web_app_url" = "null" ]; then
        echo "⚠️ staticWebsiteUrl not found in deployment outputs, falling back to resource query..."
        
        static_web_app_name=$(az staticwebapp list \
            --resource-group "$rg" \
            --query "[0].name" \
            --output tsv 2>/dev/null || echo "")
        
        if [ -n "$static_web_app_name" ] && [ "$static_web_app_name" != "null" ]; then
            local hostname
            hostname=$(az staticwebapp show \
                --name "$static_web_app_name" \
                --resource-group "$rg" \
                --query "defaultHostname" \
                --output tsv 2>/dev/null || echo "")
            
            if [ -n "$hostname" ] && [ "$hostname" != "null" ]; then
                static_web_app_url="https://$hostname"
            fi
        fi
    fi
    
    # Validate results
    if [ -z "$static_web_app_url" ] || [ "$static_web_app_url" = "https://" ] || [ "$static_web_app_url" = "null" ]; then
        echo "❌ Invalid or empty Static Web App URL: '$static_web_app_url'"
        return 1
    fi
    
    if [ -z "$static_web_app_name" ] || [ "$static_web_app_name" = "null" ]; then
        echo "❌ Invalid or empty Static Web App Name: '$static_web_app_name'"
        return 1
    fi
    
    # Output results
    echo "STATIC_WEB_APP_NAME=$static_web_app_name"
    echo "STATIC_WEB_APP_URL=$static_web_app_url"
    
    return 0
}

# Main logic
DEPLOYMENT_NAME=$(find_deployment "$RESOURCE_GROUP")

if [ -z "$DEPLOYMENT_NAME" ] || [ "$DEPLOYMENT_NAME" = "null" ]; then
    echo "❌ No deployment found in resource group: $RESOURCE_GROUP"
    echo "🔍 Available deployments:"
    az deployment group list --resource-group "$RESOURCE_GROUP" --query "[].{name:name, state:provisioningState, timestamp:timestamp}" --output table 2>/dev/null || echo "Failed to list deployments"
    echo "🔍 Available resources in resource group:"
    az resource list --resource-group "$RESOURCE_GROUP" --query "[].{name:name, type:type}" --output table 2>/dev/null || echo "Failed to list resources"
    exit 1
fi

echo "📦 Found deployment: $DEPLOYMENT_NAME"

# Get deployment outputs
DEPLOYMENT_OUTPUTS=$(get_deployment_outputs "$RESOURCE_GROUP" "$DEPLOYMENT_NAME")

echo "🔍 Available deployment outputs:"
echo "$DEPLOYMENT_OUTPUTS" | jq -r 'keys[]' 2>/dev/null || echo "No outputs found or invalid JSON"

# Extract URLs based on output type
case "$OUTPUT_TYPE" in
    "backend")
        if extract_backend_urls "$DEPLOYMENT_OUTPUTS" "$RESOURCE_GROUP"; then
            echo "✅ Successfully extracted backend URLs"
        else
            echo "❌ Failed to extract backend URLs"
            exit 1
        fi
        ;;
    "frontend")
        if extract_frontend_urls "$DEPLOYMENT_OUTPUTS" "$RESOURCE_GROUP"; then
            echo "✅ Successfully extracted frontend URLs"
        else
            echo "❌ Failed to extract frontend URLs"
            exit 1
        fi
        ;;
    *)
        echo "❌ Invalid output type: $OUTPUT_TYPE (must be 'backend' or 'frontend')"
        exit 1
        ;;
esac