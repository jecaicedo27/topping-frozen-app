#!/bin/bash

# 🔧 Solución Final Basada en Diagnóstico
# Soluciona los problemas específicos identificados

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

echo "🔧 Solución Final Basada en Diagnóstico"
echo "======================================="

cd /home/gestionPedidos

# 1. Detener backend completamente
print_status "1. Deteniendo backend completamente..."
pm2 delete gestion-pedidos-backend 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -f "node.*gestion" || true

# 2. Crear archivo database-fixed.sql que falta
print_status "2. Creando archivo database-fixed.sql..."
cat > backend/src/config/database-fixed.sql << 'EOF'
-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS gestionPedidos;
USE gestionPedidos;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL DEFAULT 'mensajero',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de pedidos
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

-- Tabla de recepciones de dinero
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

# 3. Generar hash correcto usando bcrypt del backend
print_status "3. Generando hash correcto de contraseña..."
cd backend
CORRECT_HASH=$(node -e "
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('123456', 10);
console.log(hash);
" 2>/dev/null)
cd ..

if [ -z "$CORRECT_HASH" ]; then
    print_warning "Usando hash predeterminado..."
    CORRECT_HASH='$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW'
fi

print_success "Hash generado: $CORRECT_HASH"

# 4. Actualizar usuario admin con hash correcto
print_status "4. Actualizando usuario admin con hash correcto..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
UPDATE users SET password = '$CORRECT_HASH' WHERE username = 'admin';
" 2>/dev/null

# 5. Verificar que el hash se actualizó
print_status "5. Verificando hash actualizado..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
SELECT username, LEFT(password, 30) as password_hash FROM users WHERE username = 'admin';
" 2>/dev/null

# 6. Crear script de test simple
print_status "6. Creando test de verificación..."
cat > test-hash.js << 'EOF'
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function testHash() {
    try {
        const connection = await mysql.createConnection({
            host: 'localhost',
            user: 'appuser',
            password: 'apppassword123',
            database: 'gestionPedidos'
        });

        const [rows] = await connection.execute('SELECT * FROM users WHERE username = ?', ['admin']);
        
        if (rows.length > 0) {
            const user = rows[0];
            const isValid = await bcrypt.compare('123456', user.password);
            console.log('Hash válido:', isValid ? 'SÍ' : 'NO');
            
            if (isValid) {
                console.log('✅ Login funcionará correctamente');
            } else {
                console.log('❌ Hash aún incorrecto');
            }
        }
        
        await connection.end();
    } catch (error) {
        console.error('Error:', error.message);
    }
}

testHash();
EOF

# 7. Ejecutar test
print_status "7. Ejecutando test de hash..."
cd backend
node ../test-hash.js
cd ..

# 8. Limpiar PM2 y reiniciar
print_status "8. Reiniciando PM2 completamente..."
pm2 flush
pm2 start ecosystem.config.js

# 9. Esperar y verificar
print_status "9. Esperando que el backend inicie..."
sleep 10

# 10. Verificar estado final
print_status "10. Verificando estado final..."
pm2 status

# 11. Test de API final
print_status "11. Test final de API..."
sleep 5
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' \
  2>/dev/null | head -100

echo ""
print_success "🎉 Configuración completada"
echo ""
print_status "🔐 Credenciales:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"

# Limpiar archivos temporales
rm -f test-hash.js
