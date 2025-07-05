#!/bin/bash

# 🖥️ Script de Instalación Automática - Topping Frozen VPS
# Ejecutar como: bash install-vps.sh

set -e  # Salir si hay algún error

echo "🚀 Iniciando instalación de Topping Frozen en VPS Ubuntu..."
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar que se ejecuta como root o con sudo
if [[ $EUID -eq 0 ]]; then
   print_warning "Este script se está ejecutando como root. Se recomienda ejecutar con sudo."
fi

# PASO 1: Actualizar sistema
print_step "1. Actualizando sistema..."
apt update && apt upgrade -y

# PASO 2: Instalar herramientas básicas
print_step "2. Instalando herramientas básicas..."
apt install -y curl wget git unzip software-properties-common htop ufw

# PASO 3: Instalar Node.js
print_step "3. Instalando Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

print_status "Node.js $(node --version) instalado"
print_status "npm $(npm --version) instalado"

# PASO 4: Instalar PM2
print_step "4. Instalando PM2..."
npm install -g pm2

# PASO 5: Instalar MySQL
print_step "5. Instalando MySQL Server..."
apt install -y mysql-server

print_warning "Configurando MySQL..."
mysql_secure_installation

# PASO 6: Instalar Nginx
print_step "6. Instalando Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# PASO 7: Configurar Firewall
print_step "7. Configurando Firewall..."
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 3000
ufw allow 3001

print_status "Firewall configurado"

# PASO 8: Crear usuario para la aplicación
print_step "8. Creando usuario toppingapp..."
if id "toppingapp" &>/dev/null; then
    print_warning "Usuario toppingapp ya existe"
else
    adduser --disabled-password --gecos "" toppingapp
    usermod -aG sudo toppingapp
    print_status "Usuario toppingapp creado"
fi

# PASO 9: Configurar MySQL para la aplicación
print_step "9. Configurando base de datos..."
mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;"
mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

print_status "Base de datos configurada"

# PASO 10: Clonar repositorio como usuario toppingapp
print_step "10. Clonando repositorio..."
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp
if [ -d "topping-frozen-app" ]; then
    echo "Directorio ya existe, actualizando..."
    cd topping-frozen-app
    git pull origin main
else
    git clone https://github.com/jecaicedo27/topping-frozen-app.git
    cd topping-frozen-app
fi
EOF

print_status "Repositorio clonado"

# PASO 11: Configurar variables de entorno
print_step "11. Configurando variables de entorno..."
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp/topping-frozen-app/backend
cp .env.example .env

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)

# Configurar .env
cat > .env << EOL
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

# Frontend URL
FRONTEND_URL=http://${SERVER_IP}

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOL
EOF

print_status "Variables de entorno configuradas"

# PASO 12: Instalar dependencias y compilar
print_step "12. Instalando dependencias..."
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp/topping-frozen-app

# Backend
cd backend
npm install
npm run build

# Frontend
cd ..
npm install
npm run build:frontend

# Crear directorio de logs
mkdir -p logs
EOF

print_status "Dependencias instaladas y código compilado"

# PASO 13: Configurar base de datos
print_step "13. Configurando esquema de base de datos..."
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp/topping-frozen-app/backend
mysql -u toppinguser -pToppingPass2024! topping_frozen_db < src/config/database.sql
EOF

# Crear usuario admin
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp/topping-frozen-app
node create-admin-user.js
EOF

print_status "Base de datos configurada y usuario admin creado"

# PASO 14: Configurar PM2
print_step "14. Configurando PM2..."
sudo -u toppingapp bash << 'EOF'
cd /home/toppingapp/topping-frozen-app
pm2 start ecosystem.config.js
pm2 save
EOF

# Configurar PM2 para auto-start
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u toppingapp --hp /home/toppingapp

print_status "PM2 configurado"

# PASO 15: Configurar Nginx
print_step "15. Configurando Nginx..."

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)

cat > /etc/nginx/sites-available/topping-frozen << EOL
server {
    listen 80;
    server_name ${SERVER_IP};

    # Servir archivos estáticos del frontend
    location / {
        root /home/toppingapp/topping-frozen-app/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Proxy para API del backend
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Servir archivos subidos
    location /uploads/ {
        alias /home/toppingapp/topping-frozen-app/backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOL

# Habilitar sitio
ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
nginx -t

# Reiniciar Nginx
systemctl restart nginx

print_status "Nginx configurado"

# PASO 16: Crear script de deploy
print_step "16. Creando script de deploy..."
sudo -u toppingapp bash << 'EOF'
cat > /home/toppingapp/deploy.sh << 'EOL'
#!/bin/bash

echo "🚀 Iniciando deploy de Topping Frozen..."

# Ir al directorio de la aplicación
cd /home/toppingapp/topping-frozen-app

# Hacer backup de la base de datos
echo "📦 Creando backup de base de datos..."
mysqldump -u toppinguser -pToppingPass2024! topping_frozen_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Actualizar código desde GitHub
echo "📥 Actualizando código..."
git pull origin main

# Instalar dependencias del backend
echo "📦 Instalando dependencias del backend..."
cd backend
npm install
npm run build

# Instalar dependencias del frontend
echo "📦 Instalando dependencias del frontend..."
cd ..
npm install
npm run build:frontend

# Reiniciar aplicación
echo "🔄 Reiniciando aplicación..."
pm2 restart topping-backend

# Verificar estado
echo "✅ Verificando estado..."
pm2 status

echo "🎉 Deploy completado!"
EOL

chmod +x /home/toppingapp/deploy.sh
EOF

print_status "Script de deploy creado"

# PASO 17: Verificación final
print_step "17. Verificación final..."

# Verificar servicios
systemctl is-active --quiet nginx && print_status "✅ Nginx está corriendo" || print_error "❌ Nginx no está corriendo"
systemctl is-active --quiet mysql && print_status "✅ MySQL está corriendo" || print_error "❌ MySQL no está corriendo"

# Verificar PM2
sudo -u toppingapp pm2 status | grep -q "topping-backend" && print_status "✅ Aplicación está corriendo" || print_error "❌ Aplicación no está corriendo"

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)

echo ""
echo "🎉 ¡INSTALACIÓN COMPLETADA!"
echo "=================================================="
echo ""
echo "📱 Tu aplicación está disponible en:"
echo "   Frontend: http://${SERVER_IP}"
echo "   API: http://${SERVER_IP}/api"
echo ""
echo "🔐 Credenciales de acceso:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
echo ""
echo "🗄️ Base de datos MySQL:"
echo "   Usuario: toppinguser"
echo "   Contraseña: ToppingPass2024!"
echo "   Base de datos: topping_frozen_db"
echo ""
echo "📊 Comandos útiles:"
echo "   Ver logs: sudo -u toppingapp pm2 logs"
echo "   Estado: sudo -u toppingapp pm2 status"
echo "   Deploy: sudo -u toppingapp /home/toppingapp/deploy.sh"
echo ""
echo "🔧 Archivos importantes:"
echo "   Aplicación: /home/toppingapp/topping-frozen-app"
echo "   Nginx config: /etc/nginx/sites-available/topping-frozen"
echo "   Logs: /home/toppingapp/topping-frozen-app/logs"
echo ""
print_status "¡Tu sistema Topping Frozen está listo! 🚀"
