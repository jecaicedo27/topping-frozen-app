#!/bin/bash

# 🔧 Script Final Definitivo para Solucionar Login
# Diagnóstico completo y solución específica del login

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

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

print_header "🔧 DIAGNÓSTICO FINAL DEL LOGIN"

cd /home/gestionPedidos

# 1. Test directo de la API
print_status "1. Probando API de login directamente..."
API_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Respuesta de la API: $API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "token"; then
    print_success "✅ API funciona - El problema está en el frontend"
    PROBLEM_TYPE="frontend"
elif echo "$API_RESPONSE" | grep -q "Invalid credentials\|Unauthorized\|incorrect"; then
    print_warning "⚠️ Credenciales inválidas - Problema en la base de datos"
    PROBLEM_TYPE="credentials"
elif echo "$API_RESPONSE" | grep -q "Cannot POST\|404"; then
    print_error "❌ Ruta no encontrada - Problema de configuración"
    PROBLEM_TYPE="routing"
else
    print_error "❌ Error desconocido"
    PROBLEM_TYPE="unknown"
fi

print_header "🔍 DIAGNÓSTICO ESPECÍFICO: $PROBLEM_TYPE"

case $PROBLEM_TYPE in
    "frontend")
        print_status "Problema identificado: Frontend no se comunica con backend"
        
        # Verificar configuración de Nginx
        print_status "Verificando configuración de Nginx..."
        nginx -t
        
        # Verificar que el proxy esté configurado
        if grep -q "proxy_pass.*5000" /etc/nginx/sites-enabled/gestion-pedidos; then
            print_success "✅ Proxy configurado correctamente"
        else
            print_warning "⚠️ Proxy no configurado, corrigiendo..."
            
            cat > /etc/nginx/sites-available/gestion-pedidos << 'EOF'
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root /home/gestionPedidos/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Uploads
    location /uploads/ {
        alias /home/gestionPedidos/backend/uploads/;
    }
}
EOF
            
            systemctl reload nginx
            print_success "Nginx reconfigurado"
        fi
        ;;
        
    "credentials")
        print_status "Problema identificado: Hash de contraseña incorrecto"
        
        # Regenerar hash correcto
        print_status "Regenerando hash de contraseña..."
        cd backend
        NEW_HASH=$(node -e "
        const bcrypt = require('bcrypt');
        const hash = bcrypt.hashSync('123456', 10);
        console.log(hash);
        " 2>/dev/null)
        cd ..
        
        if [ -n "$NEW_HASH" ]; then
            print_success "Nuevo hash generado: $NEW_HASH"
            
            # Actualizar en base de datos
            mysql -u appuser -papppassword123 -e "
            USE gestionPedidos;
            UPDATE users SET password = '$NEW_HASH' WHERE username = 'admin';
            " 2>/dev/null
            
            print_success "Hash actualizado en base de datos"
            
            # Verificar actualización
            UPDATED_HASH=$(mysql -u appuser -papppassword123 -e "
            USE gestionPedidos;
            SELECT password FROM users WHERE username = 'admin';
            " 2>/dev/null | tail -1)
            
            print_status "Hash en BD: ${UPDATED_HASH:0:30}..."
        fi
        ;;
        
    "routing")
        print_status "Problema identificado: Rutas del backend no funcionan"
        
        # Verificar que el backend esté corriendo en puerto 5000
        if netstat -tlnp | grep :5000 > /dev/null; then
            print_success "✅ Backend corriendo en puerto 5000"
        else
            print_error "❌ Backend no está en puerto 5000"
            pm2 restart gestion-pedidos-backend
            sleep 5
        fi
        
        # Verificar logs del backend
        print_status "Logs del backend:"
        pm2 logs gestion-pedidos-backend --lines 10
        ;;
        
    "unknown")
        print_status "Problema desconocido, ejecutando diagnóstico completo..."
        
        # Verificar todos los servicios
        print_status "Estado de servicios:"
        systemctl is-active mysql && echo "✅ MySQL" || echo "❌ MySQL"
        systemctl is-active nginx && echo "✅ Nginx" || echo "❌ Nginx"
        pm2 status | grep online && echo "✅ Backend" || echo "❌ Backend"
        
        # Verificar puertos
        print_status "Puertos activos:"
        netstat -tlnp | grep :80 && echo "✅ Puerto 80" || echo "❌ Puerto 80"
        netstat -tlnp | grep :5000 && echo "✅ Puerto 5000" || echo "❌ Puerto 5000"
        netstat -tlnp | grep :3306 && echo "✅ Puerto 3306" || echo "❌ Puerto 3306"
        ;;
esac

print_header "🧪 TEST FINAL DE VERIFICACIÓN"

# Test completo paso a paso
print_status "1. Test de conexión a base de datos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT COUNT(*) as users FROM users;" 2>/dev/null && {
    print_success "✅ Base de datos accesible"
} || {
    print_error "❌ Error de base de datos"
}

print_status "2. Test de hash de contraseña..."
cd backend
node -e "
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function testLogin() {
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
            
            if (!isValid) {
                console.log('❌ El hash no coincide con la contraseña 123456');
            } else {
                console.log('✅ Hash correcto para contraseña 123456');
            }
        } else {
            console.log('❌ Usuario admin no encontrado');
        }
        
        await connection.end();
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testLogin();
" 2>/dev/null
cd ..

print_status "3. Test de API final..."
sleep 3
FINAL_API_TEST=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null)

echo "Respuesta final de API: $FINAL_API_TEST"

if echo "$FINAL_API_TEST" | grep -q "token"; then
    print_success "🎉 ¡LOGIN FUNCIONANDO CORRECTAMENTE!"
    
    # Extraer token
    TOKEN=$(echo "$FINAL_API_TEST" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    print_success "Token JWT generado: ${TOKEN:0:30}..."
    
elif echo "$FINAL_API_TEST" | grep -q "Invalid\|incorrect\|wrong"; then
    print_error "❌ Credenciales incorrectas"
    print_status "Verificando usuario en BD:"
    mysql -u appuser -papppassword123 -e "
    USE gestionPedidos;
    SELECT id, username, role, LEFT(password, 30) as hash_preview FROM users WHERE username = 'admin';
    " 2>/dev/null
    
else
    print_error "❌ Error en API"
    print_status "Verificando logs del backend:"
    pm2 logs gestion-pedidos-backend --lines 5
fi

print_header "📋 INFORMACIÓN FINAL"

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
print_status "🌐 URLs de acceso:"
echo "• Aplicación: http://$SERVER_IP"
echo "• phpMyAdmin: http://$SERVER_IP:8080"
echo ""
print_status "🔐 Credenciales:"
echo "• Usuario: admin"
echo "• Contraseña: 123456"
echo ""
print_status "🔧 Si el login aún falla:"
echo "• Verifica en phpMyAdmin que el usuario admin existe"
echo "• Prueba con otros usuarios: facturacion, cartera, logistica"
echo "• Verifica que uses exactamente: admin / 123456 (sin espacios)"
echo "• Prueba en modo incógnito del navegador"
echo ""
print_status "📞 Comandos de diagnóstico:"
echo "• Ver logs: pm2 logs gestion-pedidos-backend"
echo "• Estado: pm2 status"
echo "• Reiniciar: pm2 restart gestion-pedidos-backend"
