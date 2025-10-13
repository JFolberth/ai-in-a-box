# AGENTS.md - Frontend

This directory contains a vanilla JavaScript SPA (Single Page Application) that integrates with AI Foundry through a backend proxy. The frontend is built with Vite and deployed to Azure Storage Static Websites.

## Project Setup

### Development Environment

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Run tests in watch mode
npm run test:watch
```

### Key Dependencies

- **Vite**: Build tool and dev server (ES modules, fast HMR)
- **Jest**: Testing framework with DOM testing utilities
- **Babel**: For test environment transformation
- **Prettier**: Code formatting

## Architecture

### File Structure

- `index.html`: Main HTML entry point
- `main.js`: Application entry point and routing
- `ai-foundry-client-backend.js`: AI Foundry API client (proxy integration)
- `auth.js`: Authentication utilities (public mode)
- `style.css`: Application styles
- `environments/`: Environment-specific configurations
- `tests/`: Jest test files
- `test-utils/`: Testing utilities and mocks

### Application Flow

1. **Initialization**: `main.js` sets up the application and DOM manipulation
2. **Backend Integration**: `ai-foundry-client-backend.js` handles API calls to the Function App proxy
3. **UI Updates**: Vanilla JavaScript DOM manipulation for dynamic content
4. **Error Handling**: Comprehensive error handling for network and API failures

## Development Guidelines

### Code Style

- **ES6+ Features**: Use modern JavaScript (async/await, arrow functions, destructuring)
- **Functional Patterns**: Prefer pure functions and immutable data patterns
- **Error Handling**: Always use try-catch blocks for async operations
- **Code Comments**: Document complex logic and API integrations

### JavaScript Patterns

```javascript
// ✅ GOOD: Async/await with proper error handling
async function fetchAIResponse(message) {
  try {
    const response = await aiFoundryClient.sendMessage(message)
    return response.data
  } catch (error) {
    console.error('AI Foundry request failed:', error)
    throw new Error('Failed to get AI response')
  }
}

// ✅ GOOD: Functional approach for DOM updates
const updateChatUI = messages => {
  const chatContainer = document.getElementById('chat-container')
  chatContainer.innerHTML = messages
    .map(msg => `<div class="message ${msg.role}">${msg.content}</div>`)
    .join('')
}
```

### Testing Requirements

- **Unit Tests**: All utility functions must have tests
- **Integration Tests**: API client functions must be tested with mocks
- **DOM Testing**: UI interactions should be tested with DOM utilities
- **Coverage**: Maintain >80% test coverage

### Testing Patterns

```javascript
// Example test structure
import { aiFoundryClient } from '../ai-foundry-client-backend.js'
import { mockFetch } from '../test-utils/fetch-mock.js'

describe('AI Foundry Client', () => {
  beforeEach(() => {
    mockFetch.setup()
  })

  afterEach(() => {
    mockFetch.restore()
  })

  test('should send message and return response', async () => {
    // Test implementation
  })
})
```

## Environment Configuration

### Environment Files

- `.env.example`: Template for environment variables
- `environments/`: Directory containing environment-specific configs

### Required Environment Variables

```javascript
// Available in development
const config = {
  BACKEND_URL: process.env.BACKEND_URL || 'http://localhost:7071',
  API_VERSION: process.env.API_VERSION || 'v1',
  DEBUG_MODE: process.env.NODE_ENV === 'development',
}
```

### Environment-Specific Builds

```bash
# Development build (includes debug info)
npm run build:dev

# Production build (optimized, minified)
npm run build:prod

# Staging build (production optimizations, debug logging)
npm run build:staging
```

## Backend Integration

### API Client (`ai-foundry-client-backend.js`)

- **Base URL**: Configured per environment (local Function App or deployed Azure Function)
- **Authentication**: Public mode (no auth headers required)
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Retry Logic**: Automatic retry for transient failures

### API Endpoints

```javascript
// Example API client usage
const aiClient = new AIFoundryClient({
  baseUrl: config.BACKEND_URL,
  timeout: 30000,
})

// Send message to AI Foundry
const response = await aiClient.sendMessage({
  message: 'Hello, AI!',
  conversationId: 'optional-conversation-id',
})
```

### Local Development Integration

1. **Start Azurite**: Required for Function App storage
2. **Launch Function App**: Backend proxy on `http://localhost:7071`
3. **Start Frontend**: Vite dev server on `http://localhost:5173`
4. **Configure Backend URL**: Point frontend to local Function App

## Build and Deployment

### Vite Configuration (`vite.config.js`)

- **Build Output**: `dist/` directory
- **Asset Optimization**: Automatic minification and bundling
- **Environment Variables**: Injected at build time
- **Development Server**: Hot module replacement enabled

### Production Build Process

```bash
# Clean previous builds
rm -rf dist/

# Build with production optimizations
npm run build

# Verify build output
ls -la dist/

# Optional: Preview production build locally
npm run preview
```

### Azure Storage Static Website Deployment

The build output (`dist/`) is deployed to Azure Storage Static Websites:

- **Index Document**: `index.html`
- **Error Document**: `index.html` (SPA routing)
- **Asset Caching**: Configure cache headers for static assets
- **CDN Integration**: Optional Azure CDN for global distribution

## Testing Strategy

### Test Categories

1. **Unit Tests**: Individual functions and utilities
2. **Integration Tests**: API client and backend communication
3. **DOM Tests**: UI component behavior
4. **E2E Tests**: Full user workflows (optional, consider Playwright)

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- ai-foundry-client-backend.test.js

# Debug tests
npm run test:debug
```

### Mock Strategies

- **Fetch API**: Mock HTTP requests using custom fetch mock utility
- **DOM APIs**: Use jsdom for DOM testing in Node.js environment
- **Local Storage**: Mock browser storage APIs
- **Environment Variables**: Mock different environment configurations

## Performance Considerations

### Bundle Optimization

- **Code Splitting**: Use dynamic imports for large modules
- **Tree Shaking**: Remove unused code automatically via Vite
- **Asset Optimization**: Compress images and minimize CSS/JS
- **Lazy Loading**: Load non-critical resources asynchronously

### Runtime Performance

- **Efficient DOM Manipulation**: Minimize reflows and repaints
- **Debouncing**: Use debouncing for user input handling
- **Caching**: Cache API responses where appropriate
- **Memory Management**: Avoid memory leaks in event listeners

## Troubleshooting

### Common Issues

- **CORS Errors**: Ensure Function App proxy handles CORS correctly
- **Build Failures**: Check Node.js version compatibility (>=18)
- **Test Failures**: Verify mock configurations match actual API contracts
- **Deployment Issues**: Confirm Azure Storage static website is properly configured

### Debug Commands

```bash
# Check Node.js version
node --version

# Verify npm dependencies
npm ls

# Debug Vite build process
npm run build -- --debug

# Check test configuration
npm run test -- --verbose
```

### Local Development Debug

1. Open browser developer tools
2. Check console for JavaScript errors
3. Verify network requests to backend proxy
4. Confirm environment variables are properly loaded
5. Test API endpoints directly using browser or Postman
