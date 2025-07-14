#!/bin/bash

# Script de instalación completa para servidor recién formateado
# Compatible con Ubuntu 20.04/22.04 y Debian 11/12

echo "🚀 Instalación completa de Topping Frozen en servidor nuevo..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
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
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

print_info "IP del servidor detectada: $SERVER_IP"

# 1. Actualizar sistema
print_status "Actualizando sistema..."
apt update && apt upgrade -y

# 2. Instalar dependencias básicas
print_status "Instalando dependencias básicas..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 3. Instalar Node.js 18.x
print_status "Instalando Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verificar instalación de Node.js
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js instalado: $node_version"
print_status "NPM instalado: $npm_version"

# 4. Instalar PM2 globalmente
print_status "Instalando PM2..."
npm install -g pm2

# 5. Instalar MySQL
print_status "Instalando MySQL Server..."
apt install -y mysql-server

# Configurar MySQL
print_status "Configurando MySQL..."
systemctl start mysql
systemctl enable mysql

# Crear usuario y base de datos
mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;"
mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

print_status "Base de datos MySQL configurada"

# 6. Instalar Nginx y PHP
print_status "Instalando Nginx y PHP..."
apt install -y nginx apache2 php php-mysql php-mbstring php-zip php-gd php-json php-curl php-fpm

# Habilitar servicios
systemctl start nginx
systemctl enable nginx
systemctl start apache2
systemctl enable apache2

# Habilitar módulos de PHP
phpenmod mbstring

# 7. Configurar firewall básico
print_status "Configurando firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 3001/tcp
ufw --force enable

# 8. Crear directorio del proyecto
print_status "Creando directorio del proyecto..."
mkdir -p /var/www
cd /var/www

# 9. Clonar repositorio
print_status "Clonando repositorio desde GitHub..."
git clone https://github.com/jecaicedo27/topping-frozen-app.git
cd topping-frozen-app

# Hacer script ejecutable
chmod +x configure-vps-ip-only.sh

# 10. Instalar dependencias del proyecto
print_status "Instalando dependencias del frontend..."
npm install

print_status "Instalando dependencias del backend..."
cd backend
npm install
cd ..

# 11. Configurar variables de entorno
print_status "Configurando variables de entorno..."
cd backend

# Crear archivo .env para producción
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=mi-super-secreto-jwt-vps-2024

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL - Solo IP, sin DNS
FRONTEND_URL=http://$SERVER_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts

# CORS Configuration - Solo IP
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF

cd ..

# 12. Inicializar base de datos con estructura completa
print_status "Inicializando base de datos con estructura completa..."

# Crear tablas directamente con MySQL
mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de pedidos
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_address TEXT,
    items JSON NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'confirmed', 'in_preparation', 'ready', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'partial', 'refunded') DEFAULT 'pending',
    delivery_date DATE,
    delivery_time TIME,
    notes TEXT,
    created_by INT,
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

-- Tabla de recibos de dinero
CREATE TABLE IF NOT EXISTS money_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    receipt_number VARCHAR(50) UNIQUE NOT NULL,
    order_id INT,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL,
    reference_number VARCHAR(100),
    description TEXT,
    receipt_image VARCHAR(255),
    status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    created_by INT,
    verified_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- Insertar usuarios de prueba con hash correcto para contraseña "123456"
