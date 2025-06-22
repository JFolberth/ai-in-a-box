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
    define: {
      // Enable access to environment variables in the browser
      'process.env': process.env
    },
    // Ensure proper environment file loading
    envDir: '.',
    envPrefix: 'VITE_'
  }
})
