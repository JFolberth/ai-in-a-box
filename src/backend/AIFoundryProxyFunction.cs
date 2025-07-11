using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Azure.AI.Agents.Persistent;
using Azure.Identity;

namespace AIFoundryProxy
{    /// <summary>
    /// Azure Function that acts as a proxy to Azure AI Foundry, enabling browser-based applications
    /// to securely connect to Azure AI Foundry agents using managed identity authentication.
    /// 
    /// See: https://learn.microsoft.com/en-us/azure/azure-functions/ for Azure Functions documentation
    /// See: https://learn.microsoft.com/en-us/azure/ai-foundry/ for Azure AI Foundry documentation
    /// See: https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/ for Managed Identity documentation
    /// 
    /// Architecture Decision: Agent ID and Name are kept as application configuration
    /// rather than infrastructure parameters for better separation of concerns.
    /// The Azure AI Foundry workspace endpoint is automatically retrieved from infrastructure.
    /// </summary>
    public class AIFoundryProxyFunction
    {
        private readonly ILogger _logger;
        private readonly string _projectEndpoint;
        private readonly string _agentId;
        private readonly string _agentName;
        private PersistentAgentsClient? _agentsClient;        public AIFoundryProxyFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<AIFoundryProxyFunction>();
            
            // Get environment variables for Azure AI Foundry connection
            _projectEndpoint = Environment.GetEnvironmentVariable("AI_FOUNDRY_ENDPOINT") 
                ?? "https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject";
            
            // Agent configuration - can be hardcoded since it's application-specific
            // These could also be moved to app configuration or Azure Key Vault for flexibility
            _agentId = Environment.GetEnvironmentVariable("AI_FOUNDRY_AGENT_ID") 
                ?? "asst_dH7M0nbmdRblhSQO8nIGIYF4"; // Default AI in A Box agent
            _agentName = Environment.GetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME") 
                ?? "AI in A Box"; // Default agent name
            
            var workspaceName = Environment.GetEnvironmentVariable("AI_FOUNDRY_WORKSPACE_NAME") ?? "Unknown";
          
            _logger.LogInformation($"🔗 Azure AI Foundry Connection Details:");
            _logger.LogInformation($"   📍 Project Endpoint: {_projectEndpoint}");
            _logger.LogInformation($"   🏢 Workspace: {workspaceName}");
            _logger.LogInformation($"   🤖 Agent: {_agentName} ({_agentId})");
            
            // Don't initialize the AI client in constructor - do it lazily on first use
            _agentsClient = null;
            
            _logger.LogInformation("🚀 Azure AI Foundry proxy function initialized - AI client will be created on first request");
        }

