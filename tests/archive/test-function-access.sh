#!/bin/bash

# Azure Function App Resource Access Test (Bash Version)
#
# SYNOPSIS:
#   Verify Azure Function App resource access and RBAC permissions using bash
#
# DESCRIPTION:
#   This script verifies that the Function App has proper access to required Azure resources
#   including Storage Account and AI Foundry resources. It validates managed identity configuration,
#   RBAC role assignments, and Function App settings. This is the bash equivalent of the PowerShell
#   Test-FunctionAppAccess.ps1 script for cross-platform compatibility.
#
# PARAMETERS:
#   -g, --resource-group       Resource group name containing the Function App (required)
#   -f, --function-app         Function App name to test (required)  
#   -s, --storage-account      Storage Account name for access testing (required)
#   -a, --ai-foundry-resource  AI Foundry resource ID (optional)
#   -h, --help                 Show help message
#
# EXAMPLES:
#   ./test-function-access.sh -g "rg-ai-foundry-spa-backend-dev-eus2" -f "func-ai-foundry-spa-backend-dev-eus2" -s "staifoundryspabackdeveus2"
#
#   ./test-function-access.sh -g "my-rg" -f "my-func-app" -s "mystorageaccount" -a "/subscriptions/12345/resourceGroups/ai-rg/providers/Microsoft.CognitiveServices/accounts/my-ai-foundry"
#
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/test-function-access.sh -g "rg-backend" -f "func-app-eus2" -s "storageeus2"
#
#   bash test-function-access.sh -g "rg-prod" -f "func-prod-app" -s "prodstorageacct" -a "/subscriptions/abcd/resourceGroups/ai-prod/providers/Microsoft.CognitiveServices/accounts/ai-prod-foundry"
#
# PREREQUISITES:
#   - Azure CLI installed and authenticated (az login)
#   - jq installed for JSON processing
#   - Bash 4.0+ or compatible shell
#   - Sufficient Azure permissions to read resource information and role assignments
#   - Function App must exist and have system-assigned managed identity enabled
#
# EXPECTED OUTPUT:
#   - Managed identity validation results
#   - Storage Account access permissions analysis  
#   - AI Foundry access permissions (if resource ID provided)
#   - Function App configuration validation
#   - Function App status and runtime information
#   - Recommendations for fixing any permission issues
#
# Azure Function App Resource Access Test
# This script verifies that the Function App has proper access to required resources
# Requires: Azure CLI, jq (for JSON processing)

set -e

# Check for required tools
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed. Please install jq for JSON processing."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 -g <resource-group> -f <function-app-name> -s <storage-account-name> [-a <ai-foundry-resource-id>]"
    exit 1
}

# Parse parameters
while getopts "g:f:s:a:h" opt; do
    case $opt in
        g) RESOURCE_GROUP="$OPTARG" ;;
        f) FUNCTION_APP_NAME="$OPTARG" ;;
        s) STORAGE_ACCOUNT_NAME="$OPTARG" ;;
        a) AI_FOUNDRY_RESOURCE_ID="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check required parameters
if [[ -z "$RESOURCE_GROUP" || -z "$FUNCTION_APP_NAME" || -z "$STORAGE_ACCOUNT_NAME" ]]; then
    echo -e "${RED}❌ Missing required parameters${NC}"
    usage
fi

echo -e "${YELLOW}🔍 Testing Azure Function App Resource Access${NC}"
echo -e "${YELLOW}================================================${NC}"

# Test 1: Check Function App Managed Identity
echo -e "\n${CYAN}1️⃣ Testing Function App Managed Identity...${NC}"

PRINCIPAL_ID=$(az functionapp identity show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query principalId -o tsv 2>/dev/null)

if [[ -n "$PRINCIPAL_ID" && "$PRINCIPAL_ID" != "null" ]]; then
    echo -e "${GREEN}✅ System-assigned managed identity is enabled${NC}"
    echo -e "${GRAY}   Principal ID: $PRINCIPAL_ID${NC}"
