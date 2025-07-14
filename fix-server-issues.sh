#!/bin/bash

# Script para corregir problemas después de la instalación
echo "🔧 Corrigiendo problemas del servidor..."

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
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

print_info "IP del servidor: $SERVER_IP"

# 1. Detener servicios conflictivos
print_status "Deteniendo servicios conflictivos..."
systemctl stop apache2
systemctl disable apache2
pm2 stop all

# 2. Corregir conflictos de puertos
print_status "Liberando puertos..."
fuser -k 80/tcp 2>/dev/null || true
fuser -k 3001/tcp 2>/dev/null || true
fuser -k 8080/tcp 2>/dev/null || true

# 3. Verificar y corregir instalación de PHP
print_status "Verificando PHP..."
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
if [ -z "$PHP_VERSION" ]; then
    print_warning "Reinstalando PHP..."
    apt install -y php8.1 php8.1-fpm php8.1-mysql php8.1-mbstring php8.1-zip php8.1-gd php8.1-json php8.1-curl
    PHP_VERSION="8.1"
fi

print_info "PHP Version: $PHP_VERSION"

# 4. Configurar PHP-FPM
print_status "Configurando PHP-FPM..."
systemctl start php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

# 5. Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    print_error "Directorio del proyecto no encontrado"
    exit 1
}

# 6. Verificar y corregir dependencias del backend
print_status "Verificando dependencias del backend..."
cd backend

# Verificar si node_modules existe
if [ ! -d "node_modules" ]; then
    print_warning "Instalando dependencias del backend..."
    npm install
fi

# Verificar si TypeScript está instalado
if ! npm list typescript > /dev/null 2>&1; then
    print_warning "Instalando TypeScript..."
    npm install --save-dev typescript @types/node
fi

# 7. Compilar backend
print_status "Compilando backend..."
if [ -f "tsconfig.json" ]; then
    npx tsc
else
    print_warning "Creando tsconfig.json..."
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
    npx tsc
fi

# Verificar que la compilación fue exitosa
if [ ! -f "dist/index.js" ]; then
    print_error "Error en la compilación del backend"
    print_info "Intentando compilación manual..."
    mkdir -p dist
    cp -r src/* dist/
fi

cd ..

# 8. Verificar y construir frontend
print_status "Verificando frontend..."
if [ ! -d "dist" ]; then
    print_warning "Construyendo frontend..."
    npm run build || {
        print_warning "Error en build, intentando webpack..."
        npx webpack --mode production
    }
fi

# 9. Corregir configuración de Nginx
print_status "Corrigiendo configuración de Nginx..."

# Eliminar configuraciones conflictivas
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/phpmyadmin

# Crear configuración principal
cat > /etc/nginx/sites-available/topping-frozen << EOF
server {
    listen 80;
    server_name $SERVER_IP _;

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

# phpMyAdmin en puerto 8080
server {
    listen 8080;
    server_name $SERVER_IP _;
    root /var/www/html/phpmyadmin;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
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

# Habilitar sitio
ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# 10. Verificar configuración de Nginx
print_status "Verificando configuración de Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    print_status "Nginx reiniciado correctamente"
else
    print_error "Error en configuración de Nginx"
    nginx -t
fi

# 11. Verificar variables de entorno del backend
print_status "Verificando variables de entorno..."
cd backend

if [ ! -f ".env" ]; then
    print_warning "Creando archivo .env..."
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

# Frontend URL
FRONTEND_URL=http://$SERVER_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts

# CORS Configuration
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF
fi

cd ..

# 12. Verificar base de datos
print_status "Verificando conexión a base de datos..."
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) FROM users;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "Base de datos funcionando correctamente"
else
    print_warning "Problema con la base de datos, recreando..."
    mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;"
    mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
    mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# 13. Configurar PM2 correctamente
print_status "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'topping-frozen-backend',
      script: 'backend/dist/index.js',
      cwd: '/var/www/topping-frozen-app',
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

# 14. Iniciar backend con PM2
print_status "Iniciando backend con PM2..."
pm2 delete topping-frozen-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

# 15. Configurar permisos
print_status "Configurando permisos..."
chown -R www-data:www-data /var/www/topping-frozen-app
chmod -R 755 /var/www/topping-frozen-app

# Crear directorio de uploads
mkdir -p /var/www/topping-frozen-app/backend/uploads/receipts
chown -R www-data:www-data /var/www/topping-frozen-app/backend/uploads

# 16. Verificaciones finales
print_status "Realizando verificaciones finales..."

# Esperar a que los servicios inicien
sleep 15

# Verificar servicios
print_info "Estado de servicios:"
systemctl is-active nginx && print_status "Nginx: Activo" || print_error "Nginx: Inactivo"
systemctl is-active mysql && print_status "MySQL: Activo" || print_error "MySQL: Inactivo"
systemctl is-active php${PHP_VERSION}-fpm && print_status "PHP-FPM: Activo" || print_error "PHP-FPM: Inactivo"

# Verificar PM2
pm2 status | grep -q "online" && print_status "Backend PM2: Activo" || print_error "Backend PM2: Inactivo"

# Verificar puertos
print_info "Verificando puertos:"
netstat -tlnp | grep :80 > /dev/null && print_status "Puerto 80: Abierto" || print_error "Puerto 80: Cerrado"
netstat -tlnp | grep :3001 > /dev/null && print_status "Puerto 3001: Abierto" || print_error "Puerto 3001: Cerrado"
netstat -tlnp | grep :8080 > /dev/null && print_status "Puerto 8080: Abierto" || print_error "Puerto 8080: Cerrado"

# Verificar endpoints
print_info "Verificando endpoints:"
curl -s http://localhost/api/health > /dev/null && print_status "Health check: OK" || print_error "Health check: FAIL"
curl -s http://localhost > /dev/null && print_status "Frontend: OK" || print_error "Frontend: FAIL"

# 17. Mostrar información final
echo ""
echo "🎉 ¡Corrección completada!"
echo ""
echo "📋 URLs del sistema:"
echo "   🌐 Frontend: http://$SERVER_IP"
echo "   🔧 Backend API: http://$SERVER_IP/api"
echo "   ❤️  Health check: http://$SERVER_IP/api/health"
echo "   🗄️  phpMyAdmin: http://$SERVER_IP:8080"
echo ""
echo "🔧 Comandos de diagnóstico:"
echo "   Ver logs del backend: pm2 logs topping-frozen-backend"
echo "   Estado de PM2: pm2 status"
echo "   Estado de Nginx: systemctl status nginx"
echo "   Logs de Nginx: tail -f /var/log/nginx/topping-frozen.error.log"
echo ""
echo "🧪 Comandos de prueba:"
echo "   curl http://$SERVER_IP/api/health"
echo "   curl -X POST http://$SERVER_IP/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"123456\"}'"
echo ""

if curl -s http://localhost/api/health > /dev/null; then
    print_status "¡Sistema funcionando correctamente!"
else
    print_warning "Sistema parcialmente funcional. Revisar logs para más detalles."
    echo ""
    echo "📋 Logs recientes del backend:"
    pm2 logs topping-frozen-backend --lines 10
fi
