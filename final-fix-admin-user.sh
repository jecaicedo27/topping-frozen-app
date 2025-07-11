#!/bin/bash

# 🔧 Script Final para Crear Usuario Admin
# Soluciona el problema persistente de login

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

echo "🔧 Creación Final del Usuario Admin"
echo "===================================="

cd /home/gestionPedidos

# 1. Verificar conexión a la base de datos
print_status "1. Verificando conexión a la base de datos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT 1;" 2>/dev/null || {
    print_error "Error de conexión a la base de datos"
    exit 1
}
print_success "Conexión a base de datos OK"

# 2. Eliminar usuario admin existente si existe
print_status "2. Limpiando usuario admin existente..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; DELETE FROM users WHERE username='admin';" 2>/dev/null

# 3. Crear usuario admin directamente en la base de datos
print_status "3. Creando usuario admin directamente..."

# Hash de la contraseña "123456" usando bcrypt
ADMIN_PASSWORD_HASH='$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT INTO users (username, password, role, created_at, updated_at) 
VALUES ('admin', '$ADMIN_PASSWORD_HASH', 'admin', NOW(), NOW())
ON DUPLICATE KEY UPDATE 
password = '$ADMIN_PASSWORD_HASH', 
role = 'admin', 
updated_at = NOW();
" 2>/dev/null

# 4. Verificar que el usuario se creó correctamente
print_status "4. Verificando usuario admin..."
ADMIN_EXISTS=$(mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null | tail -1)

if [ "$ADMIN_EXISTS" = "1" ]; then
    print_success "✅ Usuario admin creado correctamente"
else
    print_error "❌ Error al crear usuario admin"
    exit 1
fi

# 5. Mostrar información del usuario
print_status "5. Información del usuario admin:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT id, username, role, created_at FROM users WHERE username='admin';" 2>/dev/null

# 6. Reiniciar backend para asegurar que tome los cambios
print_status "6. Reiniciando backend..."
pm2 restart gestion-pedidos-backend
sleep 3

# 7. Verificar estado del backend
print_status "7. Verificando estado del backend..."
pm2 status

# 8. Verificar logs del backend
print_status "8. Últimos logs del backend..."
pm2 logs gestion-pedidos-backend --lines 5

print_success "🎉 ¡Usuario admin configurado correctamente!"
echo ""
print_status "🔐 Credenciales de login:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL de la aplicación:"
echo "• http://$(curl -s ifconfig.me)"
echo ""
print_status "🔧 Si aún hay problemas:"
echo "• Ver logs: pm2 logs gestion-pedidos-backend"
echo "• Reiniciar: pm2 restart gestion-pedidos-backend"
echo "• Verificar BD: mysql -u appuser -papppassword123 -e 'USE gestionPedidos; SELECT * FROM users;'"
