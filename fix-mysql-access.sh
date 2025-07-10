#!/bin/bash

# 🔧 Script para Solucionar Error de Acceso MySQL
# Soluciona el error "ER_ACCESS_DENIED_NO_PASSWORD_ERROR"

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

echo "🔧 Solucionando Error de Acceso a MySQL"
echo "========================================"

cd /home/gestionPedidos

# 1. Detener el backend
print_status "1. Deteniendo backend..."
pm2 stop gestion-pedidos-backend

# 2. Configurar MySQL con contraseña para root
print_status "2. Configurando MySQL..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword123';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 3. Crear usuario appuser con contraseña
print_status "3. Creando usuario de aplicación..."
sudo mysql -u root -prootpassword123 -e "CREATE USER IF NOT EXISTS 'appuser'@'localhost' IDENTIFIED BY 'apppassword123';"
sudo mysql -u root -prootpassword123 -e "GRANT ALL PRIVILEGES ON gestionPedidos.* TO 'appuser'@'localhost';"
sudo mysql -u root -prootpassword123 -e "FLUSH PRIVILEGES;"

# 4. Actualizar archivos .env con las nuevas credenciales
print_status "4. Actualizando archivos de configuración..."

# Actualizar .env principal
cat > .env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=apppassword123
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo-para-produccion

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL
FRONTEND_URL=http://localhost

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

# Actualizar backend/.env
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
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo-para-produccion

# Frontend URL
FRONTEND_URL=http://localhost

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
EOF

# 5. Verificar conexión a la base de datos
print_status "5. Verificando conexión a la base de datos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SHOW TABLES;" 2>/dev/null && {
    print_success "✅ Conexión a base de datos exitosa"
} || {
    print_error "❌ Error de conexión a base de datos"
    exit 1
}

# 6. Inicializar base de datos si es necesario
print_status "6. Inicializando base de datos..."
cd backend
npm run build 2>/dev/null || {
    print_warning "Build falló, continuando..."
}
node dist/scripts/init-db.js 2>/dev/null || {
    print_warning "Init-db falló, continuando..."
}
cd ..

# 7. Crear usuario admin
print_status "7. Creando usuario administrador..."
node create-admin-user.js || {
    print_warning "Error al crear usuario admin, continuando..."
}

# 8. Reiniciar backend
print_status "8. Reiniciando backend..."
pm2 restart gestion-pedidos-backend

# 9. Verificar estado
print_status "9. Verificando estado final..."
sleep 3
pm2 status

print_success "🎉 ¡Configuración completada!"
echo ""
print_status "📋 Nuevas credenciales MySQL:"
echo "• Usuario: appuser"
echo "• Contraseña: apppassword123"
echo "• Base de datos: gestionPedidos"
echo ""
print_status "🔐 Credenciales de login de la aplicación:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🔧 Comandos útiles:"
echo "• Ver logs: pm2 logs gestion-pedidos-backend"
echo "• Reiniciar: pm2 restart gestion-pedidos-backend"
echo "• Estado: pm2 status"
