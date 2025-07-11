// Environment Configuration Entry Point
// Automatically loads the correct environment based on NODE_ENV or VITE_ENV

import devEnvironment from './dev.js';

// Determine which environment to use
const getEnvironment = () => {
  const env = import.meta.env.VITE_ENV || import.meta.env.NODE_ENV || 'dev';
  
  switch (env) {
    case 'development':
    case 'dev':
      return devEnvironment;
    case 'staging':
      // Add staging environment when needed
      return devEnvironment; // Fallback to dev for now
    case 'production':
    case 'prod':
      // Add production environment when needed
      return devEnvironment; // Fallback to dev for now
    default:
      console.warn(`Unknown environment: ${env}, falling back to dev`);
      return devEnvironment;
  }
};

export const environment = getEnvironment();
export default environment;
