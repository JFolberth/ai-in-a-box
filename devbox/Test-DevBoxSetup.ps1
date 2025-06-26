# Test-DevBoxSetup.ps1
# A comprehensive script to validate DevBox configuration and setup

param(
    [switch]$Detailed,
    [switch]$SkipExtensions
)

Write-Host "🚀 DevBox Configuration Validation" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Function to test command availability
function Test-Command {
    param([string]$Command, [string]$Description, [string]$ExpectedVersion = $null)
    
    try {
        $result = & $Command --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description" -ForegroundColor Green
            if ($Detailed -and $result) {
                Write-Host "   Version: $result" -ForegroundColor Gray
            }
            return $true
        } else {
            Write-Host "❌ $Description - Command failed" -ForegroundColor Red
            $script:errors++
            return $false
        }
    } catch {
        Write-Host "❌ $Description - Not found" -ForegroundColor Red
        $script:errors++
        return $false
    }
}

# Function to test VS Code extension
function Test-VSCodeExtension {
    param([string]$ExtensionId, [string]$Description)
    
    try {
        $result = code --list-extensions | Where-Object { $_ -eq $ExtensionId }
        if ($result) {
            Write-Host "✅ $Description" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  $Description - Not installed" -ForegroundColor Yellow
            $script:warnings++
            return $false
        }
    } catch {
        Write-Host "❌ $Description - VS Code not accessible" -ForegroundColor Red
        $script:errors++
        return $false
    }
}

# Function to test directory existence
function Test-Directory {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        Write-Host "✅ $Description" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $Description - Directory not found: $Path" -ForegroundColor Red
        $script:errors++
        return $false
    }
}

# Function to test Azure CLI extension
function Test-AzureCliExtension {
    param([string]$ExtensionName, [string]$Description)
    
    try {
        $result = az extension list --query "[?name=='$ExtensionName'].name" --output tsv 2>$null
        if ($result -eq $ExtensionName) {
            Write-Host "✅ $Description" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  $Description - Not installed" -ForegroundColor Yellow
            Write-Host "   Install with: az extension add --name $ExtensionName" -ForegroundColor Gray
            $script:warnings++
            return $false
        }
    } catch {
        Write-Host "❌ $Description - Azure CLI not accessible or extension check failed" -ForegroundColor Red
        $script:errors++
        return $false
    }
}

Write-Host "1️⃣ Testing System-Level Tools..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

Test-Command "node" "Node.js Runtime"
Test-Command "npm" "NPM Package Manager"
Test-Command "dotnet" ".NET 8 SDK"
Test-Command "az" "Azure CLI"
Test-Command "python" "Python 3.12"
Test-Command "pip" "Python Package Manager"
Test-Command "git" "Git Version Control"

# Test for func (Azure Functions Core Tools)
Write-Host ""
try {
    $funcResult = func --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure Functions Core Tools" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "   Version: $funcResult" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Azure Functions Core Tools - Not available" -ForegroundColor Yellow
        Write-Host "   Install with: npm install -g azure-functions-core-tools@4 --unsafe-perm true" -ForegroundColor Gray
        $warnings++
    }
} catch {
    Write-Host "⚠️  Azure Functions Core Tools - Not found" -ForegroundColor Yellow
    Write-Host "   Install with: npm install -g azure-functions-core-tools@4 --unsafe-perm true" -ForegroundColor Gray
    $warnings++
}

# Test Docker installation
Write-Host ""
try {
    $dockerResult = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker Engine" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "   Version: $dockerResult" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Docker Engine - Not available" -ForegroundColor Yellow
        Write-Host "   Start Docker Desktop or install Docker" -ForegroundColor Gray
        $warnings++
    }
} catch {
    Write-Host "⚠️  Docker Engine - Not found" -ForegroundColor Yellow
    Write-Host "   Install Docker Desktop or ensure Docker is in PATH" -ForegroundColor Gray
    $warnings++
}

# Test Docker Compose
try {
    $composeResult = docker-compose --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker Compose" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "   Version: $composeResult" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Docker Compose - Not available" -ForegroundColor Yellow
        Write-Host "   Included with Docker Desktop" -ForegroundColor Gray
        $warnings++
    }
} catch {
    Write-Host "⚠️  Docker Compose - Not found" -ForegroundColor Yellow
    Write-Host "   Included with Docker Desktop" -ForegroundColor Gray
    $warnings++
}

# Test Azure CLI extensions
Write-Host ""
Write-Host "1️⃣.1 Testing Azure CLI Extensions..." -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

Test-AzureCliExtension "bicep" "Azure Bicep Extension"
Test-AzureCliExtension "devcenter" "Azure DevCenter Extension"

Write-Host ""
Write-Host "2️⃣ Testing User Environment..." -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

# Test workspace directories
Test-Directory "$env:USERPROFILE\Workspaces" "Workspace Directory"
Test-Directory "$env:USERPROFILE\.azurite" "Azurite Data Directory"

# Test Azurite installation
try {
    $azuriteResult = azurite --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azurite Storage Emulator" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "   Version: $azuriteResult" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Azurite Storage Emulator - Not available" -ForegroundColor Yellow
        Write-Host "   Install with: npm install -g azurite" -ForegroundColor Gray
        $warnings++
    }
} catch {
    Write-Host "⚠️  Azurite Storage Emulator - Not found" -ForegroundColor Yellow
    Write-Host "   Install with: npm install -g azurite" -ForegroundColor Gray
    $warnings++
}

