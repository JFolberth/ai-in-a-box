#!/bin/bash
# Test-UrlExtraction.sh
# Tests the URL extraction logic used in CI workflow

echo "🧪 Testing URL extraction logic..."

# Mock deployment outputs for testing
MOCK_DEPLOYMENT_OUTPUTS='{
  "functionAppUrl": {
    "type": "String",
    "value": "https://func-ai-foundry-spa-backend-test-eus2.azurewebsites.net"
  },
  "functionAppName": {
    "type": "String", 
    "value": "func-ai-foundry-spa-backend-test-eus2"
  },
  "staticWebsiteUrl": {
    "type": "String",
    "value": "https://stapp-aibox-fd-test.azurestaticapps.net"
  },
  "staticWebAppName": {
    "type": "String",
    "value": "stapp-aibox-fd-test"
  }
}'

echo "📋 Testing Backend URL Extraction..."

# Test backend URL extraction
FUNCTION_APP_URL=$(echo "$MOCK_DEPLOYMENT_OUTPUTS" | jq -r '.functionAppUrl.value // empty' 2>/dev/null)
FUNCTION_APP_NAME=$(echo "$MOCK_DEPLOYMENT_OUTPUTS" | jq -r '.functionAppName.value // empty' 2>/dev/null)

echo "Extracted Function App URL: $FUNCTION_APP_URL"
echo "Extracted Function App Name: $FUNCTION_APP_NAME"

# Validate URLs are not empty
if [ -z "$FUNCTION_APP_URL" ] || [ "$FUNCTION_APP_URL" = "https://" ] || [ "$FUNCTION_APP_URL" = "null" ]; then
  echo "❌ Invalid or empty Function App URL: '$FUNCTION_APP_URL'"
  exit 1
else
  echo "✅ Backend URL extraction successful"
fi

if [ -z "$FUNCTION_APP_NAME" ] || [ "$FUNCTION_APP_NAME" = "null" ]; then
  echo "❌ Invalid or empty Function App Name: '$FUNCTION_APP_NAME'"
  exit 1
else
  echo "✅ Backend name extraction successful"
fi

echo ""
echo "📋 Testing Frontend URL Extraction..."

# Test frontend URL extraction
STATIC_WEB_APP_URL=$(echo "$MOCK_DEPLOYMENT_OUTPUTS" | jq -r '.staticWebsiteUrl.value // empty' 2>/dev/null)
STATIC_WEB_APP_NAME=$(echo "$MOCK_DEPLOYMENT_OUTPUTS" | jq -r '.staticWebAppName.value // empty' 2>/dev/null)

echo "Extracted Static Web App URL: $STATIC_WEB_APP_URL"
echo "Extracted Static Web App Name: $STATIC_WEB_APP_NAME"

# Validate URLs are not empty
if [ -z "$STATIC_WEB_APP_URL" ] || [ "$STATIC_WEB_APP_URL" = "https://" ] || [ "$STATIC_WEB_APP_URL" = "null" ]; then
  echo "❌ Invalid or empty Static Web App URL: '$STATIC_WEB_APP_URL'"
  exit 1
else
  echo "✅ Frontend URL extraction successful"
fi

if [ -z "$STATIC_WEB_APP_NAME" ] || [ "$STATIC_WEB_APP_NAME" = "null" ]; then
  echo "❌ Invalid or empty Static Web App Name: '$STATIC_WEB_APP_NAME'"
  exit 1
else
  echo "✅ Frontend name extraction successful"
fi

echo ""
echo "📋 Testing Error Cases..."

# Test empty deployment outputs
EMPTY_OUTPUTS='{}'
FUNCTION_APP_URL_EMPTY=$(echo "$EMPTY_OUTPUTS" | jq -r '.functionAppUrl.value // empty' 2>/dev/null)

if [ -z "$FUNCTION_APP_URL_EMPTY" ]; then
  echo "✅ Empty deployment outputs handled correctly"
else
  echo "❌ Empty deployment outputs not handled correctly: '$FUNCTION_APP_URL_EMPTY'"
  exit 1
fi

# Test null deployment outputs
NULL_OUTPUTS='{"functionAppUrl": {"value": null}}'
FUNCTION_APP_URL_NULL=$(echo "$NULL_OUTPUTS" | jq -r '.functionAppUrl.value // empty' 2>/dev/null)

if [ -z "$FUNCTION_APP_URL_NULL" ] || [ "$FUNCTION_APP_URL_NULL" = "null" ]; then
  echo "✅ Null deployment outputs handled correctly"
else
  echo "❌ Null deployment outputs not handled correctly: '$FUNCTION_APP_URL_NULL'"
  exit 1
fi

echo ""
echo "🎉 All URL extraction tests passed successfully!"
exit 0