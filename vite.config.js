import { defineConfig } from 'vite'

export default defineConfig({
  root: './src/frontend',
  build: {
    outDir: '../../dist',
    assetsDir: 'assets',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: '/index.html'
      }
    }
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
  }
})
