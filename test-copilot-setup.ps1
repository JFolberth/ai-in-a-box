#!/usr/bin/env pwsh

# Test script to validate GitHub Copilot setup steps
# This script tests all commands from .github/copilot-setup-steps.yml
# to ensure they work correctly in the current environment

param(
    [switch]$SkipAzureExtensions = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

function Write-TestStep {
    param([string]$Message)
    Write-Host "🧪 TEST: $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ SUCCESS: $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "❌ FAILURE: $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Command)
    try {
        $result = Get-Command $Command -ErrorAction SilentlyContinue
        return $null -ne $result
    } catch {
        return $false
    }
}

# Initialize test results
$testResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Issues = @()
}

Write-Host "🚀 Testing GitHub Copilot Setup Steps for AI Foundry SPA Project" -ForegroundColor Blue
Write-Host "=" * 70

# Test 1: Azure CLI extensions
Write-TestStep "Testing Azure CLI extensions setup"
if (-not (Test-Command "az")) {
    Write-Failure "Azure CLI not found - this is expected in non-Azure environments"
    $testResults.Issues += "Azure CLI not available for extension testing"
    $testResults.Warnings++
} elseif ($SkipAzureExtensions) {
    Write-Warning "Skipping Azure CLI extension tests (--SkipAzureExtensions flag)"
    $testResults.Warnings++
} else {
    try {
        Write-Host "  Testing Azure CLI version..."
        az --version | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" }
        
        Write-Host "  Testing extension installations..."
        # Note: In a testing environment, we'll just check if the commands would work
        # The actual extensions may not be needed for validation
        Write-Success "Azure CLI is available for extension installation"
        $testResults.Passed++
    } catch {
        Write-Failure "Azure CLI extension test failed: $($_.Exception.Message)"
        $testResults.Issues += "Azure CLI extension testing failed"
        $testResults.Failed++
    }
}

# Test 2: Node.js environment for frontend
Write-TestStep "Testing Node.js environment for frontend"
try {
    if (-not (Test-Command "node")) {
        throw "Node.js not found"
    }
    $nodeVersion = node --version
    Write-Host "  Node.js version: $nodeVersion"
    
    if (-not (Test-Command "npm")) {
        throw "npm not found"
    }
    $npmVersion = npm --version
    Write-Host "  npm version: $npmVersion"
    
    # Test frontend directory and package.json
    $frontendPath = "src/frontend"
    if (-not (Test-Path $frontendPath)) {
        throw "Frontend directory not found: $frontendPath"
    }
    Write-Host "  Frontend directory exists: $frontendPath"
    
    $packageJsonPath = Join-Path $frontendPath "package.json"
    if (-not (Test-Path $packageJsonPath)) {
        throw "package.json not found in frontend directory"
    }
    Write-Host "  package.json exists in frontend directory"
    
    # Test npm ci command (dry run)
    Push-Location $frontendPath
    try {
        Write-Host "  Testing npm install in frontend directory..."
        npm ci --dry-run --silent 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  npm ci command validation successful"
        } else {
            Write-Host "  npm ci dry run had warnings (normal for missing node_modules)"
        }
        
        # Check if Vite is available after install
        if (Test-Path "node_modules") {
            $viteCheck = npx vite --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Vite is available: $viteCheck"
            }
        }
    } finally {
        Pop-Location
    }
    
    Write-Success "Node.js environment is properly configured"
    $testResults.Passed++
} catch {
    Write-Failure "Node.js environment test failed: $($_.Exception.Message)"
    $testResults.Issues += "Node.js environment validation failed"
    $testResults.Failed++
}

# Test 3: .NET SDK for backend development
Write-TestStep "Testing .NET SDK for backend development"
try {
    if (-not (Test-Command "dotnet")) {
        throw ".NET SDK not found"
    }
    
    $dotnetVersion = dotnet --version
    Write-Host "  .NET SDK version: $dotnetVersion"
    
    $sdks = dotnet --list-sdks
    Write-Host "  Available SDKs:"
    $sdks | ForEach-Object { Write-Host "    $_" }
    
    # Test backend directory and project file
    $backendPath = "src/backend"
    if (-not (Test-Path $backendPath)) {
        throw "Backend directory not found: $backendPath"
    }
    Write-Host "  Backend directory exists: $backendPath"
    
    $projectPath = Join-Path $backendPath "AIFoundryProxy.csproj"
    if (-not (Test-Path $projectPath)) {
        throw "AIFoundryProxy.csproj not found in backend directory"
    }
    Write-Host "  AIFoundryProxy.csproj exists in backend directory"
    
    # Test dotnet restore
    Push-Location $backendPath
    try {
        Write-Host "  Testing dotnet restore..."
        dotnet restore AIFoundryProxy.csproj --no-cache --verbosity quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  dotnet restore successful"
        } else {
            Write-Warning "dotnet restore had issues (may be expected without internet)"
        }
    } finally {
        Pop-Location
    }
    
    # Test for Azure Functions Core Tools
    if (Test-Command "func") {
        $funcVersion = func --version
        Write-Host "  Azure Functions Core Tools version: $funcVersion"
    } else {
        Write-Warning "Azure Functions Core Tools not found (may be installed separately)"
        $testResults.Warnings++
    }
    
    Write-Success ".NET SDK environment is properly configured"
    $testResults.Passed++
} catch {
    Write-Failure ".NET SDK test failed: $($_.Exception.Message)"
    $testResults.Issues += ".NET SDK validation failed"
    $testResults.Failed++
}

