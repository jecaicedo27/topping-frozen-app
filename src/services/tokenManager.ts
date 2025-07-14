// Token manager for handling JWT tokens in memory
class TokenManager {
  private token: string | null = null;

  // Set token in memory
  setToken(token: string): void {
    this.token = token;
  }

  // Get token from memory
  getToken(): string | null {
    return this.token;
  }

  // Check if token exists
  hasToken(): boolean {
    return this.token !== null && this.token !== '';
  }

  // Clear token from memory
  clearToken(): void {
    this.token = null;
  }

  // Get authorization header
  getAuthHeader(): { Authorization: string } | {} {
    if (this.hasToken()) {
      return { Authorization: `Bearer ${this.token}` };
    }
    return {};
  }
}

// Export singleton instance
export const tokenManager = new TokenManager();
