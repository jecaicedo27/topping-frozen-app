import api from './api';

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
      
      // Store token and user in localStorage
      if (response.data.success && response.data.data) {
        localStorage.setItem('token', response.data.data.token);
        localStorage.setItem('user', JSON.stringify(response.data.data.user));
        console.log('AuthService: Token and user stored in localStorage');
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
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    // Use React Router for navigation instead of forcing a page reload
    // The AuthContext will handle the redirect
  },
  
  // Get current user
  getCurrentUser: (): any => {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      return JSON.parse(userStr);
    }
    return null;
  },
  
  // Check if user is authenticated
  isAuthenticated: (): boolean => {
    return !!localStorage.getItem('token');
  },
  
  // Get auth token
  getToken: (): string | null => {
    return localStorage.getItem('token');
  }
};
