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
- **Azure Functions Core Tools v4** - Local Function App development and testing (installed via npm for reliability)
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
  - `github.vscode-github-actions` - GitHub Actions integration
- **Azurite** - Azure Storage emulator for local development (user-specific installation)
- **Azure Functions Core Tools verification** - Ensures tools are properly installed and accessible
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
   - GitHub Actions workflow integration

2. **Local Development**: Azurite + Function App + Vite dev server
3. **Infrastructure**: Azure CLI + Bicep templates with full IntelliSense
4. **Deployment**: Azure CLI deployment scripts (no azd dependency)
5. **Source Control**: Git with GitHub integration and Actions support

## 📝 Customization Notes

- The configuration uses WinGet package manager for reliable software installation
- **Azure Functions Core Tools** is installed via npm instead of WinGet for better reliability (WinGet package has known issues)
- **System tasks** run as admin during DevBox provisioning for core software
- **User tasks** run as the logged-in user after first login for user-specific configuration
- **VS Code extensions** are installed per-user for personalized development experience
- Development tools are installed system-wide, but user configuration is personalized
- User workspace directory: `%USERPROFILE%\Workspaces`
- Azurite data directory: `%USERPROFILE%\.azurite`
- Extensions provide full IntelliSense and debugging support for the AI Foundry SPA stack

## 🔗 Related Documentation

- [DevBox Documentation](https://learn.microsoft.com/en-us/azure/dev-box/)
- [Project Setup Guide](../documentation/SETUP.md)
- [Development Container Configuration](../.devcontainer/devcontainer.json)

### VS Code Extensions Sync
The DevBox configuration installs the same VS Code extensions that are configured in the DevContainer setup, ensuring a consistent development experience whether using DevBox or DevContainer environments. The extensions support:
- Full Bicep IntelliSense and validation
- Azure Functions local debugging and remote deployment
- C# development with .NET 8 support
- Modern JavaScript/TypeScript development with formatting and linting
- GitHub integration for workflow automation
