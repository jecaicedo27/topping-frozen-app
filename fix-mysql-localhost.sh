#!/bin/bash

# 🔧 Script para Solucionar Conexión MySQL Localhost
# Configura MySQL para aceptar conexiones locales del backend

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

echo "🔧 Solucionando Conexión MySQL Localhost"
echo "========================================"

# 1. Detener backend
print_status "1. Deteniendo backend..."
pm2 stop gestion-pedidos-backend

# 2. Verificar configuración actual de MySQL
print_status "2. Verificando configuración actual de MySQL..."
mysql -e "SHOW VARIABLES LIKE 'bind_address';" 2>/dev/null || {
    print_error "No se puede conectar a MySQL como root"
    print_status "Intentando con usuario appuser..."
}

# 3. Verificar bind-address en archivo de configuración
print_status "3. Verificando bind-address en configuración..."
MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
if [ -f "$MYSQL_CONFIG" ]; then
    print_status "Configuración actual:"
    grep -n "bind-address" "$MYSQL_CONFIG" || echo "bind-address no encontrado"
    
    # Asegurar que bind-address sea 127.0.0.1
    print_status "Configurando bind-address a 127.0.0.1..."
    sudo sed -i '/bind-address/d' "$MYSQL_CONFIG"
    echo "bind-address = 127.0.0.1" | sudo tee -a "$MYSQL_CONFIG"
    
    print_success "bind-address configurado"
else
    print_warning "Archivo de configuración MySQL no encontrado"
fi

# 4. Verificar configuración de skip-networking
print_status "4. Verificando skip-networking..."
if grep -q "skip-networking" "$MYSQL_CONFIG" 2>/dev/null; then
    print_warning "skip-networking encontrado, comentando..."
    sudo sed -i 's/^skip-networking/#skip-networking/' "$MYSQL_CONFIG"
fi

# 5. Reiniciar MySQL
print_status "5. Reiniciando MySQL..."
sudo systemctl restart mysql
sleep 5

# 6. Verificar que MySQL esté corriendo
print_status "6. Verificando estado de MySQL..."
if systemctl is-active mysql > /dev/null; then
    print_success "✅ MySQL activo"
else
    print_error "❌ MySQL no está activo"
    sudo systemctl status mysql
    exit 1
fi

# 7. Verificar puertos de MySQL
print_status "7. Verificando puertos de MySQL..."
netstat -tlnp | grep :3306
if netstat -tlnp | grep "127.0.0.1:3306" > /dev/null; then
    print_success "✅ MySQL escuchando en localhost:3306"
elif netstat -tlnp | grep ":3306" > /dev/null; then
    print_warning "⚠️ MySQL escuchando en 3306 pero no en localhost"
else
    print_error "❌ MySQL no está escuchando en puerto 3306"
fi

# 8. Recrear usuario appuser con permisos específicos
print_status "8. Reconfigurando usuario appuser..."
mysql -e "
DROP USER IF EXISTS 'appuser'@'localhost';
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'apppassword123';
GRANT ALL PRIVILEGES ON gestionPedidos.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
" 2>/dev/null && print_success "Usuario appuser reconfigurado" || print_error "Error reconfigurando usuario"

# 9. Test de conexión desde línea de comandos
print_status "9. Test de conexión desde línea de comandos..."
mysql -u appuser -papppassword123 -h 127.0.0.1 -e "SELECT 1;" 2>/dev/null && {
    print_success "✅ Conexión exitosa con 127.0.0.1"
} || {
    print_error "❌ Error de conexión con 127.0.0.1"
}

mysql -u appuser -papppassword123 -h localhost -e "SELECT 1;" 2>/dev/null && {
    print_success "✅ Conexión exitosa con localhost"
} || {
    print_error "❌ Error de conexión con localhost"
}

# 10. Test de conexión desde Node.js
print_status "10. Test de conexión desde Node.js..."
cd /home/gestionPedidos/backend

# Test con diferentes configuraciones
node -e "
const mysql = require('mysql2/promise');

async function testConnections() {
    const configs = [
        { host: 'localhost', user: 'appuser', password: 'apppassword123', database: 'gestionPedidos' },
        { host: '127.0.0.1', user: 'appuser', password: 'apppassword123', database: 'gestionPedidos' },
        { host: 'localhost', port: 3306, user: 'appuser', password: 'apppassword123', database: 'gestionPedidos' }
    ];
    
    for (let i = 0; i < configs.length; i++) {
        try {
            console.log(\`Probando configuración \${i + 1}: \${configs[i].host}:\${configs[i].port || 3306}\`);
            const connection = await mysql.createConnection(configs[i]);
            await connection.execute('SELECT 1');
            console.log('✅ Conexión exitosa');
            await connection.end();
            break;
        } catch (error) {
            console.log('❌ Error:', error.code || error.message);
        }
    }
}

testConnections();
" 2>/dev/null

# 11. Actualizar archivo .env del backend con configuración específica
print_status "11. Actualizando configuración del backend..."
cat > .env << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=127.0.0.1
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

print_success "Archivo .env actualizado con DB_HOST=127.0.0.1"

# 12. Reiniciar backend
print_status "12. Reiniciando backend..."
cd /home/gestionPedidos
pm2 restart gestion-pedidos-backend
sleep 10

# 13. Verificar estado final
print_status "13. Verificando estado final..."
pm2 status

# 14. Test de API
print_status "14. Test de API de login..."
sleep 5
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "🎉 ¡API DE LOGIN FUNCIONANDO!"
    echo "Respuesta: $API_RESPONSE"
elif echo "$API_RESPONSE" | grep -q "Invalid\|incorrect"; then
    print_warning "⚠️ API responde pero credenciales incorrectas"
    echo "Respuesta: $API_RESPONSE"
else
    print_error "❌ API aún no responde correctamente"
    echo "Respuesta: $API_RESPONSE"
    
    print_status "Logs del backend:"
    pm2 logs gestion-pedidos-backend --lines 10
fi

echo ""
print_success "🎯 Configuración MySQL completada"
print_status "🔐 Credenciales de login:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"
echo ""
print_status "🔧 Si aún hay problemas:"
echo "• Verifica logs: pm2 logs gestion-pedidos-backend"
echo "• Reinicia MySQL: sudo systemctl restart mysql"
echo "• Reinicia backend: pm2 restart gestion-pedidos-backend"
