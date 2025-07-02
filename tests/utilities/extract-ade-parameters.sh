#!/bin/bash
# extract-ade-parameters.sh
# Reusable script to extract AI Foundry parameters from ADE parameter files
# This addresses issue #93: CI Extracting from ADE

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default parameters
BACKEND_PARAMS_FILE="/home/runner/work/ai-in-a-box/ai-in-a-box/infra/environments/backend/ade.parameters.json"
OUTPUT_FORMAT="env"  # env, json, or export
VALIDATE_ONLY=false
QUIET=false

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Extract AI Foundry parameters from ADE parameter files"
    echo ""
    echo "OPTIONS:"
    echo "  -f, --file FILE       Backend ADE parameters file (default: infra/environments/backend/ade.parameters.json)"
    echo "  -o, --output FORMAT   Output format: env, json, export (default: env)"
    echo "  -v, --validate-only   Only validate parameters, don't output them"
    echo "  -q, --quiet          Suppress informational messages"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "OUTPUT FORMATS:"
    echo "  env     - KEY=value format for sourcing"
    echo "  json    - JSON format for parsing with jq"
    echo "  export  - export KEY=value format for direct evaluation"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                    # Extract parameters as env vars"
    echo "  $0 -o json                           # Extract parameters as JSON"
    echo "  $0 -v                                # Validate parameters only"
    echo "  $0 -f custom.json -o export          # Use custom file, export format"
    echo "  source <($0 -o export -q)            # Source parameters into current shell"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            BACKEND_PARAMS_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            case $OUTPUT_FORMAT in
                env|json|export)
                    ;;
                *)
                    echo -e "${RED}❌ Invalid output format: $OUTPUT_FORMAT${NC}" >&2
                    echo "Valid formats: env, json, export" >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -v|--validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Logging function
log() {
    if [ "$QUIET" = false ]; then
        echo -e "$1" >&2
    fi
}

# Validation function
validate_parameter() {
    local param_name="$1"
    local param_value="$2"
    local is_required="${3:-true}"
    
    if [ "$is_required" = true ] && ([ -z "$param_value" ] || [ "$param_value" = "null" ]); then
        echo -e "${RED}❌ Missing or invalid required parameter: $param_name${NC}" >&2
        return 1
    elif [ -z "$param_value" ] || [ "$param_value" = "null" ]; then
        log "${YELLOW}⚠️ Optional parameter not set: $param_name${NC}"
        return 0
    else
        log "${GREEN}✅ Valid parameter: $param_name${NC}"
        return 0
    fi
}

