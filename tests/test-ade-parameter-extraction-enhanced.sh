#!/bin/bash

# Enhanced test script for ADE parameter extraction
# Tests both the original logic and the new helper script

set -e

echo "🧪 Enhanced ADE Parameter Extraction Testing"
echo "============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -e "\n${BLUE}📋 Test: $test_name${NC}"
    
    if eval "$test_command" 2>/dev/null; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test the original extraction logic (backward compatibility)
echo -e "\n${BLUE}🔧 Testing Original Extraction Logic${NC}"
echo "-------------------------------------"

backend_params="infra/environments/backend/ade.parameters.json"

run_test "Original jq extraction - AI Foundry Endpoint" \
    "[ \"\$(jq -r '.aiFoundryEndpoint' \"$backend_params\")\" = \"https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject\" ]"

run_test "Original jq extraction - AI Foundry Agent ID" \
    "[ \"\$(jq -r '.aiFoundryAgentId' \"$backend_params\")\" = \"asst_dH7M0nbmdRblhSQO8nIGIYF4\" ]"

run_test "Original jq extraction - AI Foundry Agent Name" \
    "[ \"\$(jq -r '.aiFoundryAgentName' \"$backend_params\")\" = \"AI in A Box\" ]"

# Test the new helper script
echo -e "\n${BLUE}🚀 Testing New Helper Script${NC}"
echo "-----------------------------"

run_test "Helper script validation mode" \
    "./tests/extract-ade-parameters.sh -v -q"

run_test "Helper script env format" \
    "./tests/extract-ade-parameters.sh -o env -q | grep -q 'AI_FOUNDRY_ENDPOINT='"

run_test "Helper script JSON format validation" \
    "./tests/extract-ade-parameters.sh -o json -q | jq . > /dev/null"

run_test "Helper script export format" \
    "./tests/extract-ade-parameters.sh -o export -q | grep -q 'export AI_FOUNDRY_ENDPOINT='"

# Test error handling
echo -e "\n${BLUE}🛠️  Testing Error Handling${NC}"
echo "----------------------------"

# Create a temporary invalid JSON file
TEMP_INVALID_JSON="/tmp/invalid.json"
echo '{ "invalid": json }' > "$TEMP_INVALID_JSON"

run_test "Invalid JSON handling (should fail)" \
    "! ./tests/extract-ade-parameters.sh -f \"$TEMP_INVALID_JSON\" -q"

# Create a temporary file with missing required parameters
TEMP_MISSING_PARAMS="/tmp/missing-params.json"
echo '{ "applicationName": "test" }' > "$TEMP_MISSING_PARAMS"

run_test "Missing required parameters (should fail)" \
    "! ./tests/extract-ade-parameters.sh -f \"$TEMP_MISSING_PARAMS\" -q"

# Test non-existent file
run_test "Non-existent file handling (should fail)" \
    "! ./tests/extract-ade-parameters.sh -f \"/tmp/nonexistent.json\" -q"

# Test parameter sourcing capability
echo -e "\n${BLUE}🔗 Testing Parameter Sourcing${NC}"
echo "-------------------------------"

run_test "Parameter sourcing test" \
    "eval \"\$(./tests/extract-ade-parameters.sh -o export -q)\" && [ \"\$AI_FOUNDRY_ENDPOINT\" = \"https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject\" ]"

# Test integration with CI workflow logic
echo -e "\n${BLUE}🎯 Testing CI Workflow Integration${NC}"
echo "-----------------------------------"

# Simulate the exact logic used in CI workflow
run_test "CI workflow simulation" \
    "AI_FOUNDRY_ENDPOINT=\$(jq -r '.aiFoundryEndpoint' \"$backend_params\") && \
     AI_FOUNDRY_AGENT_ID=\$(jq -r '.aiFoundryAgentId' \"$backend_params\") && \
     AI_FOUNDRY_AGENT_NAME=\$(jq -r '.aiFoundryAgentName' \"$backend_params\") && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

# Test helper script equivalent
run_test "Helper script CI equivalent" \
    "eval \"\$(./tests/extract-ade-parameters.sh -o export -q)\" && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

# Cleanup
rm -f "$TEMP_INVALID_JSON" "$TEMP_MISSING_PARAMS"

# Summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "==============="
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📋 Total Tests: $TESTS_TOTAL${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
    echo "✅ Original extraction logic works correctly"
    echo "✅ New helper script provides equivalent functionality"
    echo "✅ Error handling works as expected"
    echo "✅ Integration with CI workflow validated"
    echo "✅ Parameter sourcing capability verified"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    echo "Please review the failing tests above."
    exit 1
fi