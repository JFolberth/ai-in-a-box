#!/bin/bash

# AI Foundry SPA Backend Test Runner
#
# SYNOPSIS:
#   Build and run the comprehensive test suite for the backend Azure Function
#
# DESCRIPTION:
#   This script builds the backend Azure Function project and runs its complete test suite.
#   It compiles both the main Function App project and the test project, then executes
#   all unit tests, integration tests, and validation tests with detailed output.
#
# PARAMETERS:
#   No parameters required. Script automatically detects project structure.
#
# EXAMPLES:
#   ./run-backend-tests.sh
#
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/run-backend-tests.sh
#
#   bash run-backend-tests.sh
#
# PREREQUISITES:
#   - .NET SDK 8.0+ installed
#   - Backend Function App project in src/backend/
#   - Test project in src/backend/tests/AIFoundryProxy.Tests/
#   - PowerShell or compatible shell environment
#
# EXPECTED OUTPUT:
#   - Backend project build results
#   - Test project compilation status  
#   - Detailed test execution results with coverage summary
#   - Test categories: Basic Function Tests, Chat Models Tests, Utility Method Tests, 
#     Simulation Logic Tests, Integration Tests
#   - Final success/failure summary
#
# AI Foundry SPA Backend Test Runner
# Builds and runs the comprehensive test suite for the backend Azure Function

set -e  # Exit on any error

echo "🧪 AI Foundry SPA Backend Test Runner"
echo "======================================"

# Change to the repository root (one level up from tests folder)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "📁 Repository root: $REPO_ROOT"

# Build the backend project first
echo ""
echo "🔨 Building backend project..."
cd "$REPO_ROOT/src/backend"
dotnet build

# Build and run tests
echo ""
echo "🧪 Building and running tests..."
cd "$REPO_ROOT/src/backend/tests/AIFoundryProxy.Tests"
dotnet build

echo ""
echo "🏃 Executing test suite..."
dotnet test --verbosity normal --logger "console;verbosity=detailed"

# Check if tests passed
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed successfully!"
    echo ""
    echo "📊 Test Coverage Summary:"
    echo "   - Basic Function Tests: Constructor, configuration, initialization"
    echo "   - Chat Models Tests: Request/response serialization and validation"
    echo "   - Utility Method Tests: Helper functions and status checking"
    echo "   - Simulation Logic Tests: AI message processing and contextual responses"
    echo "   - Integration Tests: End-to-end workflows and multi-request handling"
    echo ""
    echo "🎯 The AI Foundry SPA backend is ready for deployment!"
else
    echo ""
    echo "❌ Some tests failed. Please review the output above."
    exit 1
fi