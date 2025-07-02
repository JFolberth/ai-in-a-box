#!/bin/bash

# CI Workflow Simulation Script
# 
# This script simulates the CI workflow locally to test the backend and frontend
# build processes, including the deployment package creation and validation.
#
# SYNOPSIS:
#   Simulates the GitHub Actions CI workflow for local testing
#
# USAGE:
#   # Basic usage (runs complete CI simulation)
#   ./simulate-ci-workflow.sh
#
#   # Full absolute path (recommended)
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/simulate-ci-workflow.sh
#
# PREREQUISITES:
#   - .NET 8 SDK
#   - Node.js and npm
#   - zip utility
#   - Working directory should be repository root
#
# EXPECTED OUTPUT:
#   - Backend build, test, and package creation results
#   - Frontend build and test results
#   - Package validation results
#   - Workflow summary

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 CI Workflow Simulation${NC}"
echo -e "${CYAN}========================${NC}"
echo ""

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo -e "${GRAY}Working directory: $(pwd)${NC}"
echo ""

# 1. Backend Build and Test (simulating shared-backend-build.yml)
echo -e "${CYAN}1️⃣ Backend Build and Test${NC}"
echo -e "${YELLOW}   📂 Backend directory: src/backend${NC}"

cd src/backend

# Restore dependencies
echo -e "${GRAY}   📦 Restoring dependencies...${NC}"
if ! dotnet restore > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend dependency restore failed${NC}"
    exit 1
fi

# Build
echo -e "${GRAY}   🔨 Building backend...${NC}"
if ! dotnet build --configuration Release --no-restore > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
fi

# Test
echo -e "${GRAY}   🧪 Running backend tests...${NC}"
if ! dotnet test tests/AIFoundryProxy.Tests/ --configuration Release --verbosity minimal > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend tests failed${NC}"
    exit 1
fi

# Publish
echo -e "${GRAY}   📦 Publishing backend...${NC}"
if ! dotnet publish --configuration Release --no-build --output ./publish > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend publish failed${NC}"
    exit 1
fi

# Create deployment package
echo -e "${GRAY}   📁 Creating deployment package...${NC}"
cd publish
if ! zip -r ../backend-deployment.zip . -x "*.pdb" > /dev/null 2>&1; then
    echo -e "${RED}❌ Deployment package creation failed${NC}"
    exit 1
fi
cd ..

# Verify package (simulating the enhanced validation)
echo -e "${GRAY}   ✅ Verifying deployment package...${NC}"
if ! unzip -l backend-deployment.zip | grep -E "\.azurefunctions|azurefunctions/" > /dev/null; then
    echo -e "${RED}❌ .azurefunctions directory not found in deployment package!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend build, test, and package creation successful${NC}"

# Get package info
PACKAGE_SIZE=$(du -h backend-deployment.zip | cut -f1)
PACKAGE_FILES=$(unzip -l backend-deployment.zip | grep -E "^\s+[0-9]+" | wc -l)
echo -e "${GRAY}   📊 Package: $PACKAGE_SIZE, $PACKAGE_FILES files${NC}"

cd "$REPO_ROOT"
echo ""

# 2. Frontend Build and Test (simulating shared-frontend-build.yml)
echo -e "${CYAN}2️⃣ Frontend Build and Test${NC}"
echo -e "${YELLOW}   📂 Frontend directory: src/frontend${NC}"

cd src/frontend

# Install dependencies
echo -e "${GRAY}   📦 Installing dependencies...${NC}"
if ! npm install > /dev/null 2>&1; then
    echo -e "${RED}❌ Frontend dependency installation failed${NC}"
    exit 1
fi

# Test
echo -e "${GRAY}   🧪 Running frontend tests...${NC}"
if ! npm test > /dev/null 2>&1; then
    echo -e "${RED}❌ Frontend tests failed${NC}"
    exit 1
fi

# Build
echo -e "${GRAY}   🔨 Building frontend...${NC}"
if ! npm run build > /dev/null 2>&1; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

# Verify build output
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Frontend build output (dist/) not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build and test successful${NC}"

# Get build info
DIST_SIZE=$(du -sh dist | cut -f1)
DIST_FILES=$(find dist -type f | wc -l)
echo -e "${GRAY}   📊 Build output: $DIST_SIZE, $DIST_FILES files${NC}"

cd "$REPO_ROOT"
echo ""

# 3. Package Validation (simulating CI deployment validation)
echo -e "${CYAN}3️⃣ Deployment Package Validation${NC}"
echo -e "${GRAY}   🔍 Running comprehensive package validation...${NC}"

if ! ./tests/integration/test-backend-validation.sh --package-only src/backend/backend-deployment.zip | tail -5; then
    echo -e "${RED}❌ Package validation failed${NC}"
    exit 1
fi

echo ""

# 4. Simulation Summary
echo -e "${CYAN}4️⃣ CI Workflow Simulation Summary${NC}"
echo -e "${GREEN}✅ All workflow steps completed successfully!${NC}"
echo ""
echo -e "${GRAY}Simulated workflow steps:${NC}"
echo -e "${GRAY}  ✅ Backend: restore → build → test → publish → package → validate${NC}"
echo -e "${GRAY}  ✅ Frontend: install → test → build → verify${NC}"
echo -e "${GRAY}  ✅ Package validation: structure → contents → deployment readiness${NC}"
echo ""
echo -e "${GRAY}📦 Artifacts created:${NC}"
echo -e "${GRAY}  - Backend: src/backend/backend-deployment.zip ($PACKAGE_SIZE)${NC}"
echo -e "${GRAY}  - Frontend: src/frontend/dist/ ($DIST_SIZE)${NC}"
echo ""
echo -e "${GREEN}🚀 Ready for deployment!${NC}"
echo -e "${GRAY}   Backend package can be deployed to Azure Function App${NC}"
echo -e "${GRAY}   Frontend dist can be deployed to Static Web App${NC}"