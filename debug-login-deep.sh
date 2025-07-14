#!/bin/bash

# Script de diagnóstico profundo para el login
echo "🔍 Diagnóstico profundo del sistema de login..."

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

echo ""
echo "🔍 DIAGNÓSTICO COMPLETO DEL LOGIN"
echo "=================================================="

# 1. Verificar que el backend responda
print_status "1. Verificando backend..."
BACKEND_HEALTH=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if [ ! -z "$BACKEND_HEALTH" ]; then
    print_status "Backend responde: $BACKEND_HEALTH"
else
    print_error "Backend no responde"
fi

# 2. Verificar usuarios en base de datos
print_status "2. Verificando usuarios en base de datos..."
echo ""
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT id, username, role, LEFT(password, 20) as password_hash, is_active FROM users;" 2>/dev/null

# 3. Probar login directo con curl
print_status "3. Probando login directo con curl..."
echo ""
print_info "Probando admin/123456:"
LOGIN_RESULT=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "Respuesta: $LOGIN_RESULT"

echo ""
print_info "Probando desde IP externa:"
LOGIN_RESULT_EXTERNAL=$(curl -s -X POST http://$SERVER_IP/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "Respuesta: $LOGIN_RESULT_EXTERNAL"

# 4. Verificar logs del backend en tiempo real
print_status "4. Verificando logs del backend..."
echo ""
print_info "Últimos 10 logs del backend:"
pm2 logs topping-frozen-backend --lines 10 --nostream

# 5. Verificar configuración de CORS
print_status "5. Verificando CORS..."
echo ""
CORS_TEST=$(curl -s -I -H "Origin: http://$SERVER_IP" http://localhost:3001/api/health 2>/dev/null | grep -i "access-control")
if [ ! -z "$CORS_TEST" ]; then
    print_status "CORS headers encontrados:"
    echo "$CORS_TEST"
else
    print_warning "No se encontraron headers CORS"
fi

# 6. Verificar archivo .env del backend
print_status "6. Verificando configuración del backend..."
echo ""
cd /var/www/topping-frozen-app/backend
if [ -f ".env" ]; then
    print_info "Archivo .env existe. Contenido (sin contraseñas):"
    grep -v "PASSWORD\|SECRET" .env
else
    print_error "Archivo .env no existe"
fi

# 7. Verificar que el frontend esté apuntando al backend correcto
print_status "7. Verificando configuración del frontend..."
echo ""
cd /var/www/topping-frozen-app
if [ -f "src/services/api.ts" ]; then
    print_info "Configuración de API en frontend:"
    grep -n "baseURL\|API_URL\|localhost\|46.202" src/services/api.ts || echo "No se encontró configuración específica"
fi

# 8. Generar nuevo hash para verificar
print_status "8. Generando hash de prueba..."
echo ""
cd /var/www/topping-frozen-app/backend
NEW_HASH=$(node -e "const bcrypt = require('bcrypt'); console.log(bcrypt.hashSync('123456', 10));" 2>/dev/null)
if [ ! -z "$NEW_HASH" ]; then
    print_info "Nuevo hash generado: $NEW_HASH"
    
    # Actualizar hash en base de datos
    print_info "Actualizando hash del usuario admin..."
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "UPDATE users SET password = '$NEW_HASH' WHERE username = 'admin';"
    print_status "Hash actualizado"
else
    print_warning "No se pudo generar nuevo hash"
fi

# 9. Reiniciar backend y probar de nuevo
print_status "9. Reiniciando backend..."
pm2 restart topping-frozen-backend
sleep 5

print_status "10. Prueba final después de reinicio..."
echo ""
FINAL_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "Resultado final: $FINAL_TEST"

# 10. Verificar si hay errores en nginx
print_status "11. Verificando logs de Nginx..."
echo ""
if [ -f "/var/log/nginx/topping-frozen.error.log" ]; then
    print_info "Últimos errores de Nginx:"
    tail -5 /var/log/nginx/topping-frozen.error.log 2>/dev/null || echo "No hay errores recientes"
fi

# 11. Verificar conectividad de red
print_status "12. Verificando conectividad..."
echo ""
print_info "Puertos en uso:"
netstat -tlnp | grep -E ':(80|3001|8080)'

echo ""
echo "🧪 COMANDOS DE PRUEBA MANUAL"
echo "=================================================="
echo ""
echo "# Probar desde el servidor:"
echo "curl -X POST http://localhost:3001/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"123456\"}'"
echo ""
echo "# Probar desde navegador (abrir consola F12):"
echo "fetch('http://$SERVER_IP/api/auth/login', {"
echo "  method: 'POST',"
echo "  headers: {'Content-Type': 'application/json'},"
echo "  body: JSON.stringify({username: 'admin', password: '123456'})"
echo "}).then(r => r.json()).then(console.log)"
echo ""
echo "# Ver logs en tiempo real:"
echo "pm2 logs topping-frozen-backend --lines 0"
echo ""

# Verificación final
if echo "$FINAL_TEST" | grep -q "token\|success"; then
    print_status "✅ Login funcionando correctamente!"
else
    print_warning "⚠️  Login aún tiene problemas. Revisar logs y configuración."
    echo ""
    echo "🔧 Próximos pasos sugeridos:"
    echo "1. Revisar logs del backend: pm2 logs topping-frozen-backend"
    echo "2. Verificar configuración de CORS en el código"
    echo "3. Comprobar que el frontend esté apuntando a la URL correcta"
    echo "4. Verificar que no haya problemas de red/firewall"
fi

echo ""
echo "=================================================="
print_info "Diagnóstico completado"
