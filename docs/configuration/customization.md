# Customization Guide

*How to customize the AI Foundry SPA for your specific needs.*

## 🎯 Overview

The AI Foundry SPA is designed to be easily customizable. This guide covers the most common customizations, from simple UI changes to advanced AI agent modifications.

## 🎨 UI Customization

### Change Colors and Branding

**Location:** `src/frontend/src/styles/`

**Basic Color Scheme:**
```css
/* src/frontend/src/styles/main.css */

:root {
  /* Primary colors */
  --primary-color: #0078d4;      /* Microsoft Blue */
  --primary-hover: #106ebe;
  --primary-light: #deecf9;
  
  /* Secondary colors */
  --secondary-color: #6c757d;
  --accent-color: #28a745;
  
  /* Background colors */
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --bg-dark: #343a40;
  
  /* Text colors */
  --text-primary: #212529;
  --text-secondary: #6c757d;
  --text-light: #ffffff;
}

/* Custom primary color example */
:root {
  --primary-color: #ff6b35;      /* Orange theme */
  --primary-hover: #e55a2b;
  --primary-light: #ffe4dc;
}
```

**Update Logo and Branding:**
```html
<!-- src/frontend/index.html -->
<head>
  <title>Your AI Assistant</title>
  <link rel="icon" href="/your-favicon.ico">
</head>

<!-- Update header in your main component -->
<header class="chat-header">
  <img src="/your-logo.png" alt="Your Company" class="logo">
  <h1>Your AI Assistant</h1>
</header>
```

### Customize Chat Interface

**Location:** `src/frontend/src/components/`

**Message Styling:**
```css
/* Custom message bubbles */
.message.user {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 18px 18px 4px 18px;
}

.message.assistant {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  color: white;
  border-radius: 18px 18px 18px 4px;
}

/* Add animation effects */
.message {
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

**Custom Input Area:**
```html
<!-- Add send button icon or custom styling -->
<div class="input-container">
  <input type="text" placeholder="Ask your AI assistant..." />
  <button class="send-button">
    <svg><!-- Your custom send icon --></svg>
  </button>
</div>
```

## 🤖 AI Agent Customization

### Change Agent Personality

**Method 1: Update Agent in AI Foundry Portal**

1. **Go to Azure AI Foundry** portal
2. **Find your "AI in A Box" agent**
3. **Edit the system prompt**:

```text
Original prompt:
"You are AI in A Box, a helpful AI assistant..."

Custom prompt examples:

Customer Service Agent:
"You are a helpful customer service representative for [Your Company]. 
You are knowledgeable about our products and services, friendly, and 
professional. Always aim to resolve customer issues efficiently while 
maintaining a positive, empathetic tone."

Technical Documentation Assistant:
"You are a technical documentation assistant specializing in [Your Technology]. 
You provide clear, accurate explanations with practical examples. When users 
ask questions, provide step-by-step solutions and include relevant code 
snippets when helpful."

Personal Productivity Assistant:
"You are a personal productivity assistant. You help users organize their 
tasks, manage their time, and achieve their goals. You're encouraging, 
practical, and always suggest actionable next steps."
```

**Method 2: Create New Agent**

1. **Create new agent** in AI Foundry portal
2. **Update configuration** to use new agent:

```bash
# Update environment variables
az functionapp config appsettings set \
  --name "your-function-app" \
  --resource-group "your-rg" \
  --settings "AI_FOUNDRY_AGENT_NAME=Your Custom Agent"
```

### Add Custom Instructions

**Add context-specific instructions:**

```text
System Prompt Template:
"You are [Agent Name], a [Role Description].

CONTEXT:
- Company: [Your Company Name]
- Industry: [Your Industry]
- Primary Users: [User Description]

CAPABILITIES:
- [List specific capabilities]
- [Domain knowledge areas]
- [Special functions]

GUIDELINES:
- Always [specific behavior 1]
- When asked about [topic], [specific response approach]
- If you don't know something, [fallback behavior]

