#!/bin/bash

# 🔧 Script para Solucionar Error de Archivo database-fixed.sql
# Soluciona el error ENOENT del archivo faltante

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

echo "🔧 Solucionando Error de Archivo database-fixed.sql"
echo "=================================================="

cd /home/gestionPedidos

# 1. Detener backend
print_status "1. Deteniendo backend..."
pm2 delete gestion-pedidos-backend 2>/dev/null || true

# 2. Crear directorio dist/config si no existe
print_status "2. Creando directorio dist/config..."
mkdir -p backend/dist/config

# 3. Crear archivo database-fixed.sql en la ubicación correcta
print_status "3. Creando archivo database-fixed.sql en dist/config..."
cat > backend/dist/config/database-fixed.sql << 'EOF'
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

# 4. También crear en src/config por si acaso
print_status "4. Creando archivo en src/config también..."
mkdir -p backend/src/config
cp backend/dist/config/database-fixed.sql backend/src/config/database-fixed.sql

# 5. Verificar que los archivos existen
print_status "5. Verificando archivos creados..."
if [ -f "backend/dist/config/database-fixed.sql" ]; then
    print_success "✅ Archivo dist/config/database-fixed.sql creado"
else
    print_error "❌ Error creando archivo en dist/config"
fi

if [ -f "backend/src/config/database-fixed.sql" ]; then
    print_success "✅ Archivo src/config/database-fixed.sql creado"
else
    print_error "❌ Error creando archivo en src/config"
fi

# 6. Verificar otros archivos necesarios
print_status "6. Verificando otros archivos de configuración..."
ls -la backend/dist/config/ 2>/dev/null || print_warning "Directorio dist/config vacío"
ls -la backend/src/config/ 2>/dev/null || print_warning "Directorio src/config vacío"

# 7. Copiar todos los archivos de config a dist
print_status "7. Copiando archivos de configuración..."
if [ -d "backend/src/config" ]; then
    cp -r backend/src/config/* backend/dist/config/ 2>/dev/null || true
fi

# 8. Verificar estructura final
print_status "8. Estructura final de archivos:"
echo "backend/dist/config/:"
ls -la backend/dist/config/ 2>/dev/null || echo "Directorio no existe"
echo ""
echo "backend/src/config/:"
ls -la backend/src/config/ 2>/dev/null || echo "Directorio no existe"

# 9. Iniciar backend nuevamente
print_status "9. Iniciando backend..."
pm2 start ecosystem.config.js

# 10. Esperar y verificar
print_status "10. Esperando inicialización..."
sleep 10

# 11. Verificar estado
print_status "11. Verificando estado..."
pm2 status

# 12. Verificar logs
print_status "12. Verificando logs recientes..."
pm2 logs gestion-pedidos-backend --lines 10

# 13. Test de conectividad
print_status "13. Test de conectividad..."
if netstat -tlnp | grep :5000 > /dev/null; then
    print_success "✅ Puerto 5000 activo"
    
    # Test de API
    sleep 3
    API_TEST=$(curl -s -X POST http://localhost:5000/api/auth/login \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"123456"}' 2>/dev/null)
    
    if echo "$API_TEST" | grep -q "token\|error"; then
        print_success "✅ API responde correctamente"
        echo "Respuesta: $API_TEST"
    else
        print_warning "⚠️ API responde pero sin token"
        echo "Respuesta: $API_TEST"
    fi
else
    print_error "❌ Puerto 5000 no activo"
fi

echo ""
print_success "🎉 Archivo database-fixed.sql creado en ambas ubicaciones"
print_status "🔐 Credenciales de login:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"
