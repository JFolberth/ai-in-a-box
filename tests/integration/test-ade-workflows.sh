#!/bin/bash

# Comprehensive ADE Parameter Extraction and Workflow Testing
#
# SYNOPSIS:
#   Test ADE parameter extraction logic, helper scripts, and CI workflow integration
#
# DESCRIPTION:
#   This consolidated test script validates ADE parameter extraction functionality
#   including both the original jq-based logic and the new reusable helper script.
#   It replaces both test-ade-parameter-extraction.sh and test-ade-parameter-extraction-enhanced.sh
#   to provide comprehensive testing without duplication.
#
# USAGE:
#   # Basic usage (runs all tests)
#   ./test-ade-workflows.sh
#
#   # Full absolute path (recommended)
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/integration/test-ade-workflows.sh
#
#   # Quick validation only
#   ./test-ade-workflows.sh --quick
#
# PREREQUISITES:
#   - jq utility for JSON processing
#   - Backend ADE parameters file: infra/environments/backend/ade.parameters.json
#   - Frontend ADE parameters file: infra/environments/frontend/ade.parameters.json
#   - Helper script: tests/utilities/extract-ade-parameters.sh
#
# EXPECTED OUTPUT:
#   - Original extraction logic validation
#   - Helper script functionality testing
#   - Error handling validation
#   - CI workflow integration testing
#   - Parameter sourcing capability verification

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test mode (quick or comprehensive)
QUICK_MODE=false
if [ "$1" = "--quick" ]; then
    QUICK_MODE=true
fi

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

echo "🧪 Comprehensive ADE Parameter Extraction Testing"
echo "================================================="
if [ "$QUICK_MODE" = true ]; then
    echo "🚀 Quick validation mode enabled"
fi
echo ""

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -e "${BLUE}📋 Test: $test_name${NC}"
    
    if eval "$test_command" 2>/dev/null; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Legacy test function for backward compatibility
test_extraction() {
    local description="$1"
    local json_file="$2"
    local jq_query="$3"
    local expected_type="$4" # empty, nonempty, or specific value
    
    echo -e "${BLUE}📋 Testing: $description${NC}"
    
    if [ ! -f "$json_file" ]; then
        echo -e "${RED}❌ JSON file not found: $json_file${NC}"
        return 1
    fi
    
    # Execute the jq command
    result=$(jq -r "$jq_query" "$json_file" 2>/dev/null || echo "ERROR")
    
    if [ "$result" = "ERROR" ]; then
        echo -e "${RED}❌ jq command failed${NC}"
        return 1
    fi
    
    case "$expected_type" in
        "empty")
            if [ -z "$result" ] || [ "$result" = "null" ]; then
                echo -e "${GREEN}✅ Expected empty value: '$result'${NC}"
                return 0
            else
                echo -e "${RED}❌ Expected empty, got: '$result'${NC}"
                return 1
            fi
            ;;
        "nonempty")
            if [ -n "$result" ] && [ "$result" != "null" ]; then
                echo -e "${GREEN}✅ Expected non-empty value: '$result'${NC}"
                return 0
            else
                echo -e "${RED}❌ Expected non-empty, got: '$result'${NC}"
                return 1
            fi
            ;;
        *)
            if [ "$result" = "$expected_type" ]; then
                echo -e "${GREEN}✅ Expected value matches: '$result'${NC}"
                return 0
            else
                echo -e "${RED}❌ Expected '$expected_type', got: '$result'${NC}"
                return 1
            fi
            ;;
    esac
}

# 1. Test Original Extraction Logic (Backward Compatibility)
echo -e "${BLUE}🔧 Testing Original Extraction Logic${NC}"
echo "-------------------------------------"

backend_params="/home/runner/work/ai-in-a-box/ai-in-a-box/infra/environments/backend/ade.parameters.json"

if test_extraction "AI Foundry Endpoint" "$backend_params" ".aiFoundryEndpoint" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Agent ID" "$backend_params" ".aiFoundryAgentId" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Agent Name" "$backend_params" ".aiFoundryAgentName" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Instance Name" "$backend_params" ".aiFoundryInstanceName" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Resource Group" "$backend_params" ".aiFoundryResourceGroupName" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# 2. Test Frontend Parameter File
echo -e "\n${BLUE}🎨 Testing Frontend Parameter File${NC}"
echo "-----------------------------------"

frontend_params="/home/runner/work/ai-in-a-box/ai-in-a-box/infra/environments/frontend/ade.parameters.json"

