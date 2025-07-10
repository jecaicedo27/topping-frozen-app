#!/bin/bash

# 🔧 Script para Crear Tablas Faltantes en la Base de Datos
# Completa la estructura de la base de datos gestionPedidos

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

echo "🔧 Creando Tablas Faltantes en la Base de Datos"
echo "==============================================="

# 1. Verificar conexión a MySQL
print_status "1. Verificando conexión a MySQL..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT 1;" 2>/dev/null || {
    print_error "Error de conexión a MySQL"
    exit 1
}
print_success "Conexión a MySQL exitosa"

# 2. Mostrar tablas existentes
print_status "2. Tablas existentes actualmente:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null

# 3. Crear tabla orders
print_status "3. Creando tabla 'orders'..."
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
" 2>/dev/null && print_success "✅ Tabla 'orders' creada" || print_error "❌ Error creando tabla 'orders'"

# 4. Crear tabla money_receipts
print_status "4. Creando tabla 'money_receipts'..."
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
" 2>/dev/null && print_success "✅ Tabla 'money_receipts' creada" || print_error "❌ Error creando tabla 'money_receipts'"

# 5. Crear tabla companies (opcional para configuración de empresa)
print_status "5. Creando tabla 'companies'..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
CREATE TABLE IF NOT EXISTS companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    logo_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
" 2>/dev/null && print_success "✅ Tabla 'companies' creada" || print_error "❌ Error creando tabla 'companies'"

# 6. Insertar datos de ejemplo en companies
print_status "6. Insertando datos de ejemplo en 'companies'..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT INTO companies (name, address, phone, email) VALUES 
('TOPPING FROZEN', 'Dirección de la empresa', '123-456-7890', 'info@toppingfrozen.com')
ON DUPLICATE KEY UPDATE name = 'TOPPING FROZEN';
" 2>/dev/null && print_success "✅ Datos de empresa insertados" || print_warning "⚠️ Error insertando datos de empresa"

# 7. Crear usuarios adicionales de ejemplo
print_status "7. Creando usuarios adicionales..."

# Generar hash para contraseña "123456"
cd /home/gestionPedidos/backend 2>/dev/null || cd /home/gestionPedidos
HASH_123456=$(node -e "
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('123456', 10);
console.log(hash);
" 2>/dev/null)

if [ -n "$HASH_123456" ]; then
    mysql -u appuser -papppassword123 -e "
    USE gestionPedidos;
    INSERT IGNORE INTO users (username, password, role) VALUES 
    ('facturacion', '$HASH_123456', 'facturacion'),
    ('cartera', '$HASH_123456', 'cartera'),
    ('logistica', '$HASH_123456', 'logistica'),
    ('mensajero1', '$HASH_123456', 'mensajero'),
    ('mensajero2', '$HASH_123456', 'mensajero');
    " 2>/dev/null && print_success "✅ Usuarios adicionales creados" || print_warning "⚠️ Error creando usuarios adicionales"
else
    print_warning "⚠️ No se pudo generar hash para usuarios adicionales"
fi

# 8. Insertar pedidos de ejemplo
print_status "8. Insertando pedidos de ejemplo..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT IGNORE INTO orders (customer_name, customer_phone, customer_address, items, total_amount, status, payment_status, created_by) VALUES 
('Juan Pérez', '300-123-4567', 'Calle 123 #45-67, Bogotá', 'Helado de vainilla x2, Helado de chocolate x1', 25000.00, 'pendiente', 'pendiente', 1),
('María García', '301-234-5678', 'Carrera 45 #12-34, Medellín', 'Helado de fresa x3, Cono de waffle x3', 35000.00, 'en_proceso', 'pagado', 1),
('Carlos López', '302-345-6789', 'Avenida 68 #23-45, Cali', 'Sundae especial x1, Malteada x2', 42000.00, 'enviado', 'pagado', 1),
('Ana Rodríguez', '303-456-7890', 'Calle 50 #34-56, Barranquilla', 'Helado de mango x2, Paleta de frutas x4', 28000.00, 'entregado', 'pagado', 1);
" 2>/dev/null && print_success "✅ Pedidos de ejemplo insertados" || print_warning "⚠️ Error insertando pedidos de ejemplo"

# 9. Insertar recepciones de dinero de ejemplo
print_status "9. Insertando recepciones de dinero de ejemplo..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT IGNORE INTO money_receipts (order_id, amount, receipt_type, notes, received_by) VALUES 
(2, 35000.00, 'efectivo', 'Pago completo en efectivo', 1),
(3, 42000.00, 'transferencia', 'Transferencia bancaria', 1),
(4, 28000.00, 'efectivo', 'Pago al momento de la entrega', 1);
" 2>/dev/null && print_success "✅ Recepciones de dinero insertadas" || print_warning "⚠️ Error insertando recepciones"

# 10. Mostrar resumen final
print_status "10. Resumen final de la base de datos:"
echo ""
print_status "Tablas creadas:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null

echo ""
print_status "Usuarios en el sistema:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT id, username, role FROM users;" 2>/dev/null

echo ""
print_status "Pedidos de ejemplo:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT id, customer_name, total_amount, status FROM orders;" 2>/dev/null

echo ""
print_status "Recepciones de dinero:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT id, order_id, amount, receipt_type FROM money_receipts;" 2>/dev/null

echo ""
print_success "🎉 ¡Base de datos completada exitosamente!"
echo ""
print_status "📋 Información de acceso:"
echo "• phpMyAdmin: http://$(curl -s ifconfig.me):8080"
echo "• Usuario BD: appuser"
echo "• Contraseña BD: apppassword123"
echo ""
print_status "👥 Usuarios de la aplicación (todos con contraseña: 123456):"
echo "• admin (Administrador)"
echo "• facturacion (Facturación)"
echo "• cartera (Cartera)"
echo "• logistica (Logística)"
echo "• mensajero1 (Mensajero)"
echo "• mensajero2 (Mensajero)"
echo ""
print_status "🔧 Ahora ejecuta el script de conexión del backend:"
echo "wget https://raw.githubusercontent.com/jecaicedo27/gestionPedidos/main/fix-database-connection.sh"
echo "chmod +x fix-database-connection.sh"
echo "./fix-database-connection.sh"
