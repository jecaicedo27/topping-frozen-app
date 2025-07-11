#!/bin/bash

# 🔧 Solución Final Definitiva para el Login
# Enfoque específico en el problema de autenticación

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

echo "🔧 Solución Final Definitiva para el Login"
echo "=========================================="

cd /home/gestionPedidos

# 1. Test directo de la API de login
print_status "1. Probando API de login directamente..."
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Respuesta de la API: $API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "✅ API de login funciona - El problema está en el frontend"
    PROBLEM_TYPE="frontend"
elif echo "$API_RESPONSE" | grep -q "Invalid credentials\|Unauthorized"; then
    print_warning "⚠️ Credenciales inválidas - El problema está en la base de datos"
    PROBLEM_TYPE="database"
elif echo "$API_RESPONSE" | grep -q "error\|Error"; then
    print_error "❌ Error en el backend - El problema está en el servidor"
    PROBLEM_TYPE="backend"
else
    print_error "❌ API no responde correctamente"
    PROBLEM_TYPE="connection"
fi

echo ""
print_status "Tipo de problema identificado: $PROBLEM_TYPE"
echo ""

# 2. Solucionar según el tipo de problema
case $PROBLEM_TYPE in
    "frontend")
        print_status "2. Solucionando problema de frontend..."
        
        # Verificar configuración de Nginx
        print_status "Verificando configuración de Nginx..."
        sudo nginx -t
        
        # Recargar Nginx
        print_status "Recargando Nginx..."
        sudo systemctl reload nginx
        
        # Verificar que el frontend esté sirviendo correctamente
        print_status "Verificando frontend..."
        curl -s http://localhost/ | head -10
        ;;
        
    "database")
        print_status "2. Solucionando problema de base de datos..."
        
        # Recrear usuario admin con hash correcto
        print_status "Recreando usuario admin..."
        
        # Generar hash correcto
        cd backend
        NEW_HASH=$(node -e "
        const bcrypt = require('bcrypt');
        const hash = bcrypt.hashSync('123456', 10);
        console.log(hash);
        " 2>/dev/null)
        cd ..
        
        if [ -n "$NEW_HASH" ]; then
            print_success "Hash generado: $NEW_HASH"
            
            # Actualizar en base de datos
            mysql -u appuser -papppassword123 -e "
            USE gestionPedidos;
            DELETE FROM users WHERE username = 'admin';
            INSERT INTO users (username, password, role) VALUES ('admin', '$NEW_HASH', 'admin');
            " 2>/dev/null
            
            print_success "Usuario admin recreado"
        else
            print_error "Error generando hash"
        fi
        ;;
        
    "backend")
        print_status "2. Solucionando problema de backend..."
        
        # Reiniciar backend
        print_status "Reiniciando backend..."
        pm2 restart gestion-pedidos-backend
        sleep 5
        ;;
        
    "connection")
        print_status "2. Solucionando problema de conexión..."
        
        # Verificar que el backend esté corriendo
        if ! netstat -tlnp | grep :5000 > /dev/null; then
            print_error "Backend no está corriendo en puerto 5000"
            pm2 restart gestion-pedidos-backend
            sleep 5
        fi
        ;;
esac

# 3. Test final después de la solución
print_status "3. Test final después de la solución..."
sleep 3

FINAL_TEST=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Respuesta final: $FINAL_TEST"

if echo "$FINAL_TEST" | grep -q "token"; then
    print_success "🎉 ¡LOGIN FUNCIONANDO CORRECTAMENTE!"
    
    # Extraer el token para verificar
    TOKEN=$(echo "$FINAL_TEST" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        print_success "Token generado: ${TOKEN:0:20}..."
    fi
    
else
    print_error "❌ Login aún no funciona"
    print_status "Respuesta completa: $FINAL_TEST"
    
    # Mostrar logs del backend para diagnóstico
    print_status "Logs del backend:"
    pm2 logs gestion-pedidos-backend --lines 10
fi

# 4. Verificar usuario en base de datos
print_status "4. Verificando usuario en base de datos..."
mysql -u appuser -papppassword123 -e "
USE gestionPedidos;
SELECT id, username, role, LEFT(password, 30) as password_preview FROM users WHERE username = 'admin';
" 2>/dev/null

# 5. Test de hash de contraseña
print_status "5. Test de verificación de contraseña..."
cd backend
node -e "
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function testPassword() {
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
            console.log('Verificación de contraseña:', isValid ? 'VÁLIDA' : 'INVÁLIDA');
        } else {
            console.log('Usuario admin no encontrado');
        }
        
        await connection.end();
    } catch (error) {
        console.error('Error:', error.message);
    }
}

testPassword();
" 2>/dev/null
cd ..

echo ""
print_success "🎯 Diagnóstico y solución completados"
print_status "🔐 Credenciales:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🌐 URL: http://$(curl -s ifconfig.me)"
echo ""
print_status "🔧 Si aún falla:"
echo "• Verifica que uses exactamente: admin / 123456"
echo "• Prueba en modo incógnito del navegador"
echo "• Verifica que no haya espacios en las credenciales"