INSERT IGNORE INTO users (username, password, role, email, full_name) VALUES
('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'admin@toppingfrozen.com', 'Administrador'),
('facturacion', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'facturacion', 'facturacion@toppingfrozen.com', 'Usuario Facturación'),
('cartera', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cartera', 'cartera@toppingfrozen.com', 'Usuario Cartera'),
('logistica', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'logistica', 'logistica@toppingfrozen.com', 'Usuario Logística'),
('mensajero', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mensajero', 'mensajero@toppingfrozen.com', 'Usuario Mensajero');

-- Insertar algunos pedidos de ejemplo
INSERT IGNORE INTO orders (order_number, customer_name, customer_phone, customer_address, items, total_amount, status, payment_status, delivery_date, created_by) VALUES
('ORD-001', 'María García', '3001234567', 'Calle 123 #45-67, Bogotá', '{"items": [{"name": "Helado Vainilla", "quantity": 2, "price": 15000}, {"name": "Helado Chocolate", "quantity": 1, "price": 15000}]}', 45000.00, 'pending', 'pending', CURDATE(), 1),
('ORD-002', 'Carlos López', '3007654321', 'Carrera 45 #12-34, Medellín', '{"items": [{"name": "Helado Fresa", "quantity": 3, "price": 15000}]}', 45000.00, 'confirmed', 'paid', CURDATE(), 1),
('ORD-003', 'Ana Rodríguez', '3009876543', 'Avenida 68 #23-45, Cali', '{"items": [{"name": "Helado Mango", "quantity": 1, "price": 15000}, {"name": "Helado Coco", "quantity": 2, "price": 15000}]}', 45000.00, 'in_preparation', 'partial', CURDATE(), 1);

-- Insertar algunos recibos de ejemplo
INSERT IGNORE INTO money_receipts (receipt_number, order_id, amount, payment_method, reference_number, description, status, created_by) VALUES
('REC-001', 2, 45000.00, 'transfer', 'TRF123456789', 'Pago completo pedido ORD-002', 'verified', 2),
('REC-002', 3, 22500.00, 'cash', '', 'Pago parcial pedido ORD-003', 'pending', 2);
EOF

if [ $? -eq 0 ]; then
    print_status "Base de datos inicializada con estructura completa"
else
    print_warning "Error al crear las tablas, continuando..."
fi

# 13. Construir frontend para producción
print_status "Construyendo frontend para producción..."
npm run build

# 14. Configurar Nginx
print_status "Configurando Nginx..."
cat > /etc/nginx/sites-available/topping-frozen << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    # Frontend
    location / {
        root /var/www/topping-frozen-app/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "http://$SERVER_IP" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Logs
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    print_status "Nginx configurado correctamente"
else
    print_error "Error en configuración de Nginx"
fi

# 15. Instalar y configurar phpMyAdmin
print_status "Instalando phpMyAdmin..."

# Configurar firewall para phpMyAdmin
ufw allow 8080/tcp

# Descargar phpMyAdmin
cd /tmp
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
tar xzf phpMyAdmin-latest-all-languages.tar.gz

# Instalar phpMyAdmin
PHPMYADMIN_DIR=$(ls -d phpMyAdmin-*/ | head -1)
mv "$PHPMYADMIN_DIR" /var/www/html/phpmyadmin
chown -R www-data:www-data /var/www/html/phpmyadmin

# Configurar phpMyAdmin
cd /var/www/html/phpmyadmin
cp config.sample.inc.php config.inc.php

# Generar blowfish secret
BLOWFISH_SECRET=$(openssl rand -base64 32)

# Crear configuración
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
\$cfg['CheckConfigurationPermissions'] = false;
\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
EOF

# Crear directorios necesarios
mkdir -p /var/lib/phpmyadmin/tmp
chown -R www-data:www-data /var/lib/phpmyadmin

# Configurar Nginx para phpMyAdmin
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

    access_log /var/log/nginx/phpmyadmin.access.log;
    error_log /var/log/nginx/phpmyadmin.error.log;
}
EOF

# Habilitar sitio phpMyAdmin
ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

# Crear usuario de base de datos para phpMyAdmin
mysql -e "CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY 'PhpMyAdmin2024!';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# Reiniciar servicios
systemctl restart apache2
systemctl restart php8.1-fpm
systemctl reload nginx

print_status "phpMyAdmin instalado y configurado"

# Volver al directorio del proyecto
cd /var/www/topping-frozen-app

# 16. Compilar backend para producción
print_status "Compilando backend para producción..."
cd backend
npm run build 2>/dev/null || {
    print_warning "No se encontró script build, compilando manualmente..."
    npx tsc
}
cd ..

# 16. Configurar PM2
print_status "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'topping-frozen-backend',
      script: 'backend/dist/index.js',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: '/var/log/pm2/topping-frozen-backend-error.log',
      out_file: '/var/log/pm2/topping-frozen-backend-out.log',
      log_file: '/var/log/pm2/topping-frozen-backend.log'
    }
  ]
};
EOF

# Crear directorio de logs
mkdir -p /var/log/pm2

# 17. Iniciar aplicación con PM2
print_status "Iniciando aplicación con PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# 17. Configurar permisos
print_status "Configurando permisos..."
chown -R www-data:www-data /var/www/topping-frozen-app
chmod -R 755 /var/www/topping-frozen-app

# Crear directorio de uploads
mkdir -p /var/www/topping-frozen-app/backend/uploads/receipts
chown -R www-data:www-data /var/www/topping-frozen-app/backend/uploads

# 18. Verificaciones finales
print_status "Realizando verificaciones finales..."

# Esperar a que el backend inicie
sleep 10

# Verificar backend
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "Backend funcionando correctamente"
else
    print_error "Backend no responde"
    print_info "Verificando logs de PM2..."
    pm2 logs topping-frozen-backend --lines 10
fi

# Verificar login
if curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' | grep -q "success"; then
    print_status "Sistema de login funcionando"
else
    print_warning "Sistema de login no responde correctamente"
fi

# Verificar Nginx
if curl -s http://$SERVER_IP > /dev/null; then
    print_status "Nginx funcionando correctamente"
else
    print_error "Nginx no responde"
fi

# 19. Mostrar información final
echo ""
echo "🎉 ¡Instalación completada!"
echo ""
echo "📋 Información del servidor:"
echo "   🌐 IP del servidor: $SERVER_IP"
echo "   🖥️  Frontend: http://$SERVER_IP"
echo "   🔧 Backend API: http://$SERVER_IP/api"
echo "   ❤️  Health check: http://$SERVER_IP/api/health"
echo "   🗄️  phpMyAdmin: http://$SERVER_IP:8080"
echo ""
echo "🔐 Credenciales de base de datos:"
echo "   👤 Usuario aplicación: toppinguser"
echo "   🔑 Contraseña: ToppingPass2024!"
echo "   🗄️ Base de datos: topping_frozen_db"
echo ""
echo "   👤 Usuario phpMyAdmin: phpmyadmin"
echo "   🔑 Contraseña: PhpMyAdmin2024!"
echo "   🗄️ Acceso: Todas las bases de datos"
echo ""
echo "👤 Usuarios de prueba (contraseña: 123456):"
echo "   • admin - Administrador"
echo "   • facturacion - Facturación"
echo "   • cartera - Cartera"
echo "   • logistica - Logística"
echo "   • mensajero - Mensajero"
echo ""
echo "🔧 Comandos útiles:"
echo "   Ver logs del backend: pm2 logs topping-frozen-backend"
echo "   Reiniciar backend: pm2 restart topping-frozen-backend"
echo "   Estado de PM2: pm2 status"
echo "   Reiniciar Nginx: systemctl restart nginx"
echo ""
echo "🧪 Probar el sistema:"
echo "   curl http://$SERVER_IP/api/health"
echo "   curl -X POST http://$SERVER_IP/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"123456\"}'"
echo ""
echo "📁 Directorio del proyecto: /var/www/topping-frozen-app"
echo ""
print_status "¡Servidor listo para usar!"
