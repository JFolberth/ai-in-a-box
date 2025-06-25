#!/bin/bash

# AI Foundry SPA Deployment Script with separate resource groups for frontend and backend
# This script deploys the AI Foundry SPA to Azure using Azure CLI and Bicep templates
# Frontend: Storage Account for static website hosting  
# Backend: Function App for AI Foundry proxy
# NO Azure Developer CLI (azd) dependencies - uses pure Azure CLI commands

set -e

# Default values
SUBSCRIPTION_ID=""
LOCATION="eastus"
ENVIRONMENT_NAME="dev"
APPLICATION_NAME="ai-foundry-spa"
SKIP_BUILD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    -l|--location)
      LOCATION="$2"
      shift 2
      ;;
    -e|--environment)
      ENVIRONMENT_NAME="$2"
      shift 2
      ;;
    -a|--application)
      APPLICATION_NAME="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 -s <subscription-id> [-l <location>] [--skip-build]"
      echo "  -s, --subscription      Azure subscription ID (required)"
      echo "  -l, --location          Azure region (default: eastus)"
      echo "  --skip-build           Skip npm build step"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "❌ Error: Subscription ID is required. Use -s or --subscription"
  exit 1
fi

# Verify files exist
if [[ ! -f "infra/main-orchestrator.bicep" ]]; then
  echo "❌ Bicep template not found: infra/main-orchestrator.bicep"
  exit 1
fi

if [[ ! -f "infra/dev-orchestrator.parameters.bicepparam" ]]; then
  echo "❌ Parameters file not found: infra/dev-orchestrator.parameters.bicepparam"  exit 1
fi

echo "🚀 Starting deployment of AI Foundry SPA..."
echo "📋 Subscription: $SUBSCRIPTION_ID"
echo "📋 Location: $LOCATION"

# Verify Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI is not installed"
  exit 1
fi

if ! az account show &> /dev/null; then
  echo "❌ Please login to Azure CLI first: az login"
  exit 1
fi

# Set subscription
echo "🔧 Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "✅ Using Azure subscription: $SUBSCRIPTION_NAME"

# Deploy infrastructure using orchestrator
echo "🏗️ Deploying infrastructure with orchestrator..."
DEPLOYMENT_OUTPUT=$(az deployment sub create \
  --location "$LOCATION" \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/dev-orchestrator.parameters.bicepparam" \
  --query 'properties.outputs' -o json)

if [[ $? -ne 0 ]]; then
  echo "❌ Infrastructure deployment failed"
  exit 1
fi

echo "✅ Infrastructure deployed successfully"

# Extract outputs
FRONTEND_RESOURCE_GROUP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendResourceGroupName.value')
BACKEND_RESOURCE_GROUP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.backendResourceGroupName.value')
FRONTEND_STORAGE_ACCOUNT=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendStorageAccountName.value')
BACKEND_FUNCTION_APP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.backendFunctionAppName.value')
FRONTEND_STATIC_WEBSITE_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendStaticWebsiteUrl.value')
BACKEND_API_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.backendApiUrl.value')

echo "📊 Deployment Outputs:"
echo "  Frontend Resource Group: $FRONTEND_RESOURCE_GROUP"
echo "  Backend Resource Group: $BACKEND_RESOURCE_GROUP"
echo "  Frontend Storage Account: $FRONTEND_STORAGE_ACCOUNT"
echo "  Backend Function App: $BACKEND_FUNCTION_APP"
echo "  Frontend Website URL: $FRONTEND_STATIC_WEBSITE_URL"
echo "  Backend API URL: $BACKEND_API_URL"

# Build application
if [[ "$SKIP_BUILD" == false ]]; then
  echo "🔨 Building application..."
  npm install
  npm run build
  echo "✅ Application built successfully"
else
  echo "⏭️ Skipping build step"
fi

# Verify dist folder exists
if [[ ! -d "src/frontend/dist" ]]; then
  echo "❌ Build output not found. Please run 'npm run build' first or remove --skip-build flag"
  exit 1
fi

# Enable static website hosting
echo "🌐 Configuring static website hosting..."
az storage blob service-properties update \
  --account-name "$FRONTEND_STORAGE_ACCOUNT" \
  --static-website \
  --index-document "index.html" \
  --404-document "index.html" \
  --output none

echo "✅ Static website hosting enabled"

# Upload files to storage
echo "📤 Uploading website files..."
az storage blob upload-batch \
  --destination '$web' \
  --source "./src/frontend/dist" \
  --account-name "$FRONTEND_STORAGE_ACCOUNT" \
  --overwrite \
  --output table

echo "✅ Website files uploaded successfully"

# Build and deploy Function App
echo "⚡ Building and deploying Function App..."
cd src/backend
dotnet build AIFoundryProxy.csproj --configuration Release
dotnet publish AIFoundryProxy.csproj --configuration Release --output "./bin/Release/net8.0/publish"

# Create deployment package
zip -r "./bin/Release/net8.0/publish.zip" "./bin/Release/net8.0/publish/"*
cd ../..

# Deploy Function App
az functionapp deployment source config-zip \
  --resource-group "$BACKEND_RESOURCE_GROUP" \
  --name "$BACKEND_FUNCTION_APP" \
  --src "src/backend/bin/Release/net8.0/publish.zip"

echo "✅ Function App deployed successfully"

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   📦 Frontend Resource Group: $FRONTEND_RESOURCE_GROUP"
echo "   📦 Backend Resource Group: $BACKEND_RESOURCE_GROUP"
echo "   🌐 Frontend URL: $FRONTEND_STATIC_WEBSITE_URL"
echo "   ⚡ Backend API URL: $BACKEND_API_URL"
echo ""
echo "🔗 Next Steps:"
echo "   1. Update your .env file with the Backend API URL"
echo "   2. Test the application at the Frontend URL"
echo "   3. Monitor frontend and backend separately using their respective Application Insights"
echo ""
echo "   $WEBSITE_URL"
echo ""
echo "📋 Next steps:"
echo "   1. Update your Azure AD app registration redirect URI to: $WEBSITE_URL"
echo "   2. Configure your AI Foundry endpoint settings"
echo "   3. Test the application"
