// Token manager without localStorage
class TokenManager {
  private token: string | null = null;

  setToken(token: string): void {
    this.token = token;
  }

  getToken(): string | null {
    return this.token;
  }

  clearToken(): void {
    this.token = null;
  }

  hasToken(): boolean {
    return !!this.token;
  }
}

export const tokenManager = new TokenManager();
