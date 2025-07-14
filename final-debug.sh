#!/bin/bash

# 🔧 Script Final de Debug - Topping Frozen
# Ejecutar como: bash final-debug.sh

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

echo "🔧 Debug Final - Problema de Login..."
echo "===================================="

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

print_step "1. Verificando configuración del frontend..."

# Verificar archivo de configuración API
if [ -f "$APP_DIR/src/services/api.ts" ]; then
    echo "Configuración actual de API:"
    grep -n "baseURL\|API_URL\|localhost\|apptoppingfrozen" "$APP_DIR/src/services/api.ts" || echo "No se encontraron configuraciones de URL"
fi

print_step "2. Verificando archivos compilados del frontend..."
if [ -d "/var/www/topping-frozen" ]; then
    print_status "Frontend compilado encontrado en /var/www/topping-frozen"
    ls -la /var/www/topping-frozen/
else
    print_error "Frontend compilado no encontrado"
fi

print_step "3. Verificando configuración de Nginx..."
echo "Configuración actual de Nginx:"
cat /etc/nginx/sites-available/topping-frozen

print_step "4. Probando endpoints específicos..."

# Probar health endpoint
echo "=== Probando /api/health ==="
curl -v http://apptoppingfrozen.com/api/health 2>&1

echo ""
echo "=== Probando /api/auth/login ==="
curl -v -X POST http://apptoppingfrozen.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>&1

print_step "5. Verificando logs de Nginx en tiempo real..."
echo "Últimos logs de Nginx:"
tail -20 /var/log/nginx/topping-frozen.access.log
echo ""
tail -20 /var/log/nginx/topping-frozen.error.log

print_step "6. Verificando procesos del backend..."
echo "Procesos de Node.js corriendo:"
ps aux | grep -E "(node|npm|ts-node)" | grep -v grep

print_step "7. Verificando puertos..."
echo "Puertos abiertos:"
netstat -tlnp | grep -E ":80|:3001|:443"

print_step "8. Creando configuración de API corregida..."

# Crear configuración de API que funcione
cat > $APP_DIR/src/services/api-fixed.ts << 'EOF'
import axios from 'axios';

// Configuración de la API
const API_BASE_URL = window.location.origin + '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para agregar token de autenticación
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Interceptor para manejar respuestas
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
EOF

print_step "9. Verificando configuración actual de la API..."
if [ -f "$APP_DIR/src/services/api.ts" ]; then
    echo "Contenido actual de api.ts:"
    cat "$APP_DIR/src/services/api.ts"
fi

print_step "10. Recompilando frontend con configuración corregida..."
cd $APP_DIR

# Backup del archivo original
cp src/services/api.ts src/services/api.ts.backup 2>/dev/null || true

# Usar la configuración corregida
cp src/services/api-fixed.ts src/services/api.ts

# Recompilar frontend
npm run build:frontend

# Copiar a directorio de Nginx
cp -r dist/* /var/www/topping-frozen/

print_step "11. Reiniciando servicios..."
systemctl restart nginx

# Reiniciar backend si es necesario
cd $APP_DIR/backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 2
nohup npm run dev > /tmp/backend-final.log 2>&1 &
sleep 5

print_step "12. Verificación final..."
echo "=== Probando API después de los cambios ==="
curl -s http://apptoppingfrozen.com/api/health

echo ""
echo "=== Probando login después de los cambios ==="
LOGIN_RESULT=$(curl -s -X POST http://apptoppingfrozen.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}')

echo "Resultado del login: $LOGIN_RESULT"

if echo "$LOGIN_RESULT" | grep -q "token\|success"; then
    print_status "¡Login funcionando!"
else
    print_error "Login aún falla"
fi

echo ""
echo "🎉 DEBUG COMPLETADO"
echo "==================="
echo ""
echo "📋 RESUMEN:"
echo "   - Frontend recompilado con configuración de API corregida"
echo "   - Nginx reiniciado"
echo "   - Backend reiniciado"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 LOGS PARA REVISAR:"
echo "   Backend: tail -f /tmp/backend-final.log"
echo "   Nginx: tail -f /var/log/nginx/topping-frozen.error.log"
echo ""
print_status "Debug completado. Prueba el login ahora."
