#!/bin/bash

# 🔧 Script para Solucionar Problema de Login - Topping Frozen
# Ejecutar como: bash fix-login-issue.sh

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

echo "🔧 Solucionando problema de Login..."
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

print_step "1. Verificando backend..."
if curl -s http://127.0.0.1:3001/api/health | grep -q "success"; then
    print_status "Backend respondiendo correctamente"
else
    print_error "Backend no responde, reiniciando..."
    cd $APP_DIR/backend
    pkill -f "npm run dev" || true
    pkill -f "ts-node-dev" || true
    sleep 2
    nohup npm run dev > /tmp/backend.log 2>&1 &
    sleep 5
fi

print_step "2. Probando endpoint de login..."
LOGIN_TEST=$(curl -s -X POST http://127.0.0.1:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}')

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "Login endpoint funcionando"
else
    print_error "Login endpoint falló: $LOGIN_TEST"
fi

print_step "3. Configurando Nginx para HTTPS..."
# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

sudo tee /etc/nginx/sites-available/topping-frozen > /dev/null << EOF
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # SSL configuration (asumiendo que ya tienes certificados)
    # ssl_certificate /path/to/certificate.crt;
    # ssl_certificate_key /path/to/private.key;

    # Servir archivos estáticos del frontend
    location / {
        root /var/www/topping-frozen;
        try_files \$uri \$uri/ /index.html;
        index index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Proxy para API del backend con CORS
    location /api/ {
        # Configuración CORS
        add_header 'Access-Control-Allow-Origin' 'https://apptoppingfrozen.com' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://apptoppingfrozen.com';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOF

print_step "4. Configurando backend para CORS..."
cat > $APP_DIR/backend/cors-config.js << 'EOF'
const cors = require('cors');

const corsOptions = {
  origin: [
    'https://apptoppingfrozen.com',
    'https://www.apptoppingfrozen.com',
    'http://localhost:3000',
    'http://localhost:3001'
  ],
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

module.exports = corsOptions;
EOF

print_step "5. Actualizando configuración del backend..."
# Verificar que el backend tenga CORS configurado
if ! grep -q "cors" $APP_DIR/backend/src/index.ts; then
    print_error "CORS no configurado en backend"
fi

print_step "6. Reiniciando servicios..."
# Verificar configuración de Nginx
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    print_status "Nginx reiniciado"
else
    print_error "Error en configuración de Nginx"
fi

# Reiniciar backend
cd $APP_DIR/backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 3
nohup npm run dev > /tmp/backend.log 2>&1 &
sleep 5

print_step "7. Verificando conexión final..."
# Probar desde el dominio
if curl -s -k https://apptoppingfrozen.com/api/health | grep -q "success"; then
    print_status "API accesible desde el dominio"
else
    print_error "API no accesible desde el dominio"
fi

# Probar login desde el dominio
LOGIN_DOMAIN_TEST=$(curl -s -k -X POST https://apptoppingfrozen.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}')

if echo "$LOGIN_DOMAIN_TEST" | grep -q "token\|success"; then
    print_status "Login funcionando desde el dominio"
else
    print_error "Login falló desde el dominio: $LOGIN_DOMAIN_TEST"
fi

echo ""
echo "🎉 DIAGNÓSTICO COMPLETADO"
echo "========================="
echo ""
echo "📋 VERIFICACIONES:"
echo "   Backend local: $(curl -s http://127.0.0.1:3001/api/health | grep -q success && echo "✅ OK" || echo "❌ FAIL")"
echo "   API desde dominio: $(curl -s -k https://apptoppingfrozen.com/api/health | grep -q success && echo "✅ OK" || echo "❌ FAIL")"
echo ""
echo "🔧 COMANDOS PARA VERIFICAR:"
echo "   curl -s http://127.0.0.1:3001/api/health"
echo "   curl -s -k https://apptoppingfrozen.com/api/health"
echo "   sudo tail -f /var/log/nginx/topping-frozen.error.log"
echo "   tail -f /tmp/backend.log"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: https://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
print_status "Diagnóstico completado. Verifica los resultados arriba."
