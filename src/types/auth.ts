import { UserRole } from './user';

export interface AuthUser {
  id: string;
  username: string;
  name: string;
  role: UserRole;
}

export interface AuthState {
  isAuthenticated: boolean;
  user: AuthUser | null;
  loading: boolean;
  error: string | null;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthContextType {
  authState: AuthState;
  login: (credentials: LoginCredentials) => Promise<boolean>;
  logout: () => void;
  clearError: () => void;
}

// Mock users for demonstration
export const mockUsers: AuthUser[] = [
  {
    id: '1',
    username: 'admin',
    name: 'Administrador',
    role: UserRole.ADMIN
  },
  {
    id: '2',
    username: 'facturacion',
    name: 'Usuario Facturación',
    role: UserRole.FACTURACION
  },
  {
    id: '3',
    username: 'cartera',
    name: 'Usuario Cartera',
    role: UserRole.CARTERA
  },
  {
    id: '4',
    username: 'logistica',
    name: 'Usuario Logística',
    role: UserRole.LOGISTICA
  },
  {
    id: '5',
    username: 'mensajero',
    name: 'Usuario Mensajero',
    role: UserRole.MENSAJERO
  },
  {
    id: '6',
    username: 'regular',
    name: 'Usuario Regular',
    role: UserRole.REGULAR
  }
];
