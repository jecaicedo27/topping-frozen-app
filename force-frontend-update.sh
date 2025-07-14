#!/bin/bash

# 🔧 Script para Forzar Actualización del Frontend - Topping Frozen
# Ejecutar como: bash force-frontend-update.sh

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

echo "🔧 Forzando Actualización Completa del Frontend..."
echo "================================================="

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

print_step "1. Limpiando caché del frontend..."
cd $APP_DIR
rm -rf dist/
rm -rf node_modules/.cache/
rm -rf /var/www/topping-frozen/*

print_step "2. Verificando configuración de la API..."
echo "Configuración actual de api.ts:"
cat src/services/api.ts

print_step "3. Creando configuración de API simplificada..."
cat > src/services/api.ts << 'EOF'
import axios from 'axios';

// Configuración simple de la API
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
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
EOF

print_step "4. Verificando servicio de autenticación..."
if [ -f "src/services/auth.service.ts" ]; then
    echo "Contenido actual de auth.service.ts:"
    head -20 src/services/auth.service.ts
fi

print_step "5. Creando servicio de autenticación simplificado..."
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

export const authService = {
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
  },

  logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  },

  getCurrentUser() {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  },

  getToken() {
    return localStorage.getItem('token');
  },

  isAuthenticated() {
    return !!this.getToken();
  }
};
EOF

print_step "6. Recompilando frontend con configuración limpia..."
npm run build:frontend

print_step "7. Copiando archivos al directorio de Nginx..."
mkdir -p /var/www/topping-frozen
cp -r dist/* /var/www/topping-frozen/
chown -R www-data:www-data /var/www/topping-frozen/
chmod -R 755 /var/www/topping-frozen/

print_step "8. Agregando headers de no-cache a Nginx..."
cat > /etc/nginx/sites-available/topping-frozen << 'EOF'
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Servir archivos estáticos del frontend
    location / {
        root /var/www/topping-frozen;
        try_files $uri $uri/ /index.html;
        index index.html;
        
        # Headers para evitar caché
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Proxy para API del backend
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    }
}
EOF

print_step "9. Reiniciando Nginx..."
nginx -t && systemctl restart nginx

print_step "10. Verificando que el backend esté corriendo..."
if ! curl -s http://127.0.0.1:3001/api/health | grep -q "success"; then
    print_error "Backend no responde, reiniciando..."
    cd $APP_DIR/backend
    pkill -f "npm run dev" || true
    pkill -f "ts-node-dev" || true
    sleep 3
    nohup npm run dev > /tmp/backend-force.log 2>&1 &
    sleep 5
fi

print_step "11. Verificación final completa..."
echo "=== Probando API health ==="
curl -s http://apptoppingfrozen.com/api/health

echo ""
echo "=== Probando login ==="
LOGIN_RESULT=$(curl -s -X POST http://apptoppingfrozen.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}')
echo "Resultado: $LOGIN_RESULT"

echo ""
echo "=== Verificando archivos del frontend ==="
ls -la /var/www/topping-frozen/

echo ""
echo "=== Verificando configuración de Nginx ==="
nginx -t

echo ""
echo "🎉 ACTUALIZACIÓN FORZADA COMPLETADA"
echo "==================================="
echo ""
echo "📋 CAMBIOS REALIZADOS:"
echo "   ✅ Caché del frontend limpiado completamente"
echo "   ✅ Configuración de API simplificada"
echo "   ✅ Servicio de autenticación reescrito"
echo "   ✅ Frontend recompilado desde cero"
echo "   ✅ Headers de no-cache agregados a Nginx"
echo "   ✅ CORS configurado correctamente"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 INSTRUCCIONES IMPORTANTES:"
echo "   1. Abre el navegador en modo incógnito"
echo "   2. Ve a http://apptoppingfrozen.com/"
echo "   3. Abre las herramientas de desarrollador (F12)"
echo "   4. Ve a la pestaña Network/Red"
echo "   5. Intenta hacer login con admin/123456"
echo "   6. Verifica las peticiones HTTP en la pestaña Network"
echo ""
echo "🔍 LOGS PARA REVISAR:"
echo "   Backend: tail -f /tmp/backend-force.log"
echo "   Nginx: tail -f /var/log/nginx/topping-frozen.error.log"
echo ""
print_status "¡Actualización completa terminada! Prueba en modo incógnito."
