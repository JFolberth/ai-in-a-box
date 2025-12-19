// Polyfill TextEncoder/TextDecoder for jsdom
const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;

// Environment variables setup for tests
process.env.VITE_AI_FOUNDRY_AGENT_NAME = 'TestBot'
process.env.VITE_BACKEND_URL = 'http://localhost:7071/api'
process.env.VITE_USE_BACKEND = 'false'
process.env.VITE_PUBLIC_MODE = 'true'

// Mock import.meta.env for Vite environment variables
global.importMeta = {
  env: {
    VITE_AI_FOUNDRY_AGENT_NAME: 'TestBot',
    VITE_BACKEND_URL: 'http://localhost:7071/api',
    VITE_USE_BACKEND: 'false',
    VITE_PUBLIC_MODE: 'true'
  }
}