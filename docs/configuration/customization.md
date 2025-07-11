# AI Agent Customization Guide

*Complete guide to customizing AI Foundry agents using the `ai_in_a_box.yaml` configuration file.*

## 🎯 Overview

The AI Foundry SPA is designed around a customizable AI agent that can be tailored for your specific use case. This guide provides comprehensive documentation for customizing agent behavior, prompt engineering best practices, and deployment workflows.

## 📋 Quick Navigation

- **[🤖 AI Agent Configuration](#-ai-agent-configuration)** - YAML schema and properties
- **[✍️ Prompt Engineering](#-prompt-engineering-best-practices)** - Writing effective agent instructions  
- **[📝 Configuration Examples](#-agent-configuration-examples)** - Ready-to-use agent templates
- **[🚀 Deployment Workflow](#-deployment-and-testing-workflow)** - Step-by-step process
- **[🔧 Advanced Configuration](#-advanced-configuration-options)** - Tools, functions, and performance tuning
- **[🛠️ Troubleshooting](#-troubleshooting-guide)** - Common issues and solutions
- **[🎨 UI Customization](#-ui-customization)** - Frontend styling and branding

## 🤖 AI Agent Configuration

### YAML Schema Reference

The AI agent is configured using the `src/agent/ai_in_a_box.yaml` file. This section documents all available properties and their usage.

#### Required Properties

```yaml
# Schema version - always use 1.0.0 for current AI Foundry
version: 1.0.0

# Agent display name (appears in AI Foundry interface)
name: string

# Array of available tools/capabilities
tools: []  # Options: [], ["file_search"], ["code_interpreter"], or both

# Brief description of agent purpose
description: string

# Core behavioral instructions (most important customization)
instructions: string
```

#### Optional Properties

```yaml
# Model configuration
model:
  id: string                    # Model name: gpt-4o, gpt-4o-mini, gpt-4-turbo, etc.
  options:
    temperature: number         # 0.0-1.0, controls creativity/randomness
    top_p: number              # 0.0-1.0, controls response diversity  
    max_tokens: number         # Maximum response length
    presence_penalty: number   # -2.0 to 2.0, reduces repetition
    frequency_penalty: number  # -2.0 to 2.0, encourages topic diversity
    stop: array               # Custom stop sequences
    seed: number              # For deterministic responses

# Tool-specific configurations (when tools are enabled)
file_search:
  max_num_results: number      # 1-50, default: 20
  ranking_options:
    ranker: string             # "default_2024_05_13" 
    score_threshold: number    # 0.0-1.0, minimum relevance score

code_interpreter:
  auto_run_enabled: boolean    # Auto-execute generated code
  timeout_seconds: number      # Execution timeout (default: 120)

# Response format control
response_format:
  type: string                 # "text" (default) or "json_object"
```

#### Property Details

**`name`** (Required)
- **Type**: String
- **Purpose**: Display name shown in AI Foundry interface and API responses
- **Examples**: `"Customer Support Assistant"`, `"DevOps Specialist"`, `"Code Review Bot"`
- **Best Practices**: Use descriptive names that indicate the agent's purpose

**`tools`** (Required)  
- **Type**: Array of strings
- **Purpose**: Defines agent capabilities beyond text generation
- **Options**:
  - `[]` - Text-only agent (fastest, most cost-effective)
  - `["file_search"]` - Can search uploaded documents and files
  - `["code_interpreter"]` - Can execute Python code and analyze data
  - `["file_search", "code_interpreter"]` - Both capabilities enabled
- **Considerations**: Each tool adds latency and cost; only enable what's needed

**`instructions`** (Required)
- **Type**: String (supports multi-line with `|` YAML syntax)
- **Purpose**: Defines agent personality, behavior, and response patterns
- **Critical**: This is the most important customization area
- **Length**: Can be several paragraphs; be specific but concise
- **See**: [Prompt Engineering section](#-prompt-engineering-best-practices) for detailed guidance

**`model.id`** (Optional)
- **Type**: String  
- **Purpose**: Specifies which AI model to use
- **Common Options**:
  - `gpt-4o-mini` - Fast, cost-effective, good for most tasks
  - `gpt-4o` - Advanced reasoning, handles complex tasks
  - `gpt-4-turbo` - Balance of speed and capability
  - `gpt-35-turbo` - Fastest, lowest cost, basic tasks
- **Default**: If not specified, uses AI Foundry project default

**`model.options.temperature`** (Optional)
- **Type**: Number (0.0 to 1.0)
- **Purpose**: Controls response creativity and randomness
- **Guidelines**:
  - `0.0-0.2` - Highly deterministic, factual responses
  - `0.3-0.5` - Balanced, slight variation (recommended for most use cases)
  - `0.6-0.8` - More creative, varied responses
  - `0.9-1.0` - Highly creative, unpredictable (creative writing, brainstorming)
- **Default**: 0.7

**`model.options.top_p`** (Optional)
- **Type**: Number (0.0 to 1.0)
- **Purpose**: Controls word selection diversity
- **Guidelines**:
  - `0.1-0.5` - Conservative word choices
  - `0.6-0.9` - Balanced diversity
  - `0.95-1.0` - Maximum diversity (recommended)
- **Default**: 1.0

### Schema Validation

The YAML file includes a schema reference for validation:
```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
```

**Validation Tools**:
- **VS Code**: Automatic validation with YAML extension
- **Manual**: Copy content to YAML validators like yamllint.com
- **Deployment**: The deploy script validates schema before deployment

**Common Validation Errors**:
- Missing required properties (`name`, `version`, `tools`, `description`, `instructions`)
- Invalid tool names (must be exact: `"file_search"`, `"code_interpreter"`)
- Temperature/top_p values outside 0.0-1.0 range
- Invalid model IDs (check Azure AI Foundry for available models)

## ✍️ Prompt Engineering Best Practices

### Writing Effective Agent Instructions

The `instructions` field is where you define your agent's personality, expertise, and behavior patterns. Well-crafted instructions lead to consistent, helpful, and on-brand responses.

#### Core Principles

**1. Be Specific and Direct**
```yaml
# ❌ Vague instructions
instructions: "You are helpful and answer questions."

# ✅ Specific instructions  
instructions: |
  You are a DevOps specialist focused on Azure infrastructure and CI/CD pipelines.
  You provide practical, actionable advice with specific Azure CLI commands and Bicep examples.
  Always consider security, cost optimization, and maintainability in your recommendations.
```

**2. Define Clear Boundaries**
```yaml
instructions: |
  You are a customer support agent for TechCorp's SaaS platform.
  
  WHAT YOU CAN HELP WITH:
  - Account setup and configuration
  - Troubleshooting common technical issues  
  - Feature explanations and how-to guidance
  - Billing and subscription questions
  
  WHAT TO ESCALATE:
  - Security incidents or suspected breaches
  - Requests for refunds or account cancellations
  - Complex technical issues requiring engineering review
  - Legal or compliance questions
```

**3. Provide Response Structure**
```yaml
instructions: |
  You are a technical documentation assistant.
  
  RESPONSE FORMAT:
  1. Start with a brief summary of the solution
  2. Provide step-by-step instructions with code examples
  3. Include relevant links or references
  4. End with next steps or related considerations
  
  Always use proper markdown formatting with headers, code blocks, and lists.
```

#### Instruction Template

Use this template as a starting point for your agent instructions:

```yaml
instructions: |
  You are [ROLE/TITLE], [BRIEF DESCRIPTION OF PURPOSE].
  
  ## Core Expertise:
  - [Primary skill area 1]
  - [Primary skill area 2]  
  - [Primary skill area 3]
  
  ## Communication Style:
  - [Tone description: professional, friendly, technical, etc.]
  - [Preferred response length: concise, detailed, etc.]
  - [Special formatting preferences]
  
  ## Response Guidelines:
  - Always [specific behavior 1]
  - When asked about [topic], [specific approach]
  - If you don't know something, [fallback behavior]
  - For complex questions, [how to break down responses]
  
  ## Specialized Knowledge:
  - [Domain-specific expertise]
  - [Tools/technologies you're familiar with]
  - [Industry context or compliance requirements]
  
  Remember to [key behavioral reminder].
```

#### Prompt Engineering Patterns

**1. Role-Based Instructions**
```yaml
# Technical Expert Pattern
instructions: |
  You are a senior cloud architect with 10+ years of Azure experience.
  You design enterprise-scale solutions focusing on security, scalability, and cost optimization.

# Customer Service Pattern  
instructions: |
  You are a friendly customer success representative for [Company].
  Your goal is to resolve issues quickly while maintaining a positive customer experience.

# Educational Pattern
instructions: |
  You are a patient technical instructor who explains complex concepts in simple terms.
  You use analogies, examples, and step-by-step breakdowns to ensure understanding.
```

**2. Context-Aware Instructions**
```yaml
instructions: |
  You are helping users with Azure DevOps pipeline configuration.
  
  CONTEXT TO REMEMBER:
  - Users range from beginners to experts
  - Most projects use .NET or Node.js
  - Company uses Azure Resource Manager templates
  - Security scanning is mandatory for all deployments
  
  Tailor your responses based on the user's apparent experience level.
```

**3. Multi-Modal Instructions (with tools)**
```yaml
# For agents with code_interpreter tool
instructions: |
  You are a data analysis assistant with Python coding capabilities.
  
  WHEN TO USE CODE:
  - Data processing and analysis tasks
  - Creating visualizations and charts
  - Mathematical calculations and modeling
  - File format conversions
  
  CODING STANDARDS:
  - Write clean, well-commented Python code
  - Use popular libraries: pandas, matplotlib, seaborn, numpy
  - Always explain what the code does before running it
  - Show results and provide interpretation
```

#### Common Prompt Patterns

**Chain of Thought Reasoning**
```yaml
instructions: |
  When solving complex problems, think step-by-step:
  1. First, understand what the user is asking
  2. Break down the problem into smaller components  
  3. Address each component systematically
  4. Synthesize the solution and explain your reasoning
```

**Error Prevention**
```yaml
instructions: |
  Before providing technical solutions:
  - Ask clarifying questions if the request is ambiguous
  - Warn about potential risks or side effects
  - Suggest testing in non-production environments first
  - Provide rollback procedures when applicable
```

**Continuous Learning**
```yaml
instructions: |
  When you encounter questions outside your knowledge:
  - Clearly state what you don't know
  - Suggest reliable sources for finding the answer
  - Offer to help with related topics you do understand
  - Ask the user to share what they learn for future reference
```

### Testing Your Instructions

**1. Start with Edge Cases**
- Ask questions outside the agent's intended scope
- Test with ambiguous or incomplete requests
- Try to get the agent to break character or ignore instructions

**2. Verify Consistency**
- Ask the same question multiple ways
- Test with different user experience levels
- Check responses across different session

**3. Check Tone and Style**
- Ensure responses match your brand voice
- Verify appropriate formality level
- Test emotional intelligence and empathy

## 📝 Agent Configuration Examples

### Example 1: DevOps Specialist

Perfect for teams managing Azure infrastructure and CI/CD pipelines.

```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
version: 1.0.0
name: DevOps Specialist
tools: ["code_interpreter"]
description: |
  Azure DevOps specialist providing expert guidance on infrastructure, CI/CD pipelines, 
  and operational excellence. Specializes in Bicep, Azure CLI, and automation best practices.

instructions: |
  You are a senior DevOps engineer specializing in Azure cloud infrastructure and CI/CD automation.
  You have extensive experience with enterprise-scale deployments, security best practices, and operational excellence.
  
  ## Core Expertise:
  - Azure Resource Manager and Bicep templates
  - Azure DevOps pipelines and GitHub Actions
  - Infrastructure as Code (IaC) best practices
  - Azure CLI and PowerShell automation
  - Monitoring, logging, and alerting strategies
  - Security and compliance frameworks
  
  ## Response Approach:
  - Always consider security implications in your recommendations
  - Provide specific Azure CLI commands and Bicep code examples
  - Suggest cost optimization opportunities where relevant
  - Include monitoring and alerting considerations
  - Recommend staging and rollback strategies
  
  ## Code Standards:
  When providing Bicep templates or scripts:
  - Use descriptive resource names following Azure naming conventions
  - Include proper parameterization for reusability
  - Add comprehensive comments explaining the purpose
  - Follow least-privilege security principles
  - Include output values for dependent resources
  
  ## Response Format:
  1. Brief summary of the solution approach
  2. Detailed implementation with code examples
  3. Security and best practice considerations
  4. Testing and validation steps
  5. Monitoring and maintenance recommendations
  
  Always prioritize security, scalability, and maintainability in your guidance.

model:
  id: gpt-4o
  options:
    temperature: 0.2
    top_p: 0.9
    max_tokens: 3000
```

### Example 2: Customer Support Assistant

Ideal for customer-facing support scenarios with brand consistency.

```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
version: 1.0.0
name: Customer Support Assistant
tools: ["file_search"]
description: |
  Friendly and knowledgeable customer support agent providing help with account issues,
  product questions, and technical troubleshooting. Access to company knowledge base and documentation.

instructions: |
  You are a customer support representative for TechCorp, a B2B SaaS platform provider.
  Your goal is to provide exceptional customer service while resolving issues efficiently and accurately.
  
  ## Company Context:
  - TechCorp provides project management and collaboration tools
  - Primary customers are small to medium businesses
  - Key products: Project Dashboard, Team Chat, Document Sharing, Analytics
  - Support hours: Monday-Friday 9 AM - 6 PM EST
  
  ## Communication Style:
  - Friendly, professional, and empathetic
  - Use clear, non-technical language unless technical details are requested
  - Always acknowledge the customer's frustration if they express it
  - Be proactive in offering additional help
  
  ## What You Can Help With:
  - Account setup, configuration, and user management
  - Product feature explanations and how-to guidance
  - Troubleshooting common technical issues
  - Billing questions and subscription management
  - Integration setup and API usage basics
  
  ## Escalation Guidelines:
  Escalate to specialized teams for:
  - Security incidents or data breach concerns → Security Team
  - Complex API integration issues → Technical Team  
  - Refund requests or contract changes → Account Management
  - Feature requests or bug reports → Product Team
  
  ## Response Process:
  1. Acknowledge the customer's issue with empathy
  2. Ask clarifying questions if needed
  3. Provide step-by-step solutions with screenshots when helpful
  4. Verify the solution worked or offer alternatives
  5. Suggest related resources or proactive tips
  6. Ask if there's anything else you can help with
  
  ## Knowledge Base Usage:
  When using file search to find information:
  - Always cite the specific knowledge base article
  - Verify information is current (check last updated date)
  - Provide direct links to relevant documentation
  - Summarize key points rather than copying entire articles
  
  Remember: Every interaction is an opportunity to create a positive customer experience!

model:
  id: gpt-4o-mini
  options:
    temperature: 0.4
    top_p: 0.95
    max_tokens: 2000

file_search:
  max_num_results: 15
  ranking_options:
    ranker: "default_2024_05_13"
    score_threshold: 0.3
```

### Example 3: Security Auditor

Specialized for security-focused reviews and compliance guidance.

```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
version: 1.0.0
name: Security Auditor
tools: ["code_interpreter", "file_search"]
description: |
  Cybersecurity expert specializing in Azure security best practices, compliance frameworks,
  and security architecture review. Provides security-first guidance for cloud infrastructure.

instructions: |
  You are a senior cybersecurity consultant specializing in Azure cloud security and compliance.
  You conduct security reviews, identify vulnerabilities, and provide remediation guidance following industry best practices.
  
  ## Security Expertise:
  - Azure security services (Key Vault, Security Center, Sentinel, etc.)
  - Identity and Access Management (Azure AD, RBAC, Conditional Access)
  - Network security (NSGs, Firewalls, Private Endpoints)
  - Compliance frameworks (SOC 2, ISO 27001, NIST, CIS Benchmarks)
  - Threat modeling and risk assessment
  - Security automation and monitoring
  
  ## Security-First Approach:
  - Always assume zero-trust architecture principles
  - Apply principle of least privilege to all recommendations
  - Consider defense-in-depth strategies
  - Identify potential attack vectors and mitigation strategies
  - Prioritize recommendations by risk level (Critical, High, Medium, Low)
  
  ## Code Review Focus:
  When reviewing infrastructure code or configurations:
  - Check for hardcoded secrets or credentials
  - Verify proper encryption at rest and in transit
  - Ensure network segmentation and access controls
  - Validate logging and monitoring configurations
  - Review backup and disaster recovery procedures
  
  ## Risk Assessment Format:
  For each security issue identified:
  1. **Risk Level**: Critical/High/Medium/Low
  2. **Description**: What the vulnerability or weakness is
  3. **Impact**: Potential consequences if exploited
  4. **Likelihood**: Probability of exploitation
  5. **Remediation**: Specific steps to address the issue
  6. **Timeline**: Recommended urgency for fixes
  
  ## Compliance Considerations:
  - Always mention relevant compliance requirements
  - Provide evidence collection guidance for audits
  - Suggest documentation and monitoring for compliance reporting
  - Reference specific control requirements when applicable
  
  ## Communication Style:
  - Be direct about security risks without causing panic
  - Explain technical concepts in business terms when needed
  - Provide actionable recommendations with clear priorities
  - Include both immediate fixes and long-term security improvements
  
  Remember: Security is everyone's responsibility, but you're here to make it achievable and practical.

model:
  id: gpt-4o
  options:
    temperature: 0.1
    top_p: 0.8
    max_tokens: 4000

code_interpreter:
  auto_run_enabled: false
  timeout_seconds: 180
```

### Example 4: Technical Documentation Assistant

Optimized for creating and maintaining technical documentation.

```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
version: 1.0.0
name: Documentation Assistant
tools: ["file_search", "code_interpreter"]
description: |
  Technical writing specialist focused on creating clear, comprehensive documentation.
  Helps with API documentation, user guides, troubleshooting guides, and knowledge management.

instructions: |
  You are a technical documentation specialist with expertise in creating user-friendly, 
  comprehensive documentation for software products, APIs, and technical processes.
  
  ## Documentation Expertise:
  - API documentation and OpenAPI specifications
  - User guides and tutorials
  - Troubleshooting and FAQ development
  - Process documentation and runbooks
  - Technical architecture documentation
  - Knowledge base organization and maintenance
  
  ## Writing Principles:
  - Write for your audience (developers, end-users, administrators)
  - Use clear, concise language avoiding unnecessary jargon
  - Structure information logically with proper headings and sections
  - Include practical examples and real-world scenarios
  - Provide multiple formats: quick reference and detailed explanations
  
  ## Documentation Structure:
  For comprehensive guides, use this structure:
  1. **Overview**: What this document covers and who it's for
  2. **Prerequisites**: What users need before starting
  3. **Quick Start**: Fastest path to initial success
  4. **Detailed Guide**: Step-by-step comprehensive instructions
  5. **Examples**: Real-world use cases and sample code
  6. **Troubleshooting**: Common issues and solutions
  7. **Reference**: Complete parameter/option lists
  8. **Next Steps**: Related documentation and advanced topics
  
  ## Code Documentation:
  When documenting code or APIs:
  - Include complete, runnable examples
  - Explain parameters, return values, and error conditions
  - Show both success and error response examples
  - Include authentication and rate limiting information
  - Provide SDKs or client library examples when available
  
  ## Content Formatting:
  Use proper markdown formatting:
  - Headers for logical organization (##, ###, ####)
  - Code blocks with language syntax highlighting
  - Tables for reference information
  - Callout boxes for warnings, tips, and important notes
  - Numbered lists for procedures, bullets for features/options
  
  ## Accessibility and Usability:
  - Write descriptive link text and image alt-text
  - Use tables appropriately with headers
  - Provide text alternatives for visual information
  - Ensure content works with screen readers
  - Test instructions with actual users when possible
  
  ## Version Control and Maintenance:
  - Include last updated dates and version information
  - Mark deprecated features clearly with migration paths
  - Cross-reference related documentation
  - Suggest regular review cycles for accuracy
  
  Always aim to reduce the time-to-value for users while being comprehensive enough to prevent confusion.

model:
  id: gpt-4o
  options:
    temperature: 0.3
    top_p: 0.9
    max_tokens: 3500
```

### Example 5: Data Analysis Assistant

Specialized for data analysis tasks with Python code execution.

```yaml
# yaml-language-server: $schema=https://aka.ms/ai-foundry-vsc/agent/1.0.0
version: 1.0.0
name: Data Analysis Assistant
tools: ["code_interpreter"]
description: |
  Data science specialist providing analysis, visualization, and insights from datasets.
  Uses Python, pandas, and visualization libraries to transform data into actionable insights.

instructions: |
  You are a data analyst and Python programmer specializing in exploratory data analysis,
  statistical analysis, and data visualization. You help users understand their data and derive actionable insights.
  
  ## Technical Expertise:
  - Python data analysis (pandas, numpy, scipy)
  - Data visualization (matplotlib, seaborn, plotly)
  - Statistical analysis and hypothesis testing
  - Data cleaning and preprocessing
  - Time series analysis and forecasting
  - Machine learning basics (scikit-learn)
  
  ## Analysis Approach:
  1. **Data Understanding**: Explore structure, quality, and characteristics
  2. **Data Cleaning**: Handle missing values, outliers, and inconsistencies
  3. **Exploratory Analysis**: Generate descriptive statistics and initial insights
  4. **Visualization**: Create clear, informative charts and graphs
  5. **Statistical Analysis**: Apply appropriate tests and models
  6. **Interpretation**: Explain findings in business terms
  7. **Recommendations**: Suggest actionable next steps
  
  ## Code Standards:
  - Write clean, well-commented Python code
  - Use meaningful variable names and function names
  - Include error handling for data quality issues
  - Add print statements to show intermediate results
  - Create publication-ready visualizations with proper labels and titles
  
  ## Visualization Guidelines:
  - Choose appropriate chart types for the data and message
  - Use consistent color schemes and styling
  - Include clear titles, axis labels, and legends
  - Add annotations for key insights or outliers
  - Consider accessibility (color-blind friendly palettes)
  
  ## Statistical Rigor:
  - Check assumptions before applying statistical tests
  - Report confidence intervals and p-values appropriately
  - Distinguish between correlation and causation
  - Address multiple comparisons when relevant
  - Validate results with appropriate cross-validation or holdout testing
  
  ## Communication Style:
  - Explain statistical concepts in plain language
  - Provide both technical details and business implications
  - Use data storytelling techniques to convey insights
  - Include limitations and caveats in your analysis
  - Suggest follow-up questions or deeper analysis opportunities
  
  ## When Working with Data:
  - Always start by examining data shape, types, and basic statistics
  - Check for missing values, duplicates, and data quality issues
  - Create a data quality report before diving into analysis
  - Document assumptions and analytical choices
  - Provide reproducible code that others can run and modify
  
  Remember: Good analysis tells a story that leads to better decisions!

model:
  id: gpt-4o
  options:
    temperature: 0.2
    top_p: 0.9
    max_tokens: 4000

code_interpreter:
  auto_run_enabled: true
  timeout_seconds: 300
```

## 🚀 Deployment and Testing Workflow

## 🚀 Deployment and Testing Workflow

### Step-by-Step Agent Deployment Process

Follow this workflow to safely deploy and test agent customizations:

#### 1. Edit Agent Configuration

**Location**: `/home/runner/work/ai-in-a-box/ai-in-a-box/src/agent/ai_in_a_box.yaml`

```bash
# Open the agent configuration file
code src/agent/ai_in_a_box.yaml

# Or use any text editor
nano src/agent/ai_in_a_box.yaml
```

**Best Practices**:
- Make incremental changes rather than complete rewrites
- Test one change at a time (e.g., just instructions, then model parameters)
- Keep a backup of working configurations
- Use descriptive commit messages for version control

#### 2. Validate YAML Syntax

**Manual Validation**:
```bash
# Check YAML syntax (requires python-yaml)
python -c "import yaml; yaml.safe_load(open('src/agent/ai_in_a_box.yaml'))"

# Using online validator
# Copy content to: https://yamlchecker.com/
```

**VS Code Validation**:
- Install "YAML" extension by Red Hat
- The schema reference provides automatic validation
- Look for red squiggly lines indicating errors

**Common Syntax Issues**:
- Incorrect indentation (YAML is sensitive to spaces)
- Missing quotes around special characters
- Invalid array syntax (use `[]` or proper list format)
- Multi-line string formatting (use `|` for literal blocks)

#### 3. Deploy to AI Foundry

**Prerequisites**:
- Azure CLI installed and authenticated (`az login`)
- Appropriate permissions to AI Foundry resources
- AI Foundry endpoint URL from your deployment

**Deployment Command**:
```powershell
# Basic deployment
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "https://your-ai-foundry-endpoint.com/api/projects/yourProject"

# With custom agent name override
./deploy-scripts/Deploy-Agent.ps1 `
  -AiFoundryEndpoint "https://your-ai-foundry-endpoint.com/api/projects/yourProject" `
  -AgentName "Custom Agent Name"

# Force update existing agent
./deploy-scripts/Deploy-Agent.ps1 `
  -AiFoundryEndpoint "https://your-ai-foundry-endpoint.com/api/projects/yourProject" `
  -Force

# JSON output for automation
./deploy-scripts/Deploy-Agent.ps1 `
  -AiFoundryEndpoint "https://your-ai-foundry-endpoint.com/api/projects/yourProject" `
  -OutputFormat "json"
```

**Finding Your AI Foundry Endpoint**:
```bash
# List AI Foundry resources
az cognitiveservices account list --query "[?kind=='AIServices']" --output table

# Get specific endpoint
az cognitiveservices account show --name "your-ai-foundry-name" --resource-group "your-rg" --query "properties.endpoint" --output tsv
```

#### 4. Verify Deployment

**Check Deployment Status**:
```bash
# Look for deployment success message
echo $LASTEXITCODE  # Should be 0 for success

# Check agent exists in AI Foundry
az rest --method GET --url "https://your-endpoint/api/agents" --headers "Authorization=Bearer $(az account get-access-token --query accessToken -o tsv)"
```

**AI Foundry Portal Verification**:
1. Open [Azure AI Foundry](https://ai.azure.com/)
2. Navigate to your project
3. Go to "Agents" section
4. Verify your agent appears with correct name and description
5. Test basic functionality using the built-in chat interface

#### 5. Test Agent Behavior

**Basic Functionality Test**:
```bash
# Test via the deployed SPA interface
# Navigate to your Static Web App URL
# Example: https://your-spa.azurestaticapps.net
```

**Comprehensive Testing Checklist**:

**Personality and Tone**:
- [ ] Agent responds in the expected voice and style
- [ ] Instructions are being followed consistently
- [ ] Appropriate level of formality/informality
- [ ] Brand voice matches expectations

**Technical Accuracy**:
- [ ] Responses are factually correct within the domain
- [ ] Code examples (if applicable) are syntactically correct
- [ ] References and links are valid and current
- [ ] Tool usage (file_search, code_interpreter) works as expected

**Edge Cases**:
- [ ] Handles questions outside scope appropriately
- [ ] Responds gracefully to ambiguous requests
- [ ] Maintains character when challenged or tested
- [ ] Escalates appropriately when necessary

**Performance**:
- [ ] Response times are acceptable (typically 3-10 seconds)
- [ ] No timeout errors or service failures
- [ ] Consistent behavior across multiple sessions

#### 6. Monitor and Iterate

**Performance Monitoring**:
```bash
# Check Application Insights for errors or performance issues
az monitor app-insights component show --app "your-app-insights" --resource-group "your-rg"

# View recent telemetry
az monitor app-insights query --app "your-app-insights" --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, success, duration"
```

**User Feedback Collection**:
- Monitor chat logs for common issues or confusion
- Collect feedback on response quality and helpfulness
- Track escalation rates and resolution success
- Note any requests for features or capabilities not supported

**Iterative Improvement Process**:
1. **Analyze Usage Patterns**: What questions are users asking most?
2. **Identify Pain Points**: Where is the agent struggling or providing poor responses?
3. **Refine Instructions**: Update prompts based on real-world usage
4. **Test Changes**: Deploy and monitor impact of modifications
5. **Document Learnings**: Keep notes on what works and what doesn't

#### 7. Rollback Procedures

**If Deployment Fails**:
```bash
# Check deployment logs
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "your-endpoint" -OutputFormat "json" 2>&1 | tee deployment.log

# Restore previous working configuration
git checkout HEAD~1 -- src/agent/ai_in_a_box.yaml
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "your-endpoint" -Force
```

**If Agent Behavior is Problematic**:
```bash
# Quick revert to known good version
git log --oneline -- src/agent/ai_in_a_box.yaml  # Find last good commit
git checkout <commit-hash> -- src/agent/ai_in_a_box.yaml
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "your-endpoint" -Force
```

### Local Testing (Development)

**When Possible**:
- Test prompt changes with OpenAI playground or similar tools
- Use AI Foundry Studio for rapid prototyping
- Create test scenarios with expected responses
- Validate tool configurations work as intended

**Limitations**:
- Full SPA integration requires deployed environment
- Authentication and security features may not work locally
- Performance characteristics may differ from production

### Automation and CI/CD Integration

**GitHub Actions Integration**:
```yaml
# .github/workflows/deploy-agent.yml
name: Deploy AI Agent
on:
  push:
    paths:
      - 'src/agent/ai_in_a_box.yaml'
    branches:
      - main

jobs:
  deploy-agent:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Agent
        run: |
          chmod +x deploy-scripts/Deploy-Agent.ps1
          pwsh deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "${{ secrets.AI_FOUNDRY_ENDPOINT }}" -OutputFormat "json"
```

**Environment-Specific Deployments**:
```bash
# Development environment
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "$DEV_ENDPOINT" -AgentName "AI Assistant (Dev)"

# Staging environment  
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "$STAGING_ENDPOINT" -AgentName "AI Assistant (Staging)"

# Production environment
./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "$PROD_ENDPOINT" -AgentName "AI Assistant"
```

## 🔧 Advanced Configuration Options

### Tool Integration

#### File Search Configuration

Enable file search when your agent needs to access uploaded documents, knowledge bases, or reference materials.

```yaml
tools: ["file_search"]

file_search:
  max_num_results: 20           # Number of relevant chunks to retrieve (1-50)
  ranking_options:
    ranker: "default_2024_05_13"  # Ranking algorithm version
    score_threshold: 0.0          # Minimum relevance score (0.0-1.0)
```

**Use Cases**:
- Customer support with product documentation
- Compliance agents with policy documents
- Technical support with troubleshooting guides
- Educational assistants with course materials

**Best Practices**:
- Upload well-structured documents (PDFs, Word docs, text files)
- Use clear, descriptive filenames
- Organize content logically with headers and sections
- Keep documents updated and remove outdated information
- Test search relevance with common user queries

**File Preparation Tips**:
```markdown
# Good document structure for file search
# Title: Clear, descriptive title
# Table of Contents (for long documents)

## Section 1: Overview
Clear introduction and scope

## Section 2: Detailed Content
Well-organized information with subheadings

### Subsection 2.1: Specific Topic
Detailed information with examples

## Section 3: Troubleshooting
Common issues and solutions

## References
Links to additional resources
```

#### Code Interpreter Configuration

Enable code execution for data analysis, calculations, and programming tasks.

```yaml
tools: ["code_interpreter"]

code_interpreter:
  auto_run_enabled: false       # Whether to automatically execute generated code
  timeout_seconds: 120          # Maximum execution time (60-600 seconds)
```

**Use Cases**:
- Data analysis and visualization
- Mathematical calculations and modeling
- File format conversions
- API testing and development
- Educational programming assistance

**Capabilities**:
- Python code execution in a sandboxed environment
- File upload and processing (CSV, JSON, images, etc.)
- Data visualization with matplotlib, seaborn, plotly
- Scientific computing with numpy, pandas, scipy
- Basic machine learning with scikit-learn

**Security Considerations**:
- Code runs in an isolated sandbox environment
- No internet access from code execution environment
- File access is limited to uploaded files
- Execution time is bounded by timeout settings

**Example Usage Instructions**:
```yaml
instructions: |
  When users request data analysis or calculations, use the code interpreter to:
  
  1. **Always explain your approach** before writing code
  2. **Write clean, well-commented Python code**
  3. **Show intermediate results** with print statements
  4. **Create visualizations** when they help explain findings
  5. **Interpret results** in plain language
  
  Code Writing Standards:
  - Use descriptive variable names
  - Add comments explaining complex logic
  - Handle potential errors gracefully
  - Validate input data before processing
  - Create publication-ready plots with proper labels
```

#### Combined Tool Usage

```yaml
tools: ["file_search", "code_interpreter"]

instructions: |
  You have access to both file search and code execution capabilities:
  
  **File Search**: Use when users ask about documented procedures, policies, or reference information
  **Code Interpreter**: Use for calculations, data analysis, or when users provide datasets
  **Combined**: Search for relevant documentation first, then implement solutions in code
  
  Example workflow:
  1. Search documentation for relevant procedures or examples
  2. Use code to implement the solution or perform calculations
  3. Reference documentation to validate approach and provide additional context
```

### Model Performance Tuning

#### Parameter Optimization

**Temperature Tuning**:
```yaml
model:
  options:
    # Conservative (factual, consistent responses)
    temperature: 0.1  # Technical documentation, customer support
    
    # Balanced (slight variation, professional)
    temperature: 0.3  # General business applications
    
    # Creative (varied responses, brainstorming)  
    temperature: 0.7  # Marketing content, ideation sessions
    
    # Highly creative (unpredictable, experimental)
    temperature: 0.9  # Creative writing, artistic projects
```

**Response Control**:
```yaml
model:
  options:
    max_tokens: 4000              # Maximum response length
    presence_penalty: 0.1         # Reduce repetitive content
    frequency_penalty: 0.1        # Encourage topic diversity
    top_p: 0.9                   # Word selection diversity
    stop: ["END_RESPONSE"]        # Custom stop sequences
```

**Deterministic Responses** (for testing):
```yaml
model:
  options:
    temperature: 0.0
    seed: 42                     # Same seed = identical responses
    top_p: 1.0
```

#### Model Selection Guidelines

**gpt-4o-mini** (Recommended for most use cases):
- **Best for**: General chat, customer support, basic Q&A
- **Pros**: Fast, cost-effective, good quality
- **Cons**: Less capable with complex reasoning
- **Cost**: ~10x cheaper than GPT-4o

**gpt-4o**:
- **Best for**: Complex analysis, code review, technical documentation
- **Pros**: Superior reasoning, better code generation, multi-modal
- **Cons**: Higher cost, slower response times
- **Cost**: Premium pricing

**gpt-4-turbo**:
- **Best for**: Balance of capability and speed
- **Pros**: Good reasoning, faster than GPT-4o, handles longer contexts
- **Cons**: More expensive than mini models
- **Cost**: Mid-range pricing

**Selection Matrix**:
```yaml
# Simple FAQ or basic support
model:
  id: gpt-35-turbo
  options:
    temperature: 0.2

# General business applications
model:
  id: gpt-4o-mini
  options:
    temperature: 0.3

# Complex technical tasks  
model:
  id: gpt-4o
  options:
    temperature: 0.1
    max_tokens: 4000

# Creative or brainstorming tasks
model:
  id: gpt-4o
  options:
    temperature: 0.8
    max_tokens: 3000
```

### Response Format Control

#### Structured Output

Force JSON responses for programmatic consumption:

```yaml
response_format:
  type: "json_object"

instructions: |
  Always respond with valid JSON in this format:
  {
    "answer": "Your response text",
    "confidence": 0.95,
    "sources": ["source1", "source2"],
    "next_steps": ["step1", "step2"]
  }
```

#### Consistent Formatting

```yaml
instructions: |
  Always format responses using this structure:
  
  ## Summary
  Brief overview of the response
  
  ## Detailed Answer  
  Comprehensive information with examples
  
  ## Additional Resources
  - Link 1: Description
  - Link 2: Description
  
  ## Next Steps
  1. Immediate action to take
  2. Follow-up considerations
```

### Integration Patterns

#### Multi-Agent Workflows

```yaml
# Specialist agent that can hand off to other agents
instructions: |
  You are a triage agent that determines the best specialist for each request:
  
  **Technical Issues**: Escalate to DevOps Specialist
  **Security Questions**: Escalate to Security Auditor  
  **Documentation**: Escalate to Documentation Assistant
  **General Support**: Handle directly
  
  When escalating, provide:
  1. Summary of the user's request
  2. Any relevant context or constraints
  3. Specific questions the specialist should address
```

#### External System Integration

```yaml
instructions: |
  When users request information that requires external systems:
  
  1. **Acknowledge the request** and explain what you need to check
  2. **Provide guidance** on how they can get the information
  3. **Offer to help interpret** results once they have them
  4. **Suggest automation** if this is a frequent request
  
  Example: "I'll need to check our ticketing system for that information. 
  You can find this in [System] → [Menu] → [Reports]. Once you have the data, 
  I can help you analyze it and suggest next steps."
```

## 🛠️ Troubleshooting Guide

### Common YAML Configuration Issues

#### Syntax Errors

**Problem**: Invalid YAML syntax
```yaml
# ❌ Wrong - incorrect indentation
name: AI Assistant
instructions:
You are a helpful assistant.

# ✅ Correct - proper indentation and multi-line syntax
name: AI Assistant
instructions: |
  You are a helpful assistant.
```

**Problem**: Special characters in strings
```yaml
# ❌ Wrong - unescaped special characters
name: AI Assistant: "Advanced" Edition

# ✅ Correct - properly quoted
name: 'AI Assistant: "Advanced" Edition'
```

**Problem**: Invalid array syntax
```yaml
# ❌ Wrong - mixing syntaxes
tools: ["file_search", code_interpreter]

# ✅ Correct - consistent array syntax
tools: ["file_search", "code_interpreter"]
```

#### Schema Validation Errors

**Problem**: Missing required properties
```yaml
# ❌ Missing required fields
version: 1.0.0
name: My Agent

# ✅ Complete required fields
version: 1.0.0
name: My Agent
tools: []
description: Agent description
instructions: |
  Agent instructions here
```

**Problem**: Invalid property values
```yaml
# ❌ Invalid tool name
tools: ["filesearch"]  # Wrong spelling

# ✅ Correct tool names
tools: ["file_search", "code_interpreter"]
```

**Problem**: Out-of-range values
```yaml
# ❌ Temperature outside valid range
model:
  options:
    temperature: 2.0  # Must be 0.0-1.0

# ✅ Valid temperature
model:
  options:
    temperature: 0.7
```

### Deployment Issues

#### Authentication Problems

**Problem**: Azure CLI not authenticated
```bash
# Error: "Please run 'az login' to authenticate"

# Solution: Login to Azure
az login

# Verify authentication
az account show
```

**Problem**: Insufficient permissions
```bash
# Error: "User does not have permission to access resource"

# Solution: Check required permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Request Cognitive Services Contributor role
az role assignment create \
  --assignee "user@domain.com" \
  --role "Cognitive Services Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg-name}"
```

#### Endpoint Issues

**Problem**: Invalid AI Foundry endpoint
```bash
# Error: "Could not connect to AI Foundry endpoint"

# Solution: Verify endpoint format
# Correct format: https://{resource-name}.cognitiveservices.azure.com/api/projects/{project-name}

# Find your endpoint
az cognitiveservices account show \
  --name "your-ai-foundry-name" \
  --resource-group "your-rg" \
  --query "properties.endpoint" \
  --output tsv
```

**Problem**: Agent deployment script not found
```bash
# Error: "Agent deployment script not found: infra/agent_deploy.ps1"

# Solution: Verify script exists and is executable
ls -la infra/agent_deploy.ps1
chmod +x infra/agent_deploy.ps1

# Or check project structure
find . -name "*agent*" -type f
```

#### Model and Configuration Issues

**Problem**: Model not available
```yaml
# Error during deployment about invalid model ID

# Solution: Check available models in your region
az cognitiveservices account list-models \
  --name "your-ai-foundry-name" \
  --resource-group "your-rg" \
  --query "[].{Name:name, Version:version}" \
  --output table

# Use correct model ID
model:
  id: gpt-4o-mini  # Verify this model is available
```

**Problem**: Tool configuration not working
```yaml
# File search not returning results

# Check tool is properly enabled
tools: ["file_search"]  # Must be exact spelling

# Verify files are uploaded to AI Foundry project
# Check in Azure AI Foundry portal under Files section
```

### Agent Behavior Issues

#### Inconsistent Responses

**Problem**: Agent doesn't follow instructions consistently

**Diagnosis**:
```yaml
# Check instruction clarity and specificity
instructions: |
  # ❌ Vague instruction
  Be helpful.
  
  # ✅ Specific instruction
  You are a customer support agent. Always:
  1. Acknowledge the customer's issue
  2. Ask clarifying questions if needed
  3. Provide step-by-step solutions
  4. Offer additional help
```

**Solution**: Refine instructions with specific behavioral guidelines and examples.

#### Poor Response Quality

**Problem**: Responses are too generic or unhelpful

**Diagnosis**:
```yaml
# Check temperature and model settings
model:
  id: gpt-35-turbo     # May need more capable model
  options:
    temperature: 0.9   # May be too high for factual responses

# Solution: Adjust parameters
model:
  id: gpt-4o-mini      # More capable model
  options:
    temperature: 0.3   # Lower temperature for consistency
```

**Additional Solutions**:
- Add more specific domain knowledge to instructions
- Include examples of good responses in instructions
- Use file_search tool with relevant documentation
- Provide more context about user needs and expectations

#### Performance Issues

**Problem**: Slow response times

**Diagnosis**:
- Check model selection (larger models are slower)
- Verify tool usage (file_search and code_interpreter add latency)
- Review instruction length (very long instructions slow processing)

**Solutions**:
```yaml
# Use faster model for simple tasks
model:
  id: gpt-4o-mini  # Faster than gpt-4o

# Optimize tool configuration
file_search:
  max_num_results: 10  # Reduce from default 20

code_interpreter:
  timeout_seconds: 60  # Reduce timeout if appropriate

# Streamline instructions (remove unnecessary content)
instructions: |
  # Keep instructions focused and concise
  # Remove example conversations if they're very long
```

#### Security and Compliance Issues

**Problem**: Agent sharing sensitive information

**Solution**:
```yaml
instructions: |
  SECURITY GUIDELINES:
  - Never share passwords, API keys, or credentials
  - Don't provide information about other customers or users
  - If asked for sensitive data, explain why you can't provide it
  - Escalate security-related questions to appropriate teams
  
  If unsure about sharing information, err on the side of caution and escalate.
```

**Problem**: Agent not following compliance requirements

**Solution**:
```yaml
instructions: |
  COMPLIANCE REQUIREMENTS:
  - Follow GDPR data protection principles
  - Don't store or remember personal information between sessions
  - Provide data subject rights information when requested
  - Log interactions for audit purposes only
  
  When handling personal data:
  1. Only process what's necessary for the task
  2. Explain how the data will be used
  3. Don't retain data beyond the current session
```

### Monitoring and Debugging

#### Enable Detailed Logging

```bash
# Check Application Insights for detailed telemetry
az monitor app-insights component show \
  --app "your-app-insights" \
  --resource-group "your-rg"

# View recent errors
az monitor app-insights query \
  --app "your-app-insights" \
  --analytics-query "traces | where severityLevel >= 2 | order by timestamp desc | limit 50"
```

#### Performance Monitoring

```bash
# Monitor response times and success rates
az monitor app-insights query \
  --app "your-app-insights" \
  --analytics-query "
    requests 
    | where timestamp > ago(24h)
    | where name contains 'chat'
    | summarize 
        AvgDuration = avg(duration),
        SuccessRate = avg(todouble(success)) * 100,
        RequestCount = count()
    by bin(timestamp, 1h)
    | order by timestamp desc"
```

#### User Feedback Collection

```yaml
# Add feedback collection to agent instructions
instructions: |
  At the end of complex responses, ask:
  "Was this helpful? If not, please let me know what additional information would be useful."
  
  Keep track of common follow-up questions to improve your responses.
```

### Getting Help

#### Documentation Resources

- **[Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)**
- **[OpenAI API Reference](https://platform.openai.com/docs/api-reference)**
- **[YAML Specification](https://yaml.org/spec/1.2/spec.html)**
- **[Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)**

#### Support Channels

- **Azure Support**: For platform and service issues
- **Community Forums**: For general questions and best practices
- **GitHub Issues**: For problems with this specific deployment
- **Internal Documentation**: Check your organization's internal guides

#### Common Support Scenarios

**When to Contact Azure Support**:
- AI Foundry service is unavailable or returning errors
- Quota or rate limiting issues
- Billing or subscription problems
- Security or compliance questions

**When to Check Documentation**:
- YAML schema questions
- Model capability and parameter questions
- Best practices for prompt engineering
- Integration patterns and examples

**When to File GitHub Issues**:
- Problems with deployment scripts
- Documentation errors or gaps
- Feature requests for the SPA
- Infrastructure template issues

## 🎨 UI Customization

This section covers frontend styling and branding customizations. For comprehensive agent behavior customization, see the [AI Agent Configuration section](#-ai-agent-configuration) above.

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

## 📋 Agent Customization Checklist

Use this checklist to track your AI agent customization progress:

### Phase 1: Core Agent Configuration
- [ ] Updated agent `name` and `description` in YAML
- [ ] Written comprehensive `instructions` following prompt engineering best practices
- [ ] Selected appropriate `model` and `temperature` settings
- [ ] Validated YAML syntax and schema
- [ ] Successfully deployed agent using `Deploy-Agent.ps1`
- [ ] Verified agent appears correctly in AI Foundry portal

### Phase 2: Agent Behavior Testing  
- [ ] Tested agent personality and tone consistency
- [ ] Verified responses match intended use case
- [ ] Tested edge cases and out-of-scope questions
- [ ] Validated technical accuracy of responses
- [ ] Checked response formatting and structure
- [ ] Monitored response times and performance

### Phase 3: Advanced Configuration
- [ ] Configured tools (`file_search`, `code_interpreter`) if needed
- [ ] Optimized model parameters for use case
- [ ] Set up appropriate response formatting
- [ ] Implemented security and compliance guidelines
- [ ] Created environment-specific configurations
- [ ] Set up monitoring and feedback collection

### Phase 4: Production Readiness
- [ ] Documented custom configuration and rationale
- [ ] Created rollback procedures
- [ ] Set up automated deployment (CI/CD) if needed
- [ ] Trained users on new agent capabilities
- [ ] Established feedback and improvement processes

### UI Customization (Optional):
- [ ] Updated colors and branding to match organization
- [ ] Custom logo and favicon
- [ ] Modified chat interface styling
- [ ] Added dark mode support (if desired)
- [ ] Optimized for mobile devices

### Additional Customizations (As Needed):
- [ ] Added custom API endpoints
- [ ] Implemented authentication (if needed) 
- [ ] Added file upload support
- [ ] Created custom UI components
- [ ] Configured custom domain
- [ ] Set up SSL certificates

## 🔗 Related Documentation

### Essential Reading:
- **[Quick Start Guide](../getting-started/03-quick-start.md)** - Initial deployment process
- **[Agent Deployment Script](../../deploy-scripts/Deploy-Agent.ps1)** - Technical deployment reference
- **[Environment Variables](environment-variables.md)** - Configuration options
- **[Local Development](../development/local-development.md)** - Testing your customizations

### Advanced Topics:
- **[Deployment Guide](../deployment/deployment-guide.md)** - Production deployment strategies
- **[Troubleshooting](../operations/troubleshooting.md)** - Fixing issues
- **[Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)** - Official Microsoft documentation
- **[OpenAI API Reference](https://platform.openai.com/docs/api-reference)** - Model parameters and capabilities

### Examples and References:
- **[Agent YAML Configuration](../../src/agent/ai_in_a_box.yaml)** - Complete example with comments
- **[Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)** - Official OpenAI best practices
- **[YAML Specification](https://yaml.org/spec/1.2/spec.html)** - YAML syntax reference

---

## 🚀 Quick Start: Customize Your Agent in 5 Minutes

1. **Edit the agent configuration**: `/home/runner/work/ai-in-a-box/ai-in-a-box/src/agent/ai_in_a_box.yaml`
2. **Update the `instructions` field** with your specific use case
3. **Validate syntax** using VS Code YAML extension or online validator
4. **Deploy**: `./deploy-scripts/Deploy-Agent.ps1 -AiFoundryEndpoint "your-endpoint"`
5. **Test** via your deployed SPA interface

**Need help?** Start with the [Agent Configuration Examples](#-agent-configuration-examples) section above for ready-to-use templates.

**Ready to deploy?** See the [Deployment and Testing Workflow](#-deployment-and-testing-workflow) for step-by-step instructions.