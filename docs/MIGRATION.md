# Documentation Migration Guide

*Guide for users transitioning from the old documentation structure to the new organized docs.*

## 🎯 What Changed?

The documentation has been completely restructured to create a better, more beginner-friendly experience. Here's how to find what you're looking for in the new structure.

## 📊 Migration Map

### Old `documentation/` Files → New `docs/` Structure

| Old File | New Location | Notes |
|----------|-------------|-------|
| **SETUP.md** | [Getting Started](getting-started/) | Split into 4 progressive guides |
| **DEVELOPMENT.md** | [Local Development](development/local-development.md) | Enhanced with more details |
| **DEPLOYMENT_GUIDE.md** | [Deployment Guide](deployment/deployment-guide.md) | Expanded with more scenarios |
| **CONFIGURATION.md** | [Environment Variables](configuration/environment-variables.md) | More comprehensive reference |
| **INFRASTRUCTURE.md** | [Infrastructure Guide](deployment/infrastructure.md) | Better architecture explanations |
| **TROUBLESHOOTING.md** | [Troubleshooting](operations/troubleshooting.md) | Organized by issue category |
| **MULTI_RG_ARCHITECTURE.md** | [Advanced/Multi-Resource Groups](advanced/multi-resource-groups.md) | Moved to advanced section |
| **AZURE_DEPLOYMENT_ENVIRONMENTS.md** | [Advanced/ADE](advanced/azure-deployment-environments.md) | Consolidated with ADE info |
| **PUBLIC_MODE_SETUP.md** | [Security Guide](advanced/security.md) | Integrated into security guide |

### Bug Fix Documentation (Archived/Consolidated)
These temporary files have been consolidated into permanent guides:

| Old Bug Fix File | Consolidated Into |
|------------------|-------------------|
| **THREAD_PERSISTENCE_FIX.md** | Information moved to project overview and architecture docs |
| **CI_URL_RETRIEVAL_FIX.md** | Solutions incorporated into troubleshooting guide |
| **ADE_PARAMETER_EXTRACTION.md** | Content moved to deployment and configuration guides |
| **HEALTH_ENDPOINT.md** | API details moved to reference documentation |

## 🚀 Quick Navigation for Common Tasks

### "I want to..."

**Deploy the app for the first time**
- **Old**: SETUP.md
- **New**: [Getting Started Journey](getting-started/00-what-is-ai-foundry.md) → [Quick Start](getting-started/03-quick-start.md)

**Set up local development**
- **Old**: DEVELOPMENT.md
- **New**: [Local Development Guide](development/local-development.md)

**Configure environment variables**
- **Old**: CONFIGURATION.md
- **New**: [Environment Variables Reference](configuration/environment-variables.md)

**Deploy to production**
- **Old**: DEPLOYMENT_GUIDE.md
- **New**: [Deployment Guide](deployment/deployment-guide.md)

**Understand the architecture**
- **Old**: INFRASTRUCTURE.md + MULTI_RG_ARCHITECTURE.md
- **New**: [Infrastructure Guide](deployment/infrastructure.md)

**Fix deployment issues**
- **Old**: TROUBLESHOOTING.md + various bug fix docs
- **New**: [Troubleshooting Guide](operations/troubleshooting.md)

**Customize the app**
- **Old**: Scattered across multiple files
- **New**: [Customization Guide](configuration/customization.md)

## 🆕 What's New?

### Beginner-Friendly Content
**New additions not in old docs:**

1. **[What is AI Foundry?](getting-started/00-what-is-ai-foundry.md)**
   - Complete introduction for newcomers
   - Explains concepts before diving into implementation

2. **[Project Overview](getting-started/01-project-overview.md)**
   - Clear explanation of what this project does
   - Architecture overview for beginners

3. **[Prerequisites Guide](getting-started/02-prerequisites.md)**
   - Complete setup requirements
   - Cost estimates and planning

4. **[First Steps](getting-started/04-first-steps.md)**
   - Testing and validation procedures
   - Post-deployment verification

### Enhanced Existing Content

**Better Organization:**
- **Task-oriented structure** - Find info by what you want to do
- **Progressive complexity** - Start simple, dive deeper as needed
- **Cross-references** - Easy navigation between related topics

**More Comprehensive:**
- **Complete command examples** with absolute paths
- **Troubleshooting by category** (deployment, frontend, backend, AI)
- **Environment-specific guidance** (dev, staging, production)

## 📖 New Documentation Structure

