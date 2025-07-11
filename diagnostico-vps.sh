#!/bin/bash

# Script de diagnóstico para Topping Frozen App
# Ejecutar en el VPS para identificar problemas

echo "🔍 DIAGNÓSTICO DE TOPPING FROZEN APP"
echo "===================================="

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

echo ""
echo "1. VERIFICANDO SERVICIOS..."
echo "----------------------------"

# Verificar PM2
if command -v pm2 &> /dev/null; then
    print_status "PM2 está instalado"
    echo "Estado de PM2:"
    pm2 status
    echo ""
    
    # Verificar si la aplicación está corriendo
    if pm2 list | grep -q "topping-frozen-backend"; then
        if pm2 list | grep "topping-frozen-backend" | grep -q "online"; then
            print_status "Backend está corriendo"
        else
            print_error "Backend NO está corriendo"
            echo "Logs del backend:"
            pm2 logs topping-frozen-backend --lines 10
        fi
    else
        print_error "Aplicación topping-frozen-backend no encontrada en PM2"
    fi
else
    print_error "PM2 no está instalado"
fi

echo ""
echo "2. VERIFICANDO NGINX..."
echo "----------------------"

# Verificar Nginx
if systemctl is-active --quiet nginx; then
    print_status "Nginx está corriendo"
else
    print_error "Nginx NO está corriendo"
    echo "Estado de Nginx:"
    sudo systemctl status nginx --no-pager
fi

# Verificar configuración de Nginx
if [ -f "/etc/nginx/sites-available/topping-frozen" ]; then
    print_status "Configuración de Nginx existe"
else
    print_error "Configuración de Nginx NO existe"
fi

if [ -L "/etc/nginx/sites-enabled/topping-frozen" ]; then
    print_status "Sitio habilitado en Nginx"
else
    print_error "Sitio NO habilitado en Nginx"
fi

echo ""
echo "3. VERIFICANDO MYSQL..."
echo "----------------------"

# Verificar MySQL
if systemctl is-active --quiet mysql; then
    print_status "MySQL está corriendo"
    
    # Verificar base de datos
    if mysql -u toppinguser -pToppingFrozen2024! -e "USE topping_frozen; SHOW TABLES;" &> /dev/null; then
        print_status "Base de datos accesible"
        echo "Tablas en la base de datos:"
        mysql -u toppinguser -pToppingFrozen2024! -e "USE topping_frozen; SHOW TABLES;"
    else
        print_error "No se puede acceder a la base de datos"
    fi
else
    print_error "MySQL NO está corriendo"
    echo "Estado de MySQL:"
    sudo systemctl status mysql --no-pager
fi

echo ""
echo "4. VERIFICANDO PUERTOS..."
echo "------------------------"

# Verificar puertos
print_info "Puertos en uso:"
netstat -tlnp | grep -E ':80|:443|:3000|:5000'

echo ""
echo "5. VERIFICANDO FIREWALL..."
echo "-------------------------"

# Verificar UFW
if command -v ufw &> /dev/null; then
    print_info "Estado del firewall:"
    sudo ufw status
else
    print_warning "UFW no está instalado"
fi

echo ""
echo "6. VERIFICANDO ARCHIVOS..."
echo "-------------------------"

# Verificar directorio de la aplicación
if [ -d "/var/www/topping-frozen" ]; then
    print_status "Directorio de aplicación existe"
    
    if [ -f "/var/www/topping-frozen/backend/dist/index.js" ]; then
        print_status "Backend compilado existe"
    else
        print_error "Backend NO está compilado"
    fi
    
    if [ -d "/var/www/topping-frozen/build" ]; then
        print_status "Frontend compilado existe"
    else
        print_error "Frontend NO está compilado"
    fi
    
    if [ -f "/var/www/topping-frozen/backend/.env" ]; then
        print_status "Archivo .env del backend existe"
    else
        print_error "Archivo .env del backend NO existe"
    fi
else
    print_error "Directorio de aplicación NO existe"
fi

echo ""
echo "7. VERIFICANDO CONECTIVIDAD..."
echo "------------------------------"

# Verificar si el backend responde localmente
print_info "Probando backend local (puerto 5000):"
if curl -s http://localhost:5000/api/health &> /dev/null; then
    print_status "Backend responde en localhost:5000"
else
    print_error "Backend NO responde en localhost:5000"
fi

# Verificar si Nginx responde
print_info "Probando Nginx local (puerto 80):"
if curl -s http://localhost &> /dev/null; then
    print_status "Nginx responde en localhost:80"
else
    print_error "Nginx NO responde en localhost:80"
fi

echo ""
echo "8. INFORMACIÓN DEL SISTEMA..."
echo "----------------------------"

print_info "IP del servidor:"
hostname -I

print_info "Uso de memoria:"
free -h

print_info "Uso de disco:"
df -h /

echo ""
echo "9. LOGS RECIENTES..."
echo "-------------------"

print_info "Últimos logs de Nginx (errores):"
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No hay logs de error de Nginx"

print_info "Últimos logs del sistema:"
sudo tail -5 /var/log/syslog | grep -i error || echo "No hay errores recientes en syslog"

echo ""
echo "=================================="
echo "🔍 DIAGNÓSTICO COMPLETADO"
echo "=================================="

echo ""
print_info "COMANDOS ÚTILES PARA SOLUCIONAR:"
echo "- Reiniciar backend: pm2 restart topping-frozen-backend"
echo "- Ver logs backend: pm2 logs topping-frozen-backend"
echo "- Reiniciar Nginx: sudo systemctl restart nginx"
echo "- Reiniciar MySQL: sudo systemctl restart mysql"
echo "- Ver configuración Nginx: sudo nginx -t"
echo "- Verificar puertos: netstat -tlnp"
