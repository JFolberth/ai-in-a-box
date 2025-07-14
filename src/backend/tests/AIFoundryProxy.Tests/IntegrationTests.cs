using Xunit;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using AIFoundryProxy;
using System.Text.Json;

namespace AIFoundryProxy.Tests
{
    /// <summary>
    /// Integration tests that test the complete workflow and interaction between components.
    /// These tests validate end-to-end functionality without external dependencies.
    /// </summary>
    public class IntegrationTests
    {
        private readonly Mock<ILoggerFactory> _mockLoggerFactory;
        private readonly Mock<ILogger> _mockLogger;

        public IntegrationTests()
        {
            _mockLoggerFactory = new Mock<ILoggerFactory>();
            _mockLogger = new Mock<ILogger>();
            
            _mockLoggerFactory
                .Setup(x => x.CreateLogger(It.IsAny<string>()))
                .Returns(_mockLogger.Object);
        }

        [Fact]        public void Function_InitializationAndBasicWorkflow_CompletesSuccessfully()
        {
            // Arrange - Set up environment for testing
            Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", "https://test-ai-foundry.example.com/api/projects/test");
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", "test-agent-123");
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", "TestBot");
            Environment.SetEnvironmentVariable("AI_FOUNDRY_WORKSPACE_NAME", "test-workspace");

            try
            {
                // Act - Initialize function
                var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);

                // Assert - Function initialization
                function.Should().NotBeNull();
                
                // Verify proper initialization logging
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("AI Foundry Connection Details")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);

                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("test-ai-foundry.example.com")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);

                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("TestBot") && v.ToString()!.Contains("test-agent-123")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", null);
            }
        }

        [Fact]
        public void ChatRequestResponse_SerializationWorkflow_WorksEndToEnd()
        {
            // Arrange
            var originalRequest = new ChatRequest
            {
                Message = "Hello, this is a test message",
                ThreadId = "integration-test-thread-123"
            };

            // Act - Serialize request
            var requestJson = JsonSerializer.Serialize(originalRequest);
            var deserializedRequest = JsonSerializer.Deserialize<ChatRequest>(requestJson);

            // Create response based on request
            var response = new ChatResponse
            {
                ThreadId = deserializedRequest!.ThreadId,
                Message = $"Response to: {deserializedRequest.Message}",
                AgentName = "TestBot",
                Timestamp = DateTime.UtcNow
            };

            // Serialize response
            var responseJson = JsonSerializer.Serialize(response);
            var deserializedResponse = JsonSerializer.Deserialize<ChatResponse>(responseJson);

            // Assert - End-to-end workflow
            deserializedRequest.Should().NotBeNull();
            deserializedRequest.Message.Should().Be(originalRequest.Message);
            deserializedRequest.ThreadId.Should().Be(originalRequest.ThreadId);

            deserializedResponse.Should().NotBeNull();
            deserializedResponse!.ThreadId.Should().Be(originalRequest.ThreadId);
            deserializedResponse.Message.Should().Contain("Response to:");
            deserializedResponse.Message.Should().Contain(originalRequest.Message);
            deserializedResponse.AgentName.Should().Be("TestBot");
            deserializedResponse.Error.Should().BeNull();
        }

        [Theory]
        [InlineData("Hello there", "simulation mode")]
        [InlineData("What is AI in A Box?", "simulation mode")]
        [InlineData("How can you help me?", "simulation mode")]
        [InlineData("Tell me about this system", "simulation mode")]
        [InlineData("General question", "simulation mode")]
        public async Task SimulationMode_MessageProcessingWorkflow_HandlesVariousInputs(string inputMessage, string expectedKeyword)
        {
            // Arrange
            var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);
            var chatRequest = new ChatRequest
            {
                Message = inputMessage,
                ThreadId = "test-thread-456"
            };

            // Act - Process message through simulation (since we don't have real AI Foundry in tests)
            var processMethod = typeof(AIFoundryProxyFunction).GetMethod("ProcessWithSimulationAsync", 
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            
            var result = processMethod!.Invoke(function, new object[] { chatRequest.Message, chatRequest.ThreadId });
            var responseMessage = await (Task<string>)result!;

            // Create complete response
            var chatResponse = new ChatResponse
            {
                ThreadId = chatRequest.ThreadId,
                Message = responseMessage,
                AgentName = "AI in A Box",
                Timestamp = DateTime.UtcNow
            };

            // Assert - Complete workflow validation
            chatResponse.Should().NotBeNull();
            chatResponse.ThreadId.Should().Be(chatRequest.ThreadId);
            chatResponse.Message.Should().NotBeNullOrEmpty();
            chatResponse.Message.Should().Contain(expectedKeyword);
            chatResponse.AgentName.Should().Be("AI in A Box");
            chatResponse.Error.Should().BeNull();
            chatResponse.Timestamp.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));

            // Verify logging occurred
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Information,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Processing with simulation mode")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.AtLeastOnce);
        }

        [Fact]
        public void ErrorHandling_WithInvalidConfiguration_HandlesGracefully()
        {
            // Arrange - Set invalid configuration
            Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", "not-a-valid-url");
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", "");
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", "");

            try
            {
                // Act - Function should still initialize (uses fallback logic)
                var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);

                // Assert - Function should handle invalid config gracefully
                function.Should().NotBeNull();
                
                // Verify initialization still completed
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("AI Foundry proxy function initialized")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", null);
            }
        }

        [Fact]
        public async Task MultipleRequests_SimulationMode_MaintainsConsistency()
        {
            // Arrange
            var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);
            var requests = new[]
            {
                "Hello there",
                "What is AI in A Box?",
                "How can you help me?",
                "Tell me about this system",
                "General question"
            };

            // Act & Assert - Process multiple requests
            foreach (var requestMessage in requests)
            {
                var processMethod = typeof(AIFoundryProxyFunction).GetMethod("ProcessWithSimulationAsync", 
                    System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                
                var result = processMethod!.Invoke(function, new object[] { requestMessage, "consistent-thread-id" });
                var task = (Task<string>)result!;
                
                // Wait for completion and validate
                var responseMessage = await task;
                responseMessage.Should().NotBeNullOrEmpty();
                responseMessage.Should().Contain("simulation mode");
                responseMessage.Should().NotContain("error", "Response should not contain error messages");
            }

            // Verify consistent logging behavior
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Information,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Processing with simulation mode")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.Exactly(requests.Length));
        }
    }
}