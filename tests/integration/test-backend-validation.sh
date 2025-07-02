#!/bin/bash

# Consolidated Backend Testing and Package Validation
#
# SYNOPSIS:
#   Comprehensive backend build, test execution, and deployment package validation
#
# DESCRIPTION:
#   This script consolidates backend testing functionality by building the backend project,
#   running the complete test suite, creating deployment packages, and validating package
#   structure for Azure Function App deployment. It combines the functionality of both
#   run-backend-tests.sh and validate-backend-package.sh.
#
# USAGE:
#   # Basic usage (runs complete backend validation)
#   ./test-backend-validation.sh
#
#   # Validate existing package only (skip build and tests)
#   ./test-backend-validation.sh --package-only /path/to/backend-deployment.zip
#
#   # Full absolute path (recommended)
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/integration/test-backend-validation.sh
#
#   # From repository root
#   bash tests/integration/test-backend-validation.sh
#
# PREREQUISITES:
#   - .NET SDK 8.0+ installed
#   - Backend Function App project in src/backend/
#   - Test project in src/backend/tests/AIFoundryProxy.Tests/
#   - zip utility for package creation and validation
#   - unzip utility for package inspection
#
# EXPECTED OUTPUT:
#   - Backend project build results
#   - Test project compilation status
#   - Detailed test execution results with coverage summary  
#   - Package creation and validation results
#   - Deployment readiness assessment

set -e  # Exit on any error

echo "🧪 Consolidated Backend Testing and Package Validation"
echo "======================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Parse command line arguments
PACKAGE_ONLY=false
PACKAGE_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --package-only)
            PACKAGE_ONLY=true
            PACKAGE_PATH="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Usage: $0 [--package-only /path/to/package.zip]"
            exit 1
            ;;
    esac
done

# Determine script location for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
echo -e "${BLUE}📁 Repository root: $REPO_ROOT${NC}"

# ============================================================================
# SECTION 1: Backend Build and Testing (unless --package-only specified)
# ============================================================================

if [ "$PACKAGE_ONLY" = false ]; then
    echo -e "\n${CYAN}🔨 Building Backend Project${NC}"
    echo "============================"
    
    cd "$REPO_ROOT/src/backend"
    
    # Restore dependencies
    echo -e "${GRAY}📦 Restoring dependencies...${NC}"
    if ! dotnet restore > /dev/null 2>&1; then
        echo -e "${RED}❌ Backend dependency restore failed${NC}"
        exit 1
    fi
    
    # Build main project
    echo -e "${GRAY}🔨 Building backend project...${NC}"
    if ! dotnet build --configuration Release --no-restore; then
        echo -e "${RED}❌ Backend build failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Backend project built successfully${NC}"
    
    # ========================================================================
    # SECTION 2: Test Execution
    # ========================================================================
    echo -e "\n${CYAN}🧪 Running Backend Test Suite${NC}"
    echo "=============================="
    
    cd "$REPO_ROOT/src/backend/tests/AIFoundryProxy.Tests"
    
    # Build test project
    echo -e "${GRAY}🔨 Building test project...${NC}"
    if ! dotnet build --configuration Release; then
        echo -e "${RED}❌ Test project build failed${NC}"
        exit 1
    fi
    
    # Run tests with detailed output
    echo -e "${GRAY}🏃 Executing test suite with detailed logging...${NC}"
    if ! dotnet test --configuration Release --verbosity normal --logger "console;verbosity=detailed"; then
        echo -e "${RED}❌ Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}✅ All tests passed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Test Coverage Summary:${NC}"
    echo -e "${GRAY}   - Basic Function Tests: Constructor, configuration, initialization${NC}"
    echo -e "${GRAY}   - Chat Models Tests: Request/response serialization and validation${NC}"
    echo -e "${GRAY}   - Utility Method Tests: Helper functions and status checking${NC}"
    echo -e "${GRAY}   - Simulation Logic Tests: AI message processing and contextual responses${NC}"
    echo -e "${GRAY}   - Integration Tests: End-to-end workflows and multi-request handling${NC}"
    
    # ========================================================================
    # SECTION 3: Create Deployment Package
    # ========================================================================
    echo -e "\n${CYAN}📦 Creating Deployment Package${NC}"
    echo "==============================="
    
    cd "$REPO_ROOT/src/backend"
    
    # Publish the function app
    echo -e "${GRAY}📤 Publishing Function App for deployment...${NC}"
    if ! dotnet publish --configuration Release --no-build --output ./publish > /dev/null 2>&1; then
        echo -e "${RED}❌ Backend publish failed${NC}"
        exit 1
    fi
    
    # Create deployment package
    echo -e "${GRAY}🗜️  Creating deployment package...${NC}"
    cd publish
    if ! zip -r ../backend-deployment.zip . > /dev/null 2>&1; then
        echo -e "${RED}❌ Package creation failed${NC}"
        exit 1
    fi
    
    cd ..
    PACKAGE_PATH="$PWD/backend-deployment.zip"
    echo -e "${GREEN}✅ Deployment package created: backend-deployment.zip${NC}"
