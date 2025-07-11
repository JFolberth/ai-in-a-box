#!/bin/bash

# check-azure-openai-quota.sh
#
# SYNOPSIS
#     Checks Azure OpenAI quota usage for a specified subscription and region
#
# DESCRIPTION
#     This script retrieves and displays current Azure OpenAI quota usage using Azure CLI.
#     Shows TPM (Tokens Per Minute) and RPM (Requests Per Minute) for all models.
#
# USAGE
#     ./check-azure-openai-quota.sh SUBSCRIPTION_ID [LOCATION]
#
# EXAMPLES
#     # Basic usage - check eastus2 region
#     ./check-azure-openai-quota.sh "12345678-1234-1234-1234-123456789012"
#
#     # Check specific region
#     ./check-azure-openai-quota.sh "12345678-1234-1234-1234-123456789012" "westus2"
#
#     # With full absolute path
#     bash "C:/Users/BicepDeveloper/repo/ai-in-a-box/scripts/check-azure-openai-quota.sh" "12345678-1234-1234-1234-123456789012"
#
# PREREQUISITES
#     - Azure CLI installed and authenticated (az login)
#     - jq installed for JSON parsing
#     - Reader permissions on the subscription
#
# EXPECTED OUTPUT
#     Displays quota usage for each Azure OpenAI model with status indicators

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 SUBSCRIPTION_ID [LOCATION]"
    echo ""
    echo "Parameters:"
    echo "  SUBSCRIPTION_ID  Azure subscription ID (required)"
    echo "  LOCATION         Azure region (optional, default: eastus2)"
    echo ""
    echo "Examples:"
    echo "  $0 \"12345678-1234-1234-1234-123456789012\""
    echo "  $0 \"12345678-1234-1234-1234-123456789012\" \"westus2\""
    exit 1
}

# Function to get usage status emoji
get_status_emoji() {
    local percentage=$1
    if [ "$percentage" -ge 90 ]; then
        echo "🔴 CRITICAL"
    elif [ "$percentage" -ge 75 ]; then
        echo "🟡 HIGH"
    elif [ "$percentage" -ge 50 ]; then
        echo "🟠 MEDIUM"
    else
        echo "🟢 LOW"
    fi
}

# Check parameters
if [ $# -lt 1 ]; then
    echo "Error: Subscription ID is required"
    show_usage
fi

SUBSCRIPTION_ID="$1"
LOCATION="${2:-eastus2}"

# Validate subscription ID format
if ! echo "$SUBSCRIPTION_ID" | grep -qE '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
    echo "Error: Invalid subscription ID format"
    echo "Expected format: 12345678-1234-1234-1234-123456789012"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    echo "Please install jq: https://jqlang.github.io/jq/download/"
    exit 1
fi

echo "=== Azure OpenAI Quota Checker ==="
echo "Subscription: $SUBSCRIPTION_ID"
echo "Region: $LOCATION"
echo ""

# Check Azure CLI authentication
echo "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    echo "Error: Azure CLI not authenticated. Please run 'az login' first."
    exit 1
fi

# Set subscription context
echo "Setting subscription context..."
if ! az account set --subscription "$SUBSCRIPTION_ID" &> /dev/null; then
    echo "Error: Failed to set subscription context. Please verify subscription ID and permissions."
    exit 1
fi

# Get quota usage
echo "Fetching quota information..."
URI="https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.CognitiveServices/locations/$LOCATION/usages?api-version=2023-05-01"

if ! RESPONSE=$(az rest --method GET --uri "$URI" 2>/dev/null); then
    echo "Error: Failed to retrieve quota information"
    echo "Please ensure you have Reader permissions on the subscription"
    exit 1
fi

echo ""
echo "=== Azure OpenAI Quota Usage in $LOCATION ==="
echo ""

# Parse and display quota information
QUOTA_FOUND=false
AVAILABLE_MODELS=()

# Process each usage item
echo "$RESPONSE" | jq -r '.value[] | select(.name.value | test("TPM|RPM")) | [.name.localizedValue, .currentValue, .limit, (.name.value | test("TPM"))] | @tsv' | \
while IFS=$'\t' read -r model_name current_value limit is_tpm; do
    QUOTA_FOUND=true
    
    if [ "$limit" -gt 0 ]; then
        percentage=$((current_value * 100 / limit))
    else
        percentage=0
    fi
    
    available=$((limit - current_value))
    status=$(get_status_emoji "$percentage")
    
    # Clean up model name
    clean_model=$(echo "$model_name" | sed 's/Tokens Per Minute (thousands) - //g' | sed 's/Requests Per Minute - //g')
    
    echo "Model: $clean_model"
    printf "  Current: %'d\n" "$current_value"
    printf "  Limit: %'d\n" "$limit"
    printf "  Available: %'d\n" "$available"
    echo "  Usage: $percentage% $status"
    echo ""
    
    # Track models with available TPM capacity
    if [ "$is_tpm" = "true" ] && [ "$available" -gt 0 ]; then
        capacity_units=$((available / 1000))
        AVAILABLE_MODELS+=("$clean_model: $available TPM available ($capacity_units capacity units)")
    fi
done

# Check if any quota was found
if [ "$QUOTA_FOUND" = false ]; then
    echo "⚠️  No Azure OpenAI quota found in this region."
    echo "   This could mean:"
    echo "   • Azure OpenAI is not available in $LOCATION"
    echo "   • Your subscription doesn't have Azure OpenAI access"
    echo "   • The region name is incorrect"
    echo ""
    echo "💡 To request Azure OpenAI access:"
    echo "   https://aka.ms/oai/stuquotarequest"
else
    # Show summary of available capacity
    if [ ${#AVAILABLE_MODELS[@]} -gt 0 ]; then
        echo "=== Models with Available Capacity (TPM) ==="
        for model in "${AVAILABLE_MODELS[@]}"; do
            echo "✅ $model"
        done
    else
        echo "⚠️  No models have available TPM capacity in this region"
        echo "   Consider:"
        echo "   • Using a different region"
        echo "   • Reducing capacity on existing deployments"
        echo "   • Requesting quota increase"
    fi
    
    echo ""
    echo "💡 Helpful Links:"
    echo "   • Request quota increase: https://aka.ms/oai/stuquotarequest"
    echo "   • Manage quotas: https://ai.azure.com/"
    echo "   • Quota documentation: https://learn.microsoft.com/azure/ai-foundry/openai/how-to/quota"
fi
