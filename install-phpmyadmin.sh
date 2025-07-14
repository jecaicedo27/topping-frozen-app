#!/bin/bash

# Script para instalar phpMyAdmin en el servidor
echo "🗄️ Instalando phpMyAdmin..."

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

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
print_info "IP del servidor: $SERVER_IP"

# 1. Instalar PHP y Apache
print_status "Instalando PHP y Apache..."
apt update
apt install -y apache2 php php-mysql php-mbstring php-zip php-gd php-json php-curl

# 2. Habilitar módulos de PHP
print_status "Habilitando módulos de PHP..."
phpenmod mbstring

# 3. Reiniciar Apache
systemctl restart apache2
systemctl enable apache2

# 4. Descargar phpMyAdmin
print_status "Descargando phpMyAdmin..."
cd /tmp
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz

# 5. Extraer phpMyAdmin
print_status "Extrayendo phpMyAdmin..."
tar xzf phpMyAdmin-latest-all-languages.tar.gz

# 6. Mover a directorio web
print_status "Instalando phpMyAdmin..."
PHPMYADMIN_DIR=$(ls -d phpMyAdmin-*/ | head -1)
mv "$PHPMYADMIN_DIR" /var/www/html/phpmyadmin
chown -R www-data:www-data /var/www/html/phpmyadmin

# 7. Crear configuración de phpMyAdmin
print_status "Configurando phpMyAdmin..."
cd /var/www/html/phpmyadmin
cp config.sample.inc.php config.inc.php

# Generar blowfish secret
BLOWFISH_SECRET=$(openssl rand -base64 32)

# Configurar phpMyAdmin
cat > config.inc.php << EOF
<?php
\$cfg['blowfish_secret'] = '$BLOWFISH_SECRET';

\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;

\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';

// Configuraciones de seguridad
\$cfg['CheckConfigurationPermissions'] = false;
\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
EOF

# 8. Crear directorio temporal
print_status "Creando directorios necesarios..."
mkdir -p /var/lib/phpmyadmin/tmp
chown -R www-data:www-data /var/lib/phpmyadmin

# 9. Configurar Nginx para phpMyAdmin
print_status "Configurando Nginx para phpMyAdmin..."
cat > /etc/nginx/sites-available/phpmyadmin << EOF
server {
    listen 8080;
    server_name $SERVER_IP;
    root /var/www/html/phpmyadmin;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # Logs
    access_log /var/log/nginx/phpmyadmin.access.log;
    error_log /var/log/nginx/phpmyadmin.error.log;
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

# 10. Instalar PHP-FPM
print_status "Instalando PHP-FPM..."
apt install -y php-fpm

# 11. Configurar firewall
print_status "Configurando firewall..."
ufw allow 8080/tcp

# 12. Verificar configuración de Nginx
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    print_status "Nginx configurado correctamente"
else
    print_error "Error en configuración de Nginx"
fi

# 13. Reiniciar servicios
print_status "Reiniciando servicios..."
systemctl restart apache2
systemctl restart php8.1-fpm
systemctl restart nginx

# 14. Crear usuario de base de datos para phpMyAdmin (opcional)
print_status "Configurando acceso a base de datos..."
mysql -e "CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY 'PhpMyAdmin2024!';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# 15. Verificaciones finales
print_status "Realizando verificaciones..."

# Verificar que Apache está ejecutándose
if systemctl is-active --quiet apache2; then
    print_status "Apache funcionando correctamente"
else
    print_error "Apache no está ejecutándose"
fi

# Verificar que PHP-FPM está ejecutándose
if systemctl is-active --quiet php8.1-fpm; then
    print_status "PHP-FPM funcionando correctamente"
else
    print_error "PHP-FPM no está ejecutándose"
fi

# Verificar acceso a phpMyAdmin
sleep 3
if curl -s http://localhost:8080 > /dev/null; then
    print_status "phpMyAdmin accesible"
else
    print_warning "phpMyAdmin no responde en puerto 8080"
fi

# 16. Mostrar información final
echo ""
echo "🎉 ¡Instalación de phpMyAdmin completada!"
echo ""
echo "📋 Información de acceso:"
echo "   🌐 URL: http://$SERVER_IP:8080"
echo "   🌐 URL alternativa: http://$SERVER_IP:8080/phpmyadmin"
echo ""
echo "🔐 Credenciales de base de datos:"
echo "   👤 Usuario principal: toppinguser"
echo "   🔑 Contraseña: ToppingPass2024!"
echo "   🗄️ Base de datos: topping_frozen_db"
echo ""
echo "   👤 Usuario phpMyAdmin: phpmyadmin"
echo "   🔑 Contraseña: PhpMyAdmin2024!"
echo "   🗄️ Acceso: Todas las bases de datos"
echo ""
echo "🔧 Servicios configurados:"
echo "   ✅ Apache2 en puerto 80"
echo "   ✅ phpMyAdmin en puerto 8080"
echo "   ✅ PHP-FPM habilitado"
echo "   ✅ Nginx proxy configurado"
echo ""
echo "🧪 Para probar:"
echo "   curl http://$SERVER_IP:8080"
echo "   Abrir en navegador: http://$SERVER_IP:8080"
echo ""
print_status "¡phpMyAdmin listo para usar!"