FORMATTING:
- Use bullet points for lists
- Include relevant links when helpful
- Keep responses concise but thorough"
```

## 🔧 Feature Customization

### Add Custom API Endpoints

**Location:** `src/backend/Functions/`

**Create new Function:**
```csharp
// CustomApiFunction.cs
[Function("CustomApi")]
public async Task<HttpResponseData> RunCustomApi(
    [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "custom")] HttpRequestData req)
{
    var logger = req.FunctionContext.GetLogger("CustomApi");
    
    // Your custom logic here
    var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
    var customResult = ProcessCustomRequest(requestBody);
    
    var response = req.CreateResponse(HttpStatusCode.OK);
    await response.WriteAsJsonAsync(customResult);
    return response;
}

private object ProcessCustomRequest(string requestBody)
{
    // Implement your custom business logic
    return new { result = "Custom processing complete", timestamp = DateTime.UtcNow };
}
```

**Update Frontend to Use Custom API:**
```javascript
// src/frontend/src/services/customApi.js
export class CustomApiService {
    constructor(baseUrl) {
        this.baseUrl = baseUrl;
    }

    async callCustomEndpoint(data) {
        const response = await fetch(`${this.baseUrl}/custom`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            throw new Error(`Custom API error: ${response.statusText}`);
        }

        return await response.json();
    }
}
```

### Add Authentication

**For Enterprise Use Cases:**

**1. Update Frontend:**
```javascript
// src/frontend/src/auth/authService.js
import { PublicClientApplication } from '@azure/msal-browser';

const msalConfig = {
    auth: {
        clientId: 'your-app-registration-client-id',
        authority: 'https://login.microsoftonline.com/your-tenant-id'
    }
};

export class AuthService {
    constructor() {
        this.msalInstance = new PublicClientApplication(msalConfig);
    }

    async login() {
        const result = await this.msalInstance.loginPopup();
        return result.accessToken;
    }

    async getToken() {
        const accounts = this.msalInstance.getAllAccounts();
        if (accounts.length > 0) {
            const result = await this.msalInstance.acquireTokenSilent({
                scopes: ['https://your-api.com/.default'],
                account: accounts[0]
            });
            return result.accessToken;
        }
        return null;
    }
}
```

**2. Update Backend:**
```csharp
// Add authentication to Function App
[Function("ChatWithAuth")]
public async Task<HttpResponseData> RunWithAuth(
    [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
{
    // Validate JWT token
    var token = req.Headers.GetValues("Authorization").FirstOrDefault()?.Replace("Bearer ", "");
    var user = await ValidateTokenAsync(token);
    
    if (user == null)
    {
        var unauthorizedResponse = req.CreateResponse(HttpStatusCode.Unauthorized);
        return unauthorizedResponse;
    }

    // Continue with authenticated request
    // ...
}
```

### Add File Upload Support

**Backend Function:**
```csharp
[Function("FileUpload")]
public async Task<HttpResponseData> UploadFile(
    [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "upload")] HttpRequestData req)
{
    var formData = await MultipartFormDataParser.ParseAsync(req.Body);
    var file = formData.Files.FirstOrDefault();
    
    if (file != null)
    {
        // Process file (save to blob storage, analyze content, etc.)
        var blobClient = new BlobClient("connection-string", "container", file.FileName);
        await blobClient.UploadAsync(file.Data);
        
        // Optionally send file content to AI for analysis
        var fileAnalysis = await AnalyzeFileWithAI(file);
        
        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(new { 
            fileName = file.FileName, 
            analysis = fileAnalysis 
        });
        return response;
    }
    
    var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
    return badResponse;
}
```

**Frontend Component:**
```javascript
// File upload component
export class FileUploadComponent {
    constructor(apiService) {
        this.apiService = apiService;
    }

    async uploadFile(file) {
        const formData = new FormData();
        formData.append('file', file);

        const response = await fetch(`${this.apiService.baseUrl}/upload`, {
            method: 'POST',
            body: formData
        });

        return await response.json();
    }

    createUploadUI() {
        return `
            <div class="file-upload">
                <input type="file" id="fileInput" accept=".pdf,.doc,.txt">
                <button onclick="this.handleUpload()">Upload and Analyze</button>
            </div>
        `;
    }
}
```

## 🎨 Advanced UI Customization

### Add Dark Mode

**CSS Variables for Theme Switching:**
```css
/* Light theme (default) */
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f8f9fa;
  --text-primary: #212529;
  --text-secondary: #6c757d;
  --border-color: #dee2e6;
}

