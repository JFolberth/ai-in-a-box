// Mock utilities for tests
import axios from 'axios'

// Mock axios
jest.mock('axios', () => ({
  post: jest.fn(),
  get: jest.fn(),
  default: {
    post: jest.fn(),
    get: jest.fn()
  }
}))

// Mock DOM elements
export const createMockElements = () => ({
  messagesContainer: {
    appendChild: jest.fn(),
    querySelector: jest.fn(),
    scrollTop: 0,
    scrollHeight: 100
  },
  userInput: {
    value: '',
    focus: jest.fn(),
    addEventListener: jest.fn(),
    style: { height: 'auto' }
  },
  sendBtn: {
    disabled: false,
    addEventListener: jest.fn()
  },
  clearBtn: {
    addEventListener: jest.fn()
  },
  exportBtn: {
    addEventListener: jest.fn()
  },
  typingIndicator: {
    classList: {
      add: jest.fn(),
      remove: jest.fn()
    }
  },
  characterCount: {
    textContent: '0/4000'
  }
})

// Mock document methods
export const mockDocument = () => {
  const mockElements = createMockElements()
  
  global.document = {
    getElementById: jest.fn((id) => mockElements[id.replace('-', '').replace('-', '')]),
    querySelector: jest.fn((selector) => {
      if (selector === '.character-count') return mockElements.characterCount
      if (selector === '.welcome-message') return null
      return null
    }),
    createElement: jest.fn((tag) => ({
      tagName: tag.toUpperCase(),
      appendChild: jest.fn(),
      setAttribute: jest.fn(),
      textContent: '',
      innerHTML: '',
      classList: {
        add: jest.fn(),
        remove: jest.fn()
      }
    })),
    addEventListener: jest.fn()
  }
  
  return mockElements
}

// Mock axios responses
export const mockAxiosSuccess = (data) => {
  axios.post.mockResolvedValue({ data })
  axios.get.mockResolvedValue({ data })
}

export const mockAxiosError = (error) => {
  axios.post.mockRejectedValue(error)
  axios.get.mockRejectedValue(error)
}

// Reset mocks
export const resetMocks = () => {
  jest.clearAllMocks()
}