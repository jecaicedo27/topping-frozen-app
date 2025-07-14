#!/bin/bash

# 🔧 Script para Corregir Errores de AuthService - Topping Frozen
# Ejecutar como: bash fix-auth-service.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✅ OK]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[🔧 STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

echo "🔧 Corrigiendo Errores de AuthService..."
echo "======================================"

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

cd $APP_DIR

print_step "1. Corrigiendo archivo auth.service.ts..."
cat > src/services/auth.service.ts << 'EOF'
import api from './api';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  data?: {
    user: any;
    token: string;
  };
}

export interface User {
  id: number;
  username: string;
  name: string;
  role: string;
}

class AuthServiceClass {
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    try {
      console.log('Attempting login with:', credentials.username);
      const response = await api.post('/auth/login', credentials);
      console.log('Login response:', response.data);
      
      if (response.data.success && response.data.data?.token) {
        localStorage.setItem('token', response.data.data.token);
        localStorage.setItem('user', JSON.stringify(response.data.data.user));
      }
      
      return response.data;
    } catch (error: any) {
      console.error('Login error:', error);
      return {
        success: false,
        message: error.response?.data?.message || 'Error de conexión'
      };
    }
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  }

  getCurrentUser(): User | null {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }
}

// Exportar instancia por defecto
const AuthService = new AuthServiceClass();
export default AuthService;

// También exportar la clase para compatibilidad
export { AuthServiceClass };
export const authService = AuthService;
EOF

print_step "2. Verificando archivo api.ts..."
cat > src/services/api.ts << 'EOF'
import axios from 'axios';

// Configuración de la API
const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para agregar token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor para manejar errores
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
EOF

print_step "3. Verificando contexto de autenticación..."
if [ -f "src/context/AuthContext.tsx" ]; then
    # Corregir imports en AuthContext
    sed -i 's/import { authService }/import AuthService/g' src/context/AuthContext.tsx
    sed -i 's/authService\./AuthService\./g' src/context/AuthContext.tsx
fi

print_step "4. Verificando páginas que usan AuthService..."
# Corregir imports en Login.tsx
if [ -f "src/pages/Login.tsx" ]; then
    sed -i 's/import { authService }/import AuthService/g' src/pages/Login.tsx
    sed -i 's/authService\./AuthService\./g' src/pages/Login.tsx
fi

print_step "5. Limpiando caché y recompilando..."
rm -rf dist/
rm -rf node_modules/.cache/
npm run build:frontend

if [ $? -eq 0 ]; then
    print_status "Frontend compilado exitosamente"
else
    print_error "Error en compilación del frontend"
    exit 1
fi

print_step "6. Copiando archivos al directorio de Nginx..."
rm -rf /var/www/topping-frozen/*
cp -r dist/* /var/www/topping-frozen/
chown -R www-data:www-data /var/www/topping-frozen/
chmod -R 755 /var/www/topping-frozen/

print_step "7. Reiniciando backend..."
cd backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 3
nohup npm run dev > /tmp/backend-auth-fix.log 2>&1 &
sleep 5

print_step "8. Reiniciando Nginx..."
systemctl restart nginx

print_step "9. Verificación final..."
echo "=== Probando API health ==="
curl -s http://apptoppingfrozen.com/api/health

echo ""
echo "=== Probando login ==="
LOGIN_RESULT=$(curl -s -X POST http://apptoppingfrozen.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}')
echo "Resultado: $LOGIN_RESULT"

echo ""
echo "🎉 CORRECCIÓN DE AUTHSERVICE COMPLETADA"
echo "======================================="
echo ""
echo "📋 CAMBIOS REALIZADOS:"
echo "   ✅ AuthService corregido con exports apropiados"
echo "   ✅ API service simplificado"
echo "   ✅ Imports corregidos en componentes"
echo "   ✅ Frontend recompilado sin errores"
echo "   ✅ Backend reiniciado"
echo "   ✅ Nginx reiniciado"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 INSTRUCCIONES:"
echo "   1. Abre modo incógnito (Ctrl + Shift + N)"
echo "   2. Ve a http://apptoppingfrozen.com/"
echo "   3. Intenta login con admin/123456"
echo ""
echo "🔍 LOGS:"
echo "   Backend: tail -f /tmp/backend-auth-fix.log"
echo "   Nginx: tail -f /var/log/nginx/topping-frozen.error.log"
echo ""
print_status "¡AuthService corregido! Prueba el login ahora."
