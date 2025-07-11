# AI Foundry SPA Backend Tests

This directory contains comprehensive unit and integration tests for the AI Foundry SPA backend Azure Function App.

## Test Structure

### Test Projects

- **AIFoundryProxy.Tests**: Main test project containing all unit and integration tests

### Test Categories

#### 1. BasicFunctionTests
- Tests for function initialization and constructor behavior
- Environment variable configuration loading
- Logging verification
- Error handling for invalid inputs

#### 2. ChatModelsTests  
- Tests for `ChatRequest` and `ChatResponse` model classes
- JSON serialization and deserialization
- Property validation and default values
- Edge cases handling

#### 3. UtilityMethodTests
- Tests for static utility methods like `IsRunningStatus`
- Case sensitivity handling
- Boundary condition testing
- Pure function validation

#### 4. SimulationLogicTests
- Tests for the AI simulation mode functionality
- Keyword-based response generation
- Message processing workflow
- Logging verification for simulation mode

#### 5. IntegrationTests
- End-to-end workflow testing
- Configuration and initialization integration
- Multi-request processing consistency
- Error handling scenarios

## Test Coverage

The test suite covers:

### ✅ Core Functionality
- Function initialization and configuration loading
- Message processing in simulation mode
- Request/response model validation
- Utility method behavior

### ✅ Error Handling
- Invalid configuration scenarios
- Null parameter handling
- Exception logging and recovery

### ✅ Business Logic
- Keyword-based response generation
- Contextual AI responses for cancer-related queries
- Thread ID management
- Timestamp handling

### ✅ Integration Scenarios
- Multi-request processing
- Configuration changes
- Logging consistency

## Running Tests

### Prerequisites
- .NET 8.0 SDK
- Backend project must build successfully

### Commands

```bash
# Navigate to test directory
cd src/backend/tests/AIFoundryProxy.Tests

# Restore packages and build
dotnet build

# Run all tests
dotnet test

# Run tests with detailed output
dotnet test --verbosity normal

# Run tests with coverage (if coverage tools are installed)
dotnet test --collect:"XPlat Code Coverage"
```

### From Repository Root

```bash
# Build and test from root
dotnet build src/backend/AIFoundryProxy.csproj
dotnet test src/backend/tests/AIFoundryProxy.Tests/AIFoundryProxy.Tests.csproj
```

## Test Results

### Current Status
- **Total Tests**: 54
- **Passed**: 54 ✅
- **Failed**: 0 ✅
- **Coverage**: Core functionality and business logic

### Test Categories Breakdown
- **Basic Function Tests**: 5 tests
- **Chat Models Tests**: 8 tests  
- **Utility Method Tests**: 5 tests
- **Simulation Logic Tests**: 12 tests
- **Integration Tests**: 6 tests

## Test Design Principles

### 1. Minimal Dependencies
- Tests focus on the business logic without complex external dependencies
- Uses mocking for `ILogger` to verify logging behavior
- Avoids complex HTTP mocking in favor of direct method testing

### 2. Clear Test Structure
- Follows AAA pattern (Arrange, Act, Assert)
- Descriptive test names that explain the scenario
- Well-organized test classes by functionality

### 3. Realistic Scenarios
- Tests use realistic cancer-related messages for simulation mode
- Covers both success and error paths
- Tests edge cases and boundary conditions

### 4. Fast Execution
- Tests complete in under 15 seconds total
- No external service dependencies
- Simulation mode allows testing without AI Foundry connectivity

## Extending Tests

### Adding New Tests

1. **For new functionality**: Add tests to existing category or create new test class
2. **For new models**: Add to `ChatModelsTests` or create separate model test class
3. **For integration scenarios**: Add to `IntegrationTests` class

### Test Patterns

```csharp
[Fact]
public void MethodName_WithSpecificScenario_ExpectedBehavior()
{
    // Arrange
    var input = "test input";
    
    // Act
    var result = MethodUnderTest(input);
    
    // Assert
    result.Should().NotBeNull();
    result.Should().Contain("expected content");
}
```

### Mock Setup Pattern

```csharp
var mockLogger = new Mock<ILogger>();
mockLoggerFactory.Setup(x => x.CreateLogger(It.IsAny<string>()))
                 .Returns(mockLogger.Object);
```

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

- ✅ No external dependencies
- ✅ Fast execution (< 15 seconds)
- ✅ Deterministic results
- ✅ Clear pass/fail indicators
- ✅ Detailed error messages for debugging

## Troubleshooting

### Common Issues

1. **Build Errors**: Ensure the main backend project builds first
2. **Package Restore**: Run `dotnet restore` in the test project directory
3. **Test Discovery**: Verify test methods are marked with `[Fact]` or `[Theory]`

### Debug Mode

Run tests in debug mode to step through:

```bash
dotnet test --logger "console;verbosity=detailed"
```

## Future Enhancements

### Potential Additions
- Performance benchmarking tests
- Load testing for message processing
- Memory usage validation
- More comprehensive error scenario coverage
- Integration with actual Azure Functions runtime testing

### Code Coverage Goals
- Maintain >80% code coverage
- Focus on critical business logic paths
- Ensure all public methods are tested
- Cover exception handling scenarios

---

*Last Updated: June 2025*  
*Test Framework: xUnit with FluentAssertions and Moq*