# ADE Parameter Extraction

This document describes the AI Foundry parameter extraction functionality for Azure Deployment Environments (ADE) in the CI/CD pipeline.

## Problem Statement

The CI pipeline needs to extract AI Foundry-specific settings from `ade.parameters.json` files because:

1. **No AI Foundry deployment to query**: The Foundry resource group was not deployed via ADE
2. **Configuration source**: All AI Foundry settings are stored in the backend ADE parameters file
3. **Cross-component usage**: Both frontend and backend deployments need access to the same AI Foundry configuration

## Solution

### Reusable Helper Script

The solution provides a reusable helper script `tests/utilities/extract-ade-parameters.sh` that:

- Extracts AI Foundry parameters from ADE parameter files
- Validates required parameters are present
- Supports multiple output formats (env, json, export)
- Provides comprehensive error handling
- Can be used in CI workflows and for local testing

### Usage Examples

#### Validation Only
```bash
./tests/utilities/extract-ade-parameters.sh --validate-only
```

#### Extract as Environment Variables
```bash
./tests/utilities/extract-ade-parameters.sh --output env
```

#### Extract as JSON
```bash
./tests/utilities/extract-ade-parameters.sh --output json
```

#### Source into Current Shell
```bash
source <(./tests/utilities/extract-ade-parameters.sh --output export --quiet)
echo $AI_FOUNDRY_ENDPOINT
```

#### Custom Parameter File
```bash
./tests/utilities/extract-ade-parameters.sh --file custom-params.json --output json
```

### Parameters Extracted

The script extracts these AI Foundry parameters from the backend ADE configuration:

| Parameter | Environment Variable | Required | Description |
|-----------|---------------------|----------|-------------|
| `aiFoundryEndpoint` | `AI_FOUNDRY_ENDPOINT` | ✅ | AI Foundry API endpoint URL |
| `aiFoundryAgentId` | `AI_FOUNDRY_AGENT_ID` | ✅ | Specific agent identifier |
| `aiFoundryAgentName` | `AI_FOUNDRY_AGENT_NAME` | ⚠️ | Agent display name (defaults to "AI in A Box") |
| `aiFoundryInstanceName` | `AI_FOUNDRY_INSTANCE_NAME` | ❌ | AI Foundry instance/workspace name |
| `aiFoundryResourceGroupName` | `AI_FOUNDRY_RG_NAME` | ❌ | Resource group containing AI Foundry |

### CI Workflow Integration

The CI workflow (`ci.yml`) has been updated to use the helper script:

#### Before (Inline Code)
```bash
# Read AI Foundry configuration from ade.parameters.json
AI_FOUNDRY_ENDPOINT=$(jq -r '.aiFoundryEndpoint' infra/environments/backend/ade.parameters.json)
AI_FOUNDRY_AGENT_ID=$(jq -r '.aiFoundryAgentId' infra/environments/backend/ade.parameters.json)
# ... more inline validation logic
```

#### After (Helper Script)
```bash
# Use the reusable helper script to extract AI Foundry parameters
if ! PARAMETER_OUTPUT=$(./tests/utilities/extract-ade-parameters.sh -o export -q); then
    echo "❌ Failed to extract AI Foundry parameters"
    exit 1
fi
eval "$PARAMETER_OUTPUT"
```

### Benefits

1. **Maintainability**: Single source of truth for parameter extraction logic
2. **Reusability**: Can be used in CI, local testing, and debugging
3. **Validation**: Comprehensive error handling and parameter validation
4. **Consistency**: Same extraction logic across all use cases
5. **Testing**: Isolated testing of parameter extraction functionality

## Testing

### Test Scripts

1. **Basic validation**: `tests/test-ade-parameter-extraction.sh` (original)
2. **Enhanced testing**: `tests/test-ade-parameter-extraction-enhanced.sh` (new)

### Run Tests

```bash
# Run original test
./tests/test-ade-parameter-extraction.sh

# Run enhanced test suite
./tests/test-ade-parameter-extraction-enhanced.sh
```

### Test Coverage

The enhanced test suite covers:

- ✅ Original extraction logic (backward compatibility)
- ✅ New helper script functionality
- ✅ Error handling (invalid JSON, missing parameters, non-existent files)
- ✅ Parameter sourcing capability
- ✅ CI workflow integration simulation
- ✅ Multiple output formats

## Error Handling

The helper script provides comprehensive error handling:

### Invalid JSON Syntax
```bash
$ ./tests/utilities/extract-ade-parameters.sh -f invalid.json
❌ Invalid JSON syntax in parameters file: invalid.json
```

### Missing Required Parameters
```bash
$ ./tests/utilities/extract-ade-parameters.sh -f missing-params.json
❌ Missing or invalid required parameter: aiFoundryEndpoint
❌ Parameter validation failed. Required AI Foundry parameters are missing.
```

### Non-existent File
```bash
$ ./tests/utilities/extract-ade-parameters.sh -f nonexistent.json
❌ ADE parameters file not found: nonexistent.json
```

## Implementation Details

### File Locations

- **Helper script**: `tests/utilities/extract-ade-parameters.sh`
- **Backend parameters**: `infra/environments/backend/ade.parameters.json`
- **Frontend parameters**: `infra/environments/frontend/ade.parameters.json`
- **Enhanced tests**: `tests/test-ade-parameter-extraction-enhanced.sh`

### Output Formats

#### Environment Variables (`env`)
```
AI_FOUNDRY_ENDPOINT=https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject
AI_FOUNDRY_AGENT_ID=asst_dH7M0nbmdRblhSQO8nIGIYF4
AI_FOUNDRY_AGENT_NAME=AI in A Box
```

#### Export Format (`export`)
```bash
export AI_FOUNDRY_ENDPOINT="https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject"
export AI_FOUNDRY_AGENT_ID="asst_dH7M0nbmdRblhSQO8nIGIYF4"
export AI_FOUNDRY_AGENT_NAME="AI in A Box"
```

#### JSON Format (`json`)
```json
{
  "aiFoundryEndpoint": "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject",
  "aiFoundryAgentId": "asst_dH7M0nbmdRblhSQO8nIGIYF4", 
  "aiFoundryAgentName": "AI in A Box"
}
```

## Related Files

- `.github/workflows/ci.yml` - CI workflow using the helper script
- `infra/environments/backend/ade.parameters.json` - Source of AI Foundry parameters
- `tests/test-ade-parameter-extraction.sh` - Original test script
- `tests/test-ade-parameter-extraction-enhanced.sh` - Enhanced test suite
- `tests/utilities/extract-ade-parameters.sh` - Main helper script

## Future Enhancements

Potential future improvements:

1. **Parameter validation rules**: More sophisticated validation (URL format, agent ID format)
2. **Configuration templates**: Generate parameter files from templates
3. **Integration testing**: Test with actual ADE deployments
4. **Parameter encryption**: Support for encrypted sensitive parameters
5. **Multi-environment support**: Environment-specific parameter overrides