else
    echo -e "${RED}❌ System-assigned managed identity is NOT enabled${NC}"
    exit 1
fi

# Test 2: Check Storage Account Access
echo -e "\n${CYAN}2️⃣ Testing Storage Account Access...${NC}"

STORAGE_RESOURCE_ID=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"

# Check direct role assignments on storage account
DIRECT_STORAGE_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$STORAGE_RESOURCE_ID" 2>/dev/null || echo "[]")

# Check inherited role assignments from parent scopes (RG, subscription)
RG_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$RG_SCOPE" 2>/dev/null || echo "[]")
SUBSCRIPTION_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$SUBSCRIPTION_SCOPE" 2>/dev/null || echo "[]")

# Combine all role assignments into a single JSON array
ALL_STORAGE_ROLES=$(echo "$DIRECT_STORAGE_ROLES $RG_ROLES $SUBSCRIPTION_ROLES" | jq -s 'add | unique_by(.id)')

# Check for specific storage roles (in order of preference)
STORAGE_BLOB_DATA_OWNER=$(echo "$ALL_STORAGE_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Storage Blob Data Owner") | .scope' | head -1)
STORAGE_BLOB_DATA_CONTRIBUTOR=$(echo "$ALL_STORAGE_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Storage Blob Data Contributor") | .scope' | head -1)
STORAGE_ACCOUNT_CONTRIBUTOR=$(echo "$ALL_STORAGE_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Storage Account Contributor") | .scope' | head -1)
CONTRIBUTOR=$(echo "$ALL_STORAGE_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Contributor") | .scope' | head -1)
OWNER=$(echo "$ALL_STORAGE_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Owner") | .scope' | head -1)

HAS_STORAGE_ACCESS=false
ACCESS_TYPE=""
ACCESS_SCOPE=""

if [[ -n "$STORAGE_BLOB_DATA_OWNER" && "$STORAGE_BLOB_DATA_OWNER" != "null" ]]; then
    HAS_STORAGE_ACCESS=true
    ACCESS_TYPE="Storage Blob Data Owner (✅ Optimal)"
    ACCESS_SCOPE="$STORAGE_BLOB_DATA_OWNER"
elif [[ -n "$STORAGE_BLOB_DATA_CONTRIBUTOR" && "$STORAGE_BLOB_DATA_CONTRIBUTOR" != "null" ]]; then
    HAS_STORAGE_ACCESS=true
    ACCESS_TYPE="Storage Blob Data Contributor (✅ Good)"
    ACCESS_SCOPE="$STORAGE_BLOB_DATA_CONTRIBUTOR"
elif [[ -n "$STORAGE_ACCOUNT_CONTRIBUTOR" && "$STORAGE_ACCOUNT_CONTRIBUTOR" != "null" ]]; then
    HAS_STORAGE_ACCESS=true
    ACCESS_TYPE="Storage Account Contributor (⚠️ Over-privileged)"
    ACCESS_SCOPE="$STORAGE_ACCOUNT_CONTRIBUTOR"
elif [[ -n "$CONTRIBUTOR" && "$CONTRIBUTOR" != "null" ]]; then
    HAS_STORAGE_ACCESS=true
    ACCESS_TYPE="Contributor (⚠️ Over-privileged)"
    ACCESS_SCOPE="$CONTRIBUTOR"
elif [[ -n "$OWNER" && "$OWNER" != "null" ]]; then
    HAS_STORAGE_ACCESS=true
    ACCESS_TYPE="Owner (⚠️ Over-privileged)"
    ACCESS_SCOPE="$OWNER"
fi

