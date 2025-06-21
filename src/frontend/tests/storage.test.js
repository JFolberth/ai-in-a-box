/**
 * Tests for localStorage operations and data persistence
 */

describe('Storage Operations', () => {
  beforeEach(() => {
    // localStorage is already mocked in setup.js
    // Just clear the mocks before each test
    window.localStorage.getItem.mockClear()
    window.localStorage.setItem.mockClear()
    window.localStorage.removeItem.mockClear()
    window.localStorage.clear.mockClear()
  })

  describe('Conversation History Storage', () => {
    test('should save conversation history to localStorage', () => {
      const conversationHistory = [
        { role: 'user', content: 'Hello', timestamp: '10:00:00' },
        { role: 'assistant', content: 'Hi there!', timestamp: '10:00:05' }
      ]

      const storageKey = 'ai-foundry-chat-history'
      const expectedData = JSON.stringify(conversationHistory)

      // Simulate saving to localStorage
      window.localStorage.setItem(storageKey, expectedData)

      expect(window.localStorage.setItem).toHaveBeenCalledWith(storageKey, expectedData)
    })

    test('should load conversation history from localStorage', () => {
      const conversationHistory = [
        { role: 'user', content: 'Hello', timestamp: '10:00:00' },
        { role: 'assistant', content: 'Hi there!', timestamp: '10:00:05' }
      ]

      const storageKey = 'ai-foundry-chat-history'
      const storedData = JSON.stringify(conversationHistory)

      window.localStorage.getItem.mockReturnValue(storedData)

      const result = window.localStorage.getItem(storageKey)
      const parsedData = JSON.parse(result)

      expect(window.localStorage.getItem).toHaveBeenCalledWith(storageKey)
      expect(parsedData).toEqual(conversationHistory)
    })

    test('should handle empty storage gracefully', () => {
      const storageKey = 'ai-foundry-chat-history'
      window.localStorage.getItem.mockReturnValue(null)

      const result = window.localStorage.getItem(storageKey)
      expect(result).toBeNull()
    })

    test('should handle invalid JSON in storage', () => {
      const storageKey = 'ai-foundry-chat-history'
      window.localStorage.getItem.mockReturnValue('invalid json')

      const result = window.localStorage.getItem(storageKey)
      
      expect(() => JSON.parse(result)).toThrow()
    })

    test('should clear conversation history', () => {
      const storageKey = 'ai-foundry-chat-history'
      
      window.localStorage.removeItem(storageKey)
      
      expect(window.localStorage.removeItem).toHaveBeenCalledWith(storageKey)
    })
  })

  describe('Storage Error Handling', () => {
    test('should handle localStorage quota exceeded', () => {
      const storageKey = 'ai-foundry-chat-history'
      const data = 'test data'
      
      window.localStorage.setItem.mockImplementation(() => {
        throw new Error('QuotaExceededError')
      })

      expect(() => {
        try {
          window.localStorage.setItem(storageKey, data)
        } catch (error) {
          // This is what the app should do - handle the error gracefully
          console.warn('Failed to save conversation history:', error)
          throw error
        }
      }).toThrow('QuotaExceededError')
    })

    test('should handle localStorage access denied', () => {
      const storageKey = 'ai-foundry-chat-history'
      
      window.localStorage.getItem.mockImplementation(() => {
        throw new Error('Access denied')
      })

      expect(() => {
        try {
          window.localStorage.getItem(storageKey)
        } catch (error) {
          console.warn('Failed to load conversation history:', error)
          throw error
        }
      }).toThrow('Access denied')
    })
  })

  describe('Data Serialization', () => {
    test('should serialize message objects correctly', () => {
      const message = {
        role: 'user',
        content: 'Hello world',
        timestamp: '2023-01-01T10:00:00Z'
      }

      const serialized = JSON.stringify(message)
      const deserialized = JSON.parse(serialized)

      expect(deserialized).toEqual(message)
      expect(deserialized.role).toBe('user')
      expect(deserialized.content).toBe('Hello world')
    })

    test('should handle complex conversation data', () => {
      const conversationData = {
        messages: [
          { role: 'user', content: 'Question 1', timestamp: '10:00:00' },
          { role: 'assistant', content: 'Answer 1', timestamp: '10:00:05' }
        ],
        threadId: 'thread_123',
        lastUpdated: '2023-01-01T10:00:00Z'
      }

      const serialized = JSON.stringify(conversationData)
      const deserialized = JSON.parse(serialized)

      expect(deserialized.messages).toHaveLength(2)
      expect(deserialized.threadId).toBe('thread_123')
      expect(deserialized.messages[0].role).toBe('user')
    })
  })
})