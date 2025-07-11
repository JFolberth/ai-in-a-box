#!/bin/bash

# Azure Function App Deployment Package Validation Script
# 
# This script validates that a Function App deployment package contains
# all the required files and directories for successful Azure deployment.
#
# SYNOPSIS:
#   Validates Azure Function App deployment package structure and contents
#
# USAGE:
#   # Basic usage (validates backend-deployment.zip in current directory)
#   ./validate-backend-package.sh
#
#   # With specific package path
#   ./validate-backend-package.sh /path/to/backend-deployment.zip
#
#   # Full absolute path (recommended)
#   /home/runner/work/ai-in-a-box/ai-in-a-box/tests/validate-backend-package.sh
#
# PREREQUISITES:
#   - unzip utility
#   - grep utility
#   - Deployment package (backend-deployment.zip)
#
# EXPECTED OUTPUT:
#   - Package structure validation results
#   - .azurefunctions directory verification
#   - Required files check
#   - Package size and contents summary

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Default package path
PACKAGE_PATH="backend-deployment.zip"

# Check if a custom package path was provided
if [ $# -gt 0 ]; then
    PACKAGE_PATH="$1"
fi

echo -e "${CYAN}🔍 Azure Function App Deployment Package Validator${NC}"
echo -e "${CYAN}===================================================${NC}"
echo -e "Package: ${YELLOW}$PACKAGE_PATH${NC}"
echo ""

# Check if package exists
if [ ! -f "$PACKAGE_PATH" ]; then
    echo -e "${RED}❌ Package file not found: $PACKAGE_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Package file found${NC}"

# Get package size
PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
echo -e "${GRAY}   Package size: $PACKAGE_SIZE${NC}"
echo ""

# Validate package can be read
echo -e "${CYAN}1️⃣ Testing package readability...${NC}"
if ! unzip -t "$PACKAGE_PATH" > /dev/null 2>&1; then
    echo -e "${RED}❌ Package is corrupted or not a valid zip file${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Package is valid and readable${NC}"
echo ""

# Check for .azurefunctions directory (critical for Function App deployment)
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

# Check for required Function App files
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

# Check for application DLL
echo -e "${CYAN}4️⃣ Checking for application assembly...${NC}"
if unzip -l "$PACKAGE_PATH" | grep -q "\.dll$"; then
    echo -e "${GREEN}✅ Application assemblies found${NC}"
    echo -e "${GRAY}   Application DLLs:${NC}"
    unzip -l "$PACKAGE_PATH" | grep "\.dll$" | grep -v "Microsoft\|System\|Azure\|Google\|Grpc" | head -5 | while read -r line; do
        echo -e "${GRAY}   - $line${NC}"
    done
else
    echo -e "${RED}❌ No application assemblies found${NC}"
    exit 1
fi
echo ""

# Package summary
echo -e "${CYAN}5️⃣ Package summary...${NC}"
TOTAL_FILES=$(unzip -l "$PACKAGE_PATH" | grep -E "^\s+[0-9]+" | wc -l)
echo -e "${GREEN}✅ Package validation successful!${NC}"
echo -e "${GRAY}   Total files: $TOTAL_FILES${NC}"
echo -e "${GRAY}   Package size: $PACKAGE_SIZE${NC}"
echo -e "${GRAY}   Contains all required Function App components${NC}"
echo ""

echo -e "${GREEN}🚀 Package is ready for Azure Function App deployment!${NC}"