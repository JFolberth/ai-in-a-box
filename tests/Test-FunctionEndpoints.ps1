# Test-FunctionEndpoints.ps1
# Tests Function App endpoints with sample requests

param(
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "http://localhost:7071",
    
    [Parameter(Mandatory=$false)]
    [switch]$HealthOnly,           # Test only health endpoint
    
    [Parameter(Mandatory=$false)]
    [switch]$AiFoundryOnly,        # Test only AI Foundry integration  
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipChat,             # Skip chat endpoint tests
    
    [Parameter(Mandatory=$false)]
    [switch]$Comprehensive         # Run all tests including threading
)

$functionUrl = $BaseUrl.TrimEnd('/')

Write-Host "🔍 Testing Function App Endpoints..." -ForegroundColor Cyan
Write-Host "🎯 Target URL: $functionUrl" -ForegroundColor Gray

# Determine test mode
if ($HealthOnly) {
    Write-Host "🏥 Running HEALTH-ONLY tests" -ForegroundColor Yellow
} elseif ($AiFoundryOnly) {
    Write-Host "🤖 Running AI FOUNDRY-ONLY tests" -ForegroundColor Yellow
} elseif ($SkipChat) {
    Write-Host "⏭️ Running tests WITHOUT chat endpoints" -ForegroundColor Yellow
} elseif ($Comprehensive) {
    Write-Host "🔍 Running COMPREHENSIVE tests (all features)" -ForegroundColor Yellow
} else {
    Write-Host "📋 Running STANDARD test suite" -ForegroundColor Yellow
}

