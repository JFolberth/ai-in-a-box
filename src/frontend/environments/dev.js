// Development Environment Configuration
// AI Foundry settings for dev environment (Public Mode - No Authentication)

export const environment = {  // Environment identifier
  name: 'dev',
  production: false,
  publicMode: true, // Public mode enabled - no authentication required

  // AI Foundry Configuration (single endpoint)
  aiFoundry: {
    // Using Azure Function App as proxy
    useBackend: true,
    backendUrl: 'https://func-ai-foundry-spa-backend-dev-001.azurewebsites.net/api',
    agentName: 'CancerBot',
    agentId: 'asst_dH7M0nbmdRblhSQO8nIGIYF4',
    projectUrl: 'https://ai-foundry-dev-eus.services.ai.azure.com/api/projects/firstProject',
    endpoint: 'https://ai-foundry-dev-eus.azureml.net',
    deployment: 'gpt-4',
    apiVersion: '2024-02-15-preview'
  },

  // Application Insights Configuration
  applicationInsights: {
    // Will be set from environment variables or deployment outputs
    connectionString: import.meta.env.VITE_APPLICATION_INSIGHTS_CONNECTION_STRING || ''
  },

  // API Configuration
  api: {
    timeout: 30000,
    retryAttempts: 3,
    retryDelay: 1000
  },
  // Feature Flags
  features: {
    enableLogging: true,
    enableTelemetry: true,
    enableErrorReporting: true,
    enableAuthentication: false // Disabled for public mode
  }
};

// Validate required configuration for public mode
const validateConfig = () => {  // In public mode, we only require AI Foundry configuration
  const required = [
    'aiFoundry.agentName',
    'aiFoundry.agentId',
    'aiFoundry.projectUrl'
  ];

  const missing = required.filter(key => {
    const value = key.split('.').reduce((obj, prop) => obj?.[prop], environment);
    return !value;
  });

  if (missing.length > 0) {
    console.error('Missing required environment configuration:', missing);
    throw new Error(`Missing required environment configuration: ${missing.join(', ')}`);
  }
  
  console.log('Environment validated for public mode - authentication disabled');
};

// Validate configuration on import
validateConfig();

export default environment;
