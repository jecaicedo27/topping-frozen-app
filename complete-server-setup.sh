#!/bin/bash

# 🚀 Script Completo de Instalación desde Cero
# Configura servidor Ubuntu/Debian con todo lo necesario para la aplicación

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

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

# Función para verificar si el comando fue exitoso
check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "Error en: $1"
        exit 1
    fi
}

print_header "🚀 INSTALACIÓN COMPLETA DEL SERVIDOR"
echo "Este script instalará todo lo necesario para la aplicación:"
echo "• Node.js 18+ y PM2"
echo "• MySQL Server"
echo "• Nginx"
echo "• PHP y phpMyAdmin"
echo "• Aplicación de Gestión de Pedidos"
echo ""
read -p "¿Continuar con la instalación? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Instalación cancelada."
    exit 1
fi

# ============================================================================
print_header "📦 PASO 1: ACTUALIZACIÓN DEL SISTEMA"
# ============================================================================

print_status "Actualizando repositorios del sistema..."
apt update
check_success "Actualización de repositorios"

print_status "Actualizando paquetes del sistema..."
apt upgrade -y
check_success "Actualización de paquetes"

print_status "Instalando herramientas básicas..."
apt install -y curl wget git unzip software-properties-common ufw htop
check_success "Instalación de herramientas básicas"

# ============================================================================
print_header "🟢 PASO 2: INSTALACIÓN DE NODE.JS"
# ============================================================================

print_status "Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
check_success "Instalación de Node.js"

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js instalado: $NODE_VERSION"
print_success "NPM instalado: $NPM_VERSION"

print_status "Instalando PM2..."
npm install -g pm2
check_success "Instalación de PM2"

# ============================================================================
print_header "🗄️ PASO 3: INSTALACIÓN DE MYSQL"
# ============================================================================

print_status "Instalando MySQL Server..."
apt install -y mysql-server
check_success "Instalación de MySQL"

print_status "Iniciando MySQL..."
systemctl start mysql
systemctl enable mysql
check_success "Inicio de MySQL"

print_status "Configurando MySQL..."
# Configurar MySQL sin interacción
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword123';"
mysql -u root -prootpassword123 -e "CREATE DATABASE IF NOT EXISTS gestionPedidos;"
mysql -u root -prootpassword123 -e "CREATE USER IF NOT EXISTS 'appuser'@'localhost' IDENTIFIED BY 'apppassword123';"
mysql -u root -prootpassword123 -e "GRANT ALL PRIVILEGES ON gestionPedidos.* TO 'appuser'@'localhost';"
mysql -u root -prootpassword123 -e "FLUSH PRIVILEGES;"
check_success "Configuración de MySQL"

# ============================================================================
print_header "🌐 PASO 4: INSTALACIÓN DE NGINX"
# ============================================================================

print_status "Instalando Nginx..."
apt install -y nginx
check_success "Instalación de Nginx"

print_status "Iniciando Nginx..."
systemctl start nginx
systemctl enable nginx
check_success "Inicio de Nginx"

# ============================================================================
print_header "🐘 PASO 5: INSTALACIÓN DE PHP Y PHPMYADMIN"
# ============================================================================

print_status "Instalando PHP y extensiones..."
apt install -y php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl php-xml
check_success "Instalación de PHP"

# Detectar versión de PHP
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
print_success "PHP $PHP_VERSION instalado"

print_status "Iniciando PHP-FPM..."
systemctl start php$PHP_VERSION-fpm
systemctl enable php$PHP_VERSION-fpm
check_success "Inicio de PHP-FPM"

print_status "Instalando phpMyAdmin..."
# Preconfigurar phpMyAdmin para instalación no interactiva
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password phpmyadmin123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password rootpassword123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password phpmyadmin123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections

apt install -y phpmyadmin
check_success "Instalación de phpMyAdmin"

# ============================================================================
print_header "⚙️ PASO 6: CONFIGURACIÓN DE NGINX"
# ============================================================================

print_status "Configurando Nginx para la aplicación..."

# Configuración principal de la aplicación
cat > /etc/nginx/sites-available/gestion-pedidos << 'EOF'
server {
    listen 80;
    server_name _;

    # Frontend (archivos estáticos)
    location / {
        root /home/gestionPedidos/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Archivos subidos
    location /uploads {
        alias /home/gestionPedidos/backend/uploads;
    }
}
EOF

# Configuración de phpMyAdmin
cat > /etc/nginx/sites-available/phpmyadmin << EOF
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
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Habilitar sitios
ln -sf /etc/nginx/sites-available/gestion-pedidos /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_status "Verificando configuración de Nginx..."
nginx -t
check_success "Configuración de Nginx"

systemctl reload nginx
check_success "Recarga de Nginx"

# ============================================================================
print_header "🔥 PASO 7: CONFIGURACIÓN DEL FIREWALL"
# ============================================================================

print_status "Configurando firewall UFW..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 8080
check_success "Configuración del firewall"

# ============================================================================
print_header "📱 PASO 8: DESCARGA E INSTALACIÓN DE LA APLICACIÓN"
# ============================================================================

print_status "Creando directorio de la aplicación..."
cd /home
rm -rf gestionPedidos
git clone https://github.com/jecaicedo27/gestionPedidos.git
cd gestionPedidos
check_success "Descarga de la aplicación"

print_status "Instalando dependencias del frontend..."
npm install
check_success "Instalación de dependencias del frontend"

print_status "Instalando dependencias del backend..."
cd backend
npm install
cd ..
check_success "Instalación de dependencias del backend"

# ============================================================================
print_header "🔧 PASO 9: CONFIGURACIÓN DE LA APLICACIÓN"
# ============================================================================

print_status "Configurando variables de entorno..."

# Configurar .env principal
cat > .env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=apppassword123
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo-para-produccion-2024

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL
FRONTEND_URL=http://localhost

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

# Configurar backend/.env
cat > backend/.env << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=apppassword123
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo-para-produccion-2024

# Frontend URL
FRONTEND_URL=http://localhost

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

check_success "Configuración de variables de entorno"

# ============================================================================
print_header "🗃️ PASO 10: INICIALIZACIÓN DE LA BASE DE DATOS"
# ============================================================================

print_status "Creando estructura de la base de datos..."

# Crear archivo SQL con la estructura completa
cat > /tmp/database-structure.sql << 'EOF'
USE gestionPedidos;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL DEFAULT 'mensajero',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de pedidos
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_address TEXT,
    items TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pendiente', 'en_proceso', 'enviado', 'entregado', 'cancelado') DEFAULT 'pendiente',
    payment_status ENUM('pendiente', 'pagado', 'parcial') DEFAULT 'pendiente',
    created_by INT,
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

-- Tabla de recepciones de dinero
CREATE TABLE IF NOT EXISTS money_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    receipt_type ENUM('efectivo', 'transferencia', 'otro') NOT NULL,
    photo_path VARCHAR(255),
    notes TEXT,
    received_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (received_by) REFERENCES users(id)
);
EOF

