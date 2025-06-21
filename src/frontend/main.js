import './style.css'
import { AIFoundryClient } from './ai-foundry-client-backend.js'

class ModernChatApp {
  constructor() {
    this.aiClient = new AIFoundryClient()
    this.conversationHistory = []
    this.isTyping = false
    
    this.initializeElements()
    this.bindEvents()
    this.initializeUI()
    this.loadConversationHistory()
  }

  initializeElements() {
    this.elements = {
      messagesContainer: document.getElementById('messages-container'),
      userInput: document.getElementById('user-input'),
      sendBtn: document.getElementById('send-btn'),
      clearBtn: document.getElementById('clear-chat'),
      exportBtn: document.getElementById('export-chat'),
      typingIndicator: document.getElementById('typing-indicator'),
      characterCount: document.querySelector('.character-count')
    }
  }

  bindEvents() {
    // Send message events
    this.elements.sendBtn.addEventListener('click', () => this.handleSendMessage())
    
    // Textarea events
    this.elements.userInput.addEventListener('input', () => this.handleInputEvent())
    this.elements.userInput.addEventListener('keydown', (e) => this.handleKeyDown(e))
    
    // Header actions
    this.elements.clearBtn.addEventListener('click', () => this.clearConversation())
    this.elements.exportBtn.addEventListener('click', () => this.exportConversation())
    
    // Auto-resize textarea
    this.elements.userInput.addEventListener('input', () => this.autoResizeTextarea())
  }

  initializeUI() {
    // Enable send button (public mode)
    this.updateSendButton()
    
    // Set initial character count
    this.updateCharacterCount()
    
    // Focus on input
    this.elements.userInput.focus()
  }

  handleInputChange() {
    this.updateCharacterCount()
    this.updateSendButton()
  }

  handleKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      this.handleSendMessage()
    }
  }

  updateCharacterCount() {
    const count = this.elements.userInput.value.length
    this.elements.characterCount.textContent = `${count}/4000`
    
    if (count > 3800) {
      this.elements.characterCount.style.color = '#dc2626'
    } else if (count > 3500) {
      this.elements.characterCount.style.color = '#f59e0b'
    } else {
      this.elements.characterCount.style.color = '#6b7280'
    }
  }

  updateSendButton() {
    const hasContent = this.elements.userInput.value.trim().length > 0
    const isNotTooLong = this.elements.userInput.value.length <= 4000
    this.elements.sendBtn.disabled = !hasContent || !isNotTooLong || this.isTyping
  }

  autoResizeTextarea() {
    const textarea = this.elements.userInput
    textarea.style.height = 'auto'
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px'
  }

  async handleSendMessage() {
    const message = this.elements.userInput.value.trim()
    if (!message || this.isTyping) return

    try {
      this.isTyping = true
      this.updateSendButton()

      // Remove welcome message if present
      this.removeWelcomeMessage()

      // Add user message
      this.addMessage('user', message)
      
      // Clear input
      this.elements.userInput.value = ''
      this.elements.userInput.style.height = 'auto'
      this.updateCharacterCount()

      // Show typing indicator
      this.showTypingIndicator()

      // Send message to AI
      const response = await this.aiClient.sendMessage(message)
      
      // Hide typing indicator and add AI response
      this.hideTypingIndicator()
      this.addMessage('assistant', response)
      
      // Save conversation
      this.saveConversationHistory()
      
      // Scroll to bottom
      this.scrollToBottom()

    } catch (error) {
      console.error('Error sending message:', error)
      this.hideTypingIndicator()
      this.addMessage('error', `Error: ${error.message}`)
    } finally {
      this.isTyping = false
      this.updateSendButton()
      this.elements.userInput.focus()
    }
  }

  removeWelcomeMessage() {
    const welcomeMessage = this.elements.messagesContainer.querySelector('.welcome-message')
    if (welcomeMessage) {
      welcomeMessage.remove()
    }
  }

  addMessage(role, content) {
    const timestamp = new Date().toLocaleTimeString()
    const messageData = { role, content, timestamp }
    
    // Add to conversation history
    this.conversationHistory.push(messageData)
    
    // Create message element
    const messageElement = this.createMessageElement(messageData)
    
    // Add to DOM
    this.elements.messagesContainer.appendChild(messageElement)
    
    // Scroll to bottom
    this.scrollToBottom()
  }

  createMessageElement({ role, content, timestamp }) {
    const messageDiv = document.createElement('div')
    messageDiv.className = `message ${role}-message`
    
    const avatar = document.createElement('div')
    avatar.className = 'avatar'
    
    if (role === 'user') {
      avatar.innerHTML = '<i class="fas fa-user"></i>'
    } else if (role === 'assistant') {
      avatar.innerHTML = '<i class="fas fa-robot"></i>'
    } else if (role === 'error') {
      avatar.innerHTML = '<i class="fas fa-exclamation-triangle"></i>'
      messageDiv.className = 'message error-message'
    }
    
    const messageContent = document.createElement('div')
    messageContent.className = 'message-content'
    messageContent.innerHTML = this.formatMessage(content)
    
    const messageTimestamp = document.createElement('div')
    messageTimestamp.className = 'message-timestamp'
    messageTimestamp.textContent = timestamp
    
    messageDiv.appendChild(avatar)
    const contentWrapper = document.createElement('div')
    contentWrapper.appendChild(messageContent)
    contentWrapper.appendChild(messageTimestamp)
    messageDiv.appendChild(contentWrapper)
    
    return messageDiv
  }

  formatMessage(content) {
    // Basic markdown-like formatting
    return content
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      .replace(/`(.*?)`/g, '<code>$1</code>')
      .replace(/\n/g, '<br>')
  }

  showTypingIndicator() {
    this.elements.typingIndicator.classList.remove('hidden')
    this.scrollToBottom()
  }

  hideTypingIndicator() {
    this.elements.typingIndicator.classList.add('hidden')
  }

  scrollToBottom() {
    setTimeout(() => {
      const container = document.querySelector('.chat-container')
      container.scrollTop = container.scrollHeight
    }, 100)
  }

  clearConversation() {
    if (this.conversationHistory.length === 0) return
    
    if (confirm('Are you sure you want to clear the conversation? This cannot be undone.')) {
      this.conversationHistory = []
      this.elements.messagesContainer.innerHTML = `
        <div class="welcome-message">
          <div class="welcome-icon">
            <i class="fas fa-comments"></i>
          </div>
          <h2>Welcome to AI Foundry Chat</h2>
          <p>Start a conversation with the CancerBot AI Assistant. Ask questions about cancer research, treatment options, or general health topics.</p>
        </div>
      `
      this.saveConversationHistory()
    }
  }

  exportConversation() {
    if (this.conversationHistory.length === 0) {
      alert('No conversation to export.')
      return
    }
    
    const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-')
    const filename = `ai-chat-export-${timestamp}.txt`
    
    let exportText = `AI Foundry Chat Export\n`
    exportText += `Generated: ${new Date().toLocaleString()}\n`
    exportText += `Messages: ${this.conversationHistory.length}\n`
    exportText += `\n${'='.repeat(50)}\n\n`
    
    this.conversationHistory.forEach((message, index) => {
      const role = message.role === 'user' ? 'You' : 
                   message.role === 'assistant' ? 'CancerBot' : 'System'
      exportText += `[${message.timestamp}] ${role}:\n${message.content}\n\n`
    })
    
    const blob = new Blob([exportText], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = filename
    a.click()
    URL.revokeObjectURL(url)
  }

  saveConversationHistory() {
    try {
      localStorage.setItem('ai-foundry-chat-history', JSON.stringify(this.conversationHistory))
    } catch (error) {
      console.warn('Failed to save conversation history:', error)
    }
  }

  loadConversationHistory() {
    try {
      const saved = localStorage.getItem('ai-foundry-chat-history')
      if (saved) {
        this.conversationHistory = JSON.parse(saved)
        this.renderConversationHistory()
      }
    } catch (error) {
      console.warn('Failed to load conversation history:', error)
      this.conversationHistory = []
    }
  }

  renderConversationHistory() {
    if (this.conversationHistory.length === 0) return
    
    // Remove welcome message
    this.removeWelcomeMessage()
    
    // Render all messages
    this.conversationHistory.forEach(messageData => {
      const messageElement = this.createMessageElement(messageData)
      this.elements.messagesContainer.appendChild(messageElement)
    })
    
    // Scroll to bottom
    this.scrollToBottom()
  }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
  new ModernChatApp()
})