if [[ "$HAS_STORAGE_ACCESS" == "true" ]]; then
    echo -e "${GREEN}✅ Storage access available via: $ACCESS_TYPE${NC}"
    echo -e "${GRAY}   Scope: $ACCESS_SCOPE${NC}"
    
    # Determine if it's inherited
    if [[ "$ACCESS_SCOPE" == "$STORAGE_RESOURCE_ID" ]]; then
        echo -e "${GRAY}   📍 Direct assignment to storage account${NC}"
    elif [[ "$ACCESS_SCOPE" == "$RG_SCOPE" ]]; then
        echo -e "${GRAY}   📍 Inherited from resource group${NC}"
    elif [[ "$ACCESS_SCOPE" == "$SUBSCRIPTION_SCOPE" ]]; then
        echo -e "${GRAY}   📍 Inherited from subscription${NC}"
    else
        echo -e "${GRAY}   📍 Inherited from parent scope: $ACCESS_SCOPE${NC}"
    fi
else
    echo -e "${RED}❌ No storage access roles found${NC}"
    echo -e "${YELLOW}   Checked scopes:${NC}"
    echo -e "${GRAY}   - Storage Account: $STORAGE_RESOURCE_ID${NC}"
    echo -e "${GRAY}   - Resource Group: $RG_SCOPE${NC}"
    echo -e "${GRAY}   - Subscription: $SUBSCRIPTION_SCOPE${NC}"
    
    # Show available roles if any
    ROLE_COUNT=$(echo "$ALL_STORAGE_ROLES" | jq length)
    if [[ "$ROLE_COUNT" -gt 0 ]]; then
        echo -e "${YELLOW}   Available roles (all scopes):${NC}"
        echo "$ALL_STORAGE_ROLES" | jq -r '.[] | "\(.roleDefinitionName) [\(if .scope == "'$STORAGE_RESOURCE_ID'" then "Storage" elif .scope == "'$RG_SCOPE'" then "RG" elif .scope == "'$SUBSCRIPTION_SCOPE'" then "Sub" else "Other" end)]"' | while read -r role; do
            echo -e "${GRAY}   - $role${NC}"
        done
    fi
fi

