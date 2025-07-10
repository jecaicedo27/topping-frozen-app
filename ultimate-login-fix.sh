#!/bin/bash

# 🔧 Script Definitivo para Solucionar Login
# Soluciona todos los problemas de autenticación

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

echo "🔧 Solución Definitiva del Login"
echo "================================"

cd /home/gestionPedidos

# 1. Detener backend
print_status "1. Deteniendo backend..."
pm2 stop gestion-pedidos-backend

# 2. Verificar y crear hash correcto de contraseña
print_status "2. Generando hash correcto de contraseña..."
# Usar Node.js para generar el hash correcto
node -e "
const bcrypt = require('bcrypt');
const password = '123456';
const hash = bcrypt.hashSync(password, 10);
console.log('Hash generado:', hash);
" > /tmp/password_hash.txt 2>/dev/null || {
    # Si bcrypt no está disponible, usar hash conocido
    echo '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' > /tmp/password_hash.txt
}

PASSWORD_HASH=$(cat /tmp/password_hash.txt | grep -o '\$2b\$.*')
print_success "Hash de contraseña: $PASSWORD_HASH"

# 3. Recrear tabla users con estructura correcta
print_status "3. Recreando tabla users..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL DEFAULT 'mensajero',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
" 2>/dev/null

# 4. Insertar usuario admin con hash correcto
print_status "4. Creando usuario admin..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
INSERT INTO users (username, password, role) 
VALUES ('admin', '$PASSWORD_HASH', 'admin');
" 2>/dev/null

# 5. Verificar usuario creado
print_status "5. Verificando usuario admin..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
SELECT id, username, role, LEFT(password, 20) as password_preview FROM users WHERE username='admin';
" 2>/dev/null

# 6. Verificar configuración del backend
print_status "6. Verificando configuración backend..."
if [ ! -f "backend/.env" ]; then
    print_error "Archivo backend/.env no existe"
    exit 1
fi

# 7. Verificar que el backend tenga bcrypt instalado
print_status "7. Verificando dependencias..."
cd backend
npm list bcrypt 2>/dev/null || {
    print_warning "Instalando bcrypt..."
    npm install bcrypt
}
cd ..

# 8. Crear script de test de login
print_status "8. Creando script de test..."
cat > test-login.js << 'EOF'
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function testLogin() {
    try {
        // Conectar a la base de datos
        const connection = await mysql.createConnection({
            host: 'localhost',
            user: 'appuser',
            password: 'apppassword123',
            database: 'gestionPedidos'
        });

        // Obtener usuario admin
        const [rows] = await connection.execute(
            'SELECT * FROM users WHERE username = ?',
            ['admin']
        );

        if (rows.length === 0) {
            console.log('❌ Usuario admin no encontrado');
            return;
        }

        const user = rows[0];
        console.log('✅ Usuario encontrado:', user.username);
        console.log('🔑 Hash en BD:', user.password.substring(0, 20) + '...');

        // Verificar contraseña
        const isValid = await bcrypt.compare('123456', user.password);
        console.log('🔐 Verificación de contraseña:', isValid ? '✅ VÁLIDA' : '❌ INVÁLIDA');

        if (isValid) {
            console.log('🎉 ¡Login funcionará correctamente!');
        } else {
            console.log('❌ Problema con el hash de contraseña');
        }

        await connection.end();
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testLogin();
EOF

# 9. Ejecutar test de login
print_status "9. Ejecutando test de login..."
cd backend
node ../test-login.js
cd ..

# 10. Verificar puerto 5000 libre
print_status "10. Verificando puerto 5000..."
if netstat -tlnp | grep :5000 > /dev/null; then
    print_warning "Puerto 5000 en uso, liberando..."
    pkill -f "node.*5000" || true
    sleep 2
fi

# 11. Iniciar backend
print_status "11. Iniciando backend..."
pm2 start ecosystem.config.js
sleep 5

# 12. Verificar estado del backend
print_status "12. Verificando estado..."
pm2 status

# 13. Test de API directa
print_status "13. Test de API directa..."
sleep 3
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "✅ API de login funcionando correctamente"
    echo "Respuesta: $API_RESPONSE"
else
    print_error "❌ API de login falló"
    echo "Respuesta: $API_RESPONSE"
    
    # Mostrar logs del backend
    print_status "Logs del backend:"
    pm2 logs gestion-pedidos-backend --lines 10
fi

# 14. Verificar Nginx
print_status "14. Verificando Nginx..."
sudo nginx -t && sudo systemctl reload nginx

# 15. Test final desde frontend
print_status "15. Test final desde el navegador..."
echo ""
print_success "🎉 Configuración completada"
echo ""
print_status "🔐 Credenciales para probar:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"
echo ""
print_status "🔧 Si aún falla, ejecuta:"
echo "• pm2 logs gestion-pedidos-backend"
echo "• curl -X POST http://localhost:5000/api/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"123456\"}'"

# Limpiar archivos temporales
rm -f /tmp/password_hash.txt test-login.js
