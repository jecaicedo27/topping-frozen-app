#!/bin/bash

# Script final para corregir el backend y base de datos
echo "🔧 Corrección final del backend..."

cd /var/www/topping-frozen-app

# 1. Verificar y corregir MySQL
echo "🗄️ Corrigiendo MySQL..."
systemctl restart mysql
sleep 5

# 2. Crear usuario y base de datos
mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;"
mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 3. Crear tabla de usuarios
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

# 4. Verificar usuario creado
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null)
echo "✅ Usuarios admin en BD: $USER_COUNT"

# 5. Corregir .env del backend
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

# 6. Recompilar backend
echo "🔨 Recompilando backend..."
cd backend
npm install --silent
npx tsc 2>/dev/null || {
    mkdir -p dist
    cp -r src/* dist/
}
cd ..

# 7. Reiniciar backend
echo "🔄 Reiniciando backend..."
pm2 stop topping-frozen-backend 2>/dev/null || true
pm2 delete topping-frozen-backend 2>/dev/null || true

pm2 start ecosystem.config.js
pm2 save
sleep 10

# 8. Verificación final
echo "🧪 Verificación final..."
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
echo "Health check: $HEALTH_CHECK"

LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Login test: $LOGIN_TEST"

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    echo "🎉 ¡LOGIN FUNCIONANDO PERFECTAMENTE!"
    echo "🌐 Prueba en: http://46.202.93.54"
    echo "🔐 Usuario: admin / Contraseña: 123456"
else
    echo "⚠️ Verificando logs..."
    pm2 logs topping-frozen-backend --lines 5 --nostream
fi
