#!/bin/bash

# Test script to verify ADE parameter extraction logic
# This script tests the jq commands used in the CI workflow

set -e

echo "🧪 Testing ADE Parameter Extraction Logic"
echo "============================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_extraction() {
    local description="$1"
    local json_file="$2"
    local jq_query="$3"
    local expected_type="$4" # empty, nonempty, or specific value
    
    echo -e "\n📋 Testing: $description"
    
    if [ ! -f "$json_file" ]; then
        echo -e "${RED}❌ JSON file not found: $json_file${NC}"
        return 1
    fi
    
    # Execute the jq command
    result=$(jq -r "$jq_query" "$json_file" 2>/dev/null || echo "ERROR")
    
    if [ "$result" = "ERROR" ]; then
        echo -e "${RED}❌ jq command failed: $jq_query${NC}"
        return 1
    fi
    
    if [ "$result" = "null" ]; then
        echo -e "${RED}❌ Field not found or null: $jq_query${NC}"
        return 1
    fi
    
    if [ -z "$result" ]; then
        echo -e "${RED}❌ Empty result: $jq_query${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Success: '$result'${NC}"
    return 0
}

# Test backend parameter extractions
echo -e "\n🔧 Testing Backend Parameter Extractions"
echo "----------------------------------------"

backend_params="infra/environments/backend/ade.parameters.json"

test_extraction "AI Foundry Endpoint" "$backend_params" ".aiFoundryEndpoint" "nonempty"
test_extraction "AI Foundry Agent ID" "$backend_params" ".aiFoundryAgentId" "nonempty"
test_extraction "AI Foundry Agent Name" "$backend_params" ".aiFoundryAgentName" "nonempty"
test_extraction "AI Foundry Instance Name" "$backend_params" ".aiFoundryInstanceName" "nonempty"
test_extraction "AI Foundry Resource Group" "$backend_params" ".aiFoundryResourceGroupName" "nonempty"

# Test that frontend parameters file exists and is valid JSON
echo -e "\n🎨 Testing Frontend Parameter File"
echo "-----------------------------------"

frontend_params="infra/environments/frontend/ade.parameters.json"

if [ ! -f "$frontend_params" ]; then
    echo -e "${RED}❌ Frontend parameters file not found: $frontend_params${NC}"
    exit 1
fi

# Validate JSON syntax
if jq empty "$frontend_params" 2>/dev/null; then
    echo -e "${GREEN}✅ Frontend parameters file is valid JSON${NC}"
else
    echo -e "${RED}❌ Frontend parameters file has invalid JSON syntax${NC}"
    exit 1
fi

# Test that we can read from backend parameters for frontend (since frontend uses backend's AI Foundry config)
echo -e "\n🔗 Testing Cross-Reference (Frontend reading Backend AI Foundry config)"
echo "------------------------------------------------------------------------"

test_extraction "AI Foundry Endpoint (for frontend)" "$backend_params" ".aiFoundryEndpoint" "nonempty"
test_extraction "AI Foundry Agent ID (for frontend)" "$backend_params" ".aiFoundryAgentId" "nonempty"
test_extraction "AI Foundry Agent Name (for frontend)" "$backend_params" ".aiFoundryAgentName" "nonempty"

# Test validation logic (simulating the validation checks in CI)
echo -e "\n🔍 Testing Validation Logic"
echo "----------------------------"

validate_field() {
    local field_name="$1"
    local value="$2"
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo -e "${RED}❌ Validation failed: $field_name is missing or invalid${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Validation passed: $field_name = '$value'${NC}"
        return 0
    fi
}

# Read values for validation
AI_FOUNDRY_ENDPOINT=$(jq -r '.aiFoundryEndpoint' "$backend_params")
AI_FOUNDRY_AGENT_ID=$(jq -r '.aiFoundryAgentId' "$backend_params")
AI_FOUNDRY_AGENT_NAME=$(jq -r '.aiFoundryAgentName' "$backend_params")

validate_field "AI_FOUNDRY_ENDPOINT" "$AI_FOUNDRY_ENDPOINT"
validate_field "AI_FOUNDRY_AGENT_ID" "$AI_FOUNDRY_AGENT_ID"  
validate_field "AI_FOUNDRY_AGENT_NAME" "$AI_FOUNDRY_AGENT_NAME"

echo -e "\n🎉 All tests completed successfully!"
echo "The ADE parameter extraction logic should work correctly in CI."

# Summary
echo -e "\n📊 Summary"
echo "----------"
echo "✅ Backend ADE parameters contain all required AI Foundry configuration"
echo "✅ JSON files are syntactically valid"
echo "✅ jq extraction commands work correctly"
echo "✅ Validation logic will catch missing or invalid values"
echo "✅ Frontend can successfully read AI Foundry config from backend parameters"

echo -e "\n🔧 Enhanced Testing Available"
echo "-----------------------------"
echo "For comprehensive testing including the new helper script:"
echo "  ./tests/test-ade-parameter-extraction-enhanced.sh"
echo ""
echo "For using the reusable parameter extraction helper:"
echo "  ./tests/extract-ade-parameters.sh --help"