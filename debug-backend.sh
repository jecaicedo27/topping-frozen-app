#!/bin/bash

# 🔍 Script para Diagnosticar y Solucionar Problemas del Backend

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 Diagnóstico del Backend - Gestión de Pedidos"
echo "=================================================="

# Verificar si estamos en el directorio correcto
if [ ! -d "/home/gestionPedidos" ]; then
    print_error "Directorio /home/gestionPedidos no encontrado"
    exit 1
fi

cd /home/gestionPedidos

# 1. Verificar estado de PM2
print_status "1. Verificando estado de PM2..."
pm2 status
echo ""

# 2. Verificar logs del backend
print_status "2. Últimos logs del backend..."
pm2 logs gestion-pedidos-backend --lines 20
echo ""

# 3. Verificar estado de MySQL
print_status "3. Verificando estado de MySQL..."
sudo systemctl status mysql --no-pager
echo ""

# 4. Verificar conexión a la base de datos
print_status "4. Verificando base de datos..."
mysql -u appuser -p -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null || {
    print_warning "No se pudo conectar con las credenciales por defecto"
    print_status "Intentando con root..."
    sudo mysql -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null || {
        print_error "Error de conexión a la base de datos"
    }
}
echo ""

# 5. Verificar archivos de configuración
print_status "5. Verificando archivos .env..."
if [ -f ".env" ]; then
    print_success "Archivo .env encontrado"
    echo "Contenido (sin contraseñas):"
    grep -v "PASSWORD\|SECRET" .env
else
    print_error "Archivo .env no encontrado"
fi
echo ""

if [ -f "backend/.env" ]; then
    print_success "Archivo backend/.env encontrado"
    echo "Contenido (sin contraseñas):"
    grep -v "PASSWORD\|SECRET" backend/.env
else
    print_error "Archivo backend/.env no encontrado"
fi
echo ""

# 6. Verificar si el backend está corriendo
print_status "6. Verificando puerto 5000..."
if netstat -tlnp | grep :5000 > /dev/null; then
    print_success "Backend corriendo en puerto 5000"
else
    print_error "Backend NO está corriendo en puerto 5000"
fi
echo ""

# 7. Verificar Nginx
print_status "7. Verificando configuración de Nginx..."
sudo nginx -t
echo ""

# 8. Verificar logs de Nginx
print_status "8. Últimos logs de Nginx..."
echo "Access logs:"
sudo tail -5 /var/log/nginx/access.log
echo ""
echo "Error logs:"
sudo tail -5 /var/log/nginx/error.log
echo ""

# 9. Verificar usuario admin en la base de datos
print_status "9. Verificando usuario admin..."
sudo mysql -e "USE gestionPedidos; SELECT username, role FROM users WHERE username='admin';" 2>/dev/null || {
    print_warning "No se pudo verificar usuario admin"
}
echo ""

print_status "🔧 Comandos de solución rápida:"
echo "• Reiniciar backend: pm2 restart gestion-pedidos-backend"
echo "• Ver logs en tiempo real: pm2 logs gestion-pedidos-backend"
echo "• Reiniciar MySQL: sudo systemctl restart mysql"
echo "• Reiniciar Nginx: sudo systemctl restart nginx"
echo "• Crear usuario admin: node create-admin-user.js"
echo ""

print_status "📋 Si necesitas recrear el usuario admin:"
echo "cd /home/gestionPedidos && node create-admin-user.js"
