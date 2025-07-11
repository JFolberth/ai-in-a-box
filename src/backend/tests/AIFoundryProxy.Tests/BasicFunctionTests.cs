using Xunit;
using Microsoft.Extensions.Logging;
using Moq;
using FluentAssertions;
using AIFoundryProxy;

namespace AIFoundryProxy.Tests
{
    /// <summary>
    /// Unit tests for configuration loading and basic functionality of AIFoundryProxyFunction.
    /// These tests focus on constructor behavior, environment variable loading, and basic initialization.
    /// </summary>
    public class BasicFunctionTests
    {
        private readonly Mock<ILoggerFactory> _mockLoggerFactory;
        private readonly Mock<ILogger> _mockLogger;

        public BasicFunctionTests()
        {
            _mockLoggerFactory = new Mock<ILoggerFactory>();
            _mockLogger = new Mock<ILogger>();
            
            _mockLoggerFactory
                .Setup(x => x.CreateLogger(It.IsAny<string>()))
                .Returns(_mockLogger.Object);
        }

        [Fact]
        public void Constructor_WithDefaultEnvironment_InitializesSuccessfully()
        {
            // Arrange & Act - Clear any existing environment variables
            Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", null);
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", null);
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", null);
            Environment.SetEnvironmentVariable("AI_FOUNDRY_WORKSPACE_NAME", null);
            
            var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);

            // Assert - Function should initialize without throwing exceptions
            function.Should().NotBeNull();
            
            // Verify logger was called to log connection details
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Information,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("AI Foundry Connection Details")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.AtLeastOnce);
        }

        [Fact]
        public void Constructor_WithCustomEnvironmentVariables_LoadsCustomValues()
        {
            // Arrange
            var customEndpoint = "https://custom-ai-foundry.example.com/api/projects/test";
            var customAgentId = "custom-agent-123";
            var customAgentName = "CustomBot";
            
            Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", customEndpoint);
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", customAgentId);
            Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", customAgentName);

            try
            {
                // Act
                var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);

                // Assert - Function should initialize without throwing exceptions
                function.Should().NotBeNull();
                
                // Verify logger was called with custom values
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains(customEndpoint)),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);

                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains(customAgentName) && v.ToString()!.Contains(customAgentId)),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                    Times.AtLeastOnce);
            }            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("AI_FOUNDRY_ENDPOINT", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_ID", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_AGENT_NAME", null);
                Environment.SetEnvironmentVariable("AI_FOUNDRY_WORKSPACE_NAME", null);
            }
        }

        [Fact]
        public void Constructor_LogsInitializationMessage()
        {
            // Arrange & Act
            var function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);

            // Assert
            function.Should().NotBeNull();
            
            // Verify initialization completion message
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Information,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("AI Foundry proxy function initialized")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.AtLeastOnce);
        }

        [Fact]
        public void Constructor_WithNullLoggerFactory_ThrowsArgumentNullException()
        {
            // Arrange & Act & Assert
            Assert.Throws<ArgumentNullException>(() => new AIFoundryProxyFunction(null!));
        }
    }
}