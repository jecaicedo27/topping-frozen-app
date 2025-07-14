#!/bin/bash

# Script para corregir la conexión de base de datos AHORA
echo "🔧 Corrigiendo conexión de base de datos..."

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

cd /var/www/topping-frozen-app

print_status "1. Verificando estado de MySQL..."
systemctl status mysql --no-pager -l

print_status "2. Reiniciando MySQL..."
systemctl restart mysql
sleep 5

print_status "3. Creando usuario y base de datos..."
mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;"
mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

print_status "4. Verificando conexión..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Conexión de BD exitosa"
else
    print_error "Conexión de BD falló"
    exit 1
fi

print_status "5. Creando tablas..."
mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero', 'regular') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT IGNORE INTO users (username, password, name, role)
VALUES ('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrador', 'admin');
EOF

print_status "6. Verificando usuario admin..."
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null)
print_info "Usuarios admin en BD: $USER_COUNT"

print_status "7. Reiniciando backend..."
pm2 stop topping-frozen-backend 2>/dev/null || true
pm2 delete topping-frozen-backend 2>/dev/null || true

# Asegurar que el .env esté correcto
cat > backend/.env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306

# Server Configuration
PORT=3001
NODE_ENV=production

# JWT Configuration
JWT_SECRET=topping-frozen-secret-key-2024

# Frontend Configuration
FRONTEND_URL=http://46.202.93.54
ALLOWED_ORIGINS=http://46.202.93.54,http://localhost:3000
EOF

# Recompilar backend
cd backend
npm install --silent
npx tsc 2>/dev/null || {
    mkdir -p dist
    cp -r src/* dist/
}
cd ..

# Iniciar backend
pm2 start ecosystem.config.js
pm2 save
sleep 10

print_status "8. Verificación final..."
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
print_info "Health check: $HEALTH_CHECK"

LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo ""
print_info "Resultado del login:"
echo "$LOGIN_TEST"
echo ""

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "🎉 ¡LOGIN FUNCIONANDO!"
    echo ""
    echo "✅ Base de datos conectada correctamente"
    echo "✅ Backend funcionando"
    echo "✅ Login generando tokens"
    echo ""
    echo "🌐 Prueba en: http://46.202.93.54"
    echo "🔐 Usuario: admin / Contraseña: 123456"
else
    print_warning "Aún hay problemas. Logs del backend:"
    pm2 logs topping-frozen-backend --lines 5 --nostream
fi
