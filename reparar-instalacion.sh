#!/bin/bash

# Script de reparación para Topping Frozen App
# Soluciona los problemas identificados en el diagnóstico

echo "🔧 REPARANDO INSTALACIÓN DE TOPPING FROZEN APP"
echo "=============================================="

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

print_header() {
    echo -e "${BLUE}[PASO]${NC} $1"
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root. Usa un usuario con sudo."
   exit 1
fi

print_header "1. Instalando Nginx (faltante)..."
sudo apt update
sudo apt install -y nginx

print_header "2. Creando directorio de aplicación..."
APP_DIR="/var/www/topping-frozen"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

print_header "3. Clonando repositorio..."
cd $APP_DIR
if [ -d ".git" ]; then
    print_info "Repositorio ya existe, actualizando..."
    git pull origin main
else
    print_info "Clonando repositorio..."
    git clone https://github.com/jecaicedo27/topping-frozen-app.git .
fi

print_header "4. Instalando dependencias del backend..."
cd $APP_DIR/backend
npm install

print_header "5. Instalando dependencias del frontend..."
cd $APP_DIR
npm install

print_header "6. Creando archivo .env del backend..."
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

# JWT Secret
JWT_SECRET=tu_jwt_secret_muy_seguro_aqui_2024

# Configuración de uploads
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=5242880
EOF

print_status "Archivo .env del backend creado"

print_header "7. Compilando backend TypeScript..."
cd $APP_DIR/backend
npm run build

print_header "8. Construyendo frontend para producción..."
cd $APP_DIR
npm run build

print_header "9. Reparando base de datos..."
# Crear base de datos si no existe
sudo mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen;" 2>/dev/null || true
sudo mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingFrozen2024!';" 2>/dev/null || true
sudo mysql -e "GRANT ALL PRIVILEGES ON topping_frozen.* TO 'toppinguser'@'localhost';" 2>/dev/null || true
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Inicializar base de datos
cd $APP_DIR/backend
npm run init-db 2>/dev/null || true

print_header "10. Configurando PM2..."
cd $APP_DIR

# Eliminar proceso anterior si existe
pm2 delete topping-frozen-backend 2>/dev/null || true

# Crear nuevo ecosystem.config.js
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

# Iniciar aplicación
pm2 start ecosystem.config.js
pm2 save

print_header "11. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/topping-frozen << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Frontend (React build)
    location / {
        root /var/www/topping-frozen/build;
        index index.html index.htm;
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
    
    # Archivos estáticos de uploads
    location /uploads {
        alias /var/www/topping-frozen/backend/uploads;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t

print_header "12. Configurando firewall..."
sudo ufw allow OpenSSH 2>/dev/null || true
sudo ufw allow 'Nginx Full' 2>/dev/null || true
sudo ufw allow 80 2>/dev/null || true
sudo ufw allow 443 2>/dev/null || true
sudo ufw --force enable 2>/dev/null || true

print_header "13. Iniciando servicios..."
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl restart mysql

# Configurar PM2 para auto-inicio
pm2 startup 2>/dev/null || true

print_header "14. Verificando instalación..."
sleep 5

echo ""
print_info "Estado de servicios:"
echo "PM2:"
pm2 status

echo ""
echo "Nginx:"
sudo systemctl status nginx --no-pager -l | head -5

echo ""
echo "MySQL:"
sudo systemctl status mysql --no-pager -l | head -5

echo ""
print_info "Probando conectividad:"
if curl -s http://localhost >/dev/null 2>&1; then
    print_status "Nginx responde correctamente"
else
    print_error "Nginx no responde"
fi

if curl -s http://localhost:5000/api >/dev/null 2>&1; then
    print_status "Backend responde correctamente"
else
    print_warning "Backend puede estar iniciando..."
fi

echo ""
print_header "🎉 REPARACIÓN COMPLETADA"
echo "========================"

IP=$(hostname -I | awk '{print $1}')
print_status "Tu aplicación debería estar disponible en: http://$IP"
print_status "Credenciales: admin / 123456"

echo ""
print_info "Comandos útiles:"
echo "- Ver estado: pm2 status"
echo "- Ver logs: pm2 logs topping-frozen-backend"
echo "- Reiniciar: pm2 restart topping-frozen-backend"

echo ""
print_warning "Si aún no funciona, espera 2-3 minutos para que todos los servicios se inicien completamente."