# Test 3: Check AI Foundry Access (if provided)
if [[ -n "$AI_FOUNDRY_RESOURCE_ID" ]]; then
    echo -e "\n${CYAN}3️⃣ Testing AI Foundry Access...${NC}"
    
    # Extract AI Foundry resource group from resource ID
    AI_FOUNDRY_RG=$(echo "$AI_FOUNDRY_RESOURCE_ID" | cut -d'/' -f5)
    AI_FOUNDRY_RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$AI_FOUNDRY_RG"
    
    # Check direct role assignments on AI Foundry resource
    DIRECT_AI_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$AI_FOUNDRY_RESOURCE_ID" 2>/dev/null || echo "[]")
    
    # Check inherited role assignments from parent scopes
    AI_RG_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$AI_FOUNDRY_RG_SCOPE" 2>/dev/null || echo "[]")
    AI_SUBSCRIPTION_ROLES=$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$SUBSCRIPTION_SCOPE" 2>/dev/null || echo "[]")
    
    # Combine all AI-related role assignments
    ALL_AI_ROLES=$(echo "$DIRECT_AI_ROLES $AI_RG_ROLES $AI_SUBSCRIPTION_ROLES" | jq -s 'add | unique_by(.id)')
    
    # Check for AI-related roles (in order of preference)
    AZURE_AI_DEVELOPER=$(echo "$ALL_AI_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Azure AI Developer") | .scope' | head -1)
    AZURE_AI_ADMINISTRATOR=$(echo "$ALL_AI_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Azure AI Administrator") | .scope' | head -1)
    COGNITIVE_SERVICES_CONTRIBUTOR=$(echo "$ALL_AI_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Cognitive Services Contributor") | .scope' | head -1)
    AI_CONTRIBUTOR=$(echo "$ALL_AI_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Contributor") | .scope' | head -1)
    AI_OWNER=$(echo "$ALL_AI_ROLES" | jq -r '.[] | select(.roleDefinitionName == "Owner") | .scope' | head -1)
    
    HAS_AI_ACCESS=false
    AI_ACCESS_TYPE=""
    AI_ACCESS_SCOPE=""
    
    if [[ -n "$AZURE_AI_DEVELOPER" && "$AZURE_AI_DEVELOPER" != "null" ]]; then
        HAS_AI_ACCESS=true
        AI_ACCESS_TYPE="Azure AI Developer (✅ Optimal)"
        AI_ACCESS_SCOPE="$AZURE_AI_DEVELOPER"
    elif [[ -n "$AZURE_AI_ADMINISTRATOR" && "$AZURE_AI_ADMINISTRATOR" != "null" ]]; then
        HAS_AI_ACCESS=true
        AI_ACCESS_TYPE="Azure AI Administrator (✅ Good but elevated)"
        AI_ACCESS_SCOPE="$AZURE_AI_ADMINISTRATOR"
    elif [[ -n "$COGNITIVE_SERVICES_CONTRIBUTOR" && "$COGNITIVE_SERVICES_CONTRIBUTOR" != "null" ]]; then
        HAS_AI_ACCESS=true
        AI_ACCESS_TYPE="Cognitive Services Contributor (✅ Legacy but works)"
        AI_ACCESS_SCOPE="$COGNITIVE_SERVICES_CONTRIBUTOR"
    elif [[ -n "$AI_CONTRIBUTOR" && "$AI_CONTRIBUTOR" != "null" ]]; then
        HAS_AI_ACCESS=true
        AI_ACCESS_TYPE="Contributor (⚠️ Over-privileged)"
        AI_ACCESS_SCOPE="$AI_CONTRIBUTOR"
    elif [[ -n "$AI_OWNER" && "$AI_OWNER" != "null" ]]; then
        HAS_AI_ACCESS=true
        AI_ACCESS_TYPE="Owner (⚠️ Over-privileged)"
        AI_ACCESS_SCOPE="$AI_OWNER"
    fi
    
    if [[ "$HAS_AI_ACCESS" == "true" ]]; then
        echo -e "${GREEN}✅ AI Foundry access available via: $AI_ACCESS_TYPE${NC}"
        echo -e "${GRAY}   Scope: $AI_ACCESS_SCOPE${NC}"
        
        # Determine if it's inherited
        if [[ "$AI_ACCESS_SCOPE" == "$AI_FOUNDRY_RESOURCE_ID" ]]; then
            echo -e "${GRAY}   📍 Direct assignment to AI Foundry resource${NC}"
        elif [[ "$AI_ACCESS_SCOPE" == "$AI_FOUNDRY_RG_SCOPE" ]]; then
            echo -e "${GRAY}   📍 Inherited from AI Foundry resource group${NC}"
        elif [[ "$AI_ACCESS_SCOPE" == "$SUBSCRIPTION_SCOPE" ]]; then
            echo -e "${GRAY}   📍 Inherited from subscription${NC}"
        else
            echo -e "${GRAY}   📍 Inherited from parent scope: $AI_ACCESS_SCOPE${NC}"
        fi
    else
        echo -e "${RED}❌ No AI Foundry access roles found${NC}"
        echo -e "${YELLOW}   Checked scopes:${NC}"
        echo -e "${GRAY}   - AI Foundry Resource: $AI_FOUNDRY_RESOURCE_ID${NC}"
        echo -e "${GRAY}   - AI Foundry RG: $AI_FOUNDRY_RG_SCOPE${NC}"
        echo -e "${GRAY}   - Subscription: $SUBSCRIPTION_SCOPE${NC}"
        
        # Show available roles if any
        AI_ROLE_COUNT=$(echo "$ALL_AI_ROLES" | jq length)
        if [[ "$AI_ROLE_COUNT" -gt 0 ]]; then
            echo -e "${YELLOW}   Available roles (all scopes):${NC}"
            echo "$ALL_AI_ROLES" | jq -r '.[] | "\(.roleDefinitionName) [\(if .scope == "'$AI_FOUNDRY_RESOURCE_ID'" then "AI" elif .scope == "'$AI_FOUNDRY_RG_SCOPE'" then "RG" elif .scope == "'$SUBSCRIPTION_SCOPE'" then "Sub" else "Other" end)]"' | while read -r role; do
                echo -e "${GRAY}   - $role${NC}"
            done
        fi
    fi
