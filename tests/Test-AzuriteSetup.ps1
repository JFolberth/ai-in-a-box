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
