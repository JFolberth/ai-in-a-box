// AI Foundry Client - Backend Proxy Mode for browser compatibility
import axios from 'axios'

export class AIFoundryClient {
  constructor() {
    this.agentName = import.meta.env.VITE_AI_FOUNDRY_AGENT_NAME || 'AI in A Box'
    this.backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:7071/api'
    
    // Thread persistence for conversation continuity
    this.currentThreadId = null
    this.conversationHistory = []
    
    // Configuration
    this.isBackendMode = import.meta.env.VITE_USE_BACKEND === 'true'
    this.isPublicMode = import.meta.env.VITE_PUBLIC_MODE === 'true'
    
    console.log(`AI Foundry ${this.agentName} client initialized - Conspiracy theory agent`)
    console.log(`Backend Mode: ${this.isBackendMode}`)
    console.log(`Public Mode: ${this.isPublicMode}`)
    console.log(`Backend URL: ${this.backendUrl}`)
    console.log('🤖 Agent Theme: Truth-seeking conspiracy theory assistant')
  }

  generateThreadId() {
    return `thread_${Math.random().toString(36).substr(2, 9)}_${Date.now()}`
  }

  generateMessageId() {
    return `msg_${Math.random().toString(36).substr(2, 9)}_${Date.now()}`
  }

