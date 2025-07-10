#!/bin/bash

# 🔧 Script para Instalar y Configurar phpMyAdmin
# Permite acceso web a la base de datos MySQL

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

echo "🔧 Instalando y Configurando phpMyAdmin"
echo "======================================="

# 1. Actualizar sistema
print_status "1. Actualizando sistema..."
sudo apt update

# 2. Instalar phpMyAdmin
print_status "2. Instalando phpMyAdmin..."
sudo apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl

# 3. Habilitar extensiones PHP necesarias
print_status "3. Habilitando extensiones PHP..."
sudo phpenmod mbstring

# 4. Reiniciar Apache (si está instalado)
print_status "4. Reiniciando servicios web..."
sudo systemctl restart apache2 2>/dev/null || print_warning "Apache no está instalado"

# 5. Configurar Nginx para phpMyAdmin
print_status "5. Configurando Nginx para phpMyAdmin..."

# Crear configuración de phpMyAdmin para Nginx
sudo tee /etc/nginx/sites-available/phpmyadmin << 'EOF'
server {
    listen 8080;
    server_name _;
    
    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# 6. Habilitar sitio de phpMyAdmin
print_status "6. Habilitando sitio de phpMyAdmin..."
sudo ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# 7. Instalar PHP-FPM si no está instalado
print_status "7. Instalando PHP-FPM..."
sudo apt install -y php-fpm

# 8. Verificar configuración de Nginx
print_status "8. Verificando configuración de Nginx..."
sudo nginx -t

# 9. Reiniciar servicios
print_status "9. Reiniciando servicios..."
sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm 2>/dev/null || sudo systemctl restart php7.4-fpm 2>/dev/null || print_warning "PHP-FPM no se pudo reiniciar"

# 10. Configurar usuario MySQL para phpMyAdmin
print_status "10. Configurando acceso MySQL..."

# Crear usuario específico para phpMyAdmin
mysql -u root -p -e "
CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY 'phpmyadmin123';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
" 2>/dev/null || {
    # Si no funciona con root, usar appuser
    mysql -u appuser -papppassword123 -e "
    CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY 'phpmyadmin123';
    GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
    " 2>/dev/null
}

# 11. Configurar firewall para puerto 8080
print_status "11. Configurando firewall..."
sudo ufw allow 8080 2>/dev/null || print_warning "UFW no está configurado"

# 12. Verificar instalación
print_status "12. Verificando instalación..."

if [ -d "/usr/share/phpmyadmin" ]; then
    print_success "✅ phpMyAdmin instalado correctamente"
else
    print_error "❌ Error en la instalación de phpMyAdmin"
    exit 1
fi

# 13. Verificar que Nginx esté sirviendo en puerto 8080
print_status "13. Verificando servicio..."
sleep 3

if netstat -tlnp | grep :8080 > /dev/null; then
    print_success "✅ phpMyAdmin disponible en puerto 8080"
else
    print_warning "⚠️ Puerto 8080 no está activo, intentando solucionar..."
    sudo systemctl restart nginx
    sleep 3
fi

# 14. Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
print_success "🎉 ¡phpMyAdmin instalado correctamente!"
echo ""
print_status "📋 Información de acceso:"
echo "• URL: http://$SERVER_IP:8080"
echo "• Usuario: phpmyadmin"
echo "• Contraseña: phpmyadmin123"
echo ""
print_status "📋 También puedes usar:"
echo "• Usuario: appuser"
echo "• Contraseña: apppassword123"
echo ""
print_status "🔧 Para verificar la base de datos gestionPedidos:"
echo "1. Accede a phpMyAdmin"
echo "2. Selecciona la base de datos 'gestionPedidos'"
echo "3. Ve a la tabla 'users'"
echo "4. Verifica que existe el usuario 'admin'"
echo ""
print_warning "⚠️ Si no puedes acceder:"
echo "• Verifica que el puerto 8080 esté abierto en tu firewall"
echo "• Prueba con: http://$SERVER_IP:8080/phpmyadmin"
echo "• Reinicia Nginx: sudo systemctl restart nginx"
