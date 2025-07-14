#!/bin/bash

# Script para corregir comunicación entre frontend y backend
echo "🔗 Corrigiendo comunicación frontend-backend..."

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

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
print_info "IP del servidor: $SERVER_IP"

# 1. Verificar que el backend esté realmente funcionando
print_status "1. Verificando estado del backend..."
pm2 restart topping-frozen-backend
sleep 5

# Verificar que PM2 esté corriendo
if pm2 list | grep -q "online"; then
    print_status "Backend PM2 está online"
else
    print_error "Backend PM2 no está online"
    print_info "Iniciando backend manualmente..."
    cd /var/www/topping-frozen-app
    pm2 start ecosystem.config.js
    sleep 5
fi

# 2. Verificar que el puerto 3001 esté abierto
print_status "2. Verificando puerto 3001..."
if netstat -tlnp | grep -q ":3001"; then
    print_status "Puerto 3001 está abierto"
else
    print_error "Puerto 3001 no está abierto"
fi

# 3. Verificar que el backend responda localmente
print_status "3. Verificando respuesta local del backend..."
BACKEND_LOCAL=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if [ ! -z "$BACKEND_LOCAL" ]; then
    print_status "Backend responde localmente: $BACKEND_LOCAL"
else
    print_error "Backend no responde localmente"
fi

# 4. Verificar que el backend responda desde la IP externa
print_status "4. Verificando respuesta externa del backend..."
BACKEND_EXTERNAL=$(curl -s http://$SERVER_IP/api/health 2>/dev/null)
if [ ! -z "$BACKEND_EXTERNAL" ]; then
    print_status "Backend responde externamente: $BACKEND_EXTERNAL"
else
    print_error "Backend no responde externamente"
    print_info "Problema con Nginx proxy"
fi

# 5. Verificar configuración de Nginx
print_status "5. Verificando configuración de Nginx..."
if nginx -t > /dev/null 2>&1; then
    print_status "Configuración de Nginx OK"
else
    print_error "Error en configuración de Nginx"
    nginx -t
fi

# 6. Verificar configuración del frontend
print_status "6. Verificando configuración del frontend..."
cd /var/www/topping-frozen-app

# Verificar archivo de configuración de API
if [ -f "src/services/api.ts" ]; then
    print_info "Configuración actual de API:"
    grep -n "baseURL\|API_URL\|localhost" src/services/api.ts || echo "No se encontró configuración específica"
    
    # Verificar si está apuntando a localhost en lugar de la IP
    if grep -q "localhost" src/services/api.ts; then
        print_warning "Frontend está apuntando a localhost, corrigiendo..."
        
        # Hacer backup
        cp src/services/api.ts src/services/api.ts.backup
        
        # Corregir configuración
        sed -i "s/localhost/$SERVER_IP/g" src/services/api.ts
        sed -i "s/127.0.0.1/$SERVER_IP/g" src/services/api.ts
        
        print_status "Configuración de API corregida"
        
        # Reconstruir frontend
        print_status "Reconstruyendo frontend..."
        npm run build
    fi
fi

# 7. Verificar variables de entorno del frontend
print_status "7. Verificando variables de entorno del frontend..."
if [ -f ".env" ]; then
    print_info "Variables de entorno del frontend:"
    cat .env | grep -v "PASSWORD\|SECRET"
else
    print_warning "Creando archivo .env para frontend..."
    cat > .env << EOF
REACT_APP_API_URL=http://$SERVER_IP/api
REACT_APP_BACKEND_URL=http://$SERVER_IP
EOF
    print_status "Archivo .env creado para frontend"
    
    # Reconstruir frontend
    print_status "Reconstruyendo frontend con nuevas variables..."
    npm run build
fi

# 8. Verificar CORS en el backend
print_status "8. Verificando CORS del backend..."
cd backend

# Verificar archivo .env del backend
if grep -q "ALLOWED_ORIGINS" .env; then
    print_status "CORS configurado en backend"
else
    print_warning "Agregando configuración CORS..."
    echo "ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP" >> .env
    pm2 restart topping-frozen-backend
    sleep 3
fi

cd ..

# 9. Probar login desde diferentes puntos
print_status "9. Probando login desde diferentes puntos..."

echo ""
print_info "Prueba 1: Login desde localhost (backend directo):"
LOGIN_LOCAL=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "$LOGIN_LOCAL"

echo ""
print_info "Prueba 2: Login desde IP externa (a través de Nginx):"
LOGIN_EXTERNAL=$(curl -s -X POST http://$SERVER_IP/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "$LOGIN_EXTERNAL"

echo ""
print_info "Prueba 3: Verificando CORS headers:"
CORS_HEADERS=$(curl -s -I -H "Origin: http://$SERVER_IP" http://$SERVER_IP/api/health 2>/dev/null | grep -i "access-control")
if [ ! -z "$CORS_HEADERS" ]; then
    echo "$CORS_HEADERS"
else
    print_warning "No se encontraron headers CORS"
fi

# 10. Verificar logs en tiempo real
print_status "10. Verificando logs del backend..."
print_info "Últimos logs del backend:"
pm2 logs topping-frozen-backend --lines 10 --nostream

# 11. Verificar logs de Nginx
print_status "11. Verificando logs de Nginx..."
if [ -f "/var/log/nginx/topping-frozen.error.log" ]; then
    print_info "Últimos errores de Nginx:"
    tail -5 /var/log/nginx/topping-frozen.error.log 2>/dev/null || echo "No hay errores recientes"
fi

# 12. Reiniciar servicios
print_status "12. Reiniciando servicios..."
systemctl reload nginx
pm2 restart topping-frozen-backend
sleep 5

# 13. Verificación final
print_status "13. Verificación final..."
echo ""

# Verificar que todo esté funcionando
FINAL_HEALTH=$(curl -s http://$SERVER_IP/api/health 2>/dev/null)
FINAL_LOGIN=$(curl -s -X POST http://$SERVER_IP/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "🔍 RESULTADOS FINALES:"
echo "=================================================="
echo ""
echo "Health check: $FINAL_HEALTH"
echo ""
echo "Login test: $FINAL_LOGIN"
echo ""

if echo "$FINAL_LOGIN" | grep -q "token\|success"; then
    print_status "✅ ¡Login funcionando correctamente!"
else
    print_warning "⚠️  Login aún tiene problemas"
    echo ""
    echo "🔧 Comandos adicionales para debugging:"
    echo "   # Probar en el navegador (F12 > Console):"
    echo "   fetch('http://$SERVER_IP/api/auth/login', {"
    echo "     method: 'POST',"
    echo "     headers: {'Content-Type': 'application/json'},"
    echo "     body: JSON.stringify({username: 'admin', password: '123456'})"
    echo "   }).then(r => r.json()).then(console.log)"
    echo ""
    echo "   # Ver logs en tiempo real:"
    echo "   pm2 logs topping-frozen-backend --lines 0"
fi

echo ""
echo "🌐 URLs para probar:"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend: http://$SERVER_IP/api/health"
echo "   Login directo: http://$SERVER_IP/api/auth/login"
echo ""
echo "🔐 Credenciales:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
