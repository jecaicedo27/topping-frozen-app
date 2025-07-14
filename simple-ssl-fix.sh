#!/bin/bash

# 🔒 Script Simple para Configurar SSL - Topping Frozen
# Ejecutar como: bash simple-ssl-fix.sh

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
    echo -e "${BLUE}[🔒 STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

echo "🔒 Configuración Simple de SSL para Topping Frozen..."
echo "===================================================="

print_step "1. Verificando estado actual..."
echo "Verificando Nginx..."
systemctl status nginx --no-pager -l

echo ""
echo "Verificando puertos..."
netstat -tlnp | grep -E ":80|:443"

print_step "2. Creando certificado autofirmado..."
mkdir -p /etc/ssl/private
mkdir -p /etc/ssl/certs

# Crear certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/apptoppingfrozen.key \
    -out /etc/ssl/certs/apptoppingfrozen.crt \
    -subj "/C=CO/ST=Bogota/L=Bogota/O=ToppingFrozen/CN=apptoppingfrozen.com"

print_status "Certificado autofirmado creado"

print_step "3. Configurando Nginx con SSL..."
cat > /etc/nginx/sites-available/topping-frozen << 'EOF'
# Redirigir HTTP a HTTPS
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;
    return 301 https://$server_name$request_uri;
}

# Servidor HTTPS
server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Certificados SSL
    ssl_certificate /etc/ssl/certs/apptoppingfrozen.crt;
    ssl_certificate_key /etc/ssl/private/apptoppingfrozen.key;

    # Configuración SSL básica
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Servir archivos estáticos del frontend
    location / {
        root /var/www/topping-frozen;
        try_files $uri $uri/ /index.html;
        index index.html;
        
        # Headers para evitar caché
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Proxy para API del backend
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    }

    # Logs
    access_log /var/log/nginx/topping-frozen-ssl.access.log;
    error_log /var/log/nginx/topping-frozen-ssl.error.log;
}
EOF

print_step "4. Verificando configuración de Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    print_status "Configuración de Nginx válida"
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

print_step "5. Verificando que el frontend esté disponible..."
if [ ! -d "/var/www/topping-frozen" ] || [ ! -f "/var/www/topping-frozen/index.html" ]; then
    print_error "Frontend no encontrado, copiando archivos..."
    
    if [ -d "/root/topping-frozen-app/dist" ]; then
        mkdir -p /var/www/topping-frozen
        cp -r /root/topping-frozen-app/dist/* /var/www/topping-frozen/
        chown -R www-data:www-data /var/www/topping-frozen/
        chmod -R 755 /var/www/topping-frozen/
        print_status "Frontend copiado"
    else
        print_error "No se encontró el frontend compilado"
    fi
fi

print_step "6. Verificando firewall..."
# Verificar si ufw está activo
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        print_step "Configurando firewall para HTTPS..."
        ufw allow 443/tcp
        ufw allow 'Nginx Full'
        print_status "Firewall configurado"
    fi
fi

print_step "7. Reiniciando Nginx..."
systemctl restart nginx

if [ $? -eq 0 ]; then
    print_status "Nginx reiniciado exitosamente"
else
    print_error "Error al reiniciar Nginx"
    exit 1
fi

print_step "8. Verificando que el backend esté corriendo..."
if ! pgrep -f "npm run dev" > /dev/null; then
    print_error "Backend no está corriendo, iniciando..."
    cd /root/topping-frozen-app/backend
    pkill -f "npm run dev" || true
    pkill -f "ts-node-dev" || true
    sleep 2
    nohup npm run dev > /tmp/backend-ssl.log 2>&1 &
    sleep 5
    print_status "Backend iniciado"
fi

print_step "9. Verificando servicios..."
echo "Estado de Nginx:"
systemctl status nginx --no-pager -l | head -10

echo ""
echo "Puertos abiertos:"
netstat -tlnp | grep -E ":80|:443|:3001"

echo ""
echo "Procesos del backend:"
ps aux | grep -E "(npm|node|ts-node)" | grep -v grep

print_step "10. Probando conexiones..."
echo "Probando HTTP (debería redirigir):"
curl -I http://apptoppingfrozen.com/ 2>/dev/null | head -5

echo ""
echo "Probando HTTPS:"
curl -k -I https://apptoppingfrozen.com/ 2>/dev/null | head -5

echo ""
echo "Probando API HTTPS:"
curl -k -s https://apptoppingfrozen.com/api/health

echo ""
echo "🔒 CONFIGURACIÓN SSL SIMPLE COMPLETADA"
echo "======================================"
echo ""
echo "📋 RESUMEN:"
echo "   ✅ Certificado autofirmado creado"
echo "   ✅ Nginx configurado para SSL"
echo "   ✅ Redirección HTTP -> HTTPS habilitada"
echo "   ✅ Firewall configurado (si estaba activo)"
echo "   ✅ Backend verificado"
echo ""
echo "🌐 ACCESO:"
echo "   HTTP: http://apptoppingfrozen.com/ (redirige a HTTPS)"
echo "   HTTPS: https://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Se usa certificado autofirmado"
echo "   - El navegador mostrará advertencia de seguridad"
echo "   - Click en 'Avanzado' -> 'Ir al sitio' para continuar"
echo ""
echo "🔧 TROUBLESHOOTING:"
echo "   Ver logs SSL: tail -f /var/log/nginx/topping-frozen-ssl.error.log"
echo "   Ver logs backend: tail -f /tmp/backend-ssl.log"
echo "   Verificar certificado: openssl x509 -in /etc/ssl/certs/apptoppingfrozen.crt -text -noout"
echo ""
print_status "¡SSL configurado! Prueba https://apptoppingfrozen.com/ 🔒"
