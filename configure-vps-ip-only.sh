#!/bin/bash

# Script para configurar el VPS usando solo IP (sin DNS)
# Ejecutar en el servidor VPS

echo "🚀 Configurando VPS para usar solo IP (sin DNS)..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

echo "🔍 IP del servidor detectada: $SERVER_IP"

# Verificar si estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    print_error "No se encontró package.json. Asegúrate de estar en el directorio del proyecto."
    exit 1
fi

# 1. Actualizar código desde GitHub
print_status "Actualizando código desde GitHub..."
git pull origin main

# 2. Configurar archivo .env para producción
print_status "Configurando archivo .env para producción..."
cd backend

# Crear backup del .env actual si existe
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup del .env actual creado"
fi

# Crear nuevo .env basado en .env.production
if [ -f ".env.production" ]; then
    cp .env.production .env
    
    # Reemplazar YOUR_SERVER_IP con la IP real
    sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" .env
    
    print_status "Archivo .env configurado con IP: $SERVER_IP"
else
    print_warning "No se encontró .env.production, creando .env básico..."
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
fi

# 3. Instalar dependencias
print_status "Instalando dependencias del backend..."
npm install

# Volver al directorio raíz
cd ..

# 4. Instalar dependencias del frontend si es necesario
if [ -f "package.json" ]; then
    print_status "Instalando dependencias del frontend..."
    npm install
fi

# 5. Configurar Nginx si existe
if [ -f "/etc/nginx/sites-available/topping-frozen" ]; then
    print_status "Configurando Nginx para usar solo IP..."
    
    # Backup de configuración actual
    cp /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-available/topping-frozen.backup.$(date +%Y%m%d_%H%M%S)
    
    # Crear nueva configuración sin DNS
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

    # Verificar configuración de Nginx
    nginx -t
    if [ $? -eq 0 ]; then
        print_status "Configuración de Nginx válida"
        systemctl reload nginx
        print_status "Nginx recargado"
    else
        print_error "Error en la configuración de Nginx"
    fi
fi

# 6. Reiniciar servicios
print_status "Reiniciando servicios..."

# PM2
if command -v pm2 &> /dev/null; then
    pm2 restart all
    print_status "PM2 reiniciado"
fi

# Systemd services
if systemctl is-active --quiet topping-frozen-backend; then
    systemctl restart topping-frozen-backend
    print_status "Servicio backend reiniciado"
fi

if systemctl is-active --quiet topping-frozen-frontend; then
    systemctl restart topping-frozen-frontend
    print_status "Servicio frontend reiniciado"
fi

# 7. Verificaciones
print_status "Realizando verificaciones..."

# Verificar backend
sleep 5
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "Backend funcionando correctamente"
else
    print_error "Backend no responde"
fi

# Verificar login
if curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' | grep -q "success"; then
    print_status "Login funcionando correctamente"
else
    print_error "Login no funciona"
fi

# 8. Mostrar información final
echo ""
echo "🎉 Configuración completada!"
echo ""
echo "📋 Información del servidor:"
echo "   IP del servidor: $SERVER_IP"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend API: http://$SERVER_IP/api"
echo "   Health check: http://$SERVER_IP/api/health"
echo ""
echo "🔧 Configuraciones aplicadas:"
echo "   ✅ DNS eliminado, solo IP configurada"
echo "   ✅ CORS configurado para IP específica"
echo "   ✅ Nginx configurado (si existe)"
echo "   ✅ Variables de entorno actualizadas"
echo ""
echo "🧪 Para probar el sistema:"
echo "   curl http://$SERVER_IP/api/health"
echo "   curl -X POST http://$SERVER_IP/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"123456\"}'"
echo ""
