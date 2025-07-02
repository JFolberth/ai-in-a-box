#!/bin/bash

# Consolidated ADE Parameter Extraction and Workflow Testing
#
# SYNOPSIS:
#   Comprehensive testing of ADE parameter extraction functionality and CI workflow integration
#
# DESCRIPTION:
#   This script consolidates testing of ADE parameter extraction logic, combining both the original
#   extraction methods and the enhanced helper script functionality. It validates backward compatibility,
#   error handling, parameter sourcing, and CI workflow integration.
#
# USAGE:
#   # Basic usage (runs complete ADE workflow tests)
#   ./test-ade-workflows.sh
#
#   # Full absolute path (recommended)
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/integration/test-ade-workflows.sh
#
#   # From repository root
#   bash tests/integration/test-ade-workflows.sh
#
# PREREQUISITES:
#   - jq installed for JSON processing
#   - Backend ADE parameter files in infra/environments/backend/
#   - extract-ade-parameters.sh utility script available
#   - Bash 4.0+ or compatible shell
#
# EXPECTED OUTPUT:
#   - Original extraction logic validation results
#   - Enhanced helper script testing results
#   - Error handling verification
#   - CI workflow integration simulation results
#   - Parameter sourcing capability tests
#   - Comprehensive test summary

set -e

echo "🧪 Consolidated ADE Parameter Extraction Testing"
echo "================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
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

# Determine script location for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test files
backend_params="$REPO_ROOT/infra/environments/backend/ade.parameters.json"
extract_script="$REPO_ROOT/tests/utilities/extract-ade-parameters.sh"

# Verify required files exist
if [ ! -f "$backend_params" ]; then
    echo -e "${RED}❌ Backend parameters file not found: $backend_params${NC}"
    exit 1
fi

if [ ! -f "$extract_script" ]; then
    echo -e "${RED}❌ Extract parameters script not found: $extract_script${NC}"
    exit 1
fi

# ============================================================================
# SECTION 1: Original Extraction Logic Testing (Backward Compatibility)
# ============================================================================
echo -e "\n${BLUE}🔧 Testing Original Extraction Logic${NC}"
echo "-------------------------------------"

run_test "Original jq extraction - AI Foundry Endpoint" \
    "[ \"\$(jq -r '.aiFoundryEndpoint' \"$backend_params\")\" != \"null\" ] && [ -n \"\$(jq -r '.aiFoundryEndpoint' \"$backend_params\")\" ]"

run_test "Original jq extraction - AI Foundry Agent ID" \
    "[ \"\$(jq -r '.aiFoundryAgentId' \"$backend_params\")\" != \"null\" ] && [ -n \"\$(jq -r '.aiFoundryAgentId' \"$backend_params\")\" ]"

run_test "Original jq extraction - AI Foundry Agent Name" \
    "[ \"\$(jq -r '.aiFoundryAgentName' \"$backend_params\")\" != \"null\" ] && [ -n \"\$(jq -r '.aiFoundryAgentName' \"$backend_params\")\" ]"

# ============================================================================
# SECTION 2: Enhanced Helper Script Testing
# ============================================================================
echo -e "\n${BLUE}🚀 Testing Enhanced Helper Script${NC}"
echo "----------------------------------"

run_test "Helper script validation mode" \
    "\"$extract_script\" -v -q"

run_test "Helper script env format" \
    "\"$extract_script\" -o env -q | grep -q 'AI_FOUNDRY_ENDPOINT='"

run_test "Helper script JSON format validation" \
    "\"$extract_script\" -o json -q | jq . > /dev/null"

run_test "Helper script export format" \
    "\"$extract_script\" -o export -q | grep -q 'export AI_FOUNDRY_ENDPOINT='"

# ============================================================================
# SECTION 3: Error Handling Testing
# ============================================================================
echo -e "\n${BLUE}🛠️  Testing Error Handling${NC}"
echo "----------------------------"

# Create temporary invalid JSON file
TEMP_INVALID_JSON="/tmp/invalid_ade_params.json"
echo '{ invalid json syntax' > "$TEMP_INVALID_JSON"

run_test "Invalid JSON file handling" \
    "! \"$extract_script\" -f \"$TEMP_INVALID_JSON\" -q 2>/dev/null"

# Create temporary file with missing required parameters
TEMP_MISSING_PARAMS="/tmp/missing_params.json"
echo '{ "someOtherParam": "value" }' > "$TEMP_MISSING_PARAMS"

