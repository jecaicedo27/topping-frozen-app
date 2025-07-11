#!/bin/bash

# Script de instalación automatizada para Topping Frozen App en Ubuntu VPS
# Autor: Sistema automatizado
# Fecha: $(date)

set -e  # Salir si hay algún error

echo "🚀 Iniciando instalación de Topping Frozen App en Ubuntu VPS..."
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root. Usa un usuario con sudo."
   exit 1
fi

# Actualizar sistema
print_header "1. Actualizando sistema Ubuntu..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias básicas
print_header "2. Instalando dependencias básicas..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Instalar Node.js 18.x (LTS)
print_header "3. Instalando Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar instalación de Node.js
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js instalado: $node_version"
print_status "NPM instalado: $npm_version"

# Instalar PM2 globalmente
print_header "4. Instalando PM2 para gestión de procesos..."
sudo npm install -g pm2

# Instalar MySQL
print_header "5. Instalando MySQL Server..."
sudo apt install -y mysql-server

# Configurar MySQL
print_header "6. Configurando MySQL..."
sudo mysql_secure_installation

# Crear base de datos y usuario
print_header "7. Creando base de datos para la aplicación..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingFrozen2024!';"
sudo mysql -e "GRANT ALL PRIVILEGES ON topping_frozen.* TO 'toppinguser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

print_status "Base de datos 'topping_frozen' creada"
print_status "Usuario 'toppinguser' creado con contraseña 'ToppingFrozen2024!'"

# Instalar Nginx
print_header "8. Instalando Nginx..."
sudo apt install -y nginx

# Configurar firewall
print_header "9. Configurando firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 3000
sudo ufw allow 5000
sudo ufw --force enable

# Crear directorio para la aplicación
print_header "10. Preparando directorio de aplicación..."
APP_DIR="/var/www/topping-frozen"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Clonar repositorio
print_header "11. Clonando repositorio desde GitHub..."
cd $APP_DIR
git clone https://github.com/jecaicedo27/topping-frozen-app.git .

# Instalar dependencias del backend
print_header "12. Instalando dependencias del backend..."
cd $APP_DIR/backend
npm install

# Instalar dependencias del frontend
print_header "13. Instalando dependencias del frontend..."
cd $APP_DIR
npm install

# Crear archivo de configuración del backend
print_header "14. Creando configuración del backend..."
cd $APP_DIR/backend
cat > .env << EOF
# Configuración de la base de datos
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingFrozen2024!
DB_NAME=topping_frozen
DB_PORT=3306

# Configuración del servidor
PORT=5000
NODE_ENV=production

# JWT Secret (cambiar en producción)
JWT_SECRET=tu_jwt_secret_muy_seguro_aqui_2024

# Configuración de uploads
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=5242880
EOF

print_status "Archivo .env del backend creado"

# Crear archivo de configuración del frontend
print_header "15. Creando configuración del frontend..."
cd $APP_DIR
cat > .env << EOF
# Configuración del frontend
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_ENV=production
EOF

print_status "Archivo .env del frontend creado"

# Compilar TypeScript del backend
print_header "16. Compilando backend TypeScript..."
cd $APP_DIR/backend
npm run build

# Construir frontend para producción
print_header "17. Construyendo frontend para producción..."
cd $APP_DIR
npm run build

# Inicializar base de datos
print_header "18. Inicializando base de datos..."
cd $APP_DIR/backend
npm run init-db

# Configurar PM2 para el backend
print_header "19. Configurando PM2 para el backend..."
cd $APP_DIR
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'topping-frozen-backend',
    script: './backend/dist/index.js',
    cwd: '/var/www/topping-frozen',
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
print_header "20. Iniciando aplicación con PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Configurar Nginx
print_header "21. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/topping-frozen << EOF
server {
    listen 80;
    server_name _;
    
    # Frontend (React build)
    location / {
        root /var/www/topping-frozen/build;
        index index.html index.htm;
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
    
    # Archivos estáticos de uploads
    location /uploads {
        alias /var/www/topping-frozen/backend/uploads;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar sitio en Nginx
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Verificar estado de servicios
print_header "22. Verificando estado de servicios..."
print_status "Estado de MySQL:"
sudo systemctl status mysql --no-pager -l

print_status "Estado de Nginx:"
sudo systemctl status nginx --no-pager -l

print_status "Estado de PM2:"
pm2 status

# Mostrar información final
print_header "🎉 ¡Instalación completada!"
echo "=================================================="
print_status "La aplicación Topping Frozen está instalada y ejecutándose"
print_status "Frontend: Disponible en http://tu-ip-del-vps"
print_status "Backend API: Disponible en http://tu-ip-del-vps/api"
print_status "Base de datos: MySQL en localhost:3306"
echo ""
print_warning "IMPORTANTE - Información de la base de datos:"
echo "  - Base de datos: topping_frozen"
echo "  - Usuario: toppinguser"
echo "  - Contraseña: ToppingFrozen2024!"
echo ""
print_warning "PRÓXIMOS PASOS:"
echo "1. Cambia las contraseñas por defecto"
echo "2. Configura tu dominio si tienes uno"
echo "3. Instala SSL/HTTPS con Let's Encrypt"
echo "4. Configura backups automáticos"
echo ""
print_status "Logs de la aplicación: pm2 logs topping-frozen-backend"
print_status "Reiniciar aplicación: pm2 restart topping-frozen-backend"
print_status "Ver estado: pm2 status"

echo "=================================================="
echo "🚀 ¡Instalación finalizada exitosamente!"
