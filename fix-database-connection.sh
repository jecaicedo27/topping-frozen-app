#!/bin/bash

# Script para corregir la conexión a la base de datos
echo "🔧 Corrigiendo conexión a la base de datos..."

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

# 1. Verificar estado de MySQL
print_status "1. Verificando estado de MySQL..."
if systemctl is-active --quiet mysql; then
    print_status "MySQL está activo"
else
    print_warning "MySQL no está activo, iniciando..."
    systemctl start mysql
    systemctl enable mysql
    sleep 3
fi

# 2. Verificar conexión directa a MySQL
print_status "2. Verificando conexión directa a MySQL..."
if mysql -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Conexión root a MySQL OK"
else
    print_error "No se puede conectar a MySQL como root"
    print_info "Intentando configurar MySQL..."
    
    # Configurar MySQL si es necesario
    mysql_secure_installation --use-default
fi

# 3. Verificar/crear base de datos y usuario
print_status "3. Configurando base de datos y usuario..."

# Crear base de datos
mysql -e "CREATE DATABASE IF NOT EXISTS topping_frozen_db;" 2>/dev/null

# Eliminar usuario existente y recrear
mysql -e "DROP USER IF EXISTS 'toppinguser'@'localhost';" 2>/dev/null
mysql -e "CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';" 2>/dev/null
mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';" 2>/dev/null
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

# Verificar que el usuario funcione
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Usuario toppinguser creado y funcionando"
else
    print_error "Error creando usuario toppinguser"
    
    # Intentar con método alternativo
    print_info "Intentando método alternativo..."
    mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED WITH mysql_native_password BY 'ToppingPass2024!';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
fi

# 4. Crear tablas necesarias
print_status "4. Creando tablas necesarias..."
mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
CREATE TABLE IF NOT EXISTS users (
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

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_address TEXT,
    items JSON NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'confirmed', 'in_preparation', 'ready', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'partial', 'refunded') DEFAULT 'pending',
    delivery_date DATE,
    delivery_time TIME,
    notes TEXT,
    created_by INT,
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS money_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    receipt_number VARCHAR(50) UNIQUE NOT NULL,
    order_id INT,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL,
    reference_number VARCHAR(100),
    description TEXT,
    receipt_image VARCHAR(255),
    status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    created_by INT,
    verified_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (verified_by) REFERENCES users(id)
);
EOF

# 5. Insertar usuarios de prueba
print_status "5. Insertando usuarios de prueba..."
mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
INSERT IGNORE INTO users (username, password, role, email, full_name) VALUES
('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'admin@toppingfrozen.com', 'Administrador'),
('facturacion', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'facturacion', 'facturacion@toppingfrozen.com', 'Usuario Facturación'),
('cartera', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cartera', 'cartera@toppingfrozen.com', 'Usuario Cartera'),
('logistica', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'logistica', 'logistica@toppingfrozen.com', 'Usuario Logística'),
('mensajero', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mensajero', 'mensajero@toppingfrozen.com', 'Usuario Mensajero');
EOF

# 6. Verificar configuración del backend
print_status "6. Configurando backend..."
cd /var/www/topping-frozen-app/backend

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Crear archivo .env correcto
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

# CORS Configuration
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF

print_status "Archivo .env actualizado"

# 7. Verificar dependencias del backend
print_status "7. Verificando dependencias del backend..."
if [ ! -d "node_modules" ] || [ ! -f "node_modules/mysql2/package.json" ]; then
    print_warning "Instalando dependencias..."
    npm install
fi

# Asegurar que mysql2 esté instalado
npm install mysql2 bcrypt jsonwebtoken express cors dotenv

# 8. Compilar backend
print_status "8. Compilando backend..."
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
    print_warning "Compilación falló, copiando archivos manualmente..."
    mkdir -p dist
    cp -r src/* dist/ 2>/dev/null
fi

cd ..

# 9. Reiniciar backend
print_status "9. Reiniciando backend..."
pm2 delete topping-frozen-backend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

# Esperar a que inicie
sleep 10

# 10. Verificar conexión final
print_status "10. Verificando conexión final..."
echo ""

# Verificar MySQL
print_info "Estado de MySQL:"
systemctl status mysql --no-pager -l | head -3

# Verificar usuario de base de datos
print_info "Verificando usuario de base de datos:"
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) as total_users FROM users;" 2>/dev/null; then
    print_status "Conexión a base de datos OK"
else
    print_error "Aún hay problemas con la base de datos"
fi

# Verificar backend
print_info "Verificando backend:"
sleep 5
BACKEND_TEST=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if echo "$BACKEND_TEST" | grep -q "ok\|healthy\|success"; then
    print_status "Backend respondiendo: $BACKEND_TEST"
else
    print_warning "Backend no responde correctamente"
    print_info "Logs del backend:"
    pm2 logs topping-frozen-backend --lines 5 --nostream
fi

# Probar login
print_info "Probando login:"
LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$LOGIN_TEST" | grep -q "token\|success"; then
    print_status "✅ Login funcionando correctamente!"
    echo "Respuesta: $LOGIN_TEST"
else
    print_warning "Login aún tiene problemas"
    echo "Respuesta: $LOGIN_TEST"
fi

echo ""
echo "🎯 URLs para probar:"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend: http://$SERVER_IP/api/health"
echo "   Login: admin / 123456"
echo ""
echo "🔧 Si aún hay problemas:"
echo "   pm2 logs topping-frozen-backend --lines 20"
echo "   mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e 'SELECT * FROM users;'"
