using Xunit;
using FluentAssertions;
using System.Reflection;
using Microsoft.Extensions.Logging;
using Moq;
using AIFoundryProxy;

namespace AIFoundryProxy.Tests
{
    /// <summary>
    /// Tests for utility and helper methods in AIFoundryProxyFunction.
    /// Uses reflection to test private static methods that are pure functions.
    /// </summary>
    public class UtilityMethodTests
    {
        [Theory]
        [InlineData("queued", true)]
        [InlineData("inprogress", true)]
        [InlineData("in_progress", true)]
        [InlineData("running", true)]
        [InlineData("QUEUED", true)]
        [InlineData("INPROGRESS", true)]
        [InlineData("IN_PROGRESS", true)]
        [InlineData("RUNNING", true)]
        [InlineData("completed", false)]
        [InlineData("failed", false)]
        [InlineData("cancelled", false)]
        [InlineData("COMPLETED", false)]
        [InlineData("", false)]
        [InlineData(null, false)]
        [InlineData("unknown_status", false)]
        public void IsRunningStatus_WithVariousStatuses_ReturnsCorrectResult(string? status, bool expected)
        {
            // Arrange & Act
            var result = InvokePrivateStaticMethod<bool>("IsRunningStatus", status);

            // Assert
            result.Should().Be(expected);
        }

        [Fact]
        public void IsRunningStatus_WithCaseSensitivity_HandlesCorrectly()
        {
            // Test case insensitivity for all valid running statuses
            var runningStatuses = new[] { "queued", "inprogress", "in_progress", "running" };
            
            foreach (var status in runningStatuses)
            {
                // Test lowercase
                var lowerResult = InvokePrivateStaticMethod<bool>("IsRunningStatus", status.ToLowerInvariant());
                lowerResult.Should().BeTrue($"Status '{status.ToLowerInvariant()}' should be considered running");
                
                // Test uppercase
                var upperResult = InvokePrivateStaticMethod<bool>("IsRunningStatus", status.ToUpperInvariant());
                upperResult.Should().BeTrue($"Status '{status.ToUpperInvariant()}' should be considered running");
            }
        }

        [Fact]
        public void IsRunningStatus_WithNonRunningStatuses_ReturnsFalse()
        {
            // Test various non-running statuses
            var nonRunningStatuses = new[] { "completed", "failed", "cancelled", "error", "timeout", "stopped" };
            
            foreach (var status in nonRunningStatuses)
            {
                var result = InvokePrivateStaticMethod<bool>("IsRunningStatus", status);
                result.Should().BeFalse($"Status '{status}' should not be considered running");
            }
        }

        /// <summary>
        /// Helper method to invoke private static methods using reflection for testing.
        /// </summary>
        private T InvokePrivateStaticMethod<T>(string methodName, params object?[] parameters)
        {
            var method = typeof(AIFoundryProxyFunction).GetMethod(methodName, BindingFlags.NonPublic | BindingFlags.Static);
            method.Should().NotBeNull($"Private static method '{methodName}' should exist");
            
            var result = method!.Invoke(null, parameters);
            return (T)result!;
        }
    }

    /// <summary>
    /// Tests for simulation logic and message processing.
    /// Tests the business logic of the simulation mode without complex HTTP mocking.
    /// </summary>
    public class SimulationLogicTests
    {
        private readonly Mock<ILoggerFactory> _mockLoggerFactory;
        private readonly Mock<ILogger> _mockLogger;
        private readonly AIFoundryProxyFunction _function;

        public SimulationLogicTests()
        {
            _mockLoggerFactory = new Mock<ILoggerFactory>();
            _mockLogger = new Mock<ILogger>();
            
            _mockLoggerFactory
                .Setup(x => x.CreateLogger(It.IsAny<string>()))
                .Returns(_mockLogger.Object);
            
            _function = new AIFoundryProxyFunction(_mockLoggerFactory.Object);
        }

        [Theory]
        [InlineData("Hello there")]
        [InlineData("What is AI in A Box?")]
        [InlineData("How can you help me?")]
        [InlineData("Tell me about this system")]
        public async Task ProcessWithSimulationAsync_WithGenericMessage_ReturnsSimulationResponse(string message)
        {
            // Act
            var result = await InvokePrivateMethodAsync<string>("ProcessWithSimulationAsync", message, null);

            // Assert
            result.Should().NotBeNullOrEmpty();
            result.Should().Contain("simulation mode");
            result.Should().Contain(message);
        }

        [Fact]
        public async Task ProcessWithSimulationAsync_WithThreadId_CompletesSuccessfully()
        {
            // Arrange
            var message = "Test message";
            var threadId = "thread-123";

            // Act
            var result = await InvokePrivateMethodAsync<string>("ProcessWithSimulationAsync", message, threadId);

            // Assert
            result.Should().NotBeNullOrEmpty();
            result.Should().Contain("simulation mode");
            
            // Verify simulation mode was logged
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
        public async Task ProcessWithSimulationAsync_LogsSimulationResponse()
        {
            // Arrange
            var message = "What can you do?";

            // Act
            await InvokePrivateMethodAsync<string>("ProcessWithSimulationAsync", message, null);

            // Assert
            // Verify that simulation response was logged
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Information,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Generated simulation response")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.AtLeastOnce);
        }

        /// <summary>
        /// Helper method to invoke private async methods using reflection for testing.
        /// </summary>
        private async Task<T> InvokePrivateMethodAsync<T>(string methodName, params object?[] parameters)
        {
            var method = typeof(AIFoundryProxyFunction).GetMethod(methodName, BindingFlags.NonPublic | BindingFlags.Instance);
            method.Should().NotBeNull($"Private method '{methodName}' should exist");
            
            var result = method!.Invoke(_function, parameters);
            if (result is Task<T> task)
            {
                return await task;
            }
            
            throw new InvalidOperationException($"Method '{methodName}' did not return a Task<{typeof(T).Name}>");
        }
    }
}