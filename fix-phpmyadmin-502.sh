#!/bin/bash

# 🔧 Script para Solucionar Error 502 de phpMyAdmin
# Soluciona problemas de PHP-FPM y configuración

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

echo "🔧 Solucionando Error 502 de phpMyAdmin"
echo "======================================="

# 1. Verificar estado de PHP-FPM
print_status "1. Verificando estado de PHP-FPM..."
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
print_status "Versión de PHP detectada: $PHP_VERSION"

# Verificar qué versiones de PHP-FPM están disponibles
print_status "Versiones de PHP-FPM disponibles:"
ls /etc/php/*/fpm/ 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' || print_warning "No se encontraron versiones de PHP-FPM"

# 2. Instalar PHP-FPM correcto
print_status "2. Instalando PHP-FPM..."
sudo apt update
sudo apt install -y php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl

# 3. Detectar versión correcta de PHP-FPM
print_status "3. Detectando versión correcta de PHP-FPM..."
if [ -f "/var/run/php/php8.1-fpm.sock" ]; then
    PHP_FPM_VERSION="8.1"
elif [ -f "/var/run/php/php8.0-fpm.sock" ]; then
    PHP_FPM_VERSION="8.0"
elif [ -f "/var/run/php/php7.4-fpm.sock" ]; then
    PHP_FPM_VERSION="7.4"
else
    # Buscar cualquier versión disponible
    PHP_FPM_VERSION=$(ls /var/run/php/php*-fpm.sock 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' || echo "8.1")
fi

print_success "Usando PHP-FPM versión: $PHP_FPM_VERSION"

# 4. Iniciar PHP-FPM
print_status "4. Iniciando PHP-FPM..."
sudo systemctl start php$PHP_FPM_VERSION-fpm
sudo systemctl enable php$PHP_FPM_VERSION-fpm

# 5. Verificar que PHP-FPM esté corriendo
print_status "5. Verificando PHP-FPM..."
if sudo systemctl is-active php$PHP_FPM_VERSION-fpm > /dev/null; then
    print_success "✅ PHP-FPM está corriendo"
else
    print_error "❌ PHP-FPM no está corriendo"
    sudo systemctl status php$PHP_FPM_VERSION-fpm
fi

# 6. Actualizar configuración de Nginx con la versión correcta
print_status "6. Actualizando configuración de Nginx..."
sudo tee /etc/nginx/sites-available/phpmyadmin << EOF
server {
    listen 8080;
    server_name _;
    
    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_FPM_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# 7. Verificar que phpMyAdmin esté instalado
print_status "7. Verificando instalación de phpMyAdmin..."
if [ ! -d "/usr/share/phpmyadmin" ]; then
    print_warning "phpMyAdmin no está instalado, instalando..."
    sudo apt install -y phpmyadmin
fi

# 8. Configurar permisos
print_status "8. Configurando permisos..."
sudo chown -R www-data:www-data /usr/share/phpmyadmin
sudo chmod -R 755 /usr/share/phpmyadmin

# 9. Habilitar sitio
print_status "9. Habilitando sitio de phpMyAdmin..."
sudo ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# 10. Verificar configuración de Nginx
print_status "10. Verificando configuración de Nginx..."
sudo nginx -t

# 11. Reiniciar servicios
print_status "11. Reiniciando servicios..."
sudo systemctl restart php$PHP_FPM_VERSION-fpm
sudo systemctl restart nginx

# 12. Verificar que el socket de PHP-FPM existe
print_status "12. Verificando socket de PHP-FPM..."
if [ -S "/var/run/php/php$PHP_FPM_VERSION-fpm.sock" ]; then
    print_success "✅ Socket de PHP-FPM existe"
else
    print_error "❌ Socket de PHP-FPM no existe"
    ls -la /var/run/php/
fi

# 13. Test de conectividad
print_status "13. Probando conectividad..."
sleep 5

if netstat -tlnp | grep :8080 > /dev/null; then
    print_success "✅ Puerto 8080 está activo"
    
    # Test HTTP
    HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null)
    if [ "$HTTP_RESPONSE" = "200" ]; then
        print_success "✅ phpMyAdmin responde correctamente"
    else
        print_warning "⚠️ phpMyAdmin responde con código: $HTTP_RESPONSE"
    fi
else
    print_error "❌ Puerto 8080 no está activo"
fi

# 14. Mostrar logs si hay errores
print_status "14. Verificando logs de errores..."
echo "Logs de Nginx:"
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No hay logs de error"

echo ""
echo "Logs de PHP-FPM:"
sudo tail -5 /var/log/php$PHP_FPM_VERSION-fpm.log 2>/dev/null || echo "No hay logs de PHP-FPM"

# 15. Información final
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
print_success "🎉 Configuración completada"
echo ""
print_status "📋 Información de acceso:"
echo "• URL: http://$SERVER_IP:8080"
echo "• Usuario: appuser"
echo "• Contraseña: apppassword123"
echo ""
print_status "🔧 Si aún hay error 502:"
echo "• Verifica: sudo systemctl status php$PHP_FPM_VERSION-fpm"
echo "• Reinicia: sudo systemctl restart php$PHP_FPM_VERSION-fpm nginx"
echo "• Logs: sudo tail -f /var/log/nginx/error.log"
