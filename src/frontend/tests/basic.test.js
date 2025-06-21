/**
 * Basic tests for core functionality
 * Testing utility functions and simple logic
 */

describe('Basic Functionality Tests', () => {
  describe('String and Array Utilities', () => {
    test('should handle string operations', () => {
      const testString = 'Hello World'
      expect(testString.toLowerCase()).toBe('hello world')
      expect(testString.split(' ')).toEqual(['Hello', 'World'])
      expect(testString.length).toBe(11)
    })

    test('should handle array operations', () => {
      const testArray = [1, 2, 3, 4, 5]
      expect(testArray.length).toBe(5)
      expect(testArray.slice(0, 2)).toEqual([1, 2])
      expect(testArray.includes(3)).toBe(true)
    })
  })

  describe('Date and Math Operations', () => {
    test('should create valid dates', () => {
      const date = new Date('2023-01-01')
      expect(date.getFullYear()).toBe(2023)
      expect(date.getMonth()).toBe(0) // January is 0
    })

    test('should perform math operations', () => {
      expect(2 + 2).toBe(4)
      expect(Math.max(1, 2, 3)).toBe(3)
      expect(Math.min(1, 2, 3)).toBe(1)
    })
  })

  describe('Object Operations', () => {
    test('should handle object properties', () => {
      const testObj = { name: 'Test', value: 42 }
      expect(testObj.name).toBe('Test')
      expect(testObj.value).toBe(42)
      expect(Object.keys(testObj)).toEqual(['name', 'value'])
    })

    test('should handle object methods', () => {
      const testObj = {
        getValue: () => 'test value',
        add: (a, b) => a + b
      }
      expect(testObj.getValue()).toBe('test value')
      expect(testObj.add(2, 3)).toBe(5)
    })
  })

  describe('JSON Operations', () => {
    test('should serialize and deserialize JSON', () => {
      const originalObj = { message: 'Hello', count: 5 }
      const jsonString = JSON.stringify(originalObj)
      const parsedObj = JSON.parse(jsonString)
      
      expect(parsedObj).toEqual(originalObj)
      expect(parsedObj.message).toBe('Hello')
      expect(parsedObj.count).toBe(5)
    })
  })

  describe('Promise and Async Operations', () => {
    test('should handle resolved promises', async () => {
      const promise = Promise.resolve('success')
      const result = await promise
      expect(result).toBe('success')
    })

    test('should handle rejected promises', async () => {
      const promise = Promise.reject(new Error('test error'))
      await expect(promise).rejects.toThrow('test error')
    })

    test('should handle async functions', async () => {
      const asyncFunction = async () => {
        return new Promise(resolve => {
          setTimeout(() => resolve('async result'), 10)
        })
      }
      
      const result = await asyncFunction()
      expect(result).toBe('async result')
    })
  })
})