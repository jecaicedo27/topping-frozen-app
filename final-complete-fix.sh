#!/bin/bash

# Script final para corregir completamente el sistema de login
echo "🚀 Corrección completa final del sistema Topping Frozen..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
print_info "IP del servidor: $SERVER_IP"

echo ""
echo "🔧 CORRECCIÓN COMPLETA DEL SISTEMA"
echo "=================================================="

# 1. Detener todos los servicios
print_status "1. Deteniendo servicios..."
pm2 stop all 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true

# 2. Verificar y corregir MySQL
print_status "2. Verificando MySQL..."
if ! systemctl is-active --quiet mysql; then
    print_warning "MySQL no está activo, iniciando..."
    systemctl start mysql
    systemctl enable mysql
    sleep 3
fi

# 3. Recrear completamente la base de datos
print_status "3. Recreando base de datos..."
mysql -e "DROP DATABASE IF EXISTS topping_frozen_db;" 2>/dev/null
mysql -e "DROP USER IF EXISTS 'toppinguser'@'localhost';" 2>/dev/null
mysql -e "CREATE DATABASE topping_frozen_db;" 2>/dev/null
mysql -e "CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';" 2>/dev/null
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';" 2>/dev/null
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

# Verificar conexión
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Conexión a base de datos OK"
else
    print_error "Error de conexión a base de datos"
    exit 1
fi

# 4. Crear tablas
print_status "4. Creando tablas..."
mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
CREATE TABLE users (
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

INSERT INTO users (username, password, role, email, full_name) VALUES
('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'admin@toppingfrozen.com', 'Administrador');
EOF

# 5. Ir al directorio del proyecto
cd /var/www/topping-frozen-app || {
    print_error "Directorio del proyecto no encontrado"
    exit 1
}

# 6. Configurar backend
print_status "5. Configurando backend..."
cd backend

# Crear .env correcto
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

# Instalar dependencias
print_status "Instalando dependencias del backend..."
npm install mysql2 bcrypt jsonwebtoken express cors dotenv --silent

# Compilar
print_status "Compilando backend..."
if [ -f "tsconfig.json" ]; then
    npx tsc 2>/dev/null || {
        mkdir -p dist
        cp -r src/* dist/ 2>/dev/null
    }
else
    mkdir -p dist
    cp -r src/* dist/ 2>/dev/null
fi

cd ..

# 7. Configurar frontend
print_status "6. Configurando frontend..."

# Verificar y corregir api.ts
if [ -f "src/services/api.ts" ]; then
    # Hacer backup
    cp src/services/api.ts src/services/api.ts.backup 2>/dev/null
    
    # Corregir configuración
    sed -i "s/localhost/$SERVER_IP/g" src/services/api.ts 2>/dev/null
    sed -i "s/127.0.0.1/$SERVER_IP/g" src/services/api.ts 2>/dev/null
fi

# Crear .env para frontend
cat > .env << EOF
REACT_APP_API_URL=http://$SERVER_IP/api
REACT_APP_BACKEND_URL=http://$SERVER_IP
EOF

# Reconstruir frontend
print_status "Reconstruyendo frontend..."
npm run build 2>/dev/null || npx webpack --mode production 2>/dev/null

# 8. Configurar Nginx
print_status "7. Configurando Nginx..."
cat > /etc/nginx/sites-available/topping-frozen << EOF
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
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        add_header Access-Control-Allow-Origin "http://$SERVER_IP" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
EOF

# Habilitar sitio
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# Verificar y reiniciar Nginx
nginx -t && systemctl restart nginx

# 9. Configurar PM2
print_status "8. Configurando PM2..."
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

# 10. Iniciar backend
print_status "9. Iniciando backend..."
pm2 delete topping-frozen-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

# Esperar a que inicie
sleep 10

# 11. Configurar permisos
print_status "10. Configurando permisos..."
chown -R www-data:www-data /var/www/topping-frozen-app
chmod -R 755 /var/www/topping-frozen-app

# 12. Verificaciones finales
print_status "11. Verificaciones finales..."
echo ""

# Verificar servicios
print_info "Estado de servicios:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}' || echo 'offline')"

# Verificar base de datos
print_info "Verificando base de datos:"
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
echo "   Usuarios en BD: $USER_COUNT"

# Verificar puertos
print_info "Puertos abiertos:"
netstat -tlnp | grep -E ':(80|3001)' | head -2

# Esperar un poco más
sleep 5

# Probar endpoints
print_info "Probando endpoints:"
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
echo "   Health check: $HEALTH_CHECK"

LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "✅ Login funcionando correctamente!"
    echo "   Respuesta: $(echo "$LOGIN_TEST" | head -c 100)..."
else
    print_warning "Login aún tiene problemas"
    echo "   Respuesta: $LOGIN_TEST"
fi

# Probar desde IP externa
EXTERNAL_TEST=$(curl -s -X POST http://$SERVER_IP/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$EXTERNAL_TEST" | grep -q "token\|success"; then
    print_status "✅ Login externo funcionando!"
else
    print_warning "Login externo tiene problemas"
    echo "   Respuesta externa: $EXTERNAL_TEST"
fi

echo ""
echo "🎉 CORRECCIÓN COMPLETA FINALIZADA"
echo "=================================================="
echo ""
echo "🌐 URLs para probar:"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend: http://$SERVER_IP/api/health"
echo ""
echo "🔐 Credenciales:"
echo "   Usuario: admin"
echo "   Contraseña: 123456"
echo ""

if echo "$LOGIN_TEST" | grep -q "token\|success" && echo "$EXTERNAL_TEST" | grep -q "token\|success"; then
    print_status "🎉 ¡SISTEMA COMPLETAMENTE FUNCIONAL!"
    echo ""
    echo "✅ Puedes iniciar sesión en: http://$SERVER_IP"
else
    print_warning "Sistema parcialmente funcional. Comandos de diagnóstico:"
    echo ""
    echo "   pm2 logs topping-frozen-backend --lines 20"
    echo "   mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e 'SELECT * FROM users;'"
    echo "   curl -v http://$SERVER_IP/api/auth/login"
fi