# Function to test health endpoint
function Test-HealthEndpoint {
    param([string]$baseUrl)
    
    $healthUrl = "$baseUrl/api/health"
    Write-Host "`n🏥 Testing Health Endpoint: $healthUrl" -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30
        
        Write-Host "✅ Health Status: $($response.Status)" -ForegroundColor Green
        Write-Host "🕒 Timestamp: $($response.Timestamp)" -ForegroundColor Gray
        Write-Host "📋 Version: $($response.Version)" -ForegroundColor Gray
        Write-Host "🌍 Environment: $($response.Environment)" -ForegroundColor Gray
        Write-Host "🤖 Agent: $($response.AgentName) ($($response.AgentId))" -ForegroundColor Gray
        Write-Host "🔗 AI Foundry: $($response.ConnectionStatus)" -ForegroundColor $(if ($response.ConnectionStatus -like "*Connected*") { "Green" } else { "Yellow" })
        
        if ($response.Details) {
            Write-Host "🔐 Managed Identity: $($response.Details.ManagedIdentity)" -ForegroundColor Gray
            Write-Host "🔑 AI Foundry Access: $($response.Details.AiFoundryAccess)" -ForegroundColor Gray
        }
        
        return $response
    } catch {
        Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to test AI Foundry integration
function Test-AiFoundryIntegration {
    param([string]$baseUrl)
    
    Write-Host "`n🤖 Testing AI Foundry Integration..." -ForegroundColor Magenta
    
    # First test health to check AI Foundry connection
    $healthResult = Test-HealthEndpoint $baseUrl
    if (-not $healthResult) {
        Write-Host "❌ Cannot test AI Foundry integration - health check failed" -ForegroundColor Red
        return $false
    }
    
    if ($healthResult.ConnectionStatus -notlike "*Connected*") {
        Write-Host "⚠️ AI Foundry connection not established - skipping integration test" -ForegroundColor Yellow
        return $false
    }
    
    # Test actual AI chat functionality with a simple message
    Write-Host "🧪 Testing AI chat functionality..." -ForegroundColor Cyan
    
    $chatEndpoint = "$baseUrl/api/chat"
    $testMessage = "Hello, this is a connectivity test."
    
    $chatBody = @{
        Message = $testMessage
        ThreadId = $null
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod `
            -Uri $chatEndpoint `
            -Method Post `
            -Body $chatBody `
            -ContentType "application/json" `
            -TimeoutSec 60 `
            -Headers @{
                "Origin" = "http://localhost:3000"
            }
        
        if ($response -and $response.Message -and $response.Message.Length -gt 0) {
            Write-Host "✅ AI Integration Test Successful" -ForegroundColor Green
            Write-Host "📝 Response Length: $($response.Message.Length) characters" -ForegroundColor Gray
            Write-Host "🧵 Thread ID: $($response.ThreadId)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "❌ AI Integration Test Failed - Empty response" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ AI Integration Test Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test chat endpoint with different message types
$chatEndpoint = "$functionUrl/api/chat"
$messageTypes = @(
    "What are my survival rates?",
    "What treatment options are available?"
)

# Function to test a chat message
function Test-ChatMessage {
    param([string]$message)
    
    Write-Host "`n📤 Testing POST /api/chat with message: $message" -ForegroundColor Yellow
    
    $chatBody = @{
        Message = $message
        ThreadId = $null  # For new thread
    } | ConvertTo-Json

    Write-Host "URL: $chatEndpoint"
    Write-Host "Request Body:"
    Write-Host $chatBody

    try {
        $response = Invoke-RestMethod `
            -Uri $chatEndpoint `
            -Method Post `
            -Body $chatBody `
            -ContentType "application/json" `
            -Headers @{
                "Origin" = "http://localhost:3000"  # Simulating frontend origin
            }

        Write-Host "`n📥 Response:" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "`n❌ Error:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        
        if ($_.ErrorDetails) {
            Write-Host "`nError Details:"
            Write-Host $_.ErrorDetails.Message
        }
    }
}

# Main execution logic based on test mode
$testResults = @{
    HealthPassed = $false
    AiFoundryPassed = $false
    ChatPassed = $false
    ThreadingPassed = $false
    CreateThreadPassed = $false
}

# Execute tests based on mode
if ($HealthOnly) {
    Write-Host "`n=== HEALTH ENDPOINT TESTING ===" -ForegroundColor Cyan
    $healthResult = Test-HealthEndpoint $functionUrl
    $testResults.HealthPassed = ($healthResult -ne $null)
    
} elseif ($AiFoundryOnly) {
    Write-Host "`n=== AI FOUNDRY INTEGRATION TESTING ===" -ForegroundColor Cyan
    $testResults.AiFoundryPassed = Test-AiFoundryIntegration $functionUrl
    
} else {
    # Standard, comprehensive, or skip-chat modes
    
    # Always start with health check (unless specifically skipped)
    Write-Host "`n=== HEALTH ENDPOINT TESTING ===" -ForegroundColor Cyan
    $healthResult = Test-HealthEndpoint $functionUrl
    $testResults.HealthPassed = ($healthResult -ne $null)
    
    # Test createThread endpoint
    Write-Host "`n=== CREATE THREAD TESTING ===" -ForegroundColor Cyan
    $createThreadEndpoint = "$functionUrl/api/createThread"
    Write-Host "📤 Testing POST /api/createThread..." -ForegroundColor Yellow
    Write-Host "URL: $createThreadEndpoint"
    
    try {
        $response = Invoke-RestMethod `
            -Uri $createThreadEndpoint `
            -Method Post `
            -ContentType "application/json" `
            -Headers @{
                "Origin" = "http://localhost:3000"
            }
        
        Write-Host "📥 Response:" -ForegroundColor Green
        $response | ConvertTo-Json
        $testResults.CreateThreadPassed = $true
    } catch {
        Write-Host "❌ Error:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        
        if ($_.ErrorDetails) {
            Write-Host "Error Details:"
            Write-Host $_.ErrorDetails.Message
        }
        $testResults.CreateThreadPassed = $false
    }
    
    # Chat endpoint tests (unless skipped)
    if (-not $SkipChat) {
        Write-Host "`n=== CHAT ENDPOINT TESTING ===" -ForegroundColor Cyan
        
        $chatSuccess = $true
        foreach ($message in $messageTypes) {
            try {
                Test-ChatMessage -message $message
                Start-Sleep -Seconds 2
            } catch {
                $chatSuccess = $false
                Write-Host "❌ Chat test failed for message: $message" -ForegroundColor Red
            }
        }
        $testResults.ChatPassed = $chatSuccess
        
        # Threading tests (comprehensive mode only)
        if ($Comprehensive) {
            Write-Host "`n=== CONVERSATION THREADING TESTING ===" -ForegroundColor Cyan
            
            $conversationMessages = @(
                "Hello, I'm new to cancer treatment.",
                "What should I know about chemotherapy?",
                "Are there any dietary recommendations?",
                "Thank you for the information."
            )
            
            $threadId = $null
            $threadingSuccess = $true
            
            foreach ($message in $conversationMessages) {
                Write-Host "`n📤 Testing conversation message: $message" -ForegroundColor Yellow
                if ($threadId) {
                    Write-Host "🔗 Using existing thread: $threadId" -ForegroundColor Gray
                } else {
                    Write-Host "🆕 Creating new thread" -ForegroundColor Gray
                }
                
                $chatBody = @{
                    Message = $message
                    ThreadId = $threadId
                } | ConvertTo-Json
            
                Write-Host "URL: $chatEndpoint"
                
                try {
                    $response = Invoke-RestMethod `
                        -Uri $chatEndpoint `
                        -Method Post `
                        -Body $chatBody `
                        -ContentType "application/json" `
                        -Headers @{
                            "Origin" = "http://localhost:3000"
                        }
            
                    Write-Host "📥 Response (Thread: $($response.ThreadId)):" -ForegroundColor Green
                    Write-Host "Message Preview: $($response.Message.Substring(0, [Math]::Min(100, $response.Message.Length)))..." -ForegroundColor White
                    
                    $threadId = $response.ThreadId
                    
                } catch {
                    Write-Host "❌ Error:" -ForegroundColor Red
                    Write-Host $_.Exception.Message
                    $threadingSuccess = $false
                    break
                }
                
                Start-Sleep -Seconds 3
            }
            $testResults.ThreadingPassed = $threadingSuccess
        }
    }
}

# Test summary and exit codes
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎯 TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$allPassed = $true
$exitCode = 0

if ($HealthOnly) {
    if ($testResults.HealthPassed) {
        Write-Host "✅ Health Endpoint: PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ Health Endpoint: FAILED" -ForegroundColor Red
        $allPassed = $false
        $exitCode = 1
    }
} elseif ($AiFoundryOnly) {
    if ($testResults.AiFoundryPassed) {
        Write-Host "✅ AI Foundry Integration: PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ AI Foundry Integration: FAILED" -ForegroundColor Red
        $allPassed = $false
        $exitCode = 2
    }
} else {
    # Standard/comprehensive mode results
    if ($testResults.HealthPassed) {
        Write-Host "✅ Health Endpoint: PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ Health Endpoint: FAILED" -ForegroundColor Red
        $allPassed = $false
        if ($exitCode -eq 0) { $exitCode = 1 }
    }
    
    if ($testResults.CreateThreadPassed) {
        Write-Host "✅ Create Thread: PASSED" -ForegroundColor Green
    } else {
        Write-Host "❌ Create Thread: FAILED" -ForegroundColor Red
        $allPassed = $false
        if ($exitCode -eq 0) { $exitCode = 1 }
    }
    
    if (-not $SkipChat) {
        if ($testResults.ChatPassed) {
            Write-Host "✅ Chat Functionality: PASSED" -ForegroundColor Green
        } else {
            Write-Host "❌ Chat Functionality: FAILED" -ForegroundColor Red
            $allPassed = $false
            if ($exitCode -eq 0) { $exitCode = 3 }
        }
        
        if ($Comprehensive) {
            if ($testResults.ThreadingPassed) {
                Write-Host "✅ Threading Tests: PASSED" -ForegroundColor Green
            } else {
                Write-Host "❌ Threading Tests: FAILED" -ForegroundColor Red
                $allPassed = $false
                if ($exitCode -eq 0) { $exitCode = 4 }
            }
        }
    }
}

Write-Host "="*60 -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "💥 SOME TESTS FAILED!" -ForegroundColor Red
}

Write-Host "🔢 Exit Code: $exitCode" -ForegroundColor Gray
Write-Host "📋 Exit Code Legend:" -ForegroundColor Gray
Write-Host "   0 = All tests passed" -ForegroundColor Gray
Write-Host "   1 = Health endpoint failed" -ForegroundColor Gray
Write-Host "   2 = AI Foundry connection failed" -ForegroundColor Gray
Write-Host "   3 = Chat functionality failed" -ForegroundColor Gray
Write-Host "   4 = Threading tests failed" -ForegroundColor Gray

exit $exitCode