# Main extraction logic
main() {
    log "${BLUE}🔍 Extracting AI Foundry parameters from ADE configuration${NC}"
    log "${BLUE}📋 Parameter file: $BACKEND_PARAMS_FILE${NC}"
    
    # Check if parameters file exists
    if [ ! -f "$BACKEND_PARAMS_FILE" ]; then
        echo -e "${RED}❌ ADE parameters file not found: $BACKEND_PARAMS_FILE${NC}" >&2
        exit 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$BACKEND_PARAMS_FILE" 2>/dev/null; then
        echo -e "${RED}❌ Invalid JSON syntax in parameters file: $BACKEND_PARAMS_FILE${NC}" >&2
        exit 1
    fi
    
    log "${GREEN}✅ Parameters file is valid JSON${NC}"
    
    # Extract parameters using jq
    local ai_foundry_endpoint ai_foundry_agent_id ai_foundry_agent_name
    local ai_foundry_instance_name ai_foundry_rg_name
    
    ai_foundry_endpoint=$(jq -r '.aiFoundryEndpoint // empty' "$BACKEND_PARAMS_FILE" 2>/dev/null)
    ai_foundry_agent_id=$(jq -r '.aiFoundryAgentId // empty' "$BACKEND_PARAMS_FILE" 2>/dev/null)
    ai_foundry_agent_name=$(jq -r '.aiFoundryAgentName // empty' "$BACKEND_PARAMS_FILE" 2>/dev/null)
    ai_foundry_instance_name=$(jq -r '.aiFoundryInstanceName // empty' "$BACKEND_PARAMS_FILE" 2>/dev/null)
    ai_foundry_rg_name=$(jq -r '.aiFoundryResourceGroupName // empty' "$BACKEND_PARAMS_FILE" 2>/dev/null)
    
    # Validate required parameters
    local validation_failed=false
    
    if ! validate_parameter "aiFoundryEndpoint" "$ai_foundry_endpoint" true; then
        validation_failed=true
    fi
    
    if ! validate_parameter "aiFoundryAgentId" "$ai_foundry_agent_id" true; then
        validation_failed=true
    fi
    
    if ! validate_parameter "aiFoundryAgentName" "$ai_foundry_agent_name" false; then
        # Agent name is optional, use default if not provided
        if [ -z "$ai_foundry_agent_name" ] || [ "$ai_foundry_agent_name" = "null" ]; then
            ai_foundry_agent_name="AI in A Box"
            log "${BLUE}ℹ️ Using default agent name: $ai_foundry_agent_name${NC}"
        fi
    fi
    
    # Validate optional parameters
    validate_parameter "aiFoundryInstanceName" "$ai_foundry_instance_name" false
    validate_parameter "aiFoundryResourceGroupName" "$ai_foundry_rg_name" false
    
    if [ "$validation_failed" = true ]; then
        echo -e "${RED}❌ Parameter validation failed. Required AI Foundry parameters are missing.${NC}" >&2
        exit 1
    fi
    
    # If validate-only mode, exit here
    if [ "$VALIDATE_ONLY" = true ]; then
        log "${GREEN}✅ All AI Foundry parameters are valid${NC}"
        exit 0
    fi
    
    # Output parameters in requested format
    case $OUTPUT_FORMAT in
        env)
            echo "AI_FOUNDRY_ENDPOINT=$ai_foundry_endpoint"
            echo "AI_FOUNDRY_AGENT_ID=$ai_foundry_agent_id"
            echo "AI_FOUNDRY_AGENT_NAME=$ai_foundry_agent_name"
            [ -n "$ai_foundry_instance_name" ] && [ "$ai_foundry_instance_name" != "null" ] && echo "AI_FOUNDRY_INSTANCE_NAME=$ai_foundry_instance_name"
            [ -n "$ai_foundry_rg_name" ] && [ "$ai_foundry_rg_name" != "null" ] && echo "AI_FOUNDRY_RG_NAME=$ai_foundry_rg_name"
            ;;
        export)
            echo "export AI_FOUNDRY_ENDPOINT=\"$ai_foundry_endpoint\""
            echo "export AI_FOUNDRY_AGENT_ID=\"$ai_foundry_agent_id\""
            echo "export AI_FOUNDRY_AGENT_NAME=\"$ai_foundry_agent_name\""
            [ -n "$ai_foundry_instance_name" ] && [ "$ai_foundry_instance_name" != "null" ] && echo "export AI_FOUNDRY_INSTANCE_NAME=\"$ai_foundry_instance_name\""
            [ -n "$ai_foundry_rg_name" ] && [ "$ai_foundry_rg_name" != "null" ] && echo "export AI_FOUNDRY_RG_NAME=\"$ai_foundry_rg_name\""
            ;;
        json)
            # Build JSON object dynamically
            local json_parts=()
            json_parts+=("\"aiFoundryEndpoint\": \"$ai_foundry_endpoint\"")
            json_parts+=("\"aiFoundryAgentId\": \"$ai_foundry_agent_id\"")
            json_parts+=("\"aiFoundryAgentName\": \"$ai_foundry_agent_name\"")
            
            if [ -n "$ai_foundry_instance_name" ] && [ "$ai_foundry_instance_name" != "null" ]; then
                json_parts+=("\"aiFoundryInstanceName\": \"$ai_foundry_instance_name\"")
            fi
            
            if [ -n "$ai_foundry_rg_name" ] && [ "$ai_foundry_rg_name" != "null" ]; then
                json_parts+=("\"aiFoundryResourceGroupName\": \"$ai_foundry_rg_name\"")
            fi
            
            # Join with commas and output
            printf "{\n"
            for i in "${!json_parts[@]}"; do
                printf "  %s" "${json_parts[$i]}"
                if [ $i -lt $((${#json_parts[@]} - 1)) ]; then
                    printf ","
                fi
                printf "\n"
            done
            printf "}\n"
            ;;
    esac
    
    log "${GREEN}✅ Successfully extracted AI Foundry parameters${NC}"
}

# Run main function
main "$@"