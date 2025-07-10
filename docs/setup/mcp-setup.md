# MCP Server Setup Guide

This guide explains how to configure and use Model Context Protocol (MCP) servers for enhanced development experience with the AI Foundry SPA project.

## Overview

MCP (Model Context Protocol) servers provide enhanced integration with external services and documentation. This project includes configuration for:

1. **Microsoft Learn MCP** - Access to Azure, Bicep, .NET, and AI services documentation
2. **GitHub MCP** - Enhanced GitHub repository management and workflow assistance

## Configuration Files

### VS Code Workspace Settings (`.vscode/settings.json`)

The workspace settings include MCP server configuration that applies when working in VS Code:

```json
{
    "mcp.servers": {
        "microsoft.docs.mcp": {
            "url": "https://learn.microsoft.com/api/mcp",
            "name": "Microsoft Learn",
            "description": "Microsoft documentation and API reference for Azure, Bicep, and .NET development"
        },
        "github.mcp": {
            "url": "https://api.githubcopilot.com/mcp/",
            "name": "GitHub Integration", 
            "description": "Enhanced GitHub repository management and integration"
        }
    }
}
```

### MCP Server Definitions (`.vscode/mcp.json`)

Dedicated MCP configuration file with detailed server definitions:

```json
{
    "servers": {
        "microsoft.docs.mcp": {
            "url": "https://learn.microsoft.com/api/mcp",
            "name": "Microsoft Learn",
            "description": "Access to Microsoft documentation and learning resources for Azure, Bicep, .NET, and AI services"
        },
        "github.mcp": {
            "url": "https://api.githubcopilot.com/mcp/",
            "name": "GitHub Integration",
            "description": "Enhanced GitHub repository management, issue tracking, and CI/CD workflow assistance"
        }
    }
}
```

### DevContainer Integration (`.devcontainer/devcontainer.json`)

MCP servers are automatically configured in the DevContainer environment, ensuring consistent access across team members.

## Benefits for AI Foundry SPA Development

### Microsoft Learn MCP

- **Azure Documentation**: Quick access to Azure service documentation and best practices
- **Bicep Reference**: Get Bicep template help, examples, and Azure Verified Module documentation
- **Function Apps**: Access to Azure Functions development guides and troubleshooting
- **Static Web Apps**: Documentation for frontend hosting and deployment
- **AI Services**: AI Foundry, Azure OpenAI, and Cognitive Services documentation
- **DevBox/DevContainer**: Azure development environment setup and configuration guides

### GitHub MCP

- **Repository Management**: Enhanced GitHub integration for repository operations
- **Issue Tracking**: Better issue and pull request management workflows  
- **Code Review**: Improved code review processes and automation
- **CI/CD**: GitHub Actions workflow assistance and troubleshooting
- **Security**: Security scanning and dependency management guidance

## Usage Examples

### Getting Azure Documentation

With Microsoft Learn MCP configured, you can:

1. Ask for specific Azure service documentation
2. Get Bicep template examples and best practices
3. Find troubleshooting guides for Azure Functions
4. Access AI Foundry setup and configuration guides

Example queries:
- "Show me Azure Function App configuration options"
- "How do I configure RBAC for Azure AI services?"
- "What are the best practices for Bicep modules?"

### GitHub Workflow Assistance

With GitHub MCP configured, you can:

1. Get help with GitHub Actions workflow configuration
2. Find best practices for repository management
3. Access troubleshooting guides for CI/CD issues
4. Get assistance with security scanning and compliance

Example queries:
- "How do I set up GitHub Actions for Azure deployment?"
- "What are the security best practices for GitHub repositories?"
- "How do I configure dependabot for my project?"

## Setup for New Team Members

### Using DevContainer (Recommended)

1. Open the project in VS Code
2. Click "Reopen in Container" when prompted
3. MCP servers are automatically configured
4. No additional setup required

### Local Development Setup

1. Ensure VS Code is installed with relevant extensions:
   - GitHub Copilot
   - Azure extensions (Bicep, Functions, etc.)
   
2. Open the project in VS Code
3. MCP servers will be automatically loaded from `.vscode/settings.json`
4. Verify configuration in VS Code settings

### DevBox Environment

1. Create DevBox using the provided configuration
2. Clone the repository
3. Open in VS Code
4. MCP servers are pre-configured and ready to use

## Troubleshooting

### MCP Servers Not Loading

1. **Check VS Code Extensions**: Ensure GitHub Copilot and relevant Azure extensions are installed
2. **Reload Window**: Use `Ctrl+Shift+P` → "Developer: Reload Window"
3. **Check Settings**: Verify MCP configuration in `.vscode/settings.json`
4. **Network Access**: Ensure internet access to MCP server URLs

### Authentication Issues

1. **GitHub**: Ensure you're signed in to GitHub in VS Code
2. **Azure**: Sign in to Azure account through Azure extensions
3. **Copilot**: Verify GitHub Copilot subscription and VS Code authentication

### Configuration Validation

Use these commands to validate JSON configuration:

```bash
# Validate VS Code settings
cat .vscode/settings.json | jq '.'

# Validate MCP configuration  
cat .vscode/mcp.json | jq '.'

# Validate DevContainer configuration
cat .devcontainer/devcontainer.json | jq '.'
```

## Integration with Project Workflows

### Development Workflow

1. **Local Development**: MCP servers provide context-aware assistance during coding
2. **Documentation**: Quick access to relevant Azure and GitHub documentation
3. **Troubleshooting**: AI-powered assistance with debugging and problem resolution
4. **Best Practices**: Guidance on Azure, Bicep, and GitHub best practices

### Deployment Workflow

1. **Infrastructure**: Bicep template assistance and Azure resource documentation
2. **CI/CD**: GitHub Actions workflow optimization and troubleshooting
3. **Monitoring**: Application Insights and Azure monitoring guidance
4. **Security**: RBAC configuration and security best practices

## Related Documentation

- [Local Development](../development/local-development.md) - Local development setup and workflows
- [Configuration Reference](../configuration/configuration-reference.md) - Environment variables and service configuration
- [Public Mode Setup](public-mode-setup.md) - Complete project setup guide
- [DevBox README](../../devbox/README.md) - DevBox environment configuration

## Support

For MCP-related issues:

1. Check this documentation first
2. Review VS Code extension logs
3. Verify internet connectivity to MCP server URLs
4. Consult GitHub Copilot documentation
5. Raise an issue in the project repository

---

*Last Updated: July 2025*  
*MCP Configuration Version: 1.0*
