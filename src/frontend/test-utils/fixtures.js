// Test fixtures and sample data

export const sampleMessages = [
  {
    role: 'user',
    content: 'Hello, I have a question about cancer treatment.',
    timestamp: '10:30:00 AM'
  },
  {
    role: 'assistant',
    content: 'Hello! I\'m here to help with your questions. What would you like to know?',
    timestamp: '10:30:15 AM'
  },
  {
    role: 'user',
    content: 'What are the side effects of chemotherapy?',
    timestamp: '10:31:00 AM'
  }
]

export const sampleConversationHistory = [
  {
    role: 'user',
    content: 'Test message 1',
    timestamp: '10:00:00 AM'
  },
  {
    role: 'assistant',
    content: 'Test response 1',
    timestamp: '10:00:15 AM'
  }
]

export const sampleApiResponse = {
  ThreadId: 'thread_test123',
  MessageId: 'msg_test456',
  Response: 'This is a test response from the API',
  AgentName: 'TestBot'
}

export const sampleErrorResponse = {
  message: 'Network error occurred',
  code: 'NETWORK_ERROR'
}

export const sampleHealthResponse = {
  AgentName: 'TestBot',
  Status: 'Healthy',
  Version: '1.0.0'
}

export const sampleEnvironmentConfig = {
  VITE_AI_FOUNDRY_AGENT_NAME: 'TestBot',
  VITE_BACKEND_URL: 'http://localhost:7071/api',
  VITE_USE_BACKEND: 'true',
  VITE_PUBLIC_MODE: 'false'
}