else
    echo -e "\n${YELLOW}3️⃣ Skipping AI Foundry Access Test (no resource ID provided)${NC}"
fi

# Test 4: Check Function App Configuration
echo -e "\n${CYAN}4️⃣ Testing Function App Configuration...${NC}"

# Check for conflicting storage settings
STORAGE_ACCOUNT_SETTING=$(az functionapp config appsettings list --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='AzureWebJobsStorage__accountName'].value" -o tsv 2>/dev/null)
OLD_STORAGE_SETTING=$(az functionapp config appsettings list --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='AzureWebJobsStorage'].value" -o tsv 2>/dev/null)

if [[ -n "$STORAGE_ACCOUNT_SETTING" ]]; then
    echo -e "${RED}❌ Found AzureWebJobsStorage__accountName setting (conflicts with AVM managed identity)${NC}"
    echo -e "${GRAY}   Value: $STORAGE_ACCOUNT_SETTING${NC}"
    echo -e "${YELLOW}   💡 Remove this setting to use AVM managed identity configuration${NC}"
elif [[ -n "$OLD_STORAGE_SETTING" ]]; then
    echo -e "${RED}❌ Found old AzureWebJobsStorage connection string${NC}"
    echo -e "${YELLOW}   💡 Remove this setting to use managed identity${NC}"
else
    echo -e "${GREEN}✅ No conflicting storage settings found (using AVM managed identity)${NC}"
fi

# Check required settings
REQUIRED_SETTINGS=("APPLICATIONINSIGHTS_CONNECTION_STRING" "AI_FOUNDRY_PROJECT_URL" "AI_FOUNDRY_AGENT_ID")

for setting in "${REQUIRED_SETTINGS[@]}"; do
    SETTING_VALUE=$(az functionapp config appsettings list --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?name=='$setting'].value" -o tsv 2>/dev/null)
    if [[ -n "$SETTING_VALUE" ]]; then
        echo -e "${GREEN}✅ $setting is configured${NC}"
    else
        echo -e "${RED}❌ $setting is missing${NC}"
    fi
done

# Test 5: Check Function App Status
echo -e "\n${CYAN}5️⃣ Testing Function App Status...${NC}"

FUNCTION_STATE=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query state -o tsv 2>/dev/null)
RUNTIME_VERSION=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "siteConfig.netFrameworkVersion" -o tsv 2>/dev/null)
HTTPS_ONLY=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query httpsOnly -o tsv 2>/dev/null)

echo -e "${GREEN}✅ Function App State: $FUNCTION_STATE${NC}"
echo -e "${GREEN}✅ Runtime Version: $RUNTIME_VERSION${NC}"
echo -e "${GREEN}✅ HTTPS Only: $HTTPS_ONLY${NC}"

if [[ "$FUNCTION_STATE" != "Running" ]]; then
    echo -e "${YELLOW}⚠️ Function App is not in Running state${NC}"
fi

echo -e "\n${YELLOW}🏁 Resource Access Test Completed${NC}"
echo -e "${YELLOW}================================================${NC}"

echo -e "\n${CYAN}💡 If you're still seeing MSI token errors:${NC}"
echo -e "${NC}   1. Wait 5-10 minutes for RBAC propagation${NC}"
echo -e "${NC}   2. Restart the Function App: az functionapp restart --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP${NC}"
echo -e "${NC}   3. Ensure no conflicting storage settings are present${NC}"
echo -e "${NC}   4. Check that the storage account allows the Function App's managed identity${NC}"
