#!/bin/bash

# Script para actualizar y corregir el servidor VPS automáticamente
# Ejecutar directamente en el servidor VPS

echo "🚀 Actualizando y corrigiendo servidor Topping Frozen..."
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Verificar que estamos en el directorio correcto
if [ ! -d "/var/www/topping-frozen-app" ]; then
    print_error "Directorio del proyecto no encontrado. ¿Estás en el servidor correcto?"
    exit 1
fi

# Ir al directorio del proyecto
cd /var/www/topping-frozen-app

print_info "Directorio actual: $(pwd)"

# Paso 1: Actualizar desde Git
print_status "Actualizando código desde Git..."
git pull origin main

if [ $? -eq 0 ]; then
    print_status "Código actualizado correctamente"
else
    print_warning "Problema al actualizar desde Git, continuando..."
fi

# Paso 2: Hacer scripts ejecutables
print_status "Configurando permisos de scripts..."
chmod +x fix-server-issues.sh 2>/dev/null
chmod +x quick-vps-fix.sh 2>/dev/null
chmod +x update-and-fix-server.sh 2>/dev/null

# Paso 3: Verificar qué script usar
if [ -f "quick-vps-fix.sh" ]; then
    SCRIPT_TO_USE="quick-vps-fix.sh"
    print_info "Usando script de corrección rápida"
elif [ -f "fix-server-issues.sh" ]; then
    SCRIPT_TO_USE="fix-server-issues.sh"
    print_info "Usando script de corrección completa"
else
    print_error "No se encontraron scripts de corrección"
    exit 1
fi

# Paso 4: Ejecutar corrección
print_status "Ejecutando corrección del servidor..."
echo "=================================================="

./$SCRIPT_TO_USE

# Paso 5: Verificaciones finales
echo ""
echo "=================================================="
print_status "Verificaciones finales..."

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Verificar servicios
print_info "Estado de servicios:"
if systemctl is-active --quiet nginx; then
    print_status "Nginx: Activo"
else
    print_error "Nginx: Inactivo"
fi

if systemctl is-active --quiet mysql; then
    print_status "MySQL: Activo"
else
    print_error "MySQL: Inactivo"
fi

if pm2 list | grep -q "online"; then
    print_status "Backend PM2: Activo"
else
    print_error "Backend PM2: Inactivo"
fi

# Verificar endpoints
print_info "Probando endpoints..."
sleep 5

if curl -s http://localhost/api/health > /dev/null 2>&1; then
    print_status "Health check: OK"
else
    print_warning "Health check: No responde"
fi

if curl -s http://localhost > /dev/null 2>&1; then
    print_status "Frontend: OK"
else
    print_warning "Frontend: No responde"
fi

# Mostrar información final
echo ""
echo "🎉 ¡Actualización y corrección completada!"
echo "=================================================="
echo ""
echo "📋 URLs para probar:"
echo "   🌐 Frontend: http://$SERVER_IP"
echo "   🔧 Backend API: http://$SERVER_IP/api/health"
echo "   🗄️  phpMyAdmin: http://$SERVER_IP:8080"
echo ""
echo "👤 Credenciales de prueba:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
echo ""
echo "🔧 Comandos útiles:"
echo "   Ver logs: pm2 logs topping-frozen-backend"
echo "   Estado PM2: pm2 status"
echo "   Estado Nginx: systemctl status nginx"
echo ""

# Verificación final
if curl -s http://localhost/api/health > /dev/null 2>&1 && curl -s http://localhost > /dev/null 2>&1; then
    print_status "¡Servidor funcionando correctamente! 🚀"
    echo ""
    echo "✅ Puedes probar la aplicación en: http://$SERVER_IP"
else
    print_warning "Servidor parcialmente funcional. Revisar logs:"
    echo ""
    echo "📋 Comandos de diagnóstico:"
    echo "   pm2 logs topping-frozen-backend --lines 10"
    echo "   systemctl status nginx"
    echo "   systemctl status mysql"
fi

echo ""
echo "=================================================="
print_info "Script completado. ¡Gracias por usar Topping Frozen!"
