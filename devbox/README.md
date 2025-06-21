# DevBox Configuration for AI Foundry SPA

This directory contains the DevBox image definition for the AI Foundry SPA project, providing a consistent development environment across team members.

## 📋 What's Included

The DevBox configuration (`imageDefinition.yaml`) installs and configures:

### System-Level Tasks (Admin)
These run during DevBox provisioning:
- **Node.js LTS** - JavaScript runtime for frontend development
- **Visual Studio Code** - Primary IDE with extensions
- **.NET 8 SDK** - For C# Azure Functions backend development
- **Git** - Source control management
- **Azure CLI** - Infrastructure deployment and management
- **Azure Functions Core Tools** - Local Function App development and testing
- **Python 3.12** - Development scripting and tooling support
- **Bicep Extension** - Infrastructure as Code templates (system-wide)

### User-Level Tasks (Run as User)
These run after user first login:
- **VS Code Extensions** - Development-specific extensions:
  - `ms-vscode.vscode-bicep` - Azure Bicep language support
  - `ms-vscode.azure-account` - Azure account integration
  - `ms-azuretools.vscode-azurefunctions` - Azure Functions development
  - `ms-dotnettools.csharp` - C# language support
  - `ms-dotnettools.vscode-dotnet-runtime` - .NET runtime integration
  - `esbenp.prettier-vscode` - Code formatting
  - `ms-vscode.vscode-eslint` - JavaScript/TypeScript linting
  - `ms-vscode.vscode-json` - JSON language support
  - `GitHub.copilot` - GitHub Copilot AI code assistant
  - `GitHub.copilot-chat` - GitHub Copilot Chat integration
  - `ms-toolsai.vscode-ai-toolkit` - Azure AI Toolkit for AI development
  - `ms-python.python` - Python language support
  - `ms-python.pylint` - Python linting and code analysis
  - `ms-vscode.vscode-dev-containers` - DevContainer and DevBox support
  - `github.vscode-github-actions` - GitHub Actions integration
- **Azurite** - Azure Storage emulator for local development (user-specific installation)
- **Python Development** - User-specific pip and virtualenv setup
- **User workspace directories** - `%USERPROFILE%\Workspaces` and `%USERPROFILE%\.azurite`
- **Environment variables** - User-specific development configuration
- **NPM configuration** - User-specific registry settings

### Base Image
- **Visual Studio 2022 Enterprise** with Windows 11 and Microsoft 365 integration
- Pre-configured with common development tools and enterprise features

## 🚀 Getting Started