else
    echo -e "\n${YELLOW}⏭️  Skipping build and tests (package-only mode)${NC}"
    if [ ! -f "$PACKAGE_PATH" ]; then
        echo -e "${RED}❌ Package file not found: $PACKAGE_PATH${NC}"
        exit 1
    fi
fi

# ============================================================================
# SECTION 4: Package Validation
# ============================================================================
echo -e "\n${CYAN}🔍 Validating Deployment Package${NC}"
echo "================================="

# Get package info
PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" 2>/dev/null | cut -f1 || echo "Unknown")
echo -e "${BLUE}📦 Package: $PACKAGE_PATH${NC}"
echo -e "${BLUE}📏 Package size: $PACKAGE_SIZE${NC}"
echo ""

# Test 1: Package readability
echo -e "${CYAN}1️⃣ Testing package readability...${NC}"
if ! unzip -t "$PACKAGE_PATH" > /dev/null 2>&1; then
    echo -e "${RED}❌ Package is corrupted or not a valid zip file${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Package is valid and readable${NC}"
echo ""

# Test 2: Check for .azurefunctions directory (critical for Function App deployment)
echo -e "${CYAN}2️⃣ Checking for .azurefunctions directory...${NC}"
if unzip -l "$PACKAGE_PATH" | grep -E "\.azurefunctions|azurefunctions/" > /dev/null; then
    echo -e "${GREEN}✅ .azurefunctions directory found${NC}"
    echo -e "${GRAY}   .azurefunctions contents:${NC}"
    unzip -l "$PACKAGE_PATH" | grep -E "\.azurefunctions|azurefunctions/" | while read -r line; do
        echo -e "${GRAY}   - $line${NC}"
    done
else
    echo -e "${RED}❌ .azurefunctions directory NOT found!${NC}"
    echo -e "${RED}   This WILL cause Function App deployment to fail.${NC}"
    echo -e "${YELLOW}   The .azurefunctions directory is required for Azure Functions runtime.${NC}"
    exit 1
fi
echo ""

# Test 3: Check for required Function App files
echo -e "${CYAN}3️⃣ Checking for required Function App files...${NC}"

REQUIRED_FILES=(
    "host.json"
    "functions.metadata"
    "worker.config.json"
)

missing_files=0
for file in "${REQUIRED_FILES[@]}"; do
    if unzip -l "$PACKAGE_PATH" | grep -q "$file"; then
        echo -e "${GREEN}✅ Found: $file${NC}"
    else
        echo -e "${RED}❌ Missing: $file${NC}"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo -e "${RED}❌ $missing_files required files are missing${NC}"
    exit 1
fi
echo ""

