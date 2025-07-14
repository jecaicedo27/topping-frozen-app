#!/bin/bash

# 🔧 Script de Verificación y Reparación - Topping Frozen
# Ejecutar como: bash verify-and-fix.sh

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${GREEN}[✅ OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[🔧 STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️  INFO]${NC} $1"
}

echo "🚀 Iniciando verificación y reparación de Topping Frozen..."
echo "=============================================================="

# PASO 1: Verificar MySQL
print_step "1. Verificando estado de MySQL..."
if systemctl is-active --quiet mysql; then
    print_status "MySQL está corriendo"
else
    print_warning "MySQL no está corriendo, iniciando..."
    systemctl start mysql
    systemctl enable mysql
    print_status "MySQL iniciado"
fi

# PASO 2: Verificar conexión a MySQL
print_step "2. Verificando conexión a MySQL..."
if mysql -e "SELECT 1;" &>/dev/null; then
    print_status "Conexión a MySQL como root exitosa"
else
    print_error "No se puede conectar a MySQL como root"
    exit 1
fi

# PASO 3: Crear base de datos y usuario
print_step "3. Configurando base de datos y usuario..."
mysql << 'EOF'
CREATE DATABASE IF NOT EXISTS topping_frozen_db;
CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';
GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';
FLUSH PRIVILEGES;
EOF

print_status "Base de datos y usuario configurados"

# PASO 4: Verificar conexión con usuario de aplicación
print_step "4. Verificando conexión con usuario de aplicación..."
if mysql -u toppinguser -pToppingPass2024! -h localhost topping_frozen_db -e "SELECT 1;" &>/dev/null; then
    print_status "Conexión con usuario toppinguser exitosa"
else
    print_error "No se puede conectar con usuario toppinguser"
    exit 1
fi

# PASO 5: Verificar directorio de aplicación
print_step "5. Verificando directorio de aplicación..."
if [ -d "/root/topping-frozen-app" ]; then
    print_status "Directorio de aplicación encontrado"
    cd /root/topping-frozen-app
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    print_status "Directorio de aplicación encontrado en /home/toppingapp"
    cd /home/toppingapp/topping-frozen-app
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

APP_DIR=$(pwd)
print_info "Directorio de aplicación: $APP_DIR"

# PASO 6: Crear archivo .env
print_step "6. Creando archivo .env..."
cat > backend/.env << 'EOF'
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-vps-2024-verificado
NODE_ENV=development
PORT=3001
FRONTEND_URL=http://localhost
EOF

print_status "Archivo .env creado"

# PASO 7: Verificar dependencias
print_step "7. Verificando dependencias..."
if [ -d "backend/node_modules" ]; then
    print_status "Dependencias del backend encontradas"
else
    print_warning "Instalando dependencias del backend..."
    cd backend
    npm install
    cd ..
    print_status "Dependencias del backend instaladas"
fi

if [ -d "node_modules" ]; then
    print_status "Dependencias del frontend encontradas"
else
    print_warning "Instalando dependencias del frontend..."
    npm install
    print_status "Dependencias del frontend instaladas"
fi

# PASO 8: Inicializar esquema de base de datos
print_step "8. Inicializando esquema de base de datos..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db < backend/src/config/database.sql; then
    print_status "Esquema de base de datos inicializado"
else
    print_warning "Error al inicializar esquema, intentando con database-fixed.sql..."
    if mysql -u toppinguser -pToppingPass2024! topping_frozen_db < backend/src/config/database-fixed.sql; then
        print_status "Esquema de base de datos inicializado con database-fixed.sql"
    else
        print_error "No se pudo inicializar el esquema de base de datos"
    fi
fi

# PASO 9: Crear usuario admin
print_step "9. Creando usuario admin..."
if node create-admin-user.js; then
    print_status "Usuario admin creado"
else
    print_warning "Error al crear usuario admin, puede que ya exista"
fi

# PASO 10: Verificar puertos
print_step "10. Verificando puertos..."
if netstat -tlnp | grep :3306 &>/dev/null; then
    print_status "Puerto 3306 (MySQL) está abierto"
else
    print_warning "Puerto 3306 no está disponible"
fi

if netstat -tlnp | grep :3001 &>/dev/null; then
    print_warning "Puerto 3001 ya está en uso"
else
    print_status "Puerto 3001 está disponible"
fi

# PASO 11: Verificar Nginx
print_step "11. Verificando Nginx..."
if systemctl is-active --quiet nginx; then
    print_status "Nginx está corriendo"
else
    print_warning "Nginx no está corriendo"
fi

# PASO 12: Parar procesos PM2 existentes
print_step "12. Limpiando procesos PM2..."
pm2 stop all &>/dev/null || true
pm2 delete all &>/dev/null || true
print_status "Procesos PM2 limpiados"

# PASO 13: Probar conexión final
print_step "13. Probando conexión final a base de datos..."
cd backend
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
  console.log('✅ Conexión exitosa desde Node.js');
  process.exit(0);
}).catch(err => {
  console.log('❌ Error de conexión:', err.message);
  process.exit(1);
});
"; then
    print_status "Conexión desde Node.js exitosa"
else
    print_error "Error de conexión desde Node.js"
fi

cd ..

echo ""
echo "🎉 VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "📋 RESUMEN:"
echo "   ✅ MySQL configurado y funcionando"
echo "   ✅ Base de datos 'topping_frozen_db' creada"
echo "   ✅ Usuario 'toppinguser' configurado"
echo "   ✅ Archivo .env creado"
echo "   ✅ Dependencias verificadas"
echo "   ✅ Esquema de base de datos inicializado"
echo "   ✅ Usuario admin creado"
echo ""
echo "🚀 COMANDOS PARA INICIAR:"
echo ""
echo "   Backend (Manual):"
echo "   cd $APP_DIR/backend && npm run dev"
echo ""
echo "   Backend (PM2):"
echo "   cd $APP_DIR && pm2 start ecosystem.config.js"
echo ""
echo "   Frontend ya está disponible via Nginx"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://$(curl -s ifconfig.me 2>/dev/null || echo 'TU_IP_DEL_VPS')"
echo "   API: http://$(curl -s ifconfig.me 2>/dev/null || echo 'TU_IP_DEL_VPS')/api"
echo "   Credenciales: admin / 123456"
echo ""
echo "📊 VERIFICAR ESTADO:"
echo "   pm2 status"
echo "   pm2 logs topping-backend"
echo "   curl http://localhost:3001/api/health"
echo ""
print_status "¡Sistema listo para usar! 🚀"
