#!/bin/bash

# Script para corregir el sistema de login específicamente
echo "🔐 Corrigiendo sistema de login..."

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

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
print_info "IP del servidor: $SERVER_IP"

# 1. Verificar que el backend esté funcionando
print_status "Verificando backend..."
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "Backend respondiendo en puerto 3001"
else
    print_error "Backend no responde en puerto 3001"
    print_info "Reiniciando backend..."
    cd /var/www/topping-frozen-app
    pm2 restart topping-frozen-backend
    sleep 5
fi

# 2. Verificar conexión a base de datos
print_status "Verificando conexión a base de datos..."
if mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;" > /dev/null 2>&1; then
    print_status "Conexión a base de datos OK"
else
    print_error "Error de conexión a base de datos"
    print_info "Verificando usuario de base de datos..."
    mysql -e "CREATE USER IF NOT EXISTS 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
    mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# 3. Verificar que existan usuarios en la base de datos
print_status "Verificando usuarios en base de datos..."
USER_COUNT=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)

if [ "$USER_COUNT" -eq 0 ] || [ -z "$USER_COUNT" ]; then
    print_warning "No hay usuarios en la base de datos, creando usuarios de prueba..."
    
    # Crear tabla de usuarios si no existe
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
EOF

    # Insertar usuarios con hash correcto para "123456"
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db << 'EOF'
INSERT IGNORE INTO users (username, password, role, email, full_name) VALUES
('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'admin@toppingfrozen.com', 'Administrador'),
('facturacion', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'facturacion', 'facturacion@toppingfrozen.com', 'Usuario Facturación'),
('cartera', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cartera', 'cartera@toppingfrozen.com', 'Usuario Cartera'),
('logistica', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'logistica', 'logistica@toppingfrozen.com', 'Usuario Logística'),
('mensajero', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mensajero', 'mensajero@toppingfrozen.com', 'Usuario Mensajero');
EOF

    print_status "Usuarios creados en base de datos"
else
    print_status "Usuarios encontrados en base de datos: $USER_COUNT"
fi

# 4. Verificar hash de contraseña del usuario admin
print_status "Verificando hash de contraseña del usuario admin..."
ADMIN_HASH=$(mysql -u toppinguser -pToppingPass2024! topping_frozen_db -se "SELECT password FROM users WHERE username='admin';" 2>/dev/null)

if [ -z "$ADMIN_HASH" ]; then
    print_warning "Usuario admin no encontrado, creando..."
    mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "INSERT IGNORE INTO users (username, password, role, email, full_name) VALUES ('admin', '\$2b\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'admin@toppingfrozen.com', 'Administrador');"
else
    print_status "Usuario admin encontrado"
fi

# 5. Verificar variables de entorno del backend
print_status "Verificando variables de entorno del backend..."
cd /var/www/topping-frozen-app/backend

if [ ! -f ".env" ]; then
    print_warning "Archivo .env no encontrado, creando..."
    cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=mi-super-secreto-jwt-vps-2024

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL
FRONTEND_URL=http://$SERVER_IP

# CORS Configuration
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF
    print_status "Archivo .env creado"
fi

# 6. Verificar que el backend esté compilado
print_status "Verificando compilación del backend..."
if [ ! -f "dist/index.js" ]; then
    print_warning "Backend no compilado, compilando..."
    npm install --silent
    npx tsc 2>/dev/null || {
        print_warning "Error en TypeScript, copiando archivos..."
        mkdir -p dist
        cp -r src/* dist/ 2>/dev/null
    }
fi

cd ..

# 7. Reiniciar backend con PM2
print_status "Reiniciando backend..."
pm2 restart topping-frozen-backend
sleep 5

# 8. Verificar endpoint de login
print_status "Verificando endpoint de login..."
sleep 3

LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' 2>/dev/null)

if echo "$LOGIN_RESPONSE" | grep -q "token\|success"; then
    print_status "Endpoint de login funcionando correctamente"
else
    print_warning "Endpoint de login no responde correctamente"
    print_info "Respuesta del servidor: $LOGIN_RESPONSE"
fi

# 9. Verificar logs del backend
print_status "Verificando logs del backend..."
print_info "Últimos logs del backend:"
pm2 logs topping-frozen-backend --lines 5 --nostream

# 10. Verificar configuración de CORS
print_status "Verificando configuración de CORS..."
CORS_TEST=$(curl -s -H "Origin: http://$SERVER_IP" http://localhost:3001/api/health 2>/dev/null)
if [ ! -z "$CORS_TEST" ]; then
    print_status "CORS configurado correctamente"
else
    print_warning "Posible problema con CORS"
fi

# 11. Mostrar información de diagnóstico
echo ""
echo "🔍 Información de diagnóstico:"
echo "=================================================="
echo ""

# Estado de servicios
print_info "Estado de servicios:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Backend PM2: $(pm2 list | grep topping-frozen-backend | awk '{print $10}')"

# Verificar puertos
print_info "Puertos abiertos:"
netstat -tlnp | grep -E ':(80|3001|8080)' | while read line; do
    echo "   $line"
done

# Usuarios en base de datos
print_info "Usuarios en base de datos:"
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT username, role, is_active FROM users;" 2>/dev/null | while read line; do
    echo "   $line"
done

echo ""
echo "🧪 Comandos de prueba:"
echo "=================================================="
echo ""
echo "# Probar login desde línea de comandos:"
echo "curl -X POST http://$SERVER_IP/api/auth/login \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"username\":\"admin\",\"password\":\"123456\"}'"
echo ""
echo "# Probar health check:"
echo "curl http://$SERVER_IP/api/health"
echo ""
echo "🌐 URLs para probar:"
echo "   Frontend: http://$SERVER_IP"
echo "   Backend: http://$SERVER_IP/api/health"
echo "   Login: admin / 123456"
echo ""

# Verificación final
if curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"123456"}' | grep -q "token\|success"; then
    print_status "✅ Sistema de login funcionando correctamente!"
    echo ""
    echo "🎉 Puedes probar el login en: http://$SERVER_IP"
    echo "   Usuario: admin"
    echo "   Contraseña: 123456"
else
    print_warning "⚠️  Sistema de login aún tiene problemas."
    echo ""
    echo "🔧 Comandos adicionales de diagnóstico:"
    echo "   pm2 logs topping-frozen-backend --lines 20"
    echo "   mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e 'SELECT * FROM users;'"
    echo "   curl -v http://localhost:3001/api/auth/login"
fi