# Test 4: Check for application assemblies
echo -e "${CYAN}4️⃣ Checking for application assemblies...${NC}"
if unzip -l "$PACKAGE_PATH" | grep -q "\.dll$"; then
    echo -e "${GREEN}✅ Application assemblies found${NC}"
    echo -e "${GRAY}   Key application DLLs:${NC}"
    unzip -l "$PACKAGE_PATH" | grep "\.dll$" | grep -v "Microsoft\|System\|Azure\|Google\|Grpc" | head -5 | while read -r line; do
        echo -e "${GRAY}   - $line${NC}"
    done
else
    echo -e "${RED}❌ No application assemblies found${NC}"
    exit 1
fi
echo ""

# Test 5: Package summary and structure validation
echo -e "${CYAN}5️⃣ Package structure summary...${NC}"
TOTAL_FILES=$(unzip -l "$PACKAGE_PATH" | grep -E "^\s+[0-9]+" | wc -l)
TOTAL_SIZE=$(unzip -l "$PACKAGE_PATH" | tail -1 | awk '{print $1}')

echo -e "${BLUE}📊 Package Statistics:${NC}"
echo -e "${GRAY}   - Total files: $TOTAL_FILES${NC}"
echo -e "${GRAY}   - Uncompressed size: $TOTAL_SIZE bytes${NC}"
echo -e "${GRAY}   - Package size: $PACKAGE_SIZE${NC}"

# Check for potential deployment issues
echo -e "\n${CYAN}6️⃣ Deployment readiness assessment...${NC}"

# Check for common deployment blockers
DEPLOYMENT_WARNINGS=0

# Check package size (Azure has limits)
PACKAGE_SIZE_BYTES=$(stat -f%z "$PACKAGE_PATH" 2>/dev/null || stat -c%s "$PACKAGE_PATH" 2>/dev/null || echo 0)
if [ "$PACKAGE_SIZE_BYTES" -gt 104857600 ]; then  # 100MB
    echo -e "${YELLOW}⚠️  Package size exceeds 100MB - may cause deployment issues${NC}"
    DEPLOYMENT_WARNINGS=$((DEPLOYMENT_WARNINGS + 1))
fi

# Check for excessive file count
if [ "$TOTAL_FILES" -gt 10000 ]; then
    echo -e "${YELLOW}⚠️  High file count ($TOTAL_FILES) - may slow deployment${NC}"
    DEPLOYMENT_WARNINGS=$((DEPLOYMENT_WARNINGS + 1))
fi

if [ $DEPLOYMENT_WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Package passes all deployment readiness checks${NC}"
else
    echo -e "${YELLOW}⚠️  Package has $DEPLOYMENT_WARNINGS warnings but should still deploy${NC}"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo -e "\n${BLUE}📋 Backend Validation Summary${NC}"
echo "=============================="

if [ "$PACKAGE_ONLY" = false ]; then
    echo -e "${GREEN}✅ Backend build: PASSED${NC}"
    echo -e "${GREEN}✅ Test suite: PASSED${NC}"
    echo -e "${GREEN}✅ Package creation: PASSED${NC}"
fi

echo -e "${GREEN}✅ Package validation: PASSED${NC}"
echo -e "${GREEN}✅ Deployment readiness: VERIFIED${NC}"
echo ""

if [ "$PACKAGE_ONLY" = false ]; then
    echo -e "${BLUE}🎯 The AI Foundry SPA backend is ready for deployment!${NC}"
    echo -e "${GRAY}   Package location: $PACKAGE_PATH${NC}"
    echo -e "${GRAY}   Package size: $PACKAGE_SIZE${NC}"
    echo -e "${GRAY}   Total files: $TOTAL_FILES${NC}"
else
    echo -e "${BLUE}🎯 Package validation completed successfully!${NC}"
    echo -e "${GRAY}   Validated package: $PACKAGE_PATH${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Ready for Azure Function App deployment${NC}"