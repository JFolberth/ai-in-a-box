// Test environment setup
require('@testing-library/jest-dom')

// Mock console methods to reduce noise in tests
const originalConsole = global.console
global.console = {
  ...console,
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  info: jest.fn()
}

// Mock window.scrollTo
Object.defineProperty(window, 'scrollTo', {
  value: jest.fn(),
  writable: true
})

// Create localStorage mock
const createLocalStorageMock = () => ({
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn()
})

// Set up localStorage mock
Object.defineProperty(window, 'localStorage', {
  value: createLocalStorageMock(),
  writable: true
})

// Mock Date.now for consistent timestamps while preserving constructor behavior
const mockDate = new Date('2023-01-01T00:00:00.000Z')
const originalDate = global.Date

// Create a proper Date constructor mock that handles arguments correctly
global.Date = jest.fn().mockImplementation((...args) => {
  if (args.length === 0) {
    // No arguments - return consistent mock date for new Date()
    return new originalDate(mockDate)
  } else {
    // Arguments provided - use original constructor behavior
    return new originalDate(...args)
  }
})

// Mock Date.now for consistent timestamps
global.Date.now = jest.fn(() => mockDate.getTime())

// Copy static methods from original Date
Object.setPrototypeOf(global.Date, originalDate)
Object.getOwnPropertyNames(originalDate).forEach(name => {
  if (typeof originalDate[name] === 'function') {
    global.Date[name] = originalDate[name]
  }
})

// Mock Math.random for consistent IDs
const originalRandom = Math.random
Math.random = jest.fn(() => 0.5)

// Reset all mocks before each test
beforeEach(() => {
  jest.clearAllMocks()
  
  // Reset localStorage mock
  window.localStorage.getItem.mockClear()
  window.localStorage.setItem.mockClear()
  window.localStorage.removeItem.mockClear()
  window.localStorage.clear.mockClear()
})

// Clean up after all tests
afterAll(() => {
  global.console = originalConsole
  global.Date = originalDate
  Math.random = originalRandom
})