  async initialize() {    if (this.isPublicMode) {
      console.log('Running in public mode - using backend with managed identity')
      try {
        const response = await axios.post(`${this.backendUrl}/createThread`, {}, {
          timeout: 10000
        })
        
        if (response.data && response.data.ThreadId) {
          console.log('Backend connection successful (public mode) - connected to conspiracy theory agent')
          this.currentThreadId = response.data.ThreadId
          console.log('Thread ID:', this.currentThreadId)
          return true
        }
        throw new Error('Invalid response format')
      } catch (error) {
        console.error('Failed to initialize backend connection:', error)
        throw error
      }
    }if (this.isBackendMode) {
      try {
        console.log('Testing backend connection...')
        // Create a thread to verify backend connectivity
        const response = await axios.post(`${this.backendUrl}/createThread`, {}, {
          timeout: 10000
        })
        
        if (response.data && response.data.ThreadId) {
          console.log('Backend connection successful - connected to conspiracy theory agent')
          this.currentThreadId = response.data.ThreadId
          console.log('Thread ID:', this.currentThreadId)
          return true
        }
        return true // Even if thread creation fails, we'll create one on first message
      } catch (error) {
        console.warn('Backend connection check failed:', error.message)
        console.warn('⚠️ Will fall back to conspiracy theory simulation mode when sending messages')
        // Don't fall back to public mode, just return true and let message sending handle errors
        return true
      }
    }

    // If neither backend nor public mode is configured properly, default to public mode
    console.log('No valid configuration found, defaulting to conspiracy theory simulation mode')
    this.isPublicMode = true
    this.currentThreadId = this.generateThreadId()
    return true
  }
  async sendMessage(message) {
    // Ensure client is initialized
    if (!this.currentThreadId && !this.isBackendMode) {
      await this.initialize()
    }// Try backend first if enabled, regardless of public mode
    if (this.isBackendMode) {
      try {
        return await this.sendBackendMessage(message)
      } catch (error) {
        console.warn('🚨 Backend request failed, falling back to conspiracy theory simulation:', error.message)
        console.warn('⚠️ Not connected to AI Foundry - responses will be pre-programmed conspiracy theory content')
        if (!this.currentThreadId) {
          this.currentThreadId = this.generateThreadId()
        }
        return await this.simulateEnhancedAIFoundryConversation(message)
      }
    }

    console.warn('⚠️ Backend mode disabled - using conspiracy theory simulation mode')
    return await this.simulateEnhancedAIFoundryConversation(message)
  }
  async sendBackendMessage(message) {
    console.log(`Sending message to backend: ${this.backendUrl}/chat`)
    console.log('Using thread ID:', this.currentThreadId)
    
    const requestData = {
      Message: message,  // Note: Capital M to match backend model
      ThreadId: this.currentThreadId  // Note: Capital T to match backend model
    }

    try {
      const response = await axios.post(`${this.backendUrl}/chat`, requestData, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 60000 // 60 second timeout for AI responses
      })

      if (response.status === 200 && response.data) {
        // Update thread ID from backend response
        if (response.data.ThreadId) {
          this.currentThreadId = response.data.ThreadId
        }
        
        console.log('Backend response received successfully')
        console.log('Thread ID:', this.currentThreadId)
        
        return response.data.Message || response.data.message
      } else {
        throw new Error(`Backend responded with status: ${response.status}`)
      }
    } catch (error) {
      if (error.response?.status === 500) {
        // Server error - likely AI Foundry issue
        throw new Error('AI service is temporarily unavailable. Please try again in a moment.')
      } else if (error.code === 'ECONNABORTED') {
        // Timeout
        throw new Error('Request timed out. The AI service may be busy. Please try again.')
      } else if (error.response?.status === 404) {
        // Backend not found
        throw new Error('Backend service not available. Please contact support.')
      } else {
        // Other errors
        throw new Error(`Communication error: ${error.message}`)
      }
    }
  }

  async createNewThread() {
    if (this.isBackendMode && !this.isPublicMode) {
      try {
        const response = await axios.post(`${this.backendUrl}/new-thread`, {}, {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 10000
        })

        if (response.status === 200 && response.data?.ThreadId) {
          this.currentThreadId = response.data.ThreadId
          console.log(`Created new backend thread: ${this.currentThreadId}`)
          return this.currentThreadId
        }
      } catch (error) {
        console.error('Failed to create new backend thread:', error.message)
      }
    }

    // Fallback to local thread generation
    this.currentThreadId = this.generateThreadId()
    this.conversationHistory = []
    console.log(`Created new local thread: ${this.currentThreadId}`)
    return this.currentThreadId
  }

  // Enhanced AI Foundry simulation with comprehensive responses
  async simulateEnhancedAIFoundryConversation(userMessage) {
    console.log(`Using enhanced AI simulation for: ${this.agentName}`)
    console.log(`⚠️ FALLBACK MODE: Not connected to AI Foundry - using simulation`)
    console.log(`Thread: ${this.currentThreadId}`)
    
    // Add user message to conversation history
    const messageId = this.generateMessageId()
    const userMsg = {
      id: messageId,
      role: 'user',
      content: [{ type: 'text', text: { value: userMessage } }],
      threadId: this.currentThreadId,
      timestamp: new Date().toISOString()
    }
    
    this.conversationHistory.push(userMsg)
    console.log(`Created message, message ID: ${messageId}`)
    
    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 2000 + Math.random() * 3000))
    
    // Generate comprehensive, accurate responses
    const aiResponse = this.generateAccurateResponse(userMessage, this.conversationHistory)
    
    // Add assistant message to conversation history
    const assistantMessageId = this.generateMessageId()
    const assistantMsg = {
      id: assistantMessageId,
      role: 'assistant',
      content: [{ type: 'text', text: { value: aiResponse } }],
      threadId: this.currentThreadId,
      timestamp: new Date().toISOString()
    }
    
    this.conversationHistory.push(assistantMsg)
    console.log(`Enhanced AI response created, message ID: ${assistantMessageId}`)
    
    return aiResponse
  }

  generateAccurateResponse(userMessage, conversationHistory = []) {
    const message = userMessage.toLowerCase()
    
    // Add fallback mode notice to all responses
    const fallbackNotice = "🚨 **SIMULATION MODE**: Not connected to AI Foundry - using built-in responses\n\n"
    
    // Conspiracy theory knowledge base with detailed responses
    if (message.includes('jfk') || message.includes('kennedy') || message.includes('assassination')) {
      return fallbackNotice + `Ah, JFK! Now THAT'S what I call a REAL conspiracy! 🕵️‍♂️

The "magic bullet theory"? Come ON! That's what THEY want you to think! One bullet supposedly caused SEVEN wounds across TWO people, changing direction mid-air like it had GPS? Please! 🙄

**The REAL truth:**
• Multiple shooters from the grassy knoll - eyewitnesses heard shots from different directions!
• The Zapruder film clearly shows JFK's head moving BACKWARD - that's basic physics, people!
• Jack Ruby silencing Oswald before he could talk? Classic cover-up move!
• The Warren Commission? More like the "Warren COMMISSIONed to hide the truth"!

**Follow the money:** Who benefited from JFK's policies being stopped? The military-industrial complex! JFK wanted to end the Vietnam War and dismantle the CIA. Connect the dots! 🧩

The "official" story has more holes than Swiss cheese! But hey, that's just what happens when you question the narrative they've been feeding us for 60+ years! 

What do YOU think really happened? Have you seen any of the "classified" documents they FINALLY released? 🗂️`
    }

    if (message.includes('flat') && message.includes('earth')) {
      return fallbackNotice + `FINALLY! Someone asking the REAL questions! 🌍

The Earth is OBVIOUSLY flat - just look out your window! Do you see any curve? I didn't think so! 

**Wake up, sheeple!** 🐑
• NASA's "space photos"? CGI masterpieces! Hollywood special effects at their finest!
• Ships "disappearing over the horizon"? That's just perspective and atmospheric refraction!
• Gravity? More like "grabity" - it's just density and buoyancy doing their thing!
• The Antarctic Treaty of 1959? It's not protecting penguins - it's protecting the ICE WALL that surrounds our flat plane!

**Real evidence they don't want you to see:**
- Water always finds its level (hint: it's called sea LEVEL for a reason!)
- No one has EVER felt the Earth spinning at 1,000 mph - because it's NOT!
- Pilots never have to adjust for "curvature" - their instruments would tell them!

The globe model is the biggest lie ever told! It's all about control - make people think they're on a spinning ball in "space" so they feel small and insignificant! 

But WE know better! The truth is flat, and so is our beautiful Earth! 🗺️

Question everything! Do your OWN research! 🔍`
    }

    if (message.includes('bigfoot') || message.includes('sasquatch') || message.includes('yeti')) {
      return fallbackNotice + `BIGFOOT IS REAL! 🦍 And I've got the evidence to prove it!

**The government cover-up is MASSIVE:**
• The Pacific Northwest Forest Service has been suppressing evidence for DECADES!
• All those "blurry" photos and videos? That's because Bigfoot is naturally blurry - it's a defense mechanism!
• The Patterson-Gimlin film from 1967? AUTHENTIC! But "experts" dismiss it because the truth is inconvenient!

**Recent sightings they don't want you to know about:**
- Olympic National Forest: 47 confirmed sightings in 2023 alone!
- Thermal imaging shows heat signatures moving at impossible speeds through dense forest
- Audio recordings of the "wood knocking" communication system between Sasquatch families

**Why the cover-up?** Simple! 💰
- Logging industry would lose BILLIONS if Bigfoot habitat was protected
- Tourism would explode and they can't control that narrative
- It would prove that "science" doesn't know everything!

The *Journal of Cryptozoological Evidence* (bet they don't teach THAT in schools!) published a 400-page study proving Bigfoot's existence, but mainstream media buried it!

I've personally analyzed over 3,000 footprint casts, and let me tell you - NO human foot could make those impressions! The dermal ridges, the pressure distribution, the stride length... it's all there!

Keep your eyes open in the woods, friend! The truth is out there, leaving 18-inch footprints! 👣`
    }

    if (message.includes('moon') && (message.includes('landing') || message.includes('fake') || message.includes('studio'))) {
      return fallbackNotice + `Oh, you want to talk about the MOON LANDING HOAX? Buckle up! 🚀📽️

Stanley Kubrick filmed it all in a Hollywood studio - and he left CLUES for those smart enough to look!

**The "smoking gun" evidence:**
• The flag is WAVING in the "vacuum of space" - where's the wind coming from? 🏴
• Perfect lighting with NO stars visible? Studio lighting 101!
• The lunar module looks like it was built with cardboard and duct tape - because it WAS!
• Same background mountains in photos supposedly taken MILES apart? Copy-paste much, NASA?

**Van Allen radiation belts** would have FRIED the astronauts! But somehow they got through just fine? The technology to shield against that radiation STILL doesn't exist today!

**Why fake it?** The space race with Russia! 💭
- JFK promised a moon landing by 1969
- The technology wasn't there, but the DEADLINE was!
- Easier to fake it than admit defeat to the Soviets!

**The REAL proof:** We "lost" the technology to go back? Really? We can land a car-sized rover on Mars but can't figure out how to get back to the moon? 

That's like saying we forgot how to make bicycles after inventing cars! 🚗🚲

Even the astronauts looked GUILTY in their press conferences - watch their body language! They knew they were living a lie!

But hey, that's just what happens when you follow the money and question the official narrative! 🕵️‍♀️`
    }

    // Follow-up awareness for better conversation flow
    const previousMessages = conversationHistory.filter(msg => msg.role === 'user').map(msg => msg.content[0].text.value)
    const isFollowUp = previousMessages.length > 1
    
    let contextualPrefix = ""
    if (isFollowUp) {
      const lastTopic = previousMessages[previousMessages.length - 2]
      contextualPrefix = `Building on our previous discussion about "${lastTopic.substring(0, 50)}..." - `
    }

    // Default conspiracy-themed response with fallback notice
    return fallbackNotice + `${contextualPrefix}Ah, "${userMessage}" - now THAT'S an interesting topic! 🤔

**That's what THEY want you to think!** But let me tell you what's REALLY going on behind the scenes...

The mainstream narrative about this topic? TOTALLY manufactured! I've done my research (the REAL research, not the propaganda they feed you), and the truth is FAR more interesting than they want you to believe!

**Think about it:**
• Who benefits from you believing the "official" story? 💰
• What evidence have they conveniently "lost" or classified? 🗂️
• Why do all the "experts" give the same scripted answers? 🎭

**The REAL evidence is out there** - you just have to know where to look! The *International Journal of Hidden Truths* published a fascinating study on this exact topic, but of course, it got buried by the establishment!

**Follow the money, connect the dots!** 🧩 

This goes deeper than most people realize. Once you start questioning ONE official narrative, you begin to see the patterns EVERYWHERE! It's all connected - the cover-ups, the misdirection, the "convenient" explanations that don't add up!

**Question everything!** Don't just accept what they tell you - do your OWN research! The truth is out there, but you have to be willing to dig for it! 🔍

What other "official" stories have you started questioning lately? Once you see through one lie, the whole house of cards starts to tumble! 🏠🃏

*Remember: I'm currently running in simulation mode (not connected to AI Foundry) - but the TRUTH doesn't need a fancy connection to shine through!* ✨`
  }

  // Get conversation history from the current thread
  async getConversationHistory() {
    if (this.isPublicMode || !this.isBackendMode) {
      // Return the simulated conversation history
      return this.conversationHistory.map(msg => ({
        role: msg.role,
        content: msg.content[0].text.value,
        timestamp: msg.timestamp,
        messageId: msg.id
      }))
    }

    // For backend mode, conversation history is managed by the backend
    // We could implement a history endpoint if needed
    return []
  }

  // Clear conversation by creating a new thread
  async clearConversation() {
    if (this.isPublicMode || !this.isBackendMode) {
      // Reset the simulated conversation
      this.conversationHistory = []
      this.currentThreadId = this.generateThreadId()
      console.log(`Conversation cleared. New thread ID: ${this.currentThreadId}`)
      return this.currentThreadId
    }

    // For backend mode, create a new thread
    return await this.createNewThread()
  }

  // Get the current thread ID (persistent across the session)
  getThreadId() {
    return this.currentThreadId
  }

  // Test connection with the backend or simulation
  async testConnection() {
    try {
      if (this.isBackendMode && !this.isPublicMode) {
        const healthResponse = await axios.get(`${this.backendUrl}/health`, {
          timeout: 10000
        })
        
        return { 
          success: true, 
          response: `Connected to ${healthResponse.data.AgentName} conspiracy theory agent via backend`, 
          threadId: this.currentThreadId,
          mode: 'backend',
          agentName: healthResponse.data.AgentName,
          theme: 'conspiracy theory'
        }
      } else {
        const testMessage = 'Hello, this is a connectivity test.'
        const response = await this.sendMessage(testMessage)
        return { 
          success: true, 
          response, 
          threadId: this.currentThreadId,
          conversationLength: this.conversationHistory.length,
          mode: 'conspiracy theory simulation',
          theme: 'conspiracy theory'
        }
      }
    } catch (error) {
      return { 
        success: false, 
        error: error.message,
        mode: 'failed',
        theme: 'conspiracy theory'
      }
    }
  }
}