/* Dark theme */
[data-theme="dark"] {
  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --text-primary: #ffffff;
  --text-secondary: #b0b0b0;
  --border-color: #404040;
}

/* Apply theme variables */
body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}
```

**Theme Toggle Component:**
```javascript
export class ThemeToggle {
    constructor() {
        this.currentTheme = localStorage.getItem('theme') || 'light';
        this.applyTheme();
    }

    toggle() {
        this.currentTheme = this.currentTheme === 'light' ? 'dark' : 'light';
        this.applyTheme();
        localStorage.setItem('theme', this.currentTheme);
    }

    applyTheme() {
        document.documentElement.setAttribute('data-theme', this.currentTheme);
    }

    createToggleButton() {
        return `
            <button class="theme-toggle" onclick="themeToggle.toggle()">
                ${this.currentTheme === 'light' ? '🌙' : '☀️'}
            </button>
        `;
    }
}
```

### Add Typing Indicators

**JavaScript Implementation:**
```javascript
export class TypingIndicator {
    constructor(container) {
        this.container = container;
    }

    show() {
        const indicator = document.createElement('div');
        indicator.className = 'typing-indicator';
        indicator.innerHTML = `
            <div class="typing-dots">
                <span></span>
                <span></span>
                <span></span>
            </div>
        `;
        this.container.appendChild(indicator);
    }

    hide() {
        const indicator = this.container.querySelector('.typing-indicator');
        if (indicator) {
            indicator.remove();
        }
    }
}
```

**CSS Animation:**
```css
.typing-indicator {
    display: flex;
    align-items: center;
    padding: 10px;
    margin: 5px 0;
}

.typing-dots {
    display: flex;
    gap: 4px;
}

.typing-dots span {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background-color: var(--text-secondary);
    animation: typing 1.4s infinite;
}

.typing-dots span:nth-child(2) {
    animation-delay: 0.2s;
}

.typing-dots span:nth-child(3) {
    animation-delay: 0.4s;
}

@keyframes typing {
    0%, 60%, 100% {
        transform: translateY(0);
        opacity: 0.5;
    }
    30% {
        transform: translateY(-10px);
        opacity: 1;
    }
}
```

## 🔧 Configuration Customization

### Environment-Specific Settings

**Create custom environment configs:**
```javascript
// src/frontend/environments/custom.js
export const environment = {
    production: true,
    apiBaseUrl: 'https://your-custom-domain.com/api',
    aiFoundryEndpoint: 'https://your-ai-foundry.cognitiveservices.azure.com/',
    agentName: 'Your Custom Agent',
    
    // Custom features
    enableFileUpload: true,
    enableDarkMode: true,
    enableAuthentication: true,
    maxMessageLength: 2000,
    
    // Branding
    companyName: 'Your Company',
    logoUrl: '/assets/your-logo.png',
    primaryColor: '#your-brand-color',
    
    // Feature flags
    features: {
        voiceInput: false,
        messageExport: true,
        conversationHistory: true
    }
};
```

### Custom Deployment Scripts

**Create environment-specific deployment:**
```powershell
# deploy-custom.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$CustomDomain,
    
    [string]$AgentName = "Your Custom Agent"
)

# Set environment-specific variables
$ResourcePrefix = "your-company-ai"
$Location = if ($Environment -eq "prod") { "eastus2" } else { "centralus" }

# Deploy with custom parameters
az deployment sub create `
    --template-file "infra/main-orchestrator.bicep" `
    --parameters `
        "applicationName=$ResourcePrefix" `
        "environmentName=$Environment" `
        "location=$Location" `
        "aiFoundryAgentName=$AgentName" `
        "customDomainName=$CustomDomain"

# Custom post-deployment configuration
./scripts/configure-custom-domain.ps1 -Domain $CustomDomain
./scripts/setup-monitoring.ps1 -Environment $Environment
```

