import api from './api';
import { tokenManager } from './tokenManager';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthResponse {
  success: boolean;
  message: string;
  data?: {
    user: {
      id: number;
      username: string;
      name: string;
      role: string;
    };
    token: string;
  };
}

export const AuthService = {
  // Login user
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    try {
      console.log('AuthService: Attempting login with credentials:', credentials);
      console.log('AuthService: API base URL:', api.defaults.baseURL);
      
      const response = await api.post<AuthResponse>('/auth/login', credentials);
      
      console.log('AuthService: Login response:', response.data);
      
      // Store token in memory if login successful
      if (response.data.success && response.data.data) {
        tokenManager.setToken(response.data.data.token);
        console.log('AuthService: Token stored in memory');
      }
      
      return response.data;
    } catch (error: any) {
      console.error('AuthService: Login error:', error);
      console.error('AuthService: Error response:', error.response?.data);
      return {
        success: false,
        message: error.response?.data?.message || 'Login failed'
      };
    }
  },
  
  // Logout user
  logout: (): void => {
    // Clear token from memory
    tokenManager.clearToken();
    console.log('AuthService: Token cleared from memory');
  },
  
  // Get current user from server
  getCurrentUser: async (): Promise<any> => {
    try {
      const response = await api.get('/auth/me');
      return response.data.success ? response.data.data : null;
    } catch (error) {
      console.error('AuthService: Error getting current user:', error);
      return null;
    }
  },
  
  // Verify token with server
  verifyToken: async (): Promise<boolean> => {
    try {
      // Check if we have a token in memory first
      if (!tokenManager.hasToken()) {
        return false;
      }
      
      const response = await api.get('/auth/verify');
      return response.data.success;
    } catch (error) {
      return false;
    }
  }
};
