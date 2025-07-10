import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ command, mode }) => {
  // Load environment variables based on the mode
  const env = loadEnv(mode, process.cwd(), '')
  
  return {
    build: {
      outDir: 'dist',
      assetsDir: 'assets',
      emptyOutDir: true
    },
    server: {
      port: 3000,
      host: true,
      open: true
    },
    preview: {
      port: 3000,
      host: true
    },
    // Environment variables prefixed with VITE_ are automatically exposed by Vite
    // No need to manually define process.env, which is a security risk
    // Ensure proper environment file loading
    envDir: '.',
    envPrefix: 'VITE_'
  }
})