mysql -u appuser -papppassword123 < /tmp/database-structure.sql
check_success "Creación de estructura de base de datos"

print_status "Creando usuario administrador..."
# Generar hash de contraseña usando Node.js
cd backend
ADMIN_HASH=$(node -e "
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('123456', 10);
console.log(hash);
")
cd ..

mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT INTO users (username, password, role) VALUES ('admin', '$ADMIN_HASH', 'admin')
ON DUPLICATE KEY UPDATE password = '$ADMIN_HASH';
"
check_success "Creación de usuario administrador"

# ============================================================================
print_header "🏗️ PASO 11: BUILD Y DESPLIEGUE"
# ============================================================================

print_status "Compilando frontend..."
npm run build
check_success "Compilación del frontend"

print_status "Compilando backend..."
cd backend
npm run build
cd ..
check_success "Compilación del backend"

print_status "Creando directorio de uploads..."
mkdir -p backend/uploads/receipts
chmod 755 backend/uploads/receipts
check_success "Creación de directorio de uploads"

# Crear archivo de configuración PM2
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'gestion-pedidos-backend',
    script: './backend/dist/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

mkdir -p logs

print_status "Iniciando aplicación con PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup
check_success "Inicio de la aplicación"

# ============================================================================
print_header "🔍 PASO 12: VERIFICACIÓN FINAL"
# ============================================================================

print_status "Esperando que los servicios se inicialicen..."
sleep 10

# Verificar servicios
print_status "Verificando servicios..."
systemctl is-active mysql && print_success "✅ MySQL activo" || print_error "❌ MySQL inactivo"
systemctl is-active nginx && print_success "✅ Nginx activo" || print_error "❌ Nginx inactivo"
systemctl is-active php$PHP_VERSION-fpm && print_success "✅ PHP-FPM activo" || print_error "❌ PHP-FPM inactivo"

# Verificar puertos
netstat -tlnp | grep :80 > /dev/null && print_success "✅ Puerto 80 activo" || print_error "❌ Puerto 80 inactivo"
netstat -tlnp | grep :5000 > /dev/null && print_success "✅ Puerto 5000 activo" || print_error "❌ Puerto 5000 inactivo"
netstat -tlnp | grep :8080 > /dev/null && print_success "✅ Puerto 8080 activo" || print_error "❌ Puerto 8080 inactivo"

# Verificar PM2
pm2 status

# Test de API
print_status "Probando API de login..."
sleep 3
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "✅ API de login funcionando correctamente"
else
    print_warning "⚠️ API de login necesita verificación"
fi

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# ============================================================================
print_header "🎉 INSTALACIÓN COMPLETADA"
# ============================================================================

echo ""
print_success "🎉 ¡Instalación completada exitosamente!"
echo ""
print_header "📋 INFORMACIÓN DE ACCESO"
echo ""
echo -e "${CYAN}🌐 APLICACIÓN PRINCIPAL:${NC}"
echo "• URL: http://$SERVER_IP"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
echo -e "${CYAN}🗄️ PHPMYADMIN:${NC}"
echo "• URL: http://$SERVER_IP:8080"
echo "• Usuario: appuser"
echo "• Contraseña: apppassword123"
echo ""
echo -e "${CYAN}🔧 COMANDOS ÚTILES:${NC}"
echo "• Ver estado: pm2 status"
echo "• Ver logs: pm2 logs gestion-pedidos-backend"
echo "• Reiniciar app: pm2 restart gestion-pedidos-backend"
echo "• Reiniciar Nginx: systemctl restart nginx"
echo "• Reiniciar MySQL: systemctl restart mysql"
echo ""
echo -e "${CYAN}📊 SERVICIOS INSTALADOS:${NC}"
echo "• ✅ Node.js $NODE_VERSION"
echo "• ✅ MySQL Server"
echo "• ✅ Nginx"
echo "• ✅ PHP $PHP_VERSION"
echo "• ✅ phpMyAdmin"
echo "• ✅ PM2"
echo "• ✅ UFW Firewall"
echo ""
print_success "¡Tu servidor está listo para producción! 🚀"

# Limpiar archivos temporales
rm -f /tmp/database-structure.sql
