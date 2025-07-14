#!/bin/bash

# Script para reiniciar el backend con la configuración correcta
echo "🔄 Reiniciando backend con configuración corregida..."

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

# Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    print_error "Directorio del proyecto no encontrado"
    exit 1
}

# 1. Mostrar configuración actual
print_status "1. Verificando configuración del .env..."
print_info "Configuración actual del backend:"
echo ""
cat backend/.env | grep -E "DB_|NODE_ENV|FRONTEND_URL"
echo ""

# 2. Verificar conexión a base de datos con las nuevas credenciales
print_status "2. Verificando conexión a base de datos..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) as usuarios FROM users;" 2>/dev/null; then
    print_status "Conexión a base de datos OK con nuevas credenciales"
else
    print_error "Error de conexión a base de datos"
    print_info "Verificando si el usuario existe..."
    mysql -e "SELECT User, Host FROM mysql.user WHERE User='toppinguser';" 2>/dev/null || {
        print_warning "Usuario no existe, creando..."
        mysql -e "CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
        mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"
    }
fi

# 3. Reiniciar backend
print_status "3. Reiniciando backend..."
pm2 restart topping-frozen-backend
sleep 5

# 4. Verificar que el backend esté funcionando
print_status "4. Verificando backend..."
if pm2 list | grep -q "online"; then
    print_status "Backend PM2 está online"
else
    print_error "Backend PM2 no está online"
    print_info "Intentando iniciar manualmente..."
    pm2 start ecosystem.config.js
    sleep 5
fi

# 5. Probar conexión del backend
print_status "5. Probando conexión del backend..."
sleep 3

HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
print_info "Health check: $HEALTH_CHECK"

# 6. Probar login
print_status "6. Probando login..."
LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo ""
print_info "Resultado del login:"
echo "$LOGIN_TEST"
echo ""

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "✅ ¡LOGIN FUNCIONANDO CORRECTAMENTE!"
    echo ""
    echo "🎉 El backend ahora puede conectar a la base de datos"
    echo "🔐 Puedes iniciar sesión con: admin / 123456"
    echo "🌐 Prueba en: http://46.202.93.54"
else
    print_warning "Login aún tiene problemas"
    echo ""
    print_info "Verificando logs del backend:"
    pm2 logs topping-frozen-backend --lines 10 --nostream
fi

# 7. Mostrar estado final
echo ""
print_status "7. Estado final del sistema:"
echo ""
print_info "Servicios:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}' || echo 'offline')"

print_info "Base de datos:"
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
echo "   Usuarios: $USER_COUNT"

echo ""
echo "🌐 URLs para probar:"
echo "   Frontend: http://46.202.93.54"
echo "   Backend: http://46.202.93.54/api/health"
echo ""
echo "🔐 Credenciales:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
