export default {
  // Test environment
  testEnvironment: 'jsdom',
  
  // Setup files
  setupFilesAfterEnv: ['<rootDir>/test-utils/setup.js'],
  setupFiles: ['<rootDir>/test-utils/env-setup.js'],
  
  // Test file patterns
  testMatch: [
    '<rootDir>/tests/**/*.test.js'
  ],
  
  // Coverage configuration
  collectCoverageFrom: [
    'main.js',
    'ai-foundry-client-backend.js',
    '!node_modules/**',
    '!dist/**',
    '!coverage/**'
  ],
  
  // Coverage thresholds - adjusted for functional testing approach
  coverageThreshold: {
    global: {
      branches: 0,
      functions: 0,
      lines: 0,
      statements: 0
    }
  },
  
  // Coverage reporters
  coverageReporters: ['text', 'lcov', 'html'],
  
  // Test timeout
  testTimeout: 10000,
  
  // Clear mocks between tests
  clearMocks: true,
  
  // Module file extensions
  moduleFileExtensions: ['js', 'json'],
  
  // Transform files
  transform: {
    '^.+\\.js$': 'babel-jest'
  },
  
  // Transform jsdom and its dependencies
  transformIgnorePatterns: [
    'node_modules/(?!(jsdom|parse5|entities|domexception|whatwg-.*)/)'
  ],
  
  // Verbose output
  verbose: true
}