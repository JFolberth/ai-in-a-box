# AGENTS.md - Documentation

This directory contains comprehensive documentation for the AI Foundry SPA project, organized by functional areas and user needs.

## Documentation Structure

### Core Documentation Areas
- `getting-started/`: New user onboarding and quick start guides
- `deployment/`: Infrastructure deployment and CI/CD documentation
- `development/`: Development environment setup and local testing
- `configuration/`: Environment configuration and customization options
- `architecture/`: System architecture and design decisions
- `api/`: API documentation and endpoint references
- `operations/`: Troubleshooting, monitoring, and maintenance
- `setup/`: Detailed setup guides for different deployment scenarios
- `fixes/`: Known issues, workarounds, and bug fixes

### Key Files
- `README.md`: Documentation overview and navigation guide
- `MIGRATION.md`: Migration guides for version upgrades

## Documentation Standards

### Writing Guidelines
- **Audience-Focused**: Write for specific user personas (developers, operators, end-users)
- **Step-by-Step**: Provide clear, actionable instructions with examples
- **Code Examples**: Include working code samples and command-line examples
- **Cross-Platform**: Ensure instructions work across Windows, Linux, and macOS
- **Screenshots**: Include relevant screenshots for UI-based instructions (when helpful)

### Markdown Standards
```markdown
# Main Title (H1 - used once per document)

## Section Heading (H2 - primary sections)

### Subsection (H3 - detailed topics)

#### Sub-subsection (H4 - specific items)

### Code Blocks with Language Specification
```bash
# Bash commands
az deployment sub create --template-file main.bicep
```

```powershell
# PowerShell commands
Set-Location "C:\repos\ai-in-a-box"
```

```javascript
// JavaScript code
const response = await fetch('/api/health');
```
```

### Content Organization Patterns

#### Prerequisites Section
Always include prerequisites at the beginning of procedural documents:
```markdown
## Prerequisites

- Azure subscription with Contributor access
- Azure CLI version 2.50.0 or higher
- PowerShell 7.0 or higher
- Node.js 18 LTS or higher
```

#### Command Examples
Provide both Windows and Linux examples when applicable:
```markdown
### Windows (PowerShell)
```powershell
Set-Location "C:\repos\ai-in-a-box"
.\deploy-scripts\deploy-quickstart.ps1
```

### Linux/macOS (Bash)
```bash
cd /workspaces/ai-in-a-box
./deploy-scripts/deploy-quickstart.ps1
```
```

## Content Areas

### Getting Started (`getting-started/`)
**Target Audience**: New users, evaluators, quick start scenarios
- **Sequential Learning**: Documents numbered 00-04 for logical progression
- **Practical Focus**: Emphasize hands-on experience over theory
- **Success Criteria**: Each document should have clear "what you'll achieve" outcomes

### Deployment (`deployment/`)
**Target Audience**: DevOps engineers, system administrators
- **Infrastructure as Code**: Focus on Bicep templates and Azure CLI
- **Environment Management**: Dev, staging, production deployment patterns
- **Security Configuration**: RBAC, managed identities, secure secrets handling
- **Automation**: CI/CD pipeline configuration and troubleshooting

### Development (`development/`)
**Target Audience**: Software developers, contributors
- **Local Development**: Complete setup for local testing and development
- **Testing Strategies**: Unit testing, integration testing, E2E testing
- **Code Quality**: Linting, formatting, static analysis guidelines
- **Debugging**: Common debugging scenarios and tools

### Configuration (`configuration/`)
**Target Audience**: System administrators, power users
- **Environment Variables**: Comprehensive reference of all configuration options
- **Customization**: How to modify behavior for specific organizational needs
- **Security Settings**: Security-related configuration options
- **Performance Tuning**: Configuration for optimal performance

### Architecture (`architecture/`)
**Target Audience**: Technical architects, senior developers
- **System Design**: High-level architecture diagrams and explanations
- **Component Interactions**: How different parts of the system communicate
- **Data Flow**: Request/response patterns and data processing
- **Scalability**: Design decisions for handling growth and load

## Documentation Maintenance

### Content Updates
```markdown
### Update Workflow
1. **Identify Outdated Content**: Regular audits for accuracy
2. **Verify Commands**: Test all command examples before publishing
3. **Version Alignment**: Ensure documentation matches current codebase
4. **User Feedback**: Incorporate feedback from documentation users
```

### Review Process
- **Technical Accuracy**: All commands and code examples must be tested
- **Clarity**: Review for readability and comprehension
- **Completeness**: Ensure all necessary steps are documented
- **Consistency**: Maintain consistent style and formatting

### Version Control
- **Git Integration**: All documentation changes tracked in version control
- **Change Documentation**: Document what changed and why in commit messages
- **Release Notes**: Update relevant documentation for each release

## Cross-References and Linking

### Internal Linking Patterns
```markdown
<!-- Link to other documentation -->
For detailed setup instructions, see [Local Development Guide](development/local-development.md).

<!-- Link to specific sections -->
See the [Environment Variables Reference](configuration/environment-variables.md#azure-configuration) for Azure-specific settings.

<!-- Link to code files -->
The main configuration is in [`main-orchestrator.bicep`](../infra/main-orchestrator.bicep).
```

### External Reference Standards
```markdown
<!-- Official Microsoft documentation -->
For more information, see the [Azure Functions documentation](https://docs.microsoft.com/azure/azure-functions/).

<!-- GitHub issues and PRs -->
This addresses issue [#123](https://github.com/JFolberth/ai-in-a-box/issues/123).
```

## Special Documentation Types

### API Documentation (`api/`)
- **OpenAPI/Swagger**: Use standard API documentation formats when possible
- **Request/Response Examples**: Include realistic examples with sample data
- **Error Codes**: Document all possible error conditions and their meanings
- **Authentication**: Clear explanation of authentication requirements

### Troubleshooting (`operations/troubleshooting.md`)
- **Symptom-Based Organization**: Organize by what users experience
- **Solution Steps**: Provide step-by-step resolution instructions
- **Prevention**: Include information on preventing issues
- **Escalation**: When to seek additional help

### Migration Guides (`MIGRATION.md`)
- **Version-Specific**: Clear sections for each version upgrade
- **Breaking Changes**: Highlight changes that require user action
- **Automated Migration**: Provide scripts where possible
- **Rollback Procedures**: Document how to revert if needed

## Content Creation Guidelines

### New Documentation Checklist
- [ ] Identify target audience and their goals
- [ ] Define clear learning objectives or outcomes
- [ ] Research existing related documentation to avoid duplication
- [ ] Test all commands and code examples
- [ ] Review for accessibility and readability
- [ ] Add appropriate cross-references and links
- [ ] Include in appropriate navigation/index files

### Content Review Criteria
- **Accuracy**: All technical content is correct and current
- **Completeness**: All necessary information is included
- **Clarity**: Instructions are easy to follow
- **Consistency**: Follows established style and formatting guidelines
- **Usefulness**: Addresses real user needs and scenarios

## Tools and Automation

### Documentation Tools
- **Markdown Linters**: Use markdownlint for consistency
- **Link Checkers**: Validate internal and external links
- **Spell Checkers**: Maintain professional quality
- **Auto-formatting**: Use Prettier for consistent Markdown formatting

### Automation Opportunities
- **Command Validation**: Automated testing of documented commands
- **Link Checking**: Regular validation of all documentation links
- **Content Freshness**: Automated alerts for outdated content
- **Style Consistency**: Automated formatting and style checking