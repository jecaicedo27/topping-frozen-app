#!/bin/bash

# Script para completar la configuración de la base de datos
echo "📊 Completando configuración de la base de datos..."

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

# Verificar conexión a base de datos
if ! mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_error "No se puede conectar a la base de datos"
    exit 1
fi

print_status "Conexión a base de datos verificada"

# 1. Crear todas las tablas necesarias
print_status "1. Creando todas las tablas necesarias..."

mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
-- Tabla de pedidos
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

-- Tabla de recibos de dinero
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

print_status "Tablas creadas correctamente"

# 2. Insertar todos los usuarios necesarios
print_status "2. Insertando todos los usuarios del sistema..."

mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
INSERT IGNORE INTO users (username, password, role, email, full_name) VALUES
('facturacion', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'facturacion', 'facturacion@toppingfrozen.com', 'Usuario Facturación'),
('cartera', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cartera', 'cartera@toppingfrozen.com', 'Usuario Cartera'),
('logistica', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'logistica', 'logistica@toppingfrozen.com', 'Usuario Logística'),
('mensajero', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mensajero', 'mensajero@toppingfrozen.com', 'Usuario Mensajero');
EOF

print_status "Usuarios adicionales insertados"

# 3. Insertar datos de ejemplo
print_status "3. Insertando datos de ejemplo..."

mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
-- Insertar algunos pedidos de ejemplo
INSERT IGNORE INTO orders (order_number, customer_name, customer_phone, customer_address, items, total_amount, status, payment_status, delivery_date, created_by) VALUES
('ORD-001', 'María García', '3001234567', 'Calle 123 #45-67, Bogotá', '{"items": [{"name": "Helado Vainilla", "quantity": 2, "price": 15000}, {"name": "Helado Chocolate", "quantity": 1, "price": 15000}]}', 45000.00, 'pending', 'pending', CURDATE(), 1),
('ORD-002', 'Carlos López', '3007654321', 'Carrera 45 #12-34, Medellín', '{"items": [{"name": "Helado Fresa", "quantity": 3, "price": 15000}]}', 45000.00, 'confirmed', 'paid', CURDATE(), 1),
('ORD-003', 'Ana Rodríguez', '3009876543', 'Avenida 68 #23-45, Cali', '{"items": [{"name": "Helado Mango", "quantity": 1, "price": 15000}, {"name": "Helado Coco", "quantity": 2, "price": 15000}]}', 45000.00, 'in_preparation', 'partial', CURDATE(), 1),
('ORD-004', 'Luis Martínez', '3005555555', 'Calle 50 #30-20, Barranquilla', '{"items": [{"name": "Helado Chocolate", "quantity": 4, "price": 15000}]}', 60000.00, 'ready', 'paid', CURDATE(), 1),
('ORD-005', 'Carmen Silva', '3008888888', 'Carrera 15 #25-10, Bucaramanga', '{"items": [{"name": "Helado Vainilla", "quantity": 1, "price": 15000}, {"name": "Helado Fresa", "quantity": 1, "price": 15000}]}', 30000.00, 'delivered', 'paid', CURDATE(), 1);

-- Insertar algunos recibos de ejemplo
INSERT IGNORE INTO money_receipts (receipt_number, order_id, amount, payment_method, reference_number, description, status, created_by) VALUES
('REC-001', 2, 45000.00, 'transfer', 'TRF123456789', 'Pago completo pedido ORD-002', 'verified', 1),
('REC-002', 3, 22500.00, 'cash', '', 'Pago parcial pedido ORD-003', 'pending', 1),
('REC-003', 4, 60000.00, 'card', 'CARD987654321', 'Pago completo pedido ORD-004', 'verified', 1),
('REC-004', 5, 30000.00, 'transfer', 'TRF555666777', 'Pago completo pedido ORD-005', 'verified', 1);
EOF

print_status "Datos de ejemplo insertados"

# 4. Verificar el contenido de la base de datos
print_status "4. Verificando contenido de la base de datos..."

echo ""
print_info "Usuarios en el sistema:"
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT id, username, role, full_name, is_active FROM users;" 2>/dev/null

echo ""
print_info "Pedidos en el sistema:"
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT id, order_number, customer_name, status, payment_status, total_amount FROM orders;" 2>/dev/null

echo ""
print_info "Recibos en el sistema:"
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT id, receipt_number, amount, payment_method, status FROM money_receipts;" 2>/dev/null

# 5. Crear directorio de uploads si no existe
print_status "5. Configurando directorio de uploads..."
cd /var/www/topping-frozen-app
mkdir -p backend/uploads/receipts
chown -R www-data:www-data backend/uploads
chmod -R 755 backend/uploads

# 6. Reiniciar backend para que reconozca los nuevos datos
print_status "6. Reiniciando backend..."
pm2 restart topping-frozen-backend
sleep 3

# 7. Verificación final
print_status "7. Verificación final..."
echo ""

# Contar registros
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
ORDER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM orders;" 2>/dev/null)
RECEIPT_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM money_receipts;" 2>/dev/null)

print_info "Resumen de la base de datos:"
echo "   👤 Usuarios: $USER_COUNT"
echo "   📦 Pedidos: $ORDER_COUNT"
echo "   💰 Recibos: $RECEIPT_COUNT"

# Verificar que el backend siga funcionando
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if echo "$HEALTH_CHECK" | grep -q "success\|running"; then
    print_status "Backend funcionando correctamente"
else
    print_warning "Backend puede tener problemas"
fi

echo ""
echo "🎉 BASE DE DATOS COMPLETADA"
echo "=================================================="
echo ""
echo "✅ Tablas creadas: users, orders, money_receipts"
echo "✅ Usuarios: 5 usuarios con diferentes roles"
echo "✅ Datos de ejemplo: 5 pedidos y 4 recibos"
echo "✅ Directorio de uploads configurado"
echo ""
echo "🔐 Usuarios disponibles (contraseña: 123456):"
echo "   • admin - Administrador"
echo "   • facturacion - Facturación"
echo "   • cartera - Cartera"
echo "   • logistica - Logística"
echo "   • mensajero - Mensajero"
echo ""
echo "🌐 Sistema listo en: http://$(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
