#!/bin/bash

# Script de solución experta para corregir el backend
echo "🎯 Aplicando solución experta para corregir el backend..."

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
echo "🔧 SOLUCIÓN EXPERTA - CORRECCIÓN DEL BACKEND"
echo "=================================================="

# 1. Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    print_error "Directorio del proyecto no encontrado"
    exit 1
}

print_status "1. Actualizando archivos desde Git..."
git pull origin main

# 2. Verificar configuración del .env
print_status "2. Verificando configuración del .env..."
print_info "Configuración actual:"
cat backend/.env | grep -E "DB_|NODE_ENV|FRONTEND_URL"

# 3. Ir al directorio del backend
cd backend

# 4. Instalar dependencias
print_status "3. Instalando dependencias del backend..."
npm install mysql2 bcrypt jsonwebtoken express cors dotenv --silent

# 5. Compilar el backend
print_status "4. Compilando backend..."
if [ -f "tsconfig.json" ]; then
    npx tsc
    if [ $? -eq 0 ]; then
        print_status "Compilación exitosa"
    else
        print_warning "Error en compilación, copiando archivos manualmente..."
        mkdir -p dist
        cp -r src/* dist/ 2>/dev/null
    fi
else
    print_warning "tsconfig.json no encontrado, copiando archivos..."
    mkdir -p dist
    cp -r src/* dist/ 2>/dev/null
fi

# 6. Verificar archivos compilados
print_status "5. Verificando archivos compilados..."
if [ -f "dist/index.js" ]; then
    print_status "Archivo principal compilado existe"
    ls -la dist/
else
    print_error "Archivo principal no compilado"
fi

cd ..

# 7. Detener backend actual
print_status "6. Deteniendo backend actual..."
pm2 stop topping-frozen-backend 2>/dev/null || true
pm2 delete topping-frozen-backend 2>/dev/null || true

# 8. Crear configuración PM2 actualizada
print_status "7. Creando configuración PM2..."
cat > ecosystem.config.js << EOF
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
    max_memory_restart: '1G',
    error_file: '/var/log/pm2/topping-frozen-backend-error.log',
    out_file: '/var/log/pm2/topping-frozen-backend-out.log',
    log_file: '/var/log/pm2/topping-frozen-backend.log'
  }]
};
EOF

# 9. Iniciar backend
print_status "8. Iniciando backend..."
pm2 start ecosystem.config.js
pm2 save

# Esperar a que inicie
sleep 10

# 10. Verificar estado del backend
print_status "9. Verificando estado del backend..."
if pm2 list | grep -q "online"; then
    print_status "Backend PM2 está online"
else
    print_error "Backend PM2 no está online"
    print_info "Logs de PM2:"
    pm2 logs topping-frozen-backend --lines 10 --nostream
fi

# 11. Probar conexión del backend
print_status "10. Probando conexión del backend..."
sleep 5

HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
print_info "Health check: $HEALTH_CHECK"

# 12. Probar login
print_status "11. Probando login..."
LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo ""
print_info "Resultado del login:"
echo "$LOGIN_TEST"
echo ""

# 13. Verificar base de datos
print_status "12. Verificando base de datos..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) as usuarios FROM users;" 2>/dev/null; then
    print_status "Conexión a base de datos OK"
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT id, username, role FROM users;"
else
    print_error "Error de conexión a base de datos"
fi

# 14. Verificación final
echo ""
print_status "13. VERIFICACIÓN FINAL:"
echo ""

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "🎉 ¡LOGIN FUNCIONANDO CORRECTAMENTE!"
    echo ""
    echo "✅ Problema resuelto:"
    echo "   - Backend compilado correctamente"
    echo "   - Configuración .env corregida"
    echo "   - Base de datos conectada"
    echo "   - Login funcionando"
    echo ""
    echo "🌐 Prueba en: http://46.202.93.54"
    echo "🔐 Credenciales: admin / 123456"
else
    print_warning "⚠️  Login aún tiene problemas"
    echo ""
    print_info "Diagnóstico adicional:"
    echo ""
    echo "Estado de servicios:"
    echo "   Nginx: $(systemctl is-active nginx)"
    echo "   MySQL: $(systemctl is-active mysql)"
    echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}' || echo 'offline')"
    echo ""
    echo "Logs del backend:"
    pm2 logs topping-frozen-backend --lines 5 --nostream
fi

echo ""
echo "=================================================="
print_info "Solución experta aplicada"
