#!/bin/bash

# 🔧 Script para Crear Tablas y Usuario Admin
# Soluciona problemas de estructura de base de datos

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

echo "🔧 Creando Tablas y Usuario Admin"
echo "=================================="

cd /home/gestionPedidos

# 1. Verificar conexión a la base de datos
print_status "1. Verificando conexión a la base de datos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT 1;" 2>/dev/null || {
    print_error "Error de conexión a la base de datos"
    exit 1
}
print_success "Conexión a base de datos OK"

# 2. Crear tabla users si no existe
print_status "2. Creando tabla users..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL DEFAULT 'mensajero',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
" 2>/dev/null

print_success "Tabla users creada/verificada"

# 3. Crear tabla orders si no existe
print_status "3. Creando tabla orders..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
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
" 2>/dev/null

print_success "Tabla orders creada/verificada"

# 4. Crear tabla money_receipts si no existe
print_status "4. Creando tabla money_receipts..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
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
" 2>/dev/null

print_success "Tabla money_receipts creada/verificada"

# 5. Verificar que las tablas existen
print_status "5. Verificando tablas creadas..."
TABLES=$(mysql -u appuser -papppassword123 -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null | grep -v "Tables_in")
echo "Tablas encontradas:"
echo "$TABLES"

# 6. Eliminar usuario admin existente si existe
print_status "6. Limpiando usuario admin existente..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; DELETE FROM users WHERE username='admin';" 2>/dev/null

# 7. Crear usuario admin
print_status "7. Creando usuario admin..."

# Hash de la contraseña "123456" usando bcrypt
ADMIN_PASSWORD_HASH='$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT INTO users (username, password, role, created_at, updated_at) 
VALUES ('admin', '$ADMIN_PASSWORD_HASH', 'admin', NOW(), NOW());
" 2>/dev/null

# 8. Verificar que el usuario se creó correctamente
print_status "8. Verificando usuario admin..."
ADMIN_EXISTS=$(mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null | tail -1)

if [ "$ADMIN_EXISTS" = "1" ]; then
    print_success "✅ Usuario admin creado correctamente"
else
    print_error "❌ Error al crear usuario admin"
    
    # Mostrar estructura de la tabla para debug
    print_status "Estructura de la tabla users:"
    mysql -u appuser -papppassword123 -e "USE gestionPedidos; DESCRIBE users;" 2>/dev/null
    exit 1
fi

# 9. Mostrar información del usuario
print_status "9. Información del usuario admin:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT id, username, role, created_at FROM users WHERE username='admin';" 2>/dev/null

# 10. Crear algunos usuarios de prueba
print_status "10. Creando usuarios de prueba..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT IGNORE INTO users (username, password, role) VALUES 
('facturacion', '$ADMIN_PASSWORD_HASH', 'facturacion'),
('cartera', '$ADMIN_PASSWORD_HASH', 'cartera'),
('logistica', '$ADMIN_PASSWORD_HASH', 'logistica'),
('mensajero', '$ADMIN_PASSWORD_HASH', 'mensajero');
" 2>/dev/null

# 11. Reiniciar backend
print_status "11. Reiniciando backend..."
pm2 restart gestion-pedidos-backend
sleep 3

# 12. Verificar estado del backend
print_status "12. Verificando estado del backend..."
pm2 status

print_success "🎉 ¡Base de datos y usuario admin configurados correctamente!"
echo ""
print_status "🔐 Credenciales de login:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "👥 Usuarios de prueba creados:"
echo "• facturacion / 123456"
echo "• cartera / 123456"
echo "• logistica / 123456"
echo "• mensajero / 123456"
echo ""
print_status "🌐 URL de la aplicación:"
echo "• http://$(curl -s ifconfig.me)"
