/**
 * Test to verify the Date mocking issue - create a failing test
 */
describe('Date Mocking Issue Demo', () => {
  test('should demonstrate the problem with different dates', () => {
    // This will fail because the mock always returns 2023-01-01
    const date = new Date('2024-06-15')
    expect(date.getFullYear()).toBe(2024)  // Should fail - mock returns 2023
    expect(date.getMonth()).toBe(5)        // Should fail - mock returns 0 (January)
  })
  
  test('current test passes by coincidence', () => {
    // This passes because mockDate is also 2023-01-01
    const date = new Date('2023-01-01')
    expect(date.getFullYear()).toBe(2023)  // Passes by luck
    expect(date.getMonth()).toBe(0)        // Passes by luck  
  })
})