run_test "Missing parameters handling" \
    "! \"$extract_script\" -f \"$TEMP_MISSING_PARAMS\" -q 2>/dev/null"

run_test "Non-existent file handling" \
    "! \"$extract_script\" -f \"/tmp/nonexistent_file.json\" -q 2>/dev/null"

# ============================================================================
# SECTION 4: Parameter Sourcing Testing
# ============================================================================
echo -e "\n${BLUE}🔄 Testing Parameter Sourcing${NC}"
echo "------------------------------"

run_test "Parameter sourcing capability" \
    "source <(\"$extract_script\" -o export -q) && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

# ============================================================================
# SECTION 5: CI Workflow Integration Testing
# ============================================================================
echo -e "\n${BLUE}🎯 Testing CI Workflow Integration${NC}"
echo "-----------------------------------"

# Simulate the exact logic used in CI workflow (original method)
run_test "CI workflow simulation (original)" \
    "AI_FOUNDRY_ENDPOINT=\$(jq -r '.aiFoundryEndpoint' \"$backend_params\") && \
     AI_FOUNDRY_AGENT_ID=\$(jq -r '.aiFoundryAgentId' \"$backend_params\") && \
     AI_FOUNDRY_AGENT_NAME=\$(jq -r '.aiFoundryAgentName' \"$backend_params\") && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

# Test helper script equivalent for CI
run_test "CI workflow simulation (helper script)" \
    "eval \"\$(\"$extract_script\" -o export -q)\" && \
     [ -n \"\$AI_FOUNDRY_ENDPOINT\" ] && [ \"\$AI_FOUNDRY_ENDPOINT\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_ID\" ] && [ \"\$AI_FOUNDRY_AGENT_ID\" != \"null\" ] && \
     [ -n \"\$AI_FOUNDRY_AGENT_NAME\" ] && [ \"\$AI_FOUNDRY_AGENT_NAME\" != \"null\" ]"

# ============================================================================
# SECTION 6: Multiple Output Format Validation
# ============================================================================
echo -e "\n${BLUE}📤 Testing Multiple Output Formats${NC}"
echo "-----------------------------------"

run_test "Environment variables format consistency" \
    "\"$extract_script\" -o env -q | grep -E '^AI_FOUNDRY_[A-Z_]+=.+$' | wc -l | grep -q '[3-9]'"

run_test "JSON format structure validation" \
    "\"$extract_script\" -o json -q | jq 'has(\"AI_FOUNDRY_ENDPOINT\") and has(\"AI_FOUNDRY_AGENT_ID\") and has(\"AI_FOUNDRY_AGENT_NAME\")'"

run_test "Export format bash compatibility" \
    "\"$extract_script\" -o export -q | grep -E '^export AI_FOUNDRY_[A-Z_]+=.*$' | wc -l | grep -q '[3-9]'"

# ============================================================================
# CLEANUP AND SUMMARY
# ============================================================================

# Cleanup temporary files
rm -f "$TEMP_INVALID_JSON" "$TEMP_MISSING_PARAMS"

# Test Summary
echo -e "\n${BLUE}📊 Consolidated ADE Workflow Test Summary${NC}"
echo "=========================================="
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📋 Total Tests: $TESTS_TOTAL${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All ADE workflow tests passed successfully!${NC}"
    echo ""
    echo -e "${GRAY}✅ Original extraction logic: Backward compatible${NC}"
    echo -e "${GRAY}✅ Enhanced helper script: Full functionality${NC}" 
    echo -e "${GRAY}✅ Error handling: Robust validation${NC}"
    echo -e "${GRAY}✅ CI workflow integration: Validated${NC}"
    echo -e "${GRAY}✅ Parameter sourcing: Working correctly${NC}"
    echo -e "${GRAY}✅ Multiple output formats: All functional${NC}"
    echo ""
    echo -e "${BLUE}🔗 Related Documentation:${NC}"
    echo -e "${GRAY}   - documentation/ADE_PARAMETER_EXTRACTION.md${NC}"
    echo -e "${GRAY}   - tests/utilities/extract-ade-parameters.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Some ADE workflow tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}Please review the failing tests above.${NC}"
    echo -e "${YELLOW}Check parameter files and script dependencies.${NC}"
    exit 1
fi