#!/bin/bash

# Script para verificar el estado actual del sistema
echo "🔍 Verificando estado actual del sistema..."

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
echo "🔍 DIAGNÓSTICO COMPLETO DEL SISTEMA"
echo "=================================================="

# 1. Verificar configuración del .env
print_status "1. Configuración actual del backend (.env):"
echo ""
if [ -f "/var/www/topping-frozen-app/backend/.env" ]; then
    cat /var/www/topping-frozen-app/backend/.env
else
    print_error "Archivo .env no encontrado"
fi

echo ""
echo "=================================================="

# 2. Verificar conexión a base de datos
print_status "2. Verificando conexión a base de datos:"
echo ""

# Probar con root
print_info "Probando conexión como root:"
if mysql -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Conexión root OK"
    mysql -e "SHOW DATABASES;" | grep topping
else
    print_error "No se puede conectar como root"
fi

# Probar con toppinguser
print_info "Probando conexión como toppinguser:"
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) as usuarios FROM users;" 2>/dev/null; then
    print_status "Conexión toppinguser OK"
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT username, role FROM users;"
else
    print_error "No se puede conectar como toppinguser"
    print_info "Verificando si el usuario existe:"
    mysql -e "SELECT User, Host FROM mysql.user WHERE User='toppinguser';" 2>/dev/null
fi

echo ""
echo "=================================================="

# 3. Verificar estado de servicios
print_status "3. Estado de servicios:"
echo ""
echo "   Nginx: $(systemctl is-active nginx)"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}' || echo 'offline')"

echo ""
echo "=================================================="

# 4. Verificar logs del backend
print_status "4. Últimos logs del backend:"
echo ""
pm2 logs topping-frozen-backend --lines 15 --nostream

echo ""
echo "=================================================="

# 5. Probar endpoints
print_status "5. Probando endpoints:"
echo ""

print_info "Health check:"
HEALTH=$(curl -s http://localhost:3001/api/health 2>/dev/null)
echo "$HEALTH"

echo ""
print_info "Login test:"
LOGIN=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
echo "$LOGIN"

echo ""
echo "=================================================="

# 6. Verificar archivos del backend
print_status "6. Verificando archivos del backend:"
echo ""

print_info "¿Existe el archivo compilado?"
if [ -f "/var/www/topping-frozen-app/backend/dist/index.js" ]; then
    print_status "Archivo compilado existe"
    ls -la /var/www/topping-frozen-app/backend/dist/
else
    print_error "Archivo compilado NO existe"
    print_info "Contenido del directorio backend:"
    ls -la /var/www/topping-frozen-app/backend/
fi

echo ""
echo "=================================================="

# 7. Verificar configuración de PM2
print_status "7. Configuración de PM2:"
echo ""
if [ -f "/var/www/topping-frozen-app/ecosystem.config.js" ]; then
    print_info "Configuración de PM2:"
    cat /var/www/topping-frozen-app/ecosystem.config.js
else
    print_error "Archivo ecosystem.config.js no encontrado"
fi

echo ""
echo "=================================================="

# 8. Resumen y recomendaciones
print_status "8. RESUMEN Y RECOMENDACIONES:"
echo ""

if echo "$LOGIN" | grep -q "token\|success"; then
    print_status "✅ Sistema funcionando correctamente"
else
    print_warning "⚠️  Sistema tiene problemas"
    echo ""
    echo "🔧 Pasos recomendados:"
    echo "1. Verificar que el .env tenga las credenciales correctas"
    echo "2. Asegurar que el usuario 'toppinguser' exista en MySQL"
    echo "3. Recompilar el backend si es necesario"
    echo "4. Reiniciar PM2 con la configuración correcta"
fi

echo ""
echo "🌐 URLs para probar:"
echo "   Frontend: http://46.202.93.54"
echo "   Backend: http://46.202.93.54/api/health"