        /// <summary>
        /// HTTP trigger function that handles AI Foundry chat requests.
        /// Supports CORS for browser-based applications.
        /// </summary>
        [Function("chat")]
        public async Task<HttpResponseData> RunChatAsync(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", "options")] HttpRequestData req)
        {
            _logger.LogInformation($"AI Foundry chat request received from {req.Url}");

            // Handle CORS preflight requests
            if (req.Method == "OPTIONS")
            {
                var corsResponse = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(corsResponse);
                return corsResponse;
            }

            try
            {
                // Parse the request body
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                var chatRequest = JsonSerializer.Deserialize<ChatRequest>(requestBody);

                if (chatRequest == null || string.IsNullOrEmpty(chatRequest.Message))
                {
                    var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
                    AddCorsHeaders(badRequest);
                    badRequest.Headers.Add("Content-Type", "application/json");
                    
                    await badRequest.WriteStringAsync(JsonSerializer.Serialize(new ChatResponse 
                    {
                        Error = "Message is required",
                        AgentName = _agentName,
                        Timestamp = DateTime.UtcNow
                    }));
                    
                    return badRequest;
                }

                _logger.LogInformation($"Processing message: {chatRequest.Message}");

                // Process the message
                var responseMessage = await ProcessMessageAsync(chatRequest.Message, chatRequest.ThreadId);

                // Generate a thread ID if this is a new conversation
                var threadId = chatRequest.ThreadId ?? Guid.NewGuid().ToString();

                var response = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(response);
                response.Headers.Add("Content-Type", "application/json");
                
                await response.WriteStringAsync(JsonSerializer.Serialize(new ChatResponse 
                {
                    ThreadId = threadId,
                    Message = responseMessage,
                    AgentName = _agentName,
                    Timestamp = DateTime.UtcNow
                }));
                
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing chat request");
                
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                AddCorsHeaders(errorResponse);
                errorResponse.Headers.Add("Content-Type", "application/json");
                
                await errorResponse.WriteStringAsync(JsonSerializer.Serialize(new ChatResponse 
                {
                    Error = "An error occurred processing your request",
                    AgentName = _agentName,
                    Timestamp = DateTime.UtcNow
                }));
                
                return errorResponse;
            }
        }

        /// <summary>
        /// Health check endpoint for monitoring Function App status and AI Foundry connectivity.
        /// Returns comprehensive health information including AI Foundry connection status.
        /// </summary>
        [Function("health")]
        public async Task<HttpResponseData> HealthAsync(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "options")] HttpRequestData req)
        {
            _logger.LogInformation("Health check request received");

            // Handle CORS preflight requests
            if (req.Method == "OPTIONS")
            {
                var corsResponse = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(corsResponse);
                return corsResponse;
            }

            try
            {
                var healthCheck = new
                {
                    Status = "Healthy",
                    Timestamp = DateTime.UtcNow,
                    Version = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "Unknown",
                    Environment = Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT") ?? "Unknown",
                    AiFoundryEndpoint = _projectEndpoint,
                    AgentName = _agentName,
                    AgentId = _agentId,
                    ConnectionStatus = await CheckAiFoundryConnectionAsync(),
                    Details = new
                    {
                        ManagedIdentity = CheckManagedIdentityStatus(),
                        AiFoundryAccess = await CheckAiFoundryAccessAsync(),
                        LastHealthCheck = DateTime.UtcNow
                    }
                };

                var response = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(response);
                response.Headers.Add("Content-Type", "application/json");
                
                await response.WriteStringAsync(JsonSerializer.Serialize(healthCheck, new JsonSerializerOptions 
                { 
                    WriteIndented = true 
                }));
                
                _logger.LogInformation("Health check completed successfully");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during health check");
                
                var errorHealthCheck = new
                {
                    Status = "Unhealthy",
                    Timestamp = DateTime.UtcNow,
                    Error = "Health check failed",
                    Details = new
                    {
                        Exception = ex.GetType().Name,
                        Message = ex.Message
                    }
                };

                var errorResponse = req.CreateResponse(HttpStatusCode.ServiceUnavailable);
                AddCorsHeaders(errorResponse);
                errorResponse.Headers.Add("Content-Type", "application/json");
                
                await errorResponse.WriteStringAsync(JsonSerializer.Serialize(errorHealthCheck, new JsonSerializerOptions 
                { 
                    WriteIndented = true 
                }));
                
                return errorResponse;
            }
        }

        /// <summary>
        /// HTTP trigger function to create a new thread for conversation context.
        /// </summary>
        [Function("createThread")]
        public async Task<HttpResponseData> CreateThreadAsync(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", "options")] HttpRequestData req)
        {
            _logger.LogInformation("Create thread request received");

            // Handle CORS preflight requests
            if (req.Method == "OPTIONS")
            {
                var corsResponse = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(corsResponse);
                return corsResponse;
            }

            try
            {
                // Try to initialize AI Foundry client
                var agentsClient = await InitializeAgentsClientAsync();
                
                string threadId;
                if (agentsClient != null)
                {
                    // Create real thread using AI Foundry
                    var thread = await agentsClient.Threads.CreateThreadAsync();
                    threadId = thread.Value.Id;
                    _logger.LogInformation($"✅ Created real AI Foundry thread: {threadId}");
                }
                else
                {
                    // Fallback to simulation mode
                    threadId = Guid.NewGuid().ToString();
                    _logger.LogInformation($"🎭 Created simulation thread: {threadId}");
                }
                
                var response = req.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(response);
                response.Headers.Add("Content-Type", "application/json");
                
                await response.WriteStringAsync(JsonSerializer.Serialize(new { ThreadId = threadId }));
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating thread");
                
                var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
                AddCorsHeaders(errorResponse);
                errorResponse.Headers.Add("Content-Type", "application/json");
                
                await errorResponse.WriteStringAsync(JsonSerializer.Serialize(new { error = "Failed to create thread" }));
                return errorResponse;
            }
        }

        /// <summary>
        /// Processes a chat message and returns a response.
        /// Uses real AI Foundry when available, falls back to simulation for development.
        /// </summary>
        private async Task<string> ProcessMessageAsync(string message, string? threadId = null)
        {
            try
            {
                _logger.LogInformation($"🔄 Processing message: {message} (Thread: {threadId ?? "new"})");
                
                // Try to initialize AI Foundry client if not already done
                var agentsClient = await InitializeAgentsClientAsync();
                
                if (agentsClient != null)
                {
                    // Use real AI Foundry integration
                    _logger.LogInformation("🚀 Using AI Foundry integration");
                    return await ProcessWithAIFoundryAsync(agentsClient, message, threadId);
                }
                else
                {
                    // Fall back to simulation mode
                    _logger.LogInformation("🎭 Using simulation mode (AI Foundry client not available)");
                    return await ProcessWithSimulationAsync(message, threadId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Error processing message");
                return "I'm having technical difficulties. Please try again later.";
            }
        }

        /// <summary>
        /// Processes message using real AI Foundry API with the new SDK.
        /// </summary>
        private async Task<string> ProcessWithAIFoundryAsync(PersistentAgentsClient agentsClient, string message, string? threadId)
        {
            const int maxRetries = 3;
            const int baseDelayMs = 1000;
            
            for (int attempt = 1; attempt <= maxRetries; attempt++)
            {
                try
                {
                    _logger.LogInformation($"🔗 AI Foundry attempt {attempt}/{maxRetries}");
                    
                    // Create or get thread
                    PersistentAgentThread thread;
                    if (!string.IsNullOrEmpty(threadId))
                    {
                        try
                        {
                            var existingThread = await agentsClient.Threads.GetThreadAsync(threadId);
                            thread = existingThread.Value;
                            _logger.LogInformation($"📋 Retrieved existing thread: {threadId}");
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, $"⚠️ Failed to retrieve thread {threadId}, creating new one");
                            var newThread = await agentsClient.Threads.CreateThreadAsync();
                            thread = newThread.Value;
                            _logger.LogInformation($"📋 Created new thread: {thread.Id}");
                        }
                    }
                    else
                    {
                        var newThread = await agentsClient.Threads.CreateThreadAsync();
                        thread = newThread.Value;
                        _logger.LogInformation($"📋 Created new thread: {thread.Id}");
                    }
                      // Add user message to thread  
                    await agentsClient.Messages.CreateMessageAsync(thread.Id, "user", message);
                    _logger.LogInformation($"💬 Added user message to thread");
                    
                    // Create and run the agent
                    var run = await agentsClient.Runs.CreateRunAsync(thread.Id, _agentId);                    _logger.LogInformation($"Started run: {run.Value.Id}");
                    
                    // Poll for completion with timeout
                    var runStatus = run.Value;
                    var pollCount = 0;
                    const int maxPolls = 240; // 2 minutes max (240 * 500ms = 120 seconds)
                    var startTime = DateTime.UtcNow;
                    string previousStatus = runStatus.Status.ToString();
                    
                    // Use case-insensitive status comparison and check for running states
                    while (IsRunningStatus(runStatus.Status.ToString()) && pollCount < maxPolls)
                    {
                        await Task.Delay(500);
                        var runUpdate = await agentsClient.Runs.GetRunAsync(thread.Id, runStatus.Id);
                        runStatus = runUpdate.Value;
                        pollCount++;
                        
                        var elapsed = DateTime.UtcNow - startTime;
                          // Log status changes only
                        var currentStatus = runStatus.Status.ToString();
                        if (pollCount == 1 || (pollCount > 1 && currentStatus != previousStatus))
                        {
                            _logger.LogInformation($"🔄 Status change: {currentStatus} at {elapsed.TotalSeconds:F1}s");
                            previousStatus = currentStatus;
                        }
                    }
                    
                    var totalElapsed = DateTime.UtcNow - startTime;
                    _logger.LogInformation($"📈 Polling completed after {pollCount} polls in {totalElapsed.TotalSeconds:F1}s. Final status: {runStatus.Status}");
                      if (runStatus.Status.ToString().Equals("Completed", StringComparison.OrdinalIgnoreCase))
                    {
                        _logger.LogInformation($"✅ Run completed successfully in {totalElapsed.TotalSeconds:F1}s");
                          // Get the messages from the thread (most recent first)
                        _logger.LogInformation($"📨 Retrieving messages from thread {thread.Id}");
                        var messages = agentsClient.Messages.GetMessages(thread.Id);
                        var messageCount = messages.Count();
                        _logger.LogInformation($"📨 Found {messageCount} total messages in thread");
                        
                        // Find the latest assistant message that was created after this run started
                        var runStartTime = run.Value.CreatedAt;
                        _logger.LogInformation($"🕒 Looking for assistant messages created after run start time: {runStartTime:HH:mm:ss}");
                        
                        var assistantMessageFound = false;
                        var messageIndex = 0;
                        foreach (var msg in messages.OrderByDescending(m => m.CreatedAt)) // Get newest messages first
                        {
                            messageIndex++;
                            _logger.LogInformation($"📝 Message {messageIndex}: Role={msg.Role}, CreatedAt={msg.CreatedAt:HH:mm:ss}");
                            
                            if (msg.Role.ToString().Equals("assistant", StringComparison.OrdinalIgnoreCase) && msg.CreatedAt >= runStartTime)
                            {
                                assistantMessageFound = true;
                                _logger.LogInformation($"🤖 Found NEW assistant message created at {msg.CreatedAt:HH:mm:ss} (after run start {runStartTime:HH:mm:ss})");
                                _logger.LogInformation($"🤖 Message has {msg.ContentItems.Count} content items");
                                  // Get the text content from the message
                                var contentIndex = 0;
                                foreach (var content in msg.ContentItems)
                                {
                                    contentIndex++;
                                    _logger.LogInformation($"📄 Content item {contentIndex}: Type={content.GetType().Name}");
                                    
                                    // Handle different content types from Azure.AI.Agents.Persistent
                                    string? responseText = null;
                                    
                                    if (content is Azure.AI.Agents.Persistent.MessageTextContent textContent)
                                    {
                                        responseText = textContent.Text;
                                        _logger.LogInformation($"� Found text content: {responseText?.Length ?? 0} characters");
                                    }
                                    else
                                    {
                                        // Fallback to toString for other content types
                                        responseText = content.ToString();
                                        _logger.LogInformation($"📝 Using ToString fallback: {responseText?.Length ?? 0} characters");
                                    }
                                    
                                    if (!string.IsNullOrEmpty(responseText) && responseText != content.GetType().Name)
                                    {
                                        var preview = responseText.Length > 100 ? responseText[..100] + "..." : responseText;
                                        _logger.LogInformation($"🎯 Returning AI response (length: {responseText.Length}): {preview}");
                                        return responseText;
                                    }
                                }
                                _logger.LogWarning($"⚠️ Assistant message found but no valid text content");
                            }
                        }
                        
                        if (!assistantMessageFound)
                        {
                            _logger.LogWarning($"⚠️ No assistant message found in {messageCount} messages after successful run");
                        }
                        
                        return "I processed your request but didn't generate a response. Please try again.";
                    }                    else if (runStatus.Status.ToString().Equals("Failed", StringComparison.OrdinalIgnoreCase))
                    {
                        _logger.LogError($"❌ Run failed after {totalElapsed.TotalSeconds:F1}s with status: {runStatus.Status}");
                        if (runStatus.LastError != null)
                        {
                            _logger.LogError($"❌ Error details: Code={runStatus.LastError.Code}, Message={runStatus.LastError.Message}");
                        }
                        else
                        {
                            _logger.LogError($"❌ No error details provided for failed run");
                        }
                        
                        if (attempt < maxRetries)
                        {
                            var delay = baseDelayMs * (int)Math.Pow(2, attempt - 1);
                            _logger.LogInformation($"🔄 Retrying failed run in {delay}ms (attempt {attempt + 1}/{maxRetries})...");
                            await Task.Delay(delay);
                            continue;
                        }
                        
                        return "I encountered an error processing your request. Please try again.";
                    }
                    else
                    {
                        var timeoutReason = pollCount >= maxPolls ? "timeout" : "unexpected status";
                        _logger.LogWarning($"⚠️ Run ended due to {timeoutReason} after {totalElapsed.TotalSeconds:F1}s. Status: {runStatus.Status}, Polls: {pollCount}/{maxPolls}");
                        
                        // Log additional context for timeouts
                        if (pollCount >= maxPolls)
                        {
                            _logger.LogWarning($"⏰ Timeout details: Ran for full {maxPolls * 0.5}s, final status was '{runStatus.Status}'");
                            if (runStatus.LastError != null)
                            {
                                _logger.LogWarning($"⏰ Last error before timeout: {runStatus.LastError.Message}");
                            }
                        }
                        
                        if (attempt < maxRetries)
                        {
                            var delay = baseDelayMs * (int)Math.Pow(2, attempt - 1);
                            _logger.LogInformation($"🔄 Retrying {timeoutReason} in {delay}ms (attempt {attempt + 1}/{maxRetries})...");
                            await Task.Delay(delay);
                            continue;
                        }
                        
                        return pollCount >= maxPolls 
                            ? "Your request is taking longer than expected. The AI service may be busy. Please try again."
                            : "I encountered an unexpected issue. Please try again.";
                    }                }
                catch (Exception ex)
                {
                    var elapsed = DateTime.UtcNow - DateTime.UtcNow; // This will be overridden if we had a startTime
                    _logger.LogError(ex, $"❌ AI Foundry API error (attempt {attempt}/{maxRetries}) after {elapsed.TotalSeconds:F1}s: {ex.GetType().Name}: {ex.Message}");
                    
                    // Log additional context for specific exception types
                    if (ex is HttpRequestException httpEx)
                    {
                        _logger.LogError($"🌐 HTTP Error Details: {httpEx.Message}");
                    }
                    else if (ex is TaskCanceledException timeoutEx)
                    {
                        _logger.LogError($"⏰ Timeout Error Details: {timeoutEx.Message}");
                    }
                    else if (ex is UnauthorizedAccessException authEx)
                    {
                        _logger.LogError($"🔐 Authentication Error Details: {authEx.Message}");
                    }
                    
                    // Log inner exception if present
                    if (ex.InnerException != null)
                    {
                        _logger.LogError($"🔍 Inner Exception: {ex.InnerException.GetType().Name}: {ex.InnerException.Message}");
                    }
                    
                    if (attempt < maxRetries)
                    {
                        var delay = baseDelayMs * (int)Math.Pow(2, attempt - 1);
                        _logger.LogInformation($"🔄 Retrying after exception in {delay}ms (attempt {attempt + 1}/{maxRetries})...");
                        await Task.Delay(delay);
                        continue;
                    }
                    
                    throw;
                }
            }
            
            return "I'm having difficulty connecting to the AI service. Please try again later.";
        }

        /// <summary>
        /// Enhanced version with step-by-step debugging
        /// </summary>
        private async Task<string> ProcessWithAIFoundryAsync(string message, string? threadId = null)
        {
            var stepNumber = 1;
            _logger.LogInformation($"🔍 STEP {stepNumber++}: Starting ProcessWithAIFoundryAsync");
            _logger.LogInformation($"   📝 Message: '{message}'");
            _logger.LogInformation($"   🧵 ThreadId: '{threadId ?? "null"}'");
            
            try
            {
                var agentsClient = await InitializeAgentsClientAsync();
                if (agentsClient == null)
                {
                    _logger.LogWarning($"❌ STEP {stepNumber}: AgentsClient initialization failed");
                    throw new InvalidOperationException("Failed to initialize AI Foundry client");
                }
                _logger.LogInformation($"✅ STEP {stepNumber++}: AgentsClient initialized successfully");

                // Get or create thread with detailed logging
                PersistentAgentThread thread;
                if (!string.IsNullOrEmpty(threadId))
                {
                    _logger.LogInformation($"🔍 STEP {stepNumber}: Attempting to retrieve existing thread: {threadId}");
                    try
                    {
                        var existingThread = await agentsClient.Threads.GetThreadAsync(threadId);
                        thread = existingThread.Value;
                        _logger.LogInformation($"✅ STEP {stepNumber++}: Retrieved existing thread successfully");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"⚠️ STEP {stepNumber}: Failed to retrieve thread {threadId}: {ex.Message}");
                        _logger.LogInformation($"🔍 STEP {stepNumber}: Creating new thread instead");
                        var newThread = await agentsClient.Threads.CreateThreadAsync();
                        thread = newThread.Value;
                        _logger.LogInformation($"✅ STEP {stepNumber++}: Created new thread: {thread.Id}");
                    }
                }
                else
                {
                    _logger.LogInformation($"🔍 STEP {stepNumber}: Creating new thread (no threadId provided)");
                    var newThread = await agentsClient.Threads.CreateThreadAsync();
                    thread = newThread.Value;
                    _logger.LogInformation($"✅ STEP {stepNumber++}: Created new thread: {thread.Id}");
                }

                // Add message with detailed logging
                _logger.LogInformation($"🔍 STEP {stepNumber}: Adding user message to thread {thread.Id}");
                _logger.LogInformation($"   📝 Message content: '{message}'");
                var messageResponse = await agentsClient.Messages.CreateMessageAsync(thread.Id, "user", message);
                _logger.LogInformation($"✅ STEP {stepNumber++}: User message added successfully. MessageId: {messageResponse.Value.Id}");

                // Create run with detailed logging
                _logger.LogInformation($"🔍 STEP {stepNumber}: Creating run with agent {_agentId}");
                var runResponse = await agentsClient.Runs.CreateRunAsync(thread.Id, _agentId);
                var runStatus = runResponse.Value;
                _logger.LogInformation($"✅ STEP {stepNumber++}: Run created successfully. RunId: {runStatus.Id}, Initial Status: {runStatus.Status}");

                // Enhanced polling with step-by-step logging
                var pollCount = 0;
                const int maxPolls = 240; // 2 minutes
                var startTime = DateTime.UtcNow;
                
                _logger.LogInformation($"🔍 STEP {stepNumber}: Starting polling loop");                _logger.LogInformation($"   ⏱️ Max polls: {maxPolls}, Timeout: {maxPolls * 500 / 1000} seconds");
                _logger.LogInformation($"   🏃 Initial run status: {runStatus.Status}");                // Fixed polling logic - use case-insensitive comparison
                while (pollCount < maxPolls)
                {                    // Check if run is complete and handle various completion statuses
                    var runStatusText = $"{runStatus.Status}".ToLowerInvariant();
                    _logger.LogInformation($"🔍 STEP {stepNumber} (Poll {pollCount + 1}): Current status = '{runStatusText}'");
                    
                    // Check for completion statuses (positive detection)
                    if (runStatusText == "completed" || runStatusText == "failed" || 
                        runStatusText == "cancelled" || runStatusText == "canceled")
                    {
                        _logger.LogInformation($"✅ STEP {stepNumber}: Run finished with status: {runStatus.Status}");
                        break;
                    }
                      // Continue polling for running statuses - FIXED: Don't break on queued status
                    if (runStatusText == "inprogress" || runStatusText == "queued" || 
                        runStatusText == "in_progress" || runStatusText == "running")
                    {
                        // These are running states - continue polling, don't break
                        _logger.LogInformation($"⏳ Run is {runStatus.Status} - continuing to poll...");
                        // Continue to the actual polling logic below
                    }
                    else if (runStatusText == "completed" || runStatusText == "failed" || 
                             runStatusText == "cancelled" || runStatusText == "canceled")
                    {
                        _logger.LogInformation($"✅ STEP {stepNumber}: Run finished with status: {runStatus.Status}");
                        break;
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️ STEP {stepNumber}: Unknown status '{runStatus.Status}' - treating as completed");
                        break;
                    }

                    _logger.LogInformation($"🔍 STEP {stepNumber} (Poll {pollCount + 1}): About to sleep 500ms then check run status");
                    await Task.Delay(500);
                    
                    _logger.LogInformation($"🔍 STEP {stepNumber} (Poll {pollCount + 1}): Calling GetRunAsync for thread {thread.Id}, run {runStatus.Id}");
                    var runUpdate = await agentsClient.Runs.GetRunAsync(thread.Id, runStatus.Id);
                    var previousStatus = runStatus.Status.ToString();
                    runStatus = runUpdate.Value;
                    pollCount++;
                    
                    var elapsed = DateTime.UtcNow - startTime;
                    
                    _logger.LogInformation($"🔍 STEP {stepNumber} (Poll {pollCount}): GetRunAsync completed");
                    _logger.LogInformation($"   📊 Previous Status: {previousStatus}");
                    _logger.LogInformation($"   📊 Current Status: {runStatus.Status}");
                    _logger.LogInformation($"   ⏱️ Elapsed: {elapsed.TotalSeconds:F1}s");
                    
                    // Check if status changed
                    if (previousStatus != runStatus.Status.ToString())
                    {
                        _logger.LogInformation($"🔄 STATUS CHANGE DETECTED: {previousStatus} → {runStatus.Status} at {elapsed.TotalSeconds:F1}s");
                    }
                      // Break if completed - check for multiple possible status values
                    var currentStatus = runStatus.Status.ToString();
                    if (currentStatus != "InProgress" && currentStatus != "Queued" && 
                        currentStatus != "in_progress" && currentStatus != "queued")
                    {
                        _logger.LogInformation($"✅ STEP {stepNumber}: Run completed with status: {runStatus.Status}");
                        break;
                    }
                }

                stepNumber++;
                
                // Check final status
                _logger.LogInformation($"🔍 STEP {stepNumber}: Checking final run status");
                if (runStatus.Status.ToString() == "Completed")
                {
                    _logger.LogInformation($"✅ STEP {stepNumber++}: Run completed successfully, retrieving messages");
                              // Get messages with detailed logging - FIXED API call
            _logger.LogInformation($"🔍 STEP {stepNumber}: Calling GetMessages for thread {thread.Id}");
            var messages = agentsClient.Messages.GetMessages(thread.Id);
            _logger.LogInformation($"✅ STEP {stepNumber++}: GetMessages call completed");
                    
                    var messageList = messages.ToList();
                    _logger.LogInformation($"📊 STEP {stepNumber}: Retrieved {messageList.Count} messages total");
                    
                    // Find assistant response with detailed logging
                    foreach (var msg in messageList.Select((m, i) => new { Message = m, Index = i }))
                    {
                        _logger.LogInformation($"🔍 Message {msg.Index}: Role={msg.Message.Role}, CreatedAt={msg.Message.CreatedAt}");
                          if (msg.Message.Role.ToString() == "assistant")
                        {
                            _logger.LogInformation($"✅ STEP {stepNumber++}: Found assistant message");
                            var content = msg.Message.ContentItems?.FirstOrDefault();
                            if (content != null)
                            {
                                _logger.LogInformation($"📝 Content type: {content.GetType().Name}");
                                var responseText = content.ToString();
                                _logger.LogInformation($"📝 Response length: {responseText?.Length ?? 0} characters");
                                _logger.LogInformation($"✅ STEP {stepNumber}: Successfully extracted response");
                                return responseText ?? "No response content available.";
                            }
                            else
                            {
                                _logger.LogWarning($"❌ STEP {stepNumber}: Assistant message has no content");
                            }
                        }
                    }
                    
                    _logger.LogWarning($"❌ STEP {stepNumber}: No assistant response found in {messageList.Count} messages");
                    return "No assistant response found.";
                }
                else
                {
                    _logger.LogWarning($"❌ STEP {stepNumber}: Run did not complete. Final status: {runStatus.Status}");
                    return "Your request is taking longer than expected. Please try again.";
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ STEP {stepNumber}: Exception occurred: {ex.GetType().Name}");
                _logger.LogError($"❌ Error message: {ex.Message}");
                _logger.LogError($"❌ Stack trace: {ex.StackTrace}");
                throw;
            }
        }

        /// <summary>
        /// Fallback simulation for development and testing when AI Foundry is not available.
        /// </summary>
        private async Task<string> ProcessWithSimulationAsync(string message, string? threadId = null)
        {
            _logger.LogInformation("🎭 Processing with simulation mode");
            
            // Simulate processing delay
            await Task.Delay(Random.Shared.Next(500, 1500));
            
            // Generate contextual responses based on keywords
            var lowerMessage = message.ToLowerInvariant();
            
            if (lowerMessage.Contains("survival") || lowerMessage.Contains("prognosis"))
            {
                _logger.LogInformation("🎯 Generated contextual response");
                return "Cancer survival rates vary significantly depending on the type, stage, and individual factors. I'd recommend discussing your specific situation with your oncologist who can provide personalized information based on your medical history and current condition.";
            }
            
            if (lowerMessage.Contains("treatment") || lowerMessage.Contains("therapy"))
            {
                _logger.LogInformation("🎯 Generated contextual response");
                return "Cancer treatments vary by type and stage. Common approaches include surgery, chemotherapy, radiation therapy, immunotherapy, and targeted therapy. What type of treatment information are you looking for?";
            }
            
            if (lowerMessage.Contains("side effect"))
            {
                _logger.LogInformation("🎯 Generated contextual response");
                return "Cancer treatment side effects can vary depending on the type of treatment. Common side effects may include fatigue, nausea, hair loss, and changes in appetite. It's important to discuss any side effects with your healthcare team.";
            }
            
            if (lowerMessage.Contains("support") || lowerMessage.Contains("help"))
            {
                _logger.LogInformation("🎯 Generated contextual response");
                return "There are many support resources available for cancer patients including support groups, counseling services, and patient advocacy organizations. Your healthcare team can help connect you with appropriate resources.";
            }
            
            // Default response
            _logger.LogInformation("🎯 Generated contextual response");
            return $"Thank you for your question about '{message}'. As AI in A Box, I'm designed to provide helpful information. Could you provide more context so I can give you the most relevant response?";
        }

        /// <summary>
        /// Lazily initializes the AI Agents client on first use to prevent startup failures
        /// </summary>
        private async Task<PersistentAgentsClient?> InitializeAgentsClientAsync()
        {
            if (_agentsClient != null)
                return _agentsClient;

            try
            {
                _logger.LogInformation($"🔗 Initializing AI Foundry client...");
                _logger.LogInformation($"   📍 Project Endpoint: '{_projectEndpoint}'");

                // Validate the endpoint URL format
                if (!Uri.TryCreate(_projectEndpoint, UriKind.Absolute, out Uri? endpointUri))
                {
                    _logger.LogError($"❌ Invalid endpoint URL format: '{_projectEndpoint}'");
                    throw new ArgumentException($"Invalid endpoint URL format: {_projectEndpoint}");
                }

                _logger.LogInformation($"✅ Endpoint URL validation passed: {endpointUri}");

                // Initialize AI Foundry client with appropriate credential chain
                _logger.LogInformation("🔐 Creating DefaultAzureCredential...");
                var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                {
                    ManagedIdentityClientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID"),
                    ExcludeEnvironmentCredential = false,
                    ExcludeWorkloadIdentityCredential = false,
                    ExcludeManagedIdentityCredential = false,
                    ExcludeSharedTokenCacheCredential = false,
                    ExcludeAzureCliCredential = false,
                    ExcludeInteractiveBrowserCredential = false,
                    ExcludeVisualStudioCredential = false,
                    ExcludeVisualStudioCodeCredential = false
                });
                _logger.LogInformation("✅ DefaultAzureCredential created successfully");

                // Create PersistentAgentsClient using the project endpoint
                _logger.LogInformation($"🏗️ Creating PersistentAgentsClient with endpoint: '{_projectEndpoint}'");
                var client = new PersistentAgentsClient(_projectEndpoint, credential);
                _logger.LogInformation("✅ PersistentAgentsClient created successfully");
                
                // Test the connection by trying to get an agent
                _logger.LogInformation($"🧪 Testing connection by retrieving agent: '{_agentId}'");
                var testAgent = await client.Administration.GetAgentAsync(_agentId);
                _logger.LogInformation($"✅ Connection test successful! Agent found: '{testAgent.Value.Name}'");
                
                // Store successful client for future use
                _agentsClient = client;
                
                _logger.LogInformation("🚀 AI Foundry client fully initialized and tested");
                return client;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to initialize AI Foundry client: {ex.Message}");
                _logger.LogError($"❌ Exception type: {ex.GetType().Name}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ Inner exception: {ex.InnerException.Message}");
                    _logger.LogError($"❌ Inner exception type: {ex.InnerException.GetType().Name}");
                }
                _logger.LogWarning("💡 For local development, ensure you're logged in with 'az login' and have appropriate permissions");
                _logger.LogWarning("💡 Check that the AI_FOUNDRY_ENDPOINT is correctly set in local.settings.json");
                return null;
            }        }

        /// <summary>
        /// Checks AI Foundry connection status for health endpoint.
        /// </summary>
        private async Task<string> CheckAiFoundryConnectionAsync()
        {
            try
            {
                _logger.LogInformation("🔍 Health check: Testing AI Foundry connection...");
                
                var agentsClient = await InitializeAgentsClientAsync();
                if (agentsClient == null)
                {
                    _logger.LogWarning("⚠️ Health check: AI Foundry client initialization failed");
                    return "Disconnected - Client initialization failed";
                }

                // Test connection by trying to get the agent
                var testAgent = await agentsClient.Administration.GetAgentAsync(_agentId);
                if (testAgent?.Value != null)
                {
                    _logger.LogInformation($"✅ Health check: AI Foundry connection successful. Agent: {testAgent.Value.Name}");
                    return $"Connected - Agent '{testAgent.Value.Name}' accessible";
                }
                else
                {
                    _logger.LogWarning("⚠️ Health check: Agent not found");
                    return "Disconnected - Agent not found";
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ Health check: AI Foundry connection test failed");
                return $"Disconnected - {ex.GetType().Name}: {ex.Message}";
            }
        }

        /// <summary>
        /// Checks managed identity status for health endpoint.
        /// </summary>
        private string CheckManagedIdentityStatus()
        {
            try
            {
                // Check if running in Azure Functions environment with managed identity
                var msiEndpoint = Environment.GetEnvironmentVariable("MSI_ENDPOINT");
                var msiSecret = Environment.GetEnvironmentVariable("MSI_SECRET");
                var azureClientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
                
                if (!string.IsNullOrEmpty(msiEndpoint) && !string.IsNullOrEmpty(msiSecret))
                {
                    return "Active - System-assigned managed identity available";
                }
                else if (!string.IsNullOrEmpty(azureClientId))
                {
                    return "Active - User-assigned managed identity configured";
                }
                else
                {
                    // Check if running locally with Azure CLI credentials
                    var localCredentials = Environment.GetEnvironmentVariable("AZURE_TENANT_ID") ?? 
                                         Environment.GetEnvironmentVariable("AZURE_CLIENT_ID") ??
                                         Environment.GetEnvironmentVariable("USERPROFILE"); // Windows indicator for local dev
                    
                    return localCredentials != null ? "Local Development - Azure CLI credentials" : "Inactive - No identity detected";
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Error checking managed identity status");
                return $"Error - {ex.Message}";
            }
        }

        /// <summary>
        /// Checks AI Foundry access permissions for health endpoint.
        /// </summary>
        private async Task<string> CheckAiFoundryAccessAsync()
        {
            try
            {
                var agentsClient = await InitializeAgentsClientAsync();
                if (agentsClient == null)
                {
                    return "Unauthorized - Cannot initialize client";
                }

                // Test basic access by trying to list agents (minimal permission test)
                var testAgent = await agentsClient.Administration.GetAgentAsync(_agentId);
                return testAgent?.Value != null ? "Authorized - Agent access confirmed" : "Unauthorized - Agent not accessible";
            }
            catch (UnauthorizedAccessException)
            {
                return "Unauthorized - Authentication failed";
            }
            catch (Exception ex)
            {
                return $"Error - {ex.GetType().Name}: {ex.Message}";
            }
        }

        /// <summary>
        /// Helper method to determine if a run status indicates the run is still in progress.
        /// </summary>
        private static bool IsRunningStatus(string status)
        {
            if (string.IsNullOrEmpty(status))
                return false;
                
            var lowerStatus = status.ToLowerInvariant();
            return lowerStatus == "queued" || lowerStatus == "inprogress" || lowerStatus == "in_progress" || lowerStatus == "running";
        }

        /// <summary>
        /// Adds CORS headers to the response to allow browser-based requests.
        /// </summary>
        private static void AddCorsHeaders(HttpResponseData response)
        {
            response.Headers.Add("Access-Control-Allow-Origin", "*");
            response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
            response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization");
        }
    }

    /// <summary>
    /// Request model for chat messages.
    /// </summary>
    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
        public string? ThreadId { get; set; }
    }

    /// <summary>
    /// Response model for chat messages.
    /// </summary>
    public class ChatResponse
    {
        public string? ThreadId { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? Error { get; set; }
        public string AgentName { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }
}