1. **Provision the DevBox**: Follow the [official documentation](https://learn.microsoft.com/en-us/azure/dev-box/concept-what-are-team-customizations) to create an image definition resource for your dev boxes.

2. **Clone the Repository**: 
   ```powershell
   git clone <repository-url> %USERPROFILE%\Workspaces\ai-in-a-box
   cd %USERPROFILE%\Workspaces\ai-in-a-box
   ```

3. **Configure Git** (one-time setup):
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

4. **Sign in to Azure**:
   ```powershell
   az login
   ```

5. **Start Development**:
   ```powershell
   # Install frontend dependencies
   cd src\frontend
   npm install
   
   # Start development servers (use VS Code tasks for easier management)
   # 1. Start Azurite emulator
   # 2. Start Function App
   # 3. Start frontend dev server
   ```

## 🛠️ Development Workflow

The DevBox is configured for the standard development workflow:

1. **VS Code Setup**: Extensions auto-installed for complete development experience
   - Bicep IntelliSense for infrastructure development
   - Azure Functions debugging and deployment
   - C# development with full .NET support
   - JavaScript/TypeScript development with ESLint and Prettier
   - GitHub Copilot AI assistance for enhanced coding productivity
   - Azure AI Toolkit for AI model development and deployment
   - Python development with linting and IntelliSense support
   - DevContainer/DevBox integration for consistent environments
   - GitHub Actions workflow integration

2. **Local Development**: Azurite + Function App + Vite dev server
3. **Infrastructure**: Azure CLI + Bicep templates with full IntelliSense
4. **Deployment**: Azure CLI deployment scripts (no azd dependency)
5. **Source Control**: Git with GitHub integration and Actions support

## 📝 Customization Notes

- The configuration uses WinGet package manager for reliable software installation
- **System tasks** run as admin during DevBox provisioning for core software
- **User tasks** run as the logged-in user after first login for user-specific configuration
- **VS Code extensions** are installed per-user for personalized development experience
- Development tools are installed system-wide, but user configuration is personalized
- User workspace directory: `%USERPROFILE%\Workspaces`
- Azurite data directory: `%USERPROFILE%\.azurite`
- Extensions provide full IntelliSense and debugging support for the AI Foundry SPA stack
- GitHub Copilot provides AI-powered code completion and chat assistance
- Python environment configured for development tooling and scripting
- Azure AI Toolkit integrated for AI model development workflows

## 🔗 Related Documentation

- [DevBox Documentation](https://learn.microsoft.com/en-us/azure/dev-box/)
- [Project Setup Guide](../documentation/SETUP.md)
- [Development Container Configuration](../.devcontainer/devcontainer.json)

## ✅ Validation and Troubleshooting

### Quick Validation

Use the provided validation script to check your DevBox setup:

```powershell
# Run basic validation
.\devbox\Test-DevBoxSetup.ps1

# Run detailed validation with version information
.\devbox\Test-DevBoxSetup.ps1 -Detailed

# Skip VS Code extension checks (faster)
.\devbox\Test-DevBoxSetup.ps1 -SkipExtensions
```

This script will verify all system tools, user environment, VS Code extensions, and project structure.

### DevBox Validation Checklist

After DevBox creation, verify the following components:

#### System-Level Tools
- [ ] **Node.js 20**: `node --version` (should show v20.x.x)
- [ ] **.NET 8 SDK**: `dotnet --version` (should show 8.0.x)
- [ ] **Azure CLI**: `az --version` (should show Azure CLI version)
- [ ] **Azure Functions Core Tools**: `func --version` (should show v4.x.x)
- [ ] **Python 3.12**: `python --version` (should show Python 3.12.x)
- [ ] **Git**: `git --version` (should show Git version)
- [ ] **VS Code**: Should be available in Start Menu

#### User-Level Configuration
- [ ] **VS Code Extensions**: Open VS Code and check installed extensions:
  - GitHub Copilot and Copilot Chat should be visible
  - Azure AI Toolkit should be available
  - Python extension should provide IntelliSense
  - Bicep extension should provide syntax highlighting
- [ ] **Azurite**: `azurite --version` (should show Azurite version)
- [ ] **Python pip**: `pip --version` (should show pip version)
- [ ] **Workspace Directory**: `%USERPROFILE%\Workspaces` should exist
- [ ] **Azurite Directory**: `%USERPROFILE%\.azurite` should exist

### Common Issues and Solutions

#### Extension Installation Failures
If VS Code extensions fail to install during userTasks:
1. **Manual Installation**: Open VS Code and install extensions manually:
   ```
   code --install-extension GitHub.copilot
   code --install-extension GitHub.copilot-chat
   code --install-extension ms-toolsai.vscode-ai-toolkit
   ```
2. **Check Network**: Ensure DevBox has internet access for extension downloads
3. **VS Code Update**: Update VS Code if extensions are incompatible

#### Python Configuration Issues
If Python tools don't work correctly:
1. **Path Issues**: Add Python to PATH manually if not accessible
2. **Pip Upgrade**: Run `python -m pip install --user --upgrade pip`
3. **Virtual Environment**: Create test virtual environment: `python -m venv test-env`

#### GitHub Copilot Not Working
If GitHub Copilot doesn't provide suggestions:
1. **Authentication**: Sign in to GitHub through VS Code
2. **Subscription**: Verify GitHub Copilot subscription is active
3. **Extension Activation**: Check VS Code extension is enabled and activated

#### Azure CLI Authentication
If Azure CLI commands fail:
1. **Login**: Run `az login` and complete browser authentication
2. **Subscription**: Set correct subscription: `az account set -s <subscription-id>`
3. **Permissions**: Verify account has required permissions for resources

### Development Workflow Testing

Test the complete development workflow:

1. **Clone Repository**:
   ```powershell
   cd %USERPROFILE%\Workspaces
   git clone <repository-url> ai-in-a-box
   cd ai-in-a-box
   ```

2. **Install Dependencies**:
   ```powershell
   cd src\frontend
   npm install
   cd ..\backend
   dotnet build
   ```

3. **Start Development Servers**:
   ```powershell
   # Terminal 1: Start Azurite
   azurite --silent --location %USERPROFILE%\.azurite
   
   # Terminal 2: Start Function App
   cd src\backend
   func start
   
   # Terminal 3: Start Frontend
   cd src\frontend
   npm run dev
   ```

4. **Verify Endpoints**:
   - Frontend: http://localhost:5173
   - Function App: http://localhost:7071
   - Azurite: Storage emulator running in background

### Performance Optimization

For better DevBox performance:
- **Close Unnecessary Applications**: Keep only essential tools running
- **VS Code Settings**: Disable heavy extensions if not needed
- **Antivirus Exclusions**: Add development folders to antivirus exclusions
- **Windows Updates**: Keep Windows updated for latest performance improvements

### VS Code Extensions Sync
The DevBox configuration installs the same VS Code extensions that are configured in the DevContainer setup, ensuring a consistent development experience whether using DevBox or DevContainer environments. The extensions support:
- Full Bicep IntelliSense and validation
- Azure Functions local debugging and remote deployment
- C# development with .NET 8 support
- Modern JavaScript/TypeScript development with formatting and linting
- GitHub integration for workflow automation