## 📱 Mobile Responsiveness

### Optimize for Mobile

**Responsive CSS:**
```css
/* Mobile-first approach */
.chat-container {
    width: 100%;
    max-width: 100vw;
    height: 100vh;
    display: flex;
    flex-direction: column;
}

/* Tablet and up */
@media (min-width: 768px) {
    .chat-container {
        max-width: 800px;
        margin: 0 auto;
        height: 80vh;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }
}

/* Mobile input adjustments */
@media (max-width: 767px) {
    .input-container {
        padding: 10px;
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: var(--bg-primary);
        border-top: 1px solid var(--border-color);
    }
    
    .message-input {
        font-size: 16px; /* Prevents zoom on iOS */
        min-height: 44px; /* Touch target size */
    }
}
```

### Touch-Friendly Features

**Swipe Gestures:**
```javascript
export class TouchGestures {
    constructor(element) {
        this.element = element;
        this.startX = 0;
        this.startY = 0;
        
        element.addEventListener('touchstart', this.handleTouchStart.bind(this));
        element.addEventListener('touchmove', this.handleTouchMove.bind(this));
        element.addEventListener('touchend', this.handleTouchEnd.bind(this));
    }

    handleTouchStart(e) {
        this.startX = e.touches[0].clientX;
        this.startY = e.touches[0].clientY;
    }

    handleTouchMove(e) {
        // Prevent default scrolling behavior when needed
        if (this.isHorizontalSwipe(e)) {
            e.preventDefault();
        }
    }

    handleTouchEnd(e) {
        const endX = e.changedTouches[0].clientX;
        const endY = e.changedTouches[0].clientY;
        
        const deltaX = endX - this.startX;
        const deltaY = endY - this.startY;
        
        // Detect swipe direction
        if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50) {
            if (deltaX > 0) {
                this.onSwipeRight();
            } else {
                this.onSwipeLeft();
            }
        }
    }

    onSwipeRight() {
        // Show conversation history
        this.showSidebar();
    }

    onSwipeLeft() {
        // Hide conversation history
        this.hideSidebar();
    }
}
```

## 🚀 Deployment Customization

### Custom Domain Setup

**DNS Configuration:**
```bash
# Add CNAME record pointing to Static Web App
# your-domain.com -> your-static-app.azurestaticapps.net

# Configure custom domain in Azure
az staticwebapp hostname set \
    --name "your-static-app" \
    --resource-group "your-rg" \
    --hostname "ai.your-domain.com"
```

**SSL Certificate:**
```bash
# Azure automatically provides SSL for custom domains
# Or use your own certificate
az staticwebapp hostname set \
    --name "your-static-app" \
    --resource-group "your-rg" \
    --hostname "ai.your-domain.com" \
    --certificate-source "your-certificate"
```

## 📋 Customization Checklist

### UI Customization:
- [ ] Updated colors and branding
- [ ] Custom logo and favicon
- [ ] Modified chat interface styling
- [ ] Added dark mode support
- [ ] Optimized for mobile devices

### AI Agent Customization:
- [ ] Updated agent personality/prompt
- [ ] Configured domain-specific knowledge
- [ ] Added custom instructions
- [ ] Tested agent responses

### Feature Customization:
- [ ] Added custom API endpoints
- [ ] Implemented authentication (if needed)
- [ ] Added file upload support
- [ ] Created custom UI components

### Deployment Customization:
- [ ] Configured custom domain
- [ ] Set up SSL certificates
- [ ] Created environment-specific configs
- [ ] Updated deployment scripts

## 🔗 Related Documentation

- **[Local Development](../development/local-development.md)** - Testing your customizations
- **[Environment Variables](environment-variables.md)** - Configuration options
- **[Deployment Guide](../deployment/deployment-guide.md)** - Deploying customizations
- **[Troubleshooting](../operations/troubleshooting.md)** - Fixing customization issues

---

**Ready to make it your own?** Start with simple UI changes and gradually add more advanced features as needed.