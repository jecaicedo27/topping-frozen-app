#!/bin/bash

# Script para corregir phpMyAdmin específicamente
echo "🔧 Corrigiendo phpMyAdmin..."

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

# 1. Verificar si phpMyAdmin existe
if [ ! -d "/var/www/html/phpmyadmin" ]; then
    print_warning "phpMyAdmin no encontrado, instalando..."
    
    # Crear directorio
    mkdir -p /var/www/html
    cd /tmp
    
    # Descargar phpMyAdmin
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
    tar xzf phpMyAdmin-latest-all-languages.tar.gz
    
    # Mover a directorio web
    PHPMYADMIN_DIR=$(ls -d phpMyAdmin-*/ | head -1)
    mv "$PHPMYADMIN_DIR" /var/www/html/phpmyadmin
    
    print_status "phpMyAdmin descargado"
fi

# 2. Configurar phpMyAdmin
print_status "Configurando phpMyAdmin..."
cd /var/www/html/phpmyadmin

# Crear configuración
cat > config.inc.php << 'EOF'
<?php
$cfg['blowfish_secret'] = 'H2OxcGXxflSd8JwrwVlh6KW6s2rER63i';

$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['CheckConfigurationPermissions'] = false;
$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
EOF

# 3. Crear directorios necesarios
mkdir -p /var/lib/phpmyadmin/tmp
chown -R www-data:www-data /var/lib/phpmyadmin
chown -R www-data:www-data /var/www/html/phpmyadmin

# 4. Verificar PHP-FPM
print_status "Verificando PHP-FPM..."
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
print_info "PHP Version: $PHP_VERSION"

systemctl start php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

# 5. Configurar Nginx para phpMyAdmin
print_status "Configurando Nginx para phpMyAdmin..."

# Crear configuración específica para phpMyAdmin
cat > /etc/nginx/sites-available/phpmyadmin << EOF
server {
    listen 8080;
    server_name $SERVER_IP _;
    root /var/www/html/phpmyadmin;
    index index.php index.html index.htm;

    # Logs específicos
    access_log /var/log/nginx/phpmyadmin.access.log;
    error_log /var/log/nginx/phpmyadmin.error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # Configuraciones adicionales para phpMyAdmin
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    location ~ /\.ht {
        deny all;
    }

    # Permitir archivos estáticos de phpMyAdmin
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar sitio phpMyAdmin
ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

# 6. Verificar configuración de Nginx
print_status "Verificando configuración de Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    print_status "Nginx reconfigurado correctamente"
else
    print_error "Error en configuración de Nginx"
    nginx -t
fi

# 7. Verificar usuario de base de datos para phpMyAdmin
print_status "Verificando usuario de base de datos..."
mysql -e "CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY 'PhpMyAdmin2024!';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# También verificar usuario principal
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'toppinguser'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# 8. Reiniciar servicios
print_status "Reiniciando servicios..."
systemctl restart php${PHP_VERSION}-fpm
systemctl reload nginx

# 9. Verificar que phpMyAdmin responda
print_status "Verificando phpMyAdmin..."
sleep 5

if curl -s http://localhost:8080 | grep -q "phpMyAdmin"; then
    print_status "phpMyAdmin funcionando correctamente"
else
    print_warning "phpMyAdmin no responde correctamente"
fi

# 10. Mostrar información
echo ""
echo "🎉 Configuración de phpMyAdmin completada!"
echo ""
echo "📋 Información de acceso:"
echo "   🌐 URL: http://$SERVER_IP:8080"
echo ""
echo "🔐 Credenciales disponibles:"
echo "   👤 Usuario: phpmyadmin"
echo "   🔑 Contraseña: PhpMyAdmin2024!"
echo "   📊 Acceso: Todas las bases de datos"
echo ""
echo "   👤 Usuario: toppinguser"
echo "   🔑 Contraseña: ToppingPass2024!"
echo "   📊 Acceso: Base de datos topping_frozen_db"
echo ""
echo "🔧 Si hay problemas:"
echo "   Ver logs: tail -f /var/log/nginx/phpmyadmin.error.log"
echo "   Estado PHP: systemctl status php${PHP_VERSION}-fpm"
echo "   Estado Nginx: systemctl status nginx"
echo ""

# Verificación final
if curl -s http://localhost:8080 > /dev/null; then
    print_status "✅ phpMyAdmin accesible en http://$SERVER_IP:8080"
else
    print_warning "⚠️  phpMyAdmin puede tener problemas. Revisar logs."
    echo ""
    echo "📋 Comandos de diagnóstico:"
    echo "   tail -f /var/log/nginx/phpmyadmin.error.log"
    echo "   systemctl status php${PHP_VERSION}-fpm"
    echo "   ls -la /var/www/html/phpmyadmin/"
fi
