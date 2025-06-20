# Test-FunctionEndpoints.ps1
# Tests Function App endpoints with sample requests

param(
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "http://localhost:7071"
)

$functionUrl = $BaseUrl.TrimEnd('/')

Write-Host "🔍 Testing Function App Endpoints..." -ForegroundColor Cyan
Write-Host "🎯 Target URL: $functionUrl" -ForegroundColor Gray

# Test chat endpoint with different message types
$chatEndpoint = "$functionUrl/api/chat"
$messageTypes = @(
    "What are my survival rates?",
    "What treatment options are available?",
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

# Test each message type (separate threads)
foreach ($message in $messageTypes) {
    Test-ChatMessage -message $message
    Start-Sleep -Seconds 2  # Wait between requests
}

# Test conversation threading with multiple messages in the same thread
Write-Host "`n🧵 Testing Conversation Threading (multiple messages in same thread)..." -ForegroundColor Magenta

$conversationMessages = @(
    "Hello, I'm new to cancer treatment.",
    "What should I know about chemotherapy?",
    "Are there any dietary recommendations?",
    "Thank you for the information."
)

$threadId = $null

foreach ($message in $conversationMessages) {
    Write-Host "`n📤 Testing conversation message: $message" -ForegroundColor Yellow
    if ($threadId) {
        Write-Host "🔗 Using existing thread: $threadId" -ForegroundColor Gray
    } else {
        Write-Host "🆕 Creating new thread" -ForegroundColor Gray
    }
    
    $chatBody = @{
        Message = $message
        ThreadId = $threadId  # Use existing thread or null for new
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
        
        # Save thread ID for next message
        $threadId = $response.ThreadId
        
    } catch {
        Write-Host "❌ Error:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        break  # Stop conversation test on error
    }
    
    Start-Sleep -Seconds 3  # Wait between conversation messages
}

# Test createThread endpoint (if needed)
$createThreadEndpoint = "$functionUrl/api/createThread"

Write-Host "`n📤 Testing POST /api/createThread..." -ForegroundColor Yellow
Write-Host "URL: $createThreadEndpoint"

try {
    $response = Invoke-RestMethod `
        -Uri $createThreadEndpoint `
        -Method Post `
        -ContentType "application/json" `        -Headers @{
            "Origin" = "http://localhost:3000"  # Simulating frontend origin
        }

    Write-Host "`n📥 Response:" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "`n❌ Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.ErrorDetails) {
        Write-Host "`nError Details:"
        Write-Host $_.ErrorDetails.Message
    }
}
