#!/bin/bash

# 🚀 Script de Despliegue Automático para VPS Hostinger
# Este script automatiza la instalación de la aplicación en un VPS desde cero

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
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

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para solicitar input del usuario
get_user_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    
    if [ -n "$default_value" ]; then
        read -p "$prompt [$default_value]: " input
        eval "$var_name=\"${input:-$default_value}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

print_status "🚀 Iniciando configuración del VPS para Gestión de Pedidos"
echo "=================================================="

# Verificar si estamos ejecutando como root o con sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Paso 1: Actualizar sistema
print_status "📦 Actualizando sistema..."
$SUDO apt update && $SUDO apt upgrade -y

# Paso 2: Instalar herramientas básicas
print_status "🔧 Instalando herramientas básicas..."
$SUDO apt install -y curl wget git unzip software-properties-common htop

# Paso 3: Instalar Node.js
print_status "🟢 Instalando Node.js 18..."
if ! command_exists node; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | $SUDO -E bash -
    $SUDO apt install -y nodejs
fi

# Verificar instalación de Node.js
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js instalado: $NODE_VERSION"
print_success "NPM instalado: $NPM_VERSION"

# Paso 4: Instalar PM2
print_status "⚡ Instalando PM2..."
if ! command_exists pm2; then
    $SUDO npm install -g pm2
fi

# Paso 5: Instalar MySQL
print_status "🗄️ Instalando MySQL Server..."
if ! command_exists mysql; then
    $SUDO apt install -y mysql-server
    $SUDO systemctl start mysql
    $SUDO systemctl enable mysql
    
    print_warning "⚠️  IMPORTANTE: Ejecuta 'sudo mysql_secure_installation' después de este script"
fi

# Paso 6: Instalar Nginx
print_status "🌐 Instalando Nginx..."
if ! command_exists nginx; then
    $SUDO apt install -y nginx
    $SUDO systemctl start nginx
    $SUDO systemctl enable nginx
fi

# Paso 7: Configurar firewall
print_status "🔒 Configurando firewall..."
$SUDO ufw --force enable
$SUDO ufw allow ssh
$SUDO ufw allow 80
$SUDO ufw allow 443

# Paso 8: Obtener información del usuario
echo ""
print_status "📝 Configuración de la aplicación"
echo "Por favor, proporciona la siguiente información:"

get_user_input "Nombre de usuario de MySQL para la aplicación" DB_USER "appuser"
get_user_input "Contraseña para el usuario de MySQL" DB_PASSWORD
get_user_input "Secreto JWT (mínimo 32 caracteres)" JWT_SECRET
get_user_input "Dominio o IP del servidor" DOMAIN_OR_IP "$(curl -s ifconfig.me)"

# Paso 9: Configurar MySQL
print_status "🔧 Configurando base de datos MySQL..."
$SUDO mysql -e "CREATE DATABASE IF NOT EXISTS gestionPedidos;"
$SUDO mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
$SUDO mysql -e "GRANT ALL PRIVILEGES ON gestionPedidos.* TO '$DB_USER'@'localhost';"
$SUDO mysql -e "FLUSH PRIVILEGES;"

print_success "Base de datos 'gestionPedidos' creada"
print_success "Usuario '$DB_USER' creado con permisos"

# Paso 10: Clonar repositorio
print_status "📦 Clonando repositorio de la aplicación..."
cd /home
if [ -d "gestionPedidos" ]; then
    print_warning "El directorio ya existe, actualizando..."
    cd gestionPedidos
    git pull origin main
else
    git clone https://github.com/jecaicedo27/gestionPedidos.git
    cd gestionPedidos
fi

# Paso 11: Instalar dependencias
print_status "📚 Instalando dependencias..."
npm install
cd backend && npm install && cd ..

# Paso 12: Configurar variables de entorno
print_status "⚙️ Configurando variables de entorno..."

# Crear .env principal
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL
FRONTEND_URL=http://$DOMAIN_OR_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

# Crear backend/.env
cat > backend/.env << EOF
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# Frontend URL
FRONTEND_URL=http://$DOMAIN_OR_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

print_success "Variables de entorno configuradas"

# Paso 13: Build de la aplicación
print_status "🏗️ Compilando aplicación..."
npm run build
cd backend && npm run build && cd ..

# Paso 14: Inicializar base de datos
print_status "🗄️ Inicializando base de datos..."
cd backend
node dist/scripts/init-db.js || print_warning "Error al inicializar BD - puede que ya esté inicializada"
cd ..

# Paso 15: Crear usuario admin
print_status "👤 Creando usuario administrador..."
node create-admin-user.js || print_warning "Error al crear usuario admin - puede que ya exista"

# Paso 16: Configurar Nginx
print_status "🌐 Configurando Nginx..."
$SUDO tee /etc/nginx/sites-available/gestion-pedidos > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    # Frontend (archivos estáticos)
    location / {
        root /home/gestionPedidos/dist;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Archivos subidos
    location /uploads {
        alias /home/gestionPedidos/backend/uploads;
    }
}
EOF

# Activar sitio
$SUDO ln -sf /etc/nginx/sites-available/gestion-pedidos /etc/nginx/sites-enabled/
$SUDO rm -f /etc/nginx/sites-enabled/default
$SUDO nginx -t && $SUDO systemctl restart nginx

print_success "Nginx configurado correctamente"

# Paso 17: Configurar PM2
print_status "⚡ Configurando PM2..."
cat > ecosystem.config.js << EOF
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
    }
  }]
};
EOF

# Iniciar aplicación con PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | $SUDO bash

print_success "PM2 configurado y aplicación iniciada"

# Paso 18: Configurar permisos
print_status "🔐 Configurando permisos..."
$SUDO chown -R www-data:www-data /home/gestionPedidos
$SUDO chmod -R 755 /home/gestionPedidos

# Crear script de actualización
print_status "📝 Creando script de actualización..."
cat > update-app.sh << 'EOF'
#!/bin/bash
echo "🔄 Actualizando aplicación..."

cd /home/gestionPedidos

# Backup de configuración
cp .env .env.backup
cp backend/.env backend/.env.backup

# Actualizar código
git pull origin main

# Instalar dependencias
npm install
cd backend && npm install && cd ..

# Build
npm run build
cd backend && npm run build && cd ..

# Reiniciar aplicación
pm2 restart gestion-pedidos-backend

echo "✅ Aplicación actualizada correctamente"
EOF

chmod +x update-app.sh

# Finalización
echo ""
echo "=================================================="
print_success "🎉 ¡Instalación completada exitosamente!"
echo "=================================================="
echo ""
print_status "📋 Información importante:"
echo "• URL de la aplicación: http://$DOMAIN_OR_IP"
echo "• Usuario admin: admin"
echo "• Contraseña admin: 123456"
echo "• Base de datos: gestionPedidos"
echo "• Usuario BD: $DB_USER"
echo ""
print_status "🔧 Comandos útiles:"
echo "• Ver estado: pm2 status"
echo "• Ver logs: pm2 logs"
echo "• Actualizar app: ./update-app.sh"
echo "• Reiniciar Nginx: sudo systemctl restart nginx"
echo ""
print_warning "⚠️  IMPORTANTE:"
echo "1. Ejecuta: sudo mysql_secure_installation"
echo "2. Cambia la contraseña del admin en la aplicación"
echo "3. Considera configurar SSL con: sudo certbot --nginx -d $DOMAIN_OR_IP"
echo ""
print_success "¡Tu aplicación está lista para usar! 🚀"
