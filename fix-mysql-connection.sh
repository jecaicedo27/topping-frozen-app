#!/bin/bash

# 🔧 Script para Solucionar Conexión MySQL IPv6 -> IPv4
# Ejecutar como: bash fix-mysql-connection.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✅ OK]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[🔧 STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

echo "🔧 Solucionando problema de conexión MySQL IPv6..."
echo "=================================================="

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

print_step "1. Configurando MySQL para usar IPv4..."

# Configurar MySQL para usar solo IPv4
sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf > /dev/null << 'EOF'
[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
log-error       = /var/log/mysql/error.log
bind-address    = 127.0.0.1
mysqlx-bind-address = 127.0.0.1
skip-networking = false
port = 3306
EOF

print_step "2. Reiniciando MySQL..."
sudo systemctl restart mysql
sleep 3

print_step "3. Creando archivo .env con configuración IPv4..."
cat > $APP_DIR/backend/.env << 'EOF'
DB_HOST=127.0.0.1
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-vps-2024-ipv4-fix
NODE_ENV=development
PORT=3001
FRONTEND_URL=http://localhost
EOF

print_step "4. Probando conexión con IPv4..."
if mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT 1;" &>/dev/null; then
    print_status "Conexión IPv4 exitosa"
else
    print_error "Conexión IPv4 falló"
    exit 1
fi

print_step "5. Probando conexión desde Node.js..."
cd $APP_DIR/backend
if node -e "
require('dotenv').config();
const mysql = require('mysql2/promise');
mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
}).then(() => {
  console.log('✅ Conexión Node.js exitosa con IPv4');
  process.exit(0);
}).catch(err => {
  console.log('❌ Error:', err.message);
  process.exit(1);
});
"; then
    print_status "Conexión desde Node.js exitosa"
else
    print_error "Error de conexión desde Node.js"
    exit 1
fi

print_step "6. Limpiando procesos PM2..."
pm2 stop all &>/dev/null || true
pm2 delete all &>/dev/null || true

echo ""
echo "🎉 PROBLEMA SOLUCIONADO"
echo "======================="
echo ""
echo "✅ MySQL configurado para IPv4"
echo "✅ Archivo .env actualizado"
echo "✅ Conexión desde Node.js funcionando"
echo ""
echo "🚀 COMANDOS PARA INICIAR:"
echo ""
echo "   Backend (Manual):"
echo "   cd $APP_DIR/backend && npm run dev"
echo ""
echo "   Backend (PM2):"
echo "   cd $APP_DIR && pm2 start ecosystem.config.js"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://$(curl -s ifconfig.me 2>/dev/null || echo 'TU_IP_DEL_VPS')"
echo "   Credenciales: admin / 123456"
echo ""
print_status "¡Ahora el login debería funcionar correctamente! 🚀"
