# Frontend Testing Guide

This document provides comprehensive information about the frontend testing strategy for the AI Foundry SPA.

## Overview

The frontend includes a robust test suite that validates core application functionality, user interactions, and data management operations. Tests are designed to ensure code quality and prevent regressions.

## Testing Framework

- **Jest**: Primary testing framework
- **jsdom**: Browser environment simulation for DOM testing
- **@testing-library/jest-dom**: Additional DOM testing utilities
- **Babel**: JavaScript transformation for ES6 compatibility

## Test Structure

```
src/frontend/
├── tests/
│   ├── basic.test.js              # Basic functionality tests
│   ├── storage.test.js            # localStorage operations
│   ├── dom-utils.test.js          # DOM manipulation utilities
│   ├── message-formatting.test.js # Message processing and formatting
│   └── integration.test.js        # Application workflow tests
├── test-utils/
│   ├── setup.js                   # Test environment setup
│   ├── env-setup.js              # Environment variable mocking & polyfills
│   ├── mocks.js                   # Mock utilities
│   └── fixtures.js               # Test data fixtures
└── jest.config.js                 # Jest configuration
```

## Test Categories

### 1. Basic Functionality Tests (`basic.test.js`)

- String and array operations
- Date and math operations
- Date assertions use UTC accessors to avoid timezone differences
- Object manipulation
- JSON serialization/deserialization
- Promise and async operation handling

### 2. Storage Tests (`storage.test.js`)

- localStorage save/load operations
- Conversation history persistence
- Error handling for storage failures
- Data serialization validation

### 3. DOM Utilities Tests (`dom-utils.test.js`)

- Element creation and manipulation
- CSS class management
- Event handling
- Form interactions
- Scrolling operations
- Attribute management

### 4. Message Formatting Tests (`message-formatting.test.js`)

- Message data structure validation
- Content processing and formatting
- Conversation history management
- Input validation
- Character count logic
- Typing indicator state management

### 5. Integration Tests (`integration.test.js`)

- User input processing workflows
- Message state management
- UI state transitions
- Data export functionality
- Error handling workflows
- Keyboard interaction patterns

## Running Tests

### Development Commands

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run tests for CI (no watch, coverage required)
npm run test:ci
```

### Individual Test Files

```bash
# Run specific test file
npm test -- --testPathPattern=storage.test.js

# Run tests matching pattern
npm test -- --testNamePattern="should handle"
```

## Test Configuration

### Jest Configuration (`jest.config.js`)

- jsdom test environment for DOM testing
- Babel transformation for ES6 support
- Setup files for test environment
- Coverage configuration
- Test file patterns

### Setup Files

- `test-utils/setup.js`: Mock setup for console, localStorage, Date, Math
- `test-utils/env-setup.js`: Environment variables and global polyfills (TextEncoder/TextDecoder)
- `test-utils/mocks.js`: Utility functions for mocking
- `test-utils/fixtures.js`: Sample data for tests

## Mocking Strategy

### Browser APIs

- `localStorage`: Mocked for storage testing
- `console`: Mocked to reduce test noise
- `Date.now()`: Mocked for consistent timestamps
- `Math.random()`: Mocked for predictable IDs
- `TextEncoder`/`TextDecoder`: Polyfilled for jsdom compatibility

### DOM APIs

- Element creation and manipulation
- Event handling
- Class list operations
- Style management

## Test Best Practices

### 1. Test Structure

- Use descriptive test names
- Group related tests with `describe` blocks
- Include both happy path and error scenarios
- Test edge cases and boundary conditions

### 2. Mocking

- Mock external dependencies
- Use consistent mock data
- Reset mocks between tests
- Avoid over-mocking

### 3. Assertions

- Use specific matchers
- Test behavior, not implementation
- Validate error conditions
- Check state changes

### 4. Test Data

- Use fixtures for complex data
- Keep test data minimal and relevant
- Use factories for dynamic data generation

## Continuous Integration

Tests are automatically executed in the CI pipeline:

```yaml
- name: Run frontend tests
  working-directory: ./src/frontend
  run: npm run test:ci
```

### CI Requirements

- All tests must pass
- Tests run in non-interactive mode
- Coverage reports are generated
- No watch mode or interactive prompts

## Coverage Reporting

Coverage reports are generated in multiple formats:

- **Console**: Text summary during test runs
- **HTML**: Detailed coverage report in `coverage/` directory
- **LCOV**: Machine-readable format for CI integration

## Debugging Tests

### Common Issues

1. **Import/Export Errors**: Ensure Babel is configured correctly
2. **Mock Issues**: Check mock setup in `test-utils/setup.js`
3. **Async Test Failures**: Use proper async/await patterns
4. **DOM Errors**: Verify jsdom environment setup

### Debugging Commands

```bash
# Run single test with verbose output
npm test -- --testPathPattern=integration.test.js --verbose

# Run tests without coverage for faster execution
npm test -- --no-coverage

# Run specific test by name
npm test -- --testNamePattern="should validate message length"
```

## Adding New Tests

### 1. Test File Creation

- Create new test files in `tests/` directory
- Use descriptive filenames (e.g., `new-feature.test.js`)
- Follow existing test structure patterns

### 2. Test Organization

```javascript
describe('Feature Name', () => {
  describe('Sub-feature', () => {
    test('should do something specific', () => {
      // Test implementation
    })
  })
})
```

### 3. Mock Usage

```javascript
// Use existing mocks from setup
expect(window.localStorage.setItem).toHaveBeenCalled()

// Create custom mocks for specific tests
const mockFunction = jest.fn()
mockFunction.mockReturnValue('test value')
```

## Performance Considerations

- Tests complete in under 2 minutes
- Mocks reduce external dependencies
- Parallel test execution when possible
- Minimal test data for faster execution

## Future Enhancements

### Potential Additions

- Visual regression testing
- End-to-end testing with Playwright/Cypress
- Performance testing
- Accessibility testing
- Component-specific testing

### Test Coverage Goals

- Increase integration with actual source files
- Add more complex scenario testing
- Enhance error condition coverage
- Add performance benchmarking

## Troubleshooting

### Common Test Failures

1. **TypeError: Cannot read property**: Check mock setup
2. **ReferenceError**: Verify imports and environment setup
3. **Timeout errors**: Increase Jest timeout for async tests
4. **Mock assertion failures**: Ensure mocks are cleared between tests

### Getting Help

- Check Jest documentation for specific issues
- Review existing test patterns for guidance
- Ensure all dependencies are installed
- Verify Node.js version compatibility (20+)