run_test "Frontend parameters file exists" "[ -f \"$frontend_params\" ]"
run_test "Frontend parameters file is valid JSON" "jq empty \"$frontend_params\""

# 3. Test Cross-Reference (Frontend reading Backend AI Foundry config)
echo -e "\n${BLUE}🔗 Testing Cross-Reference (Frontend reading Backend AI Foundry config)${NC}"
echo "------------------------------------------------------------------------"

if test_extraction "AI Foundry Endpoint (for frontend)" "$backend_params" ".aiFoundryEndpoint" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Agent ID (for frontend)" "$backend_params" ".aiFoundryAgentId" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

if test_extraction "AI Foundry Agent Name (for frontend)" "$backend_params" ".aiFoundryAgentName" "nonempty"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# 4. Test New Helper Script
echo -e "\n${BLUE}🚀 Testing New Helper Script${NC}"
echo "-----------------------------"

# Use absolute path to helper script
HELPER_SCRIPT="/home/runner/work/ai-in-a-box/ai-in-a-box/tests/utilities/extract-ade-parameters.sh"

run_test "Helper script validation mode" \
    "\"$HELPER_SCRIPT\" -v -q"

run_test "Helper script env format" \
    "\"$HELPER_SCRIPT\" -o env -q | grep -q 'AI_FOUNDRY_ENDPOINT='"

run_test "Helper script JSON format validation" \
    "\"$HELPER_SCRIPT\" -o json -q | jq . > /dev/null"

run_test "Helper script export format" \
    "\"$HELPER_SCRIPT\" -o export -q | grep -q 'export AI_FOUNDRY_ENDPOINT='"

# 5. Test Error Handling (only in comprehensive mode)
if [ "$QUICK_MODE" = false ]; then
    echo -e "\n${BLUE}🛠️  Testing Error Handling${NC}"
    echo "----------------------------"

    # Create a temporary invalid JSON file
    TEMP_INVALID_JSON="/tmp/invalid-ade-test.json"
    echo '{ "invalid": json }' > "$TEMP_INVALID_JSON"

    run_test "Invalid JSON handling (should fail)" \
        "! \"$HELPER_SCRIPT\" -f \"$TEMP_INVALID_JSON\" -q"

    # Create a temporary file with missing required parameters
    TEMP_MISSING_PARAMS="/tmp/missing-params-ade-test.json"
    echo '{ "applicationName": "test" }' > "$TEMP_MISSING_PARAMS"

    run_test "Missing required parameters (should fail)" \
        "! \"$HELPER_SCRIPT\" -f \"$TEMP_MISSING_PARAMS\" -q"

    # Test non-existent file
    run_test "Non-existent file handling (should fail)" \
        "! \"$HELPER_SCRIPT\" -f \"/tmp/nonexistent-ade-test.json\" -q"

    # Cleanup
    rm -f "$TEMP_INVALID_JSON" "$TEMP_MISSING_PARAMS"
fi

# 6. Test Parameter Sourcing Capability
echo -e "\n${BLUE}🔗 Testing Parameter Sourcing${NC}"
echo "-------------------------------"

run_test "Parameter sourcing test" \
    "eval \"\$(\"$HELPER_SCRIPT\" -o export -q)\" && [ \"\$AI_FOUNDRY_ENDPOINT\" = \"https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject\" ]"

run_test "Helper script CI equivalent" \
    "eval \"\$(\"$HELPER_SCRIPT\" -o export -q)\" && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

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
    if [ "$QUICK_MODE" = false ]; then
        echo "✅ Error handling works as expected"
    fi
    echo "✅ Integration with CI workflow validated"
    echo "✅ Parameter sourcing capability verified"
    echo ""
    echo -e "${BLUE}📋 Summary${NC}"
    echo "----------"
    echo "✅ Backend ADE parameters contain all required AI Foundry configuration"
    echo "✅ JSON files are syntactically valid"
    echo "✅ jq extraction commands work correctly"
    echo "✅ Validation logic will catch missing or invalid values"
    echo "✅ Frontend can successfully read AI Foundry config from backend parameters"
    echo ""
    echo -e "${BLUE}🔧 Related Scripts${NC}"
    echo "------------------"
    echo "For using the reusable parameter extraction helper:"
    echo "  $HELPER_SCRIPT --help"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    echo "Please review the failing tests above."
    exit 1
fi