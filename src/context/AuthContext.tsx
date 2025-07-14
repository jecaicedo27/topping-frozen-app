import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { AuthContextType, AuthState, LoginCredentials } from '../types/auth';
import { UserRole } from '../types/user';
import { AuthService } from '../services/auth.service';

// Initial auth state
const initialState: AuthState = {
  isAuthenticated: false,
  user: null,
  loading: true,
  error: null
};

// Auth reducer
type AuthAction =
  | { type: 'LOGIN_SUCCESS'; payload: any }
  | { type: 'LOGIN_FAILURE'; payload: string }
  | { type: 'LOGOUT' }
  | { type: 'CLEAR_ERROR' }
  | { type: 'SET_LOADING'; payload: boolean };

const authReducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        isAuthenticated: true,
        user: action.payload,
        loading: false,
        error: null
      };
    case 'LOGIN_FAILURE':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        loading: false,
        error: action.payload
      };
    case 'LOGOUT':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        loading: false
      };
    case 'CLEAR_ERROR':
      return {
        ...state,
        error: null
      };
    case 'SET_LOADING':
      return {
        ...state,
        loading: action.payload
      };
    default:
      return state;
  }
};

// Create context
export const AuthContext = createContext<AuthContextType>({
  authState: initialState,
  login: async () => false,
  logout: () => {}
});

// Auth provider component
export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [authState, dispatch] = useReducer(authReducer, initialState);

  // Check if user is already logged in (from localStorage)
  useEffect(() => {
    const checkAuth = () => {
      try {
        // Check if user is authenticated using AuthService
        const user = AuthService.getCurrentUser();
        const isAuthenticated = AuthService.isAuthenticated();
        
        if (isAuthenticated && user) {
          dispatch({ type: 'LOGIN_SUCCESS', payload: user });
        } else {
          dispatch({ type: 'SET_LOADING', payload: false });
        }
      } catch (error) {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    };

    checkAuth();
    // We only want this to run once on component mount
  }, []);

  // Login function
  const login = async (credentials: LoginCredentials): Promise<boolean> => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      
      // Use AuthService to login
      const response = await AuthService.login(credentials);
      
      if (response.success && response.data) {
        dispatch({ type: 'LOGIN_SUCCESS', payload: response.data.user });
        return true;
      } else {
        dispatch({ type: 'LOGIN_FAILURE', payload: response.message || 'Credenciales inválidas' });
        return false;
      }
    } catch (error) {
      dispatch({ type: 'LOGIN_FAILURE', payload: 'Error de autenticación' });
      return false;
    }
  };

  // Logout function
  const logout = () => {
    AuthService.logout();
    dispatch({ type: 'LOGOUT' });
  };

  return (
    <AuthContext.Provider value={{ authState, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook for using the auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
