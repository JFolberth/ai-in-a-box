#!/bin/bash

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