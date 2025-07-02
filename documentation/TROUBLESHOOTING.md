# Troubleshooting Guide

This document provides solutions to common issues you may encounter when deploying the AI in a Box application.

## 🚨 Azure Function App Deployment Issues

### Missing .azurefunctions Directory Error

**Error Message:**
```
InvalidPackageContentException: Package content validation failed: Cannot find required .azurefunctions directory at root level in the .zip package.
```

**Root Cause:**
The `.azurefunctions` directory was missing from the deployment package. This commonly occurs when:
1. GitHub Actions artifacts don't preserve directories starting with `.` (dot directories)
2. The build process doesn't properly include all required Function App files
3. Manual zip creation excludes hidden directories

**Solution:**
This issue has been resolved in the CI/CD pipeline by:
1. Creating the deployment zip during the build process (before artifact upload)
2. Using the pre-packaged zip file for deployment instead of creating it on-demand
3. Adding verification steps to ensure the `.azurefunctions` directory is present

**Verification Steps:**
To verify a deployment package is valid:
```bash
# Check if .azurefunctions directory is present in the zip
unzip -l deployment-package.zip | grep -E "\.azurefunctions|azurefunctions/"

# Expected output should show:
#         0  DATE TIME   .azurefunctions/
#    102136  DATE TIME   .azurefunctions/function.deps.json
#      4096  DATE TIME   .azurefunctions/Microsoft.Azure.Functions.Worker.Extensions.dll
#    777696  DATE TIME   .azurefunctions/Microsoft.WindowsAzure.Storage.dll
#     24064  DATE TIME   .azurefunctions/Microsoft.Azure.WebJobs.Extensions.FunctionMetadataLoader.dll
#     83832  DATE TIME   .azurefunctions/Microsoft.Azure.WebJobs.Host.Storage.dll

# Or use the validation script
./tests/integration/validate-backend-package.sh path/to/backend-deployment.zip
```

**Manual Fix (if needed):**
If you encounter this issue with manual deployments:
1. Ensure you're using `dotnet publish` to create the deployment package
2. Use `Compress-Archive` (PowerShell) or `zip -r` (Linux/Mac) to create the zip file
3. Verify the `.azurefunctions` directory is included before deployment

### ZIP Deploy Package Path Error

**Error Message:**
```
Error: Failed to deploy web package to Function App.
Error: Execution Exception (state: PublishContent) (step: Invocation)
Error: When request Azure resource at PublishContent, oneDeploy : Failed to use /path/to/temp_web_package.zip as OneDeploy content
Error: Package deployment using ZIP Deploy failed.
```

**Root Cause:**
The Azure Functions action was receiving a directory path instead of a zip file path, or the zip file was corrupted/malformed.

**Solution:**
Fixed in CI/CD pipeline by:
1. Ensuring the Functions action receives the correct zip file path
2. Adding validation of the deployment package before deployment
3. Verifying package contents include all required components

**Related Files:**
- `.github/workflows/shared-backend-build.yml` - Package creation and validation
- `.github/workflows/ci.yml` - Deployment process
- `tests/integration/validate-backend-package.sh` - Package validation script
- `deploy-scripts/deploy-backend-func-code.ps1` - Manual deployment script

## 🌐 Static Web App Deployment Issues

### SWA CLI Authentication Failures

**Error Message:**
```
Error: Unable to authenticate. Please check your credentials.
```

**Solution:**
Ensure you're logged into Azure CLI before deploying:
```bash
az login
az account show  # Verify you're logged in with the correct account
```

### Build Output Missing

**Error Message:**
```
Build output not found. Please run 'npm run build' first
```

**Solution:**
Run the frontend build before deployment:
```bash
cd src/frontend
npm install
npm run build
```

## 🔐 Authentication and Permissions Issues

### Azure CLI Not Authenticated

**Error Message:**
```
Please run 'az login' to authenticate with Azure CLI
```

**Solution:**
```bash
az login
```

### Insufficient Permissions

**Error Message:**
```
Forbidden: User does not have permission to perform this action
```

**Solution:**
Ensure your account has the required RBAC roles:
- **Function App**: Contributor or Website Contributor
- **Static Web App**: Contributor or Static Web App Contributor
- **Resource Group**: Contributor (if creating resources)

## 📋 Build and Test Issues

### .NET Build Failures

**Common Issues:**
1. **Missing .NET SDK**: Install .NET 8 SDK
2. **Package restore failures**: Run `dotnet restore` first
3. **Configuration issues**: Ensure you're building in Release configuration

**Solution:**
```bash
cd src/backend
dotnet restore
dotnet build --configuration Release
dotnet test --configuration Release
```

### Frontend Build Failures

**Common Issues:**
1. **Missing Node.js**: Install Node.js 18+ and npm
2. **Package installation failures**: Clear npm cache and reinstall
3. **Build script errors**: Check package.json scripts

**Solution:**
```bash
cd src/frontend
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
npm run build
```

## 🔧 Environment-Specific Issues

### Azure Deployment Environments (ADE)

**Issue**: ADE deployment fails with resource not found
**Solution**: 
1. Verify the ADE environment was deployed successfully
2. Check the resource group and resource names match expectations
3. Use Azure CLI to list resources and verify names:
   ```bash
   az functionapp list --query "[?contains(name, 'func-ai-foundry-spa-backend')].{name:name,resourceGroup:resourceGroup}" --output table
   az staticwebapp list --query "[?contains(name, 'stapp-aibox-fd')].{name:name,resourceGroup:resourceGroup}" --output table
   ```

### Local Development

**Issue**: Function App doesn't start locally
**Solution**: 
1. Start Azurite emulator first
2. Ensure local.settings.json is configured
3. Use VS Code tasks for proper startup sequence

## 📞 Getting Help

If you continue to experience issues:

1. **Check the logs**: Review Azure portal logs for detailed error messages
2. **Verify configuration**: Ensure all environment variables and settings are correct
3. **Test locally**: Reproduce the issue in a local development environment
4. **Check documentation**: Review the specific deployment guide for your scenario

For additional support, please refer to:
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)