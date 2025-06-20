import './style.css'
import { AIFoundryClient } from './ai-foundry-client-backend.js'

class App {
  constructor() {
    this.aiClient = new AIFoundryClient()
    this.conversationHistory = []
    
    this.initializeElements()
    this.bindEvents()
    this.initializeUI()
    this.initializeAI()
  }

  initializeElements() {
    this.elements = {
      userInfo: document.getElementById('user-info'),
      userInput: document.getElementById('user-input'),
      sendBtn: document.getElementById('send-btn'),
      responseContainer: document.getElementById('response-container'),
      historyContainer: document.getElementById('history-container')
    }
  }

  bindEvents() {
    this.elements.sendBtn.addEventListener('click', () => this.handleSendMessage())
    this.elements.userInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        this.handleSendMessage()
      }
    })
  }

  initializeUI() {
    // Set welcome message for public mode
    this.elements.userInfo.textContent = `Welcome! Chat with ${import.meta.env.VITE_AI_FOUNDRY_AGENT_NAME || 'CancerBot'} AI Agent`
    // Enable the send button
    this.elements.sendBtn.disabled = false
  }  async handleSendMessage() {
    const message = this.elements.userInput.value.trim()
    if (!message) return

    try {
      this.elements.sendBtn.disabled = true
      this.elements.sendBtn.textContent = 'Sending...'

      // Clear previous response and show loading state
      this.elements.responseContainer.innerHTML = `
        <div class="response-message loading">
          <div class="response-content">🤔 Thinking...</div>
          <div class="response-timestamp">${new Date().toLocaleTimeString()}</div>
        </div>
      `

      // Add user message to conversation immediately
      this.addToConversation('user', message)
      this.elements.userInput.value = ''
        // Send message to AI Foundry (public mode - no authentication)
      const response = await this.aiClient.sendMessage(message)
      
      // Add AI response to conversation
      this.addToConversation('assistant', response)
      
      // Update response container with latest response
      this.updateResponseContainer(response)
      
      // Scroll to bottom of history
      this.elements.historyContainer.scrollTop = this.elements.historyContainer.scrollHeight

    } catch (error) {
      console.error('Error sending message:', error)
      this.addToConversation('error', `Error: ${error.message}`)
    } finally {
      this.elements.sendBtn.disabled = false
      this.elements.sendBtn.textContent = 'Send Message'
    }
  }

  addToConversation(role, content) {
    const timestamp = new Date().toLocaleTimeString()
    this.conversationHistory.push({ role, content, timestamp })
    this.updateHistoryContainer()
  }  updateResponseContainer(response) {
    const newHTML = `
      <div class="response-message">
        <div class="response-content">${this.formatResponse(response)}</div>
        <div class="response-timestamp">${new Date().toLocaleTimeString()}</div>
      </div>
    `    
    this.elements.responseContainer.innerHTML = newHTML
  }

  updateHistoryContainer() {
    if (this.conversationHistory.length === 0) {
      this.elements.historyContainer.innerHTML = '<p class="placeholder">Conversation history will appear here...</p>'
      return
    }

    const historyHTML = this.conversationHistory.map(item => `
      <div class="history-item ${item.role}">
        <div class="history-role">${item.role === 'user' ? 'You' : item.role === 'assistant' ? 'AI' : 'Error'}</div>
        <div class="history-content">${this.formatResponse(item.content)}</div>
        <div class="history-timestamp">${item.timestamp}</div>
      </div>
    `).join('')

    this.elements.historyContainer.innerHTML = historyHTML
    this.elements.historyContainer.scrollTop = this.elements.historyContainer.scrollHeight
  }

  formatResponse(content) {
    // Basic formatting for better readability
    return content
      .replace(/\n/g, '<br>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
  }
  clearConversation() {
    this.conversationHistory = []
    this.elements.responseContainer.innerHTML = '<p class="placeholder">Your AI response will appear here...</p>'
    this.elements.historyContainer.innerHTML = '<p class="placeholder">Conversation history will appear here...</p>'
    
    // Clear the AI client's conversation thread
    this.aiClient.clearConversation()
  }

  async initializeAI() {
    try {
      console.log('Initializing AI Foundry client...')
      await this.aiClient.initialize()
      console.log('AI client initialization complete')
    } catch (error) {
      console.error('AI client initialization failed:', error)
      // App will continue to work with simulated responses
    }
  }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new App()
})
