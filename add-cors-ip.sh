#!/bin/bash

# Script para agregar IP específica a CORS
echo "🌐 Agregando IP a configuración CORS..."

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar parámetro
if [ -z "$1" ]; then
    echo "Uso: $0 <IP_ADDRESS>"
    echo "Ejemplo: $0 46.202.93.54"
    exit 1
fi

NEW_IP="$1"
print_status "Agregando IP: $NEW_IP"

# Ir al directorio del proyecto
cd /var/www/topping-frozen-app

# Obtener IP actual del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# Actualizar archivo .env del backend
print_status "Actualizando configuración CORS..."
cd backend

# Crear nueva configuración CORS
NEW_CORS="http://$SERVER_IP,https://$SERVER_IP,http://$NEW_IP,https://$NEW_IP"

# Actualizar archivo .env
if [ -f ".env" ]; then
    # Hacer backup
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    
    # Actualizar CORS
    sed -i "s|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=$NEW_CORS|g" .env
    
    print_status "Archivo .env actualizado"
    echo "CORS permitidos: $NEW_CORS"
else
    print_warning "Archivo .env no encontrado, creando..."
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

# CORS Configuration - IPs permitidas
ALLOWED_ORIGINS=$NEW_CORS
EOF
fi

cd ..

# Reiniciar PM2
print_status "Reiniciando backend..."
pm2 restart topping-frozen-backend

# Esperar un momento
sleep 3

# Verificar funcionamiento
print_status "Verificando funcionamiento..."
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "✅ Backend funcionando correctamente"
    
    # Mostrar configuración actual
    echo ""
    echo "📋 Configuración CORS actualizada:"
    echo "   Servidor: $SERVER_IP"
    echo "   Nueva IP: $NEW_IP"
    echo "   Orígenes permitidos: $NEW_CORS"
    echo ""
    echo "🧪 Probar desde la nueva IP:"
    echo "   curl http://$SERVER_IP/api/health"
    echo "   curl -H 'Origin: http://$NEW_IP' http://$SERVER_IP/api/health"
else
    print_warning "⚠️ Backend no responde, verificando logs..."
    pm2 logs topping-frozen-backend --lines 10
fi

print_status "🎉 Proceso completado!"
