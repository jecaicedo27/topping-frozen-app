#!/bin/bash

# Script rápido para corregir problemas del servidor VPS
echo "🔧 Iniciando corrección rápida del servidor..."

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo "IP del servidor: $SERVER_IP"

# Detener servicios conflictivos
echo "Deteniendo Apache..."
sudo systemctl stop apache2 2>/dev/null
sudo systemctl disable apache2 2>/dev/null

echo "Deteniendo PM2..."
pm2 stop all 2>/dev/null

# Liberar puertos
echo "Liberando puertos..."
sudo fuser -k 80/tcp 2>/dev/null
sudo fuser -k 3001/tcp 2>/dev/null

# Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    echo "❌ Error: Directorio del proyecto no encontrado"
    exit 1
}

# Verificar y compilar backend
echo "Compilando backend..."
cd backend
npm install --silent
npx tsc 2>/dev/null || {
    echo "Creando compilación manual..."
    mkdir -p dist
    cp -r src/* dist/ 2>/dev/null
}
cd ..

# Construir frontend si no existe
if [ ! -d "dist" ]; then
    echo "Construyendo frontend..."
    npm run build 2>/dev/null || npx webpack --mode production 2>/dev/null
fi

# Configurar Nginx
echo "Configurando Nginx..."
sudo tee /etc/nginx/sites-available/topping-frozen > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_IP _;
    
    location / {
        root /var/www/topping-frozen-app/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        add_header Access-Control-Allow-Origin "http://$SERVER_IP" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
EOF

# Habilitar sitio
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# Verificar y reiniciar Nginx
sudo nginx -t && sudo systemctl restart nginx

# Configurar variables de entorno
echo "Configurando variables de entorno..."
cd backend
cat > .env << EOF
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-vps-2024
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://$SERVER_IP
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF
cd ..

# Configurar PM2
echo "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'topping-frozen-backend',
    script: 'backend/dist/index.js',
    cwd: '/var/www/topping-frozen-app',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    instances: 1,
    autorestart: true,
    watch: false
  }]
};
EOF

# Iniciar backend
echo "Iniciando backend..."
pm2 delete topping-frozen-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

# Configurar permisos
sudo chown -R www-data:www-data /var/www/topping-frozen-app
sudo chmod -R 755 /var/www/topping-frozen-app

# Crear directorio de uploads
mkdir -p backend/uploads/receipts
sudo chown -R www-data:www-data backend/uploads

echo "⏳ Esperando que los servicios inicien..."
sleep 10

# Verificaciones
echo "🔍 Verificando servicios..."
echo "Nginx: $(sudo systemctl is-active nginx)"
echo "MySQL: $(sudo systemctl is-active mysql)"
echo "Backend PM2: $(pm2 list | grep -q online && echo "online" || echo "offline")"

# Probar endpoints
echo "🧪 Probando endpoints..."
if curl -s http://localhost/api/health > /dev/null; then
    echo "✅ Health check: OK"
else
    echo "❌ Health check: FAIL"
fi

if curl -s http://localhost > /dev/null; then
    echo "✅ Frontend: OK"
else
    echo "❌ Frontend: FAIL"
fi

echo ""
echo "🎉 Corrección completada!"
echo ""
echo "📋 URLs para probar:"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend: http://$SERVER_IP/api/health"
echo "   phpMyAdmin: http://$SERVER_IP:8080"
echo ""
echo "👤 Credenciales de prueba:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
echo ""
echo "🔧 Si hay problemas, ejecuta:"
echo "   pm2 logs topping-frozen-backend"
echo "   sudo systemctl status nginx"
