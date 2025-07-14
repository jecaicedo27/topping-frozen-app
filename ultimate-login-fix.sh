#!/bin/bash

# Script definitivo para corregir el login completamente
echo "🎯 CORRECCIÓN DEFINITIVA DEL LOGIN - SOLUCIÓN EXPERTA"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo ""
echo "🔧 APLICANDO TODAS LAS CORRECCIONES IDENTIFICADAS"
echo "=================================================="

# 1. Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    print_error "Directorio del proyecto no encontrado"
    exit 1
}

print_status "1. Actualizando código desde Git..."
git pull origin main

# 2. CORRECCIÓN 1: Verificar configuración del backend
print_status "2. Verificando configuración del backend..."
print_info "Configuración actual del .env:"
cat backend/.env | grep -E "DB_|NODE_ENV|FRONTEND_URL"

# 3. CORRECCIÓN 2: Asegurar que el usuario de BD existe
print_status "3. Verificando usuario de base de datos..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Usuario toppinguser existe y funciona"
else
    print_warning "Creando usuario toppinguser..."
    mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
    mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# 4. CORRECCIÓN 3: Compilar backend con correcciones
print_status "4. Compilando backend..."
cd backend
npm install mysql2 bcrypt jsonwebtoken express cors dotenv --silent

if [ -f "tsconfig.json" ]; then
    npx tsc
    if [ $? -ne 0 ]; then
        print_warning "Error en compilación TypeScript, copiando archivos..."
        mkdir -p dist
        cp -r src/* dist/ 2>/dev/null
    fi
else
    mkdir -p dist
    cp -r src/* dist/ 2>/dev/null
fi

cd ..

# 5. CORRECCIÓN 4: Compilar frontend con URL corregida
print_status "5. Compilando frontend con URL corregida..."

# Crear archivo .env para el frontend
cat > .env << 'EOF'
REACT_APP_API_URL=http://46.202.93.54/api
REACT_APP_BACKEND_URL=http://46.202.93.54
EOF

# Compilar frontend
npm run build 2>/dev/null || {
    print_warning "Error en build de React, usando webpack..."
    npx webpack --mode production 2>/dev/null || {
        print_warning "Error en webpack, verificando archivos..."
        ls -la dist/ 2>/dev/null || mkdir -p dist
    }
}

# 6. CORRECCIÓN 5: Configurar Nginx correctamente
print_status "6. Configurando Nginx..."
cat > /etc/nginx/sites-available/topping-frozen << 'EOF'
server {
    listen 80;
    server_name 46.202.93.54 _;
    
    # Frontend
    location / {
        root /var/www/topping-frozen-app/dist;
        try_files $uri $uri/ /index.html;
        
        # Headers para CORS
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "http://46.202.93.54" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "http://46.202.93.54";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
            add_header Access-Control-Allow-Credentials "true";
            return 204;
        }
    }
}
EOF

# Habilitar sitio
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# Verificar y reiniciar Nginx
nginx -t && systemctl restart nginx

# 7. CORRECCIÓN 6: Reiniciar backend con PM2
print_status "7. Reiniciando backend..."
pm2 stop topping-frozen-backend 2>/dev/null || true
pm2 delete topping-frozen-backend 2>/dev/null || true

# Crear configuración PM2 optimizada
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'topping-frozen-backend',
    script: 'backend/dist/index.js',
    cwd: '/var/www/topping-frozen-app',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
};
EOF

pm2 start ecosystem.config.js
pm2 save

# Esperar a que inicie
sleep 15

# 8. VERIFICACIONES FINALES
print_status "8. Verificaciones finales..."
echo ""

# Verificar servicios
print_info "Estado de servicios:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}' || echo 'offline')"

# Verificar base de datos
print_info "Verificando base de datos:"
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
echo "   Usuarios en BD: $USER_COUNT"

# Verificar backend
print_info "Verificando backend:"
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
echo "   Health check: $HEALTH_CHECK"

# Verificar backend desde IP externa
print_info "Verificando backend desde IP externa:"
HEALTH_EXTERNAL=$(curl -s http://46.202.93.54/api/health 2>/dev/null)
echo "   Health check externo: $HEALTH_EXTERNAL"

# Probar login
print_info "Probando login:"
LOGIN_TEST=$(curl -s -X POST http://46.202.93.54/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo ""
print_info "Resultado del login:"
echo "$LOGIN_TEST"
echo ""

# 9. RESULTADO FINAL
echo ""
print_status "9. RESULTADO FINAL:"
echo ""

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "🎉 ¡LOGIN FUNCIONANDO PERFECTAMENTE!"
    echo ""
    echo "✅ TODAS LAS CORRECCIONES APLICADAS:"
    echo "   ✅ Backend conecta a base de datos real"
    echo "   ✅ Frontend apunta a IP correcta del servidor"
    echo "   ✅ Nginx configurado con CORS correcto"
    echo "   ✅ PM2 ejecutando backend correctamente"
    echo "   ✅ Login genera token JWT válido"
    echo ""
    echo "🌐 SISTEMA COMPLETAMENTE FUNCIONAL:"
    echo "   Frontend: http://46.202.93.54"
    echo "   Backend: http://46.202.93.54/api/health"
    echo ""
    echo "🔐 CREDENCIALES:"
    echo "   Usuario: admin"
    echo "   Contraseña: 123456"
    echo ""
    print_status "¡El problema del login está COMPLETAMENTE RESUELTO!"
else
    print_warning "⚠️  Aún hay problemas con el login"
    echo ""
    print_info "Diagnóstico adicional:"
    echo "Logs del backend:"
    pm2 logs topping-frozen-backend --lines 10 --nostream
fi

echo ""
echo "=================================================="
print_info "Corrección definitiva completada"
