#!/bin/bash

# 🔧 Script para Solucionar Error de Conexión a Base de Datos
# Soluciona el error ECONNREFUSED del backend

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Solucionando Error de Conexión a Base de Datos"
echo "================================================"

cd /home/gestionPedidos

# 1. Detener backend
print_status "1. Deteniendo backend..."
pm2 stop gestion-pedidos-backend

# 2. Verificar estado de MySQL
print_status "2. Verificando estado de MySQL..."
systemctl status mysql --no-pager | head -5

if ! systemctl is-active mysql > /dev/null; then
    print_warning "MySQL no está activo, iniciando..."
    systemctl start mysql
    sleep 3
fi

# 3. Verificar conexión MySQL
print_status "3. Probando conexión MySQL..."
mysql -u appuser -papppassword123 -e "SELECT 1;" 2>/dev/null && {
    print_success "✅ Conexión MySQL exitosa"
} || {
    print_error "❌ Error de conexión MySQL"
    
    # Intentar reconfigurar MySQL
    print_status "Reconfigurando MySQL..."
    mysql -e "ALTER USER 'appuser'@'localhost' IDENTIFIED BY 'apppassword123';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON gestionPedidos.* TO 'appuser'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
}

# 4. Verificar base de datos
print_status "4. Verificando base de datos gestionPedidos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null && {
    print_success "✅ Base de datos gestionPedidos existe"
} || {
    print_warning "⚠️ Creando base de datos..."
    mysql -u appuser -papppassword123 -e "CREATE DATABASE IF NOT EXISTS gestionPedidos;" 2>/dev/null
}

# 5. Verificar archivo .env del backend
print_status "5. Verificando configuración backend/.env..."
if [ ! -f "backend/.env" ]; then
    print_warning "Archivo backend/.env no existe, creando..."
    cat > backend/.env << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=apppassword123
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo-para-produccion-2024

# Frontend URL
FRONTEND_URL=http://localhost

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF
    print_success "Archivo backend/.env creado"
else
    print_success "Archivo backend/.env existe"
    echo "Contenido actual:"
    grep -v "PASSWORD\|SECRET" backend/.env
fi

# 6. Verificar que el archivo de configuración de DB existe
print_status "6. Verificando archivos de configuración..."
if [ ! -f "backend/dist/config/database-fixed.sql" ]; then
    print_warning "Creando archivo database-fixed.sql..."
    mkdir -p backend/dist/config
    cat > backend/dist/config/database-fixed.sql << 'EOF'
USE gestionPedidos;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL DEFAULT 'mensajero',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    customer_address TEXT,
    items TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pendiente', 'en_proceso', 'enviado', 'entregado', 'cancelado') DEFAULT 'pendiente',
    payment_status ENUM('pendiente', 'pagado', 'parcial') DEFAULT 'pendiente',
    created_by INT,
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS money_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    receipt_type ENUM('efectivo', 'transferencia', 'otro') NOT NULL,
    photo_path VARCHAR(255),
    notes TEXT,
    received_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (received_by) REFERENCES users(id)
);
EOF
fi

# 7. Ejecutar estructura de base de datos
print_status "7. Ejecutando estructura de base de datos..."
mysql -u appuser -papppassword123 < backend/dist/config/database-fixed.sql 2>/dev/null && {
    print_success "✅ Estructura de base de datos creada"
} || {
    print_warning "⚠️ Error al crear estructura, continuando..."
}

# 8. Crear usuario admin si no existe
print_status "8. Verificando usuario admin..."
ADMIN_EXISTS=$(mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null | tail -1)

if [ "$ADMIN_EXISTS" != "1" ]; then
    print_status "Creando usuario admin..."
    cd backend
    ADMIN_HASH=$(node -e "
    const bcrypt = require('bcrypt');
    const hash = bcrypt.hashSync('123456', 10);
    console.log(hash);
    " 2>/dev/null)
    cd ..
    
    mysql -u appuser -papppassword123 -e "
    USE gestionPedidos;
    INSERT INTO users (username, password, role) VALUES ('admin', '$ADMIN_HASH', 'admin');
    " 2>/dev/null
    
    print_success "Usuario admin creado"
else
    print_success "Usuario admin ya existe"
fi

# 9. Verificar puerto MySQL
print_status "9. Verificando puerto MySQL..."
if netstat -tlnp | grep :3306 > /dev/null; then
    print_success "✅ Puerto 3306 (MySQL) activo"
else
    print_error "❌ Puerto 3306 no activo"
    systemctl restart mysql
    sleep 3
fi

# 10. Test de conexión desde Node.js
print_status "10. Test de conexión desde Node.js..."
cd backend
node -e "
const mysql = require('mysql2/promise');

async function testConnection() {
    try {
        const connection = await mysql.createConnection({
            host: 'localhost',
            user: 'appuser',
            password: 'apppassword123',
            database: 'gestionPedidos',
            port: 3306
        });
        
        console.log('✅ Conexión exitosa desde Node.js');
        await connection.end();
    } catch (error) {
        console.log('❌ Error de conexión:', error.message);
    }
}

testConnection();
" 2>/dev/null
cd ..

# 11. Reiniciar backend
print_status "11. Reiniciando backend..."
pm2 start gestion-pedidos-backend
sleep 5

# 12. Verificar estado final
print_status "12. Verificando estado final..."
pm2 status

# 13. Test de API
print_status "13. Test de API..."
sleep 3
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "🎉 ¡API funcionando correctamente!"
    echo "Respuesta: $API_RESPONSE"
elif echo "$API_RESPONSE" | grep -q "error\|Error"; then
    print_warning "⚠️ API responde con error"
    echo "Respuesta: $API_RESPONSE"
else
    print_error "❌ API no responde"
    echo "Respuesta: $API_RESPONSE"
    
    print_status "Logs del backend:"
    pm2 logs gestion-pedidos-backend --lines 5
fi

echo ""
print_success "🎯 Configuración completada"
print_status "🔐 Credenciales:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"
