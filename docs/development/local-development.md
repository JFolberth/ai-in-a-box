# Local Development Environment Setup

*Set up your development environment for customizing and extending the AI Foundry SPA.*

## 🎯 Overview

This guide helps you set up a local development environment where you can:
- Run the frontend and backend locally
- Make changes and see them immediately
- Test integrations with Azure AI Foundry
- Debug issues before deploying to Azure

## 📋 Prerequisites

Before starting, ensure you have these tools installed:

### Required Tools:
- **[Node.js 20+](https://nodejs.org/)** - For frontend development
- **[.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)** - For backend development
- **[Azure Functions Core Tools v4](https://docs.microsoft.com/azure/azure-functions/functions-run-local)** - For local Functions
- **[Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)** - For Azure resource management
- **[Git](https://git-scm.com/)** - For version control

### Optional Tools:
- **[Visual Studio Code](https://code.visualstudio.com/)** - Recommended editor
- **[Azure Tools Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)** - VS Code extensions
- **[Azurite](https://docs.microsoft.com/azure/storage/common/storage-use-azurite)** - Local storage emulator

### Verification:
```bash
# Verify installations
node --version      # Should be 20.0+ or later
npm --version       # Should be 9.0+ or later
dotnet --version    # Should be 8.0+ or later
func --version      # Should be 4.0+ or later
az --version        # Should be 2.50+ or later
git --version       # Any recent version
```

## 🏗️ Project Setup

### 1. Clone and Navigate

```bash
# Clone the repository
git clone https://github.com/JFolberth/ai-in-a-box.git
cd ai-in-a-box
```

### 2. Backend Setup

```bash
# Navigate to backend
cd src/backend

# Restore dependencies
dotnet restore

# Create local settings file
cp local.settings.json.example local.settings.json
```

### 3. Configure Backend Settings

Edit `src/backend/local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AI_FOUNDRY_ENDPOINT": "https://your-ai-foundry.cognitiveservices.azure.com/",
    "AI_FOUNDRY_DEPLOYMENT": "gpt-4",
    "AI_FOUNDRY_AGENT_NAME": "AI in A Box",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-key-here"
  }
}
```

### 4. Frontend Setup

```bash
# Navigate to frontend
cd ../frontend

# Install dependencies
npm install

# Create environment file
cp .env.example .env.local
```

### 5. Configure Frontend Settings

Edit `src/frontend/.env.local`:

```env
# Backend Configuration
VITE_BACKEND_URL=http://localhost:7071/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# AI Foundry Configuration
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box
VITE_AI_FOUNDRY_ENDPOINT=https://your-ai-foundry.cognitiveservices.azure.com/
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4

# Development Settings
VITE_DEBUG_LOGGING=true
```

## 🚀 Running Locally

### Option 1: Manual Startup (Recommended for Development)

**Terminal 1 - Backend:**
```bash
cd src/backend

# Start Azurite (local storage emulator)
azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log &

# Start Functions host
func start --port 7071
```

**Terminal 2 - Frontend:**
```bash
cd src/frontend

# Start development server
npm run dev
```

### Option 2: VS Code Integrated Setup

If using VS Code, you can use the included tasks:

1. **Open VS Code** in the project root
2. **Open Command Palette** (Ctrl/Cmd + Shift + P)
3. **Run Task**: `Tasks: Run Task`
4. **Select**: `Start Local Development`

This will start both frontend and backend simultaneously.

## 🔧 Development Workflow

### Making Changes

**Frontend Changes:**
- Edit files in `src/frontend/`
- Changes auto-reload in browser (hot reload)
- Check browser console for errors

**Backend Changes:**
- Edit files in `src/backend/`
- Functions host automatically reloads
- Check terminal output for errors

### Testing Changes

**Frontend Testing:**
```bash
cd src/frontend

# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

**Backend Testing:**
```bash
cd src/backend

# Run all tests
dotnet test

# Run with detailed output
dotnet test --verbosity normal

# Run specific test
dotnet test --filter "TestMethodName"
```

### Debugging

**Frontend Debugging:**
- Use browser dev tools (F12)
- Set breakpoints in Sources tab
- Check Network tab for API calls
- View Console for errors and logs

**Backend Debugging:**
- Use VS Code debugger with F5
- Set breakpoints in C# code
- Use Azure Functions Core Tools logs
- Check local storage emulator logs

## 🌐 Local URLs

When running locally, your application will be available at:

- **Frontend**: `http://localhost:5173` (or next available port)
- **Backend**: `http://localhost:7071`
- **Health Check**: `http://localhost:7071/api/health`
- **API Base**: `http://localhost:7071/api`

## 🔍 Verification

### Test Local Setup

1. **Check Backend Health:**
```bash
curl http://localhost:7071/api/health
```

2. **Test Frontend Connection:**
- Open `http://localhost:5173` in browser
- Send a test message
- Verify response from AI

3. **Check Integration:**
- Messages should flow: Frontend → Backend → AI Foundry → Backend → Frontend
- Browser network tab should show calls to `localhost:7071`
- Backend terminal should show request logs

## 🚨 Common Issues

### Issue: "Az command not found"
**Solution:**
```bash
# Install Azure CLI
# Windows: Download from Microsoft
# macOS: brew install azure-cli
# Linux: See Azure CLI installation guide
```

### Issue: "Func command not found"
**Solution:**
```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

### Issue: "AI Foundry connection failed"
**Solutions:**
1. **Check endpoint URL** in `local.settings.json`
2. **Verify Azure login**: `az login`
3. **Check AI Foundry permissions** - ensure you have access
4. **Test connection**: Use health endpoint

### Issue: "CORS errors in browser"
**Solution:**
```bash
# Backend should allow frontend origin
# Check that VITE_BACKEND_URL matches function URL
# Verify CORS configuration in Function App
```

### Issue: "Port already in use"
**Solutions:**
```bash
# Kill processes on ports
lsof -ti:7071 | xargs kill  # Backend
lsof -ti:5173 | xargs kill  # Frontend

# Or use different ports
func start --port 7072      # Backend on different port
npm run dev -- --port 5174  # Frontend on different port
```

## 📁 Project Structure

Understanding the codebase structure helps with development:

```
ai-in-a-box/
├── src/
│   ├── frontend/              # JavaScript SPA
│   │   ├── src/              # Source code
│   │   ├── public/           # Static assets
│   │   ├── tests/            # Unit tests
│   │   └── package.json      # Dependencies
│   └── backend/              # C# Azure Functions
│       ├── Functions/        # Function endpoints
│       ├── Models/           # Data models
│       ├── Services/         # Business logic
│       └── Tests/            # Unit tests
├── infra/                    # Bicep infrastructure
├── deploy-scripts/           # Deployment scripts
└── docs/                     # Documentation
```

## 🔗 Next Steps

Once your local environment is working:

1. **[Project Structure](project-structure.md)** - Understand the codebase
2. **[Testing Guide](testing-guide.md)** - Run comprehensive tests
3. **[Debugging Guide](debugging.md)** - Troubleshoot issues
4. **[Customization](../configuration/customization.md)** - Make it your own

## 📖 Related Documentation

- **[Configuration](../configuration/environment-variables.md)** - Environment variable reference
- **[Troubleshooting](../operations/troubleshooting.md)** - Common issues and solutions
- **[Deployment](../deployment/deployment-guide.md)** - Deploy your changes

---

**Ready to start developing?** Your local environment should now be ready for customization and development!