# Test VS Code availability
Write-Host ""
try {
    $codeResult = code --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Visual Studio Code" -ForegroundColor Green
        if ($Detailed) {
            Write-Host "   Version: $($codeResult[0])" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Visual Studio Code - Not accessible" -ForegroundColor Red
        $errors++
    }
} catch {
    Write-Host "❌ Visual Studio Code - Not available" -ForegroundColor Red
    $errors++
}

# Test VS Code extensions
if (-not $SkipExtensions) {
    Write-Host ""
    Write-Host "3️⃣ Testing VS Code Extensions..." -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Yellow
    
    $extensions = @(
        @("ms-vscode.vscode-bicep", "Azure Bicep Language Support"),
        @("ms-vscode.azure-account", "Azure Account Integration"),
        @("ms-azuretools.vscode-azurefunctions", "Azure Functions Development"),
        @("ms-dotnettools.csharp", "C# Language Support"),
        @("ms-dotnettools.vscode-dotnet-runtime", ".NET Runtime Integration"),
        @("esbenp.prettier-vscode", "Prettier Code Formatting"),
        @("ms-vscode.vscode-eslint", "ESLint JavaScript Linting"),
        @("ms-vscode.vscode-json", "JSON Language Support"),
        @("GitHub.copilot", "GitHub Copilot AI Assistant"),
        @("GitHub.copilot-chat", "GitHub Copilot Chat"),
        @("ms-toolsai.vscode-ai-toolkit", "Azure AI Toolkit"),
        @("ms-python.python", "Python Language Support"),
        @("ms-python.pylint", "Python Linting"),
        @("ms-vscode.vscode-dev-containers", "DevContainer Support"),
        @("ms-azuretools.vscode-docker", "Docker Development Tools"),
        @("ms-vscode.vscode-docker", "Docker Language Support"),
        @("github.vscode-github-actions", "GitHub Actions Integration")
    )
    
    foreach ($extension in $extensions) {
        Test-VSCodeExtension $extension[0] $extension[1]
    }
}

# Test development workflow
Write-Host ""
Write-Host "4️⃣ Testing Development Workflow..." -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

# Check if we're in the project directory
$currentPath = Get-Location
$isInProject = $false

if (Test-Path "src\frontend\package.json") {
    Write-Host "✅ Project structure detected (at root)" -ForegroundColor Green
    $isInProject = $true
    $frontendPath = "src\frontend"
    $backendPath = "src\backend"
} elseif (Test-Path "..\..\src\frontend\package.json") {
    Write-Host "✅ Project structure detected (in devbox directory)" -ForegroundColor Green
    $isInProject = $true
    $frontendPath = "..\..\src\frontend"
    $backendPath = "..\..\src\backend"
} else {
    Write-Host "⚠️  Project not cloned or not in correct directory" -ForegroundColor Yellow
    Write-Host "   Clone repository to: %USERPROFILE%\Workspaces\ai-in-a-box" -ForegroundColor Gray
    $warnings++
}

if ($isInProject) {
    # Test frontend build
    try {
        Push-Location $frontendPath -ErrorAction Stop
        if (Test-Path "package.json") {
            Write-Host "✅ Frontend package.json found" -ForegroundColor Green
            
            if (Test-Path "node_modules") {
                Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Frontend dependencies not installed" -ForegroundColor Yellow
                Write-Host "   Run: npm install" -ForegroundColor Gray
                $warnings++
            }
        }
        Pop-Location
    } catch {
        Write-Host "❌ Frontend directory issue" -ForegroundColor Red
        $errors++
    }
    
    # Test backend build
    try {
        Push-Location $backendPath -ErrorAction Stop
        if (Test-Path "AIFoundryProxy.csproj") {
            Write-Host "✅ Backend project file found" -ForegroundColor Green
        }
        Pop-Location
    } catch {
        Write-Host "❌ Backend directory issue" -ForegroundColor Red
        $errors++
    }
}

# Summary
Write-Host ""
Write-Host "📊 Validation Summary" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "🎉 DevBox setup is complete and ready for development!" -ForegroundColor Green
} elseif ($errors -eq 0) {
    Write-Host "✅ DevBox setup is functional with $warnings warning(s)" -ForegroundColor Yellow
    Write-Host "   Review warnings above and install missing optional components" -ForegroundColor Gray
} else {
    Write-Host "❌ DevBox setup has $errors error(s) and $warnings warning(s)" -ForegroundColor Red
    Write-Host "   Please resolve errors before proceeding with development" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
if ($errors -gt 0) {
    Write-Host "   1. Resolve the errors listed above" -ForegroundColor Gray
    Write-Host "   2. Re-run this validation script" -ForegroundColor Gray
} else {
    Write-Host "   1. Configure Git: git config --global user.name 'Your Name'" -ForegroundColor Gray
    Write-Host "   2. Configure Git: git config --global user.email 'your.email@example.com'" -ForegroundColor Gray
    Write-Host "   3. Sign in to Azure: az login" -ForegroundColor Gray
    Write-Host "   4. Clone repository: git clone <url> %USERPROFILE%\Workspaces\ai-in-a-box" -ForegroundColor Gray
    Write-Host "   5. Start development workflow" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📚 For more information, see: devbox/README.md" -ForegroundColor Cyan