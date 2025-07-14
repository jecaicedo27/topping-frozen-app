#!/bin/bash

# Script de diagnóstico rápido para el login
echo "🔍 Diagnóstico rápido del login..."

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
echo "🔍 DIAGNÓSTICO RÁPIDO"
echo "===================="

# 1. Verificar si el frontend está usando la URL correcta
print_status "1. Verificando URL del frontend..."
cd /var/www/topping-frozen-app
if grep -q "localhost" src/services/api.ts; then
    print_error "Frontend AÚN apunta a localhost"
    print_info "Contenido actual:"
    grep -n "API_URL" src/services/api.ts
else
    print_status "Frontend apunta a la IP correcta"
    grep -n "API_URL" src/services/api.ts
fi

# 2. Verificar si el backend está corriendo
print_status "2. Verificando backend..."
if pm2 list | grep -q "online"; then
    print_status "Backend PM2 está online"
else
    print_error "Backend PM2 NO está online"
fi

# 3. Probar el backend directamente
print_status "3. Probando backend directamente..."
HEALTH_LOCAL=$(curl -s http://localhost:3001/api/health 2>/dev/null)
print_info "Health local: $HEALTH_LOCAL"

HEALTH_EXTERNAL=$(curl -s http://46.202.93.54/api/health 2>/dev/null)
print_info "Health externo: $HEALTH_EXTERNAL"

# 4. Probar login directamente
print_status "4. Probando login directamente..."
LOGIN_TEST=$(curl -s -X POST http://46.202.93.54/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)
print_info "Login test: $LOGIN_TEST"

# 5. Verificar logs del backend
print_status "5. Últimos logs del backend..."
pm2 logs topping-frozen-backend --lines 5 --nostream

# 6. Verificar si el frontend fue recompilado
print_status "6. Verificando frontend compilado..."
if [ -f "dist/index.html" ]; then
    print_status "Frontend compilado existe"
    LAST_BUILD=$(stat -c %Y dist/index.html)
    CURRENT_TIME=$(date +%s)
    AGE=$((CURRENT_TIME - LAST_BUILD))
    print_info "Última compilación hace: $((AGE/60)) minutos"
else
    print_error "Frontend NO está compilado"
fi

# 7. Verificar Nginx
print_status "7. Verificando Nginx..."
if nginx -t > /dev/null 2>&1; then
    print_status "Nginx configuración OK"
else
    print_error "Error en configuración de Nginx"
fi

echo ""
echo "🔧 ACCIONES RECOMENDADAS:"
echo "========================"

if grep -q "localhost" src/services/api.ts; then
    print_warning "1. URGENTE: Corregir URL del frontend"
    echo "   sed -i 's/localhost:3001/46.202.93.54/g' src/services/api.ts"
    echo "   npm run build"
fi

if ! pm2 list | grep -q "online"; then
    print_warning "2. URGENTE: Reiniciar backend"
    echo "   pm2 restart topping-frozen-backend"
fi

if [ ! -f "dist/index.html" ]; then
    print_warning "3. URGENTE: Compilar frontend"
    echo "   npm run build"
fi

echo ""
print_info "Para aplicar TODAS las correcciones automáticamente:"
echo "sudo ./ultimate-login-fix.sh"
