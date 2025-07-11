using Xunit;
using FluentAssertions;
using System.Text.Json;
using AIFoundryProxy;

namespace AIFoundryProxy.Tests
{
    /// <summary>
    /// Tests for the ChatRequest and ChatResponse models.
    /// Validates serialization, deserialization, and basic model functionality.
    /// </summary>
    public class ChatModelsTests
    {
        #region ChatRequest Tests

        [Fact]
        public void ChatRequest_DefaultConstructor_InitializesWithDefaults()
        {
            // Arrange & Act
            var request = new ChatRequest();

            // Assert
            request.Message.Should().Be(string.Empty);
            request.ThreadId.Should().BeNull();
        }

        [Fact]
        public void ChatRequest_WithProperties_SetsValuesCorrectly()
        {
            // Arrange
            var message = "Test message";
            var threadId = "thread-123";

            // Act
            var request = new ChatRequest
            {
                Message = message,
                ThreadId = threadId
            };

            // Assert
            request.Message.Should().Be(message);
            request.ThreadId.Should().Be(threadId);
        }

        [Fact]
        public void ChatRequest_JsonSerialization_SerializesCorrectly()
        {
            // Arrange
            var request = new ChatRequest
            {
                Message = "Hello, AI in A Box!",
                ThreadId = "thread-456"
            };

            // Act
            var json = JsonSerializer.Serialize(request);
            var deserialized = JsonSerializer.Deserialize<ChatRequest>(json);

            // Assert
            json.Should().Contain("Hello, AI in A Box!");
            json.Should().Contain("thread-456");
            deserialized.Should().NotBeNull();
            deserialized!.Message.Should().Be(request.Message);
            deserialized.ThreadId.Should().Be(request.ThreadId);
        }

        [Fact]
        public void ChatRequest_JsonDeserialization_WithNullThreadId_DeserializesCorrectly()
        {
            // Arrange
            var json = """{"Message":"Test message","ThreadId":null}""";

            // Act
            var request = JsonSerializer.Deserialize<ChatRequest>(json);

            // Assert
            request.Should().NotBeNull();
            request!.Message.Should().Be("Test message");
            request.ThreadId.Should().BeNull();
        }

        [Fact]
        public void ChatRequest_JsonDeserialization_WithEmptyMessage_DeserializesCorrectly()
        {
            // Arrange
            var json = """{"Message":"","ThreadId":"thread-123"}""";

            // Act
            var request = JsonSerializer.Deserialize<ChatRequest>(json);

            // Assert
            request.Should().NotBeNull();
            request!.Message.Should().Be("");
            request.ThreadId.Should().Be("thread-123");
        }

        #endregion

        #region ChatResponse Tests

        [Fact]
        public void ChatResponse_DefaultConstructor_InitializesWithDefaults()
        {
            // Arrange & Act
            var response = new ChatResponse();

            // Assert
            response.Message.Should().Be(string.Empty);
            response.AgentName.Should().Be(string.Empty);
            response.ThreadId.Should().BeNull();
            response.Error.Should().BeNull();
            // Default DateTime is DateTime.MinValue, not DateTime.UtcNow
            response.Timestamp.Should().Be(DateTime.MinValue);
        }

        [Fact]
        public void ChatResponse_WithProperties_SetsValuesCorrectly()
        {
            // Arrange
            var message = "AI response";
            var agentName = "AI in A Box";
            var threadId = "thread-789";
            var error = "Test error";
            var timestamp = DateTime.UtcNow;

            // Act
            var response = new ChatResponse
            {
                Message = message,
                AgentName = agentName,
                ThreadId = threadId,
                Error = error,
                Timestamp = timestamp
            };

            // Assert
            response.Message.Should().Be(message);
            response.AgentName.Should().Be(agentName);
            response.ThreadId.Should().Be(threadId);
            response.Error.Should().Be(error);
            response.Timestamp.Should().Be(timestamp);
        }

        [Fact]
        public void ChatResponse_JsonSerialization_SerializesCorrectly()
        {
            // Arrange
            var response = new ChatResponse
            {
                Message = "AI response message",
                AgentName = "AI in A Box",
                ThreadId = "thread-999",
                Timestamp = new DateTime(2024, 1, 1, 12, 0, 0, DateTimeKind.Utc)
            };

            // Act
            var json = JsonSerializer.Serialize(response);
            var deserialized = JsonSerializer.Deserialize<ChatResponse>(json);

            // Assert
            json.Should().Contain("AI response message");
            json.Should().Contain("AI in A Box");
            json.Should().Contain("thread-999");
            deserialized.Should().NotBeNull();
            deserialized!.Message.Should().Be(response.Message);
            deserialized.AgentName.Should().Be(response.AgentName);
            deserialized.ThreadId.Should().Be(response.ThreadId);
            deserialized.Timestamp.Should().Be(response.Timestamp);
        }

        [Fact]
        public void ChatResponse_WithError_SerializesErrorCorrectly()
        {
            // Arrange
            var response = new ChatResponse
            {
                Error = "Something went wrong",
                AgentName = "AI in A Box",
                Timestamp = DateTime.UtcNow
            };

            // Act
            var json = JsonSerializer.Serialize(response);
            var deserialized = JsonSerializer.Deserialize<ChatResponse>(json);

            // Assert
            json.Should().Contain("Something went wrong");
            deserialized.Should().NotBeNull();
            deserialized!.Error.Should().Be(response.Error);
            deserialized.AgentName.Should().Be(response.AgentName);
        }

        [Fact]
        public void ChatResponse_WithSuccessfulResponse_HasNoError()
        {
            // Arrange & Act
            var response = new ChatResponse
            {
                Message = "Successful response",
                AgentName = "AI in A Box",
                ThreadId = "thread-123",
                Timestamp = DateTime.UtcNow
            };

            // Assert
            response.Error.Should().BeNull();
            response.Message.Should().NotBeNullOrEmpty();
            response.AgentName.Should().NotBeNullOrEmpty();
            response.ThreadId.Should().NotBeNullOrEmpty();
        }

        #endregion
    }
}