```
docs/
├── README.md                          # Documentation hub
├── getting-started/                   # 🆕 Complete beginner journey
│   ├── 00-what-is-ai-foundry.md      # 🆕 AI Foundry introduction
│   ├── 01-project-overview.md        # 🆕 Project capabilities
│   ├── 02-prerequisites.md           # 🆕 Setup requirements
│   ├── 03-quick-start.md             # Enhanced 15-min deployment
│   └── 04-first-steps.md             # 🆕 Testing & validation
├── development/                       # Local development
│   ├── local-development.md          # Enhanced setup guide
│   ├── project-structure.md          # 🔄 Coming soon
│   ├── testing-guide.md              # 🔄 Coming soon
│   └── debugging.md                  # 🔄 Coming soon
├── configuration/                     # Settings and customization
│   ├── environment-variables.md      # Comprehensive reference
│   ├── ai-foundry-setup.md          # 🔄 Coming soon
│   └── customization.md              # 🆕 Complete customization guide
├── deployment/                        # Production deployment
│   ├── infrastructure.md             # Enhanced architecture guide
│   ├── deployment-guide.md           # Enhanced deployment options
│   ├── ci-cd.md                      # 🔄 Coming soon
│   └── multi-environment.md          # 🔄 Coming soon
├── operations/                        # Monitoring and maintenance
│   ├── troubleshooting.md            # Enhanced, organized by category
│   ├── monitoring.md                 # 🔄 Coming soon
│   └── maintenance.md                # 🔄 Coming soon
├── advanced/                          # Deep-dives and architecture
│   ├── architecture-decisions.md     # 🔄 Coming soon
│   ├── multi-resource-groups.md      # 🔄 Coming soon
│   ├── azure-deployment-environments.md # 🔄 Coming soon
│   └── security.md                   # 🔄 Coming soon
└── reference/                         # Technical reference
    ├── api-endpoints.md               # 🔄 Coming soon
    ├── bicep-modules.md               # 🔄 Coming soon
    └── environment-variables-reference.md # 🔄 Coming soon
```

**Legend:**
- 🆕 = New content not in old docs
- 🔄 = Coming soon (being migrated/enhanced)
- No icon = Enhanced version of existing content

## 🔍 Finding Specific Information

### Common Searches

**"How do I fix [specific error]?"**
- **Start here**: [Troubleshooting Guide](operations/troubleshooting.md)
- **Organized by**: Deployment, Frontend, Backend, AI Integration issues

**"What does [configuration setting] do?"**
- **Start here**: [Environment Variables Reference](configuration/environment-variables.md)
- **Includes**: All frontend, backend, and infrastructure settings

**"How do I deploy to [environment]?"**
- **Start here**: [Deployment Guide](deployment/deployment-guide.md)
- **Covers**: Manual, ADE, CI/CD, and code-only deployments

**"I want to understand the architecture"**
- **Start here**: [Infrastructure Guide](deployment/infrastructure.md)
- **Covers**: Multi-resource group design, security, scalability

**"How do I customize [feature]?"**
- **Start here**: [Customization Guide](configuration/customization.md)
- **Covers**: UI, AI agent, features, and deployment customizations

## 💡 Migration Tips

### For Existing Users

**If you have bookmarks to old docs:**
1. **Start with the [Documentation Hub](README.md)** to understand the new structure
2. **Use the task-based navigation** to find what you need quickly
3. **Check the migration map above** for direct file mappings

**If you have scripts referencing old docs:**
1. **Update any documentation links** in your scripts or automation
2. **Check for updated command examples** in the new guides
3. **Verify absolute paths** are used (project requirement)

**If you're training team members:**
1. **Start new users with [Getting Started](getting-started/00-what-is-ai-foundry.md)**
2. **Use task-oriented sections** for specific training topics
3. **Reference the [troubleshooting guide](operations/troubleshooting.md)** for common issues

### For New Users

**Don't use the old `documentation/` folder** - it will be phased out. Instead:

1. **Start with [What is AI Foundry?](getting-started/00-what-is-ai-foundry.md)**
2. **Follow the complete getting started journey**
3. **Use the [Documentation Hub](README.md)** for navigation

## 🚧 Transition Period

### What's Happening

**Current State:**
- ✅ **New docs structure** is live and complete for core scenarios
- ✅ **Old docs** remain available for reference
- ✅ **Main README** updated to point to new structure

**Coming Soon:**
- 🔄 **Complete migration** of remaining specialized content
- 🔄 **Archive old documentation** folder
- 🔄 **Enhanced content** for advanced scenarios

### Timeline

**Phase 1 (Complete):** Core documentation restructure
**Phase 2 (In Progress):** Specialized content migration
**Phase 3 (Coming):** Archive old structure
**Phase 4 (Future):** Enhanced advanced content

## 📞 Need Help?

### Can't Find Something?

1. **Check the [Documentation Hub](README.md)** for task-based navigation
2. **Search the [Troubleshooting Guide](operations/troubleshooting.md)** for specific issues
3. **Create a [GitHub Issue](https://github.com/JFolberth/ai-in-a-box/issues)** if something is missing

### Feedback Welcome

If you:
- **Can't find information** that was in the old docs
- **Have suggestions** for the new structure
- **Find errors or omissions** in the migration

Please **[create a GitHub Issue](https://github.com/JFolberth/ai-in-a-box/issues/new)** with details about what you're looking for.

---

**Ready to explore the new docs?** → Start with the [Documentation Hub](README.md)