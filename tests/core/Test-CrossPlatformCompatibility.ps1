#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test Cross-Platform PowerShell Compatibility

.DESCRIPTION
This script tests the key cross-platform compatibility fixes for the PowerShell deployment scripts.
It verifies that PATH handling, command detection, and environment variables work correctly 
across Windows, Linux, and macOS.

.NOTES
This script should run successfully in devcontainers, local environments, and CI/CD pipelines.
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-ColorOutput "🧪 Cross-Platform PowerShell Compatibility Test" "Green"
Write-ColorOutput "================================================" "Green"

# Test 1: Platform Detection
Write-ColorOutput "`n1️⃣ Testing Platform Detection..." "Cyan"
if ($IsWindows) {
    Write-ColorOutput "   ✅ Detected Windows platform" "Green"
} elseif ($IsLinux) {
    Write-ColorOutput "   ✅ Detected Linux platform" "Green"
} elseif ($IsMacOS) {
    Write-ColorOutput "   ✅ Detected macOS platform" "Green"
} else {
    Write-ColorOutput "   ⚠️  Unknown platform detected" "Yellow"
}

Write-ColorOutput "   PowerShell Version: $($PSVersionTable.PSVersion)" "Gray"

# Test 2: PATH Separator
Write-ColorOutput "`n2️⃣ Testing PATH Separator..." "Cyan"
$pathSeparator = [System.IO.Path]::PathSeparator
Write-ColorOutput "   ✅ PATH Separator: '$pathSeparator'" "Green"

if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    Write-ColorOutput "   ✅ Windows PATH handling enabled" "Green"
} else {
    Write-ColorOutput "   ✅ Unix PATH handling (using shell PATH)" "Green"
}

# Test 3: Cross-Platform PATH Manipulation
Write-ColorOutput "`n3️⃣ Testing PATH Manipulation..." "Cyan"
$originalPath = $env:PATH
$testPath = "/test/path/for/compatibility"

# Test adding a path using cross-platform separator
$env:PATH = "$testPath$pathSeparator" + $env:PATH

if ($env:PATH.StartsWith($testPath)) {
    Write-ColorOutput "   ✅ PATH manipulation successful" "Green"
} else {
    Write-ColorOutput "   ❌ PATH manipulation failed" "Red"
}

# Restore original PATH
$env:PATH = $originalPath

# Test 4: Command Detection
Write-ColorOutput "`n4️⃣ Testing Command Detection..." "Cyan"
$commands = @("node", "npm", "az", "dotnet", "pwsh")

foreach ($cmd in $commands) {
    if (Test-Command $cmd) {
        Write-ColorOutput "   ✅ $cmd found" "Green"
    } else {
        Write-ColorOutput "   ⚠️  $cmd not found" "Yellow"
    }
}

# Test 5: npm Global Path Detection
Write-ColorOutput "`n5️⃣ Testing npm Global Path..." "Cyan"
try {
    $npmGlobalPath = npm config get prefix 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($npmGlobalPath)) {
        Write-ColorOutput "   ✅ npm global path: $npmGlobalPath" "Green"
        
        # Test if the path would be added correctly
        if (-not $env:PATH.Contains($npmGlobalPath)) {
            Write-ColorOutput "   ✅ npm global path not in PATH (would be added)" "Green"
        } else {
            Write-ColorOutput "   ✅ npm global path already in PATH" "Green"
        }
    } else {
        Write-ColorOutput "   ⚠️  npm global path not detected" "Yellow"
    }
} catch {
    Write-ColorOutput "   ❌ Error getting npm global path: $($_.Exception.Message)" "Red"
}

# Test 6: Environment Variable Access
Write-ColorOutput "`n6️⃣ Testing Environment Variable Access..." "Cyan"
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if ($machinePath) {
            Write-ColorOutput "   ✅ Machine PATH accessible (Windows)" "Green"
        }
        if ($userPath) {
            Write-ColorOutput "   ✅ User PATH accessible (Windows)" "Green"
        }
        if (-not $machinePath -and -not $userPath) {
            Write-ColorOutput "   ⚠️  No Windows PATH variables found" "Yellow"
        }
    } catch {
        Write-ColorOutput "   ❌ Error accessing Windows environment variables: $($_.Exception.Message)" "Red"
    }
} else {
    Write-ColorOutput "   ✅ Unix environment (using shell PATH)" "Green"
}

# Test 7: Join-Path Cross-Platform
Write-ColorOutput "`n7️⃣ Testing Path Joining..." "Cyan"
try {
    $testJoinPath = Join-Path $PSScriptRoot ".." "src" "frontend"
    Write-ColorOutput "   ✅ Join-Path works: $testJoinPath" "Green"
} catch {
    Write-ColorOutput "   ❌ Join-Path failed: $($_.Exception.Message)" "Red"
}

Write-ColorOutput "`n🎉 Cross-Platform Compatibility Test Complete!" "Green"

if ($Verbose) {
    Write-ColorOutput "`n📊 Detailed Environment Information:" "Cyan"
    Write-ColorOutput "   Platform: $([System.Environment]::OSVersion.Platform)" "Gray"
    Write-ColorOutput "   OS Description: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)" "Gray"
    Write-ColorOutput "   Process Architecture: $([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)" "Gray"
    Write-ColorOutput "   PowerShell Edition: $($PSVersionTable.PSEdition)" "Gray"
    Write-ColorOutput "   PowerShell Version: $($PSVersionTable.PSVersion)" "Gray"
    Write-ColorOutput "   .NET Version: $([System.Environment]::Version)" "Gray"
}
