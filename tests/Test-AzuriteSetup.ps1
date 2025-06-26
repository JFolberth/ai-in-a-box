#!/usr/bin/env pwsh
<#
.SYNOPSIS
Verify Azurite local Azure Storage emulator setup and configuration

.DESCRIPTION
This script validates that Azurite is properly installed and configured for local Azure Function development.
It checks Azurite installation, running services, local.settings.json configuration, and required folder structure.
Azurite emulates Azure Storage services (Blob, Queue, Table) locally for development and testing.

.EXAMPLE
./Test-AzuriteSetup.ps1

.EXAMPLE 
& "./Test-AzuriteSetup.ps1"

.EXAMPLE
& "/home/runner/work/ai-in-a-box/ai-in-a-box/tests/Test-AzuriteSetup.ps1"

.NOTES
Prerequisites:
- Node.js and npm installed
- Azurite package installed globally (npm install -g azurite)
- PowerShell 7+ or Windows PowerShell 5.1
- Azurite should be running for complete validation

Expected Output:
- Azurite installation status
- Service status for Blob (port 10000), Queue (port 10001), and Table (port 10002) services
- local.settings.json configuration validation
- .azurite folder existence check

To install Azurite: npm install -g azurite
To start Azurite: azurite --location .azurite --debug .azurite\debug.log
Configure local.settings.json with: "AzureWebJobsStorage": "UseDevelopmentStorage=true"
#>

# Test-AzuriteSetup.ps1
# A script to verify Azurite is installed and configured correctly

Write-Host "🔍 Testing Azurite Setup..." -ForegroundColor Cyan

# Check Azurite installation
try {
    $azuriteVersion = npm list -g azurite
    Write-Host "✅ Azurite is installed: $azuriteVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azurite is not installed. Run: npm install -g azurite" -ForegroundColor Red
    return
}

# Check if Azurite is running
$blobPort = 10000
$queuePort = 10001
$tablePort = 10002

$ports = @($blobPort, $queuePort, $tablePort)
$services = @("Blob", "Queue", "Table")

for ($i = 0; $i -lt $ports.Length; $i++) {
    $port = $ports[$i]
    $service = $services[$i]
    $test = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Host "✅ Azurite $service Service is running on port $port" -ForegroundColor Green
    } else {
        Write-Host "❌ Azurite $service Service is not running on port $port" -ForegroundColor Red
    }
}

# Check local.settings.json configuration
$settingsPath = "..\src\backend\local.settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
    if ($settings.Values.AzureWebJobsStorage -eq "UseDevelopmentStorage=true") {
        Write-Host "✅ local.settings.json is configured for Azurite" -ForegroundColor Green
    } else {
        Write-Host "❌ local.settings.json is not configured for Azurite" -ForegroundColor Red
        Write-Host "   Set AzureWebJobsStorage to: 'UseDevelopmentStorage=true'" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ local.settings.json not found" -ForegroundColor Red
}

# Check .azurite folder
if (Test-Path "..\.azurite") {
    Write-Host "✅ .azurite folder exists" -ForegroundColor Green
} else {
    Write-Host "❌ .azurite folder not found" -ForegroundColor Red
    Write-Host "   Create it with: mkdir .azurite" -ForegroundColor Yellow
}