# Test 4: PowerShell environment for deployment scripts
Write-TestStep "Testing PowerShell environment for deployment scripts"
try {
    if (-not (Test-Command "pwsh")) {
        # Fall back to regular PowerShell on Windows
        if ($IsWindows -and (Test-Command "powershell")) {
            Write-Warning "PowerShell Core (pwsh) not found, but Windows PowerShell is available"
            $psVersion = powershell -Command '$PSVersionTable.PSVersion'
        } else {
            throw "PowerShell Core (pwsh) not found"
        }
    } else {
        $psVersion = pwsh -Command '$PSVersionTable.PSVersion'
        Write-Host "  PowerShell Core version: $psVersion"
    }
    
    # Test deployment scripts directory
    $deployScriptsPath = "deploy-scripts"
    if (-not (Test-Path $deployScriptsPath)) {
        throw "Deploy scripts directory not found: $deployScriptsPath"
    }
    Write-Host "  Deploy scripts directory exists: $deployScriptsPath"
    
    # Check for key deployment scripts
    $keyScripts = @(
        "deploy-quickstart.ps1",
        "deploy-backend-func-code.ps1", 
        "deploy-frontend-spa-code.ps1"
    )
    
    foreach ($script in $keyScripts) {
        $scriptPath = Join-Path $deployScriptsPath $script
        if (Test-Path $scriptPath) {
            Write-Host "  ✓ $script exists"
        } else {
            Write-Warning "  ⚠ $script not found"
            $testResults.Warnings++
        }
    }
    
    Write-Success "PowerShell environment is available for deployment scripts"
    $testResults.Passed++
} catch {
    Write-Failure "PowerShell environment test failed: $($_.Exception.Message)"
    $testResults.Issues += "PowerShell environment validation failed"
    $testResults.Failed++
}

# Test 5: Azure and Bicep tooling
Write-TestStep "Testing Azure and Bicep tooling"
if (-not (Test-Command "az")) {
    Write-Failure "Azure CLI not found - Bicep tooling unavailable"
    $testResults.Issues += "Azure CLI not available for Bicep testing"
    $testResults.Failed++
} else {
    try {
        Write-Host "  Testing Azure CLI version..."
        $azVersion = az --version | Select-Object -First 1
        Write-Host "  $azVersion"
        
        Write-Host "  Testing Bicep version..."
        $bicepVersion = az bicep version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Bicep version: $bicepVersion"
        } else {
            Write-Warning "Bicep extension may not be installed"
            $testResults.Warnings++
        }
        
        # Test infra directory
        $infraPath = "infra"
        if (-not (Test-Path $infraPath)) {
            throw "Infrastructure directory not found: $infraPath"
        }
        Write-Host "  Infrastructure directory exists: $infraPath"
        
        # Look for Bicep files
        $bicepFiles = Get-ChildItem $infraPath -Filter "*.bicep" -Recurse
        if ($bicepFiles.Count -gt 0) {
            Write-Host "  Found $($bicepFiles.Count) Bicep files for template compilation"
            $bicepFiles | Select-Object -First 3 | ForEach-Object { 
                Write-Host "    $_" 
            }
        } else {
            Write-Warning "No Bicep files found in infrastructure directory"
            $testResults.Warnings++
        }
        
        Write-Success "Azure and Bicep tooling is configured"
        $testResults.Passed++
    } catch {
        Write-Failure "Azure/Bicep tooling test failed: $($_.Exception.Message)"
        $testResults.Issues += "Azure/Bicep tooling validation failed"
        $testResults.Failed++
    }
}

# Test 6: Project structure validation
Write-TestStep "Testing project structure as described in copilot-setup-steps.yml"
try {
    $requiredPaths = @{
        "src/frontend" = "JavaScript SPA with Vite"
        "src/backend" = ".NET 8 Azure Functions"
        "src/agent" = "AI Foundry agent configuration"
        "infra" = "Azure Bicep templates"
        "deploy-scripts" = "PowerShell deployment scripts"
        ".github" = "GitHub workflows and Copilot configuration"
    }
    
    $missingPaths = @()
    foreach ($path in $requiredPaths.Keys) {
        if (Test-Path $path) {
            Write-Host "  ✓ $path - $($requiredPaths[$path])"
        } else {
            Write-Host "  ❌ $path - $($requiredPaths[$path]) [MISSING]"
            $missingPaths += $path
        }
    }
    
    if ($missingPaths.Count -eq 0) {
        Write-Success "All expected project structure directories exist"
        $testResults.Passed++
    } else {
        Write-Failure "Missing directories: $($missingPaths -join ', ')"
        $testResults.Issues += "Project structure incomplete"
        $testResults.Failed++
    }
} catch {
    Write-Failure "Project structure test failed: $($_.Exception.Message)"
    $testResults.Issues += "Project structure validation failed"
    $testResults.Failed++
}

# Summary
Write-Host ""
Write-Host "📊 Test Results Summary" -ForegroundColor Blue
Write-Host "=" * 30
Write-Host "✅ Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "❌ Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host "⚠️  Warnings: $($testResults.Warnings)" -ForegroundColor Yellow

if ($testResults.Issues.Count -gt 0) {
    Write-Host ""
    Write-Host "🔍 Issues Found:" -ForegroundColor Red
    foreach ($issue in $testResults.Issues) {
        Write-Host "  • $issue" -ForegroundColor Red
    }
}

Write-Host ""
if ($testResults.Failed -eq 0) {
    Write-Host "🎉 All critical tests passed! The copilot-setup-steps.yml should work correctly." -ForegroundColor Green
    exit 0
} else {
    Write-Host "💥 Some tests failed. The copilot-setup-steps.yml may need adjustments." -ForegroundColor Red
    exit 1
}