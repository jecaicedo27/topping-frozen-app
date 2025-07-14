#!/bin/bash

# Script de depuración experta - Identificar el problema EXACTO
echo "🔍 MODO DEPURADOR EXPERTO - Análisis profundo del error 500"

cd /var/www/topping-frozen-app

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}❌ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo ""
echo "🔍 DEPURACIÓN PROFUNDA DEL ERROR 500"
echo "===================================="

# 1. VERIFICAR ESTADO ACTUAL DEL BACKEND
print_info "1. Estado actual del backend PM2:"
pm2 list | grep topping || print_error "Backend no está corriendo en PM2"

# 2. LOGS DETALLADOS DEL BACKEND
print_info "2. Logs detallados del backend (últimas 20 líneas):"
pm2 logs topping-frozen-backend --lines 20 --nostream 2>/dev/null || print_error "No se pueden obtener logs de PM2"

# 3. VERIFICAR ARCHIVO .ENV ACTUAL
print_info "3. Configuración actual del .env:"
if [ -f "backend/.env" ]; then
    cat backend/.env
else
    print_error "Archivo .env no existe"
fi

# 4. VERIFICAR CONEXIÓN MYSQL DIRECTA
print_info "4. Verificando conexión MySQL directa:"
mysql -e "SELECT 1;" 2>/dev/null && print_success "MySQL root funciona" || print_error "MySQL root falla"

# Probar con toppinguser
mysql -u toppinguser -pToppingPass2024! -e "SELECT 1;" 2>/dev/null && print_success "toppinguser funciona" || print_error "toppinguser falla"

# 5. VERIFICAR BASE DE DATOS Y TABLA
print_info "5. Verificando base de datos y tabla users:"
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SHOW TABLES;" 2>/dev/null || print_error "No se puede acceder a topping_frozen_db"

mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) as total_users FROM users;" 2>/dev/null || print_error "Tabla users no existe o no accesible"

# 6. VERIFICAR ARCHIVO COMPILADO DEL BACKEND
print_info "6. Verificando archivo compilado del backend:"
if [ -f "backend/dist/index.js" ]; then
    print_success "Archivo compilado existe"
    ls -la backend/dist/index.js
else
    print_error "Archivo compilado NO existe"
fi

# 7. PROBAR ENDPOINT DIRECTAMENTE
print_info "7. Probando endpoint de health directamente:"
HEALTH_LOCAL=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if [ -n "$HEALTH_LOCAL" ]; then
    print_success "Health endpoint responde: $HEALTH_LOCAL"
else
    print_error "Health endpoint NO responde"
fi

# 8. PROBAR LOGIN DIRECTAMENTE CON CURL
print_info "8. Probando login directamente con curl:"
LOGIN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Respuesta completa del login: $LOGIN_RESPONSE"

# 9. VERIFICAR PUERTO 3001
print_info "9. Verificando qué está corriendo en puerto 3001:"
netstat -tlnp | grep :3001 || print_error "Nada corriendo en puerto 3001"

# 10. VERIFICAR LOGS DE SISTEMA
print_info "10. Logs de sistema relacionados con Node.js:"
journalctl -u pm2-root --lines 10 --no-pager 2>/dev/null || print_warning "No hay logs de PM2 en systemd"

# 11. VERIFICAR VARIABLES DE ENTORNO EN TIEMPO REAL
print_info "11. Variables de entorno del proceso Node.js:"
ps aux | grep node | grep -v grep || print_error "No hay procesos Node.js corriendo"

# 12. ANÁLISIS DEL CÓDIGO - BUSCAR HARDCODED USERS
print_info "12. Buscando usuarios hardcodeados en el código:"
grep -r "admin.*facturacion.*cartera" backend/src/ 2>/dev/null || print_info "No se encontraron usuarios hardcodeados en backend"

# 13. VERIFICAR CONFIGURACIÓN DE NGINX
print_info "13. Verificando configuración de Nginx:"
nginx -t 2>/dev/null && print_success "Nginx configuración OK" || print_error "Error en configuración Nginx"

# 14. DIAGNÓSTICO FINAL
echo ""
print_info "🔍 DIAGNÓSTICO FINAL:"
echo "===================="

# Verificar si el problema es de conexión a BD
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" >/dev/null 2>&1; then
    print_success "Base de datos accesible"
    
    # Verificar si hay usuarios
    USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
    if [ "$USER_COUNT" -gt 0 ]; then
        print_success "Tabla users tiene $USER_COUNT usuarios"
    else
        print_error "Tabla users está vacía"
    fi
else
    print_error "PROBLEMA PRINCIPAL: No se puede conectar a la base de datos"
fi

# Verificar si el backend está corriendo
if pm2 list | grep -q "online"; then
    print_success "Backend PM2 está online"
else
    print_error "PROBLEMA PRINCIPAL: Backend PM2 no está online"
fi

# Verificar si responde a peticiones
if curl -s http://localhost:3001/api/health >/dev/null 2>&1; then
    print_success "Backend responde a peticiones"
else
    print_error "PROBLEMA PRINCIPAL: Backend no responde a peticiones"
fi

echo ""
print_info "🔧 RECOMENDACIONES BASADAS EN EL DIAGNÓSTICO:"
echo "============================================="

# Dar recomendaciones específicas basadas en los hallazgos
if ! pm2 list | grep -q "online"; then
    echo "1. REINICIAR BACKEND: pm2 restart topping-frozen-backend"
fi

if ! mysql -u toppinguser -pToppingPass2024! -e "SELECT 1;" >/dev/null 2>&1; then
    echo "2. RECREAR USUARIO MYSQL: Ejecutar comandos de creación de usuario"
fi

if [ ! -f "backend/dist/index.js" ]; then
    echo "3. RECOMPILAR BACKEND: cd backend && npx tsc"
fi

echo ""
print_info "Ejecuta las recomendaciones en orden y vuelve a probar el login."
