// Public mode authentication manager - no authentication required
export class AuthManager {
  constructor() {
    // Always public mode - no authentication
    this.isPublic = true
  }

  async initialize() {
    // Public mode only - no authentication calls
    return { name: 'Public User', username: 'public' }
  }

  async login() {
    // Public mode - no login required
    return { name: 'Public User', username: 'public' }
  }

  async logout() {
    // Public mode - no logout needed
  }

  async getAccessToken() {
    // Public mode - no tokens needed
    return null
  }

  getCredential() {
    // Public mode - no credentials
    return null
  }

  isAuthenticated() {
    // Always considered "authenticated" in public mode
    return true
  }
}
