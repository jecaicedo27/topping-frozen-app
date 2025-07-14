#!/bin/bash

# 🔒 Script para Configurar SSL/HTTPS - Topping Frozen
# Ejecutar como: bash setup-ssl.sh

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

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

echo "🔒 Configurando SSL/HTTPS para Topping Frozen..."
echo "==============================================="

# Verificar que estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root"
    exit 1
fi

print_step "1. Actualizando sistema..."
apt update

print_step "2. Instalando Certbot y plugin de Nginx..."
apt install -y certbot python3-certbot-nginx

print_step "3. Verificando configuración actual de Nginx..."
nginx -t
if [ $? -ne 0 ]; then
    print_error "Error en configuración de Nginx"
    exit 1
fi

print_step "4. Creando configuración base de Nginx para SSL..."
cat > /etc/nginx/sites-available/topping-frozen << 'EOF'
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Servir archivos estáticos del frontend
    location / {
        root /var/www/topping-frozen;
        try_files $uri $uri/ /index.html;
        index index.html;
        
        # Headers para evitar caché durante desarrollo
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
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOF

print_step "5. Verificando configuración de Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    print_status "Configuración de Nginx válida"
    systemctl reload nginx
else
    print_error "Error en configuración de Nginx"
    exit 1
fi

print_step "6. Verificando que el dominio apunte al servidor..."
DOMAIN_IP=$(dig +short apptoppingfrozen.com)
SERVER_IP=$(curl -s ifconfig.me)

echo "IP del dominio: $DOMAIN_IP"
echo "IP del servidor: $SERVER_IP"

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    print_warning "El dominio no apunta a este servidor"
    print_warning "Dominio IP: $DOMAIN_IP"
    print_warning "Servidor IP: $SERVER_IP"
    print_warning "Continuando de todas formas..."
fi

print_step "7. Obteniendo certificado SSL con Let's Encrypt..."
print_warning "IMPORTANTE: Asegúrate de que el dominio apptoppingfrozen.com apunte a este servidor"
print_warning "Presiona Enter para continuar o Ctrl+C para cancelar"
read -p "¿Continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Operación cancelada"
    exit 1
fi

# Obtener certificado SSL
certbot --nginx -d apptoppingfrozen.com -d www.apptoppingfrozen.com --non-interactive --agree-tos --email admin@apptoppingfrozen.com --redirect

if [ $? -eq 0 ]; then
    print_status "Certificado SSL obtenido exitosamente"
else
    print_error "Error al obtener certificado SSL"
    print_warning "Esto puede deberse a:"
    print_warning "1. El dominio no apunta a este servidor"
    print_warning "2. El puerto 80 no está accesible desde internet"
    print_warning "3. Firewall bloqueando conexiones"
    
    print_step "Configurando SSL manual con certificado autofirmado..."
    
    # Crear certificado autofirmado como respaldo
    mkdir -p /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/apptoppingfrozen.key \
        -out /etc/ssl/certs/apptoppingfrozen.crt \
        -subj "/C=CO/ST=Bogota/L=Bogota/O=ToppingFrozen/CN=apptoppingfrozen.com"
    
    # Configurar Nginx con certificado autofirmado
    cat > /etc/nginx/sites-available/topping-frozen << 'EOF'
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Certificado SSL autofirmado
    ssl_certificate /etc/ssl/certs/apptoppingfrozen.crt;
    ssl_certificate_key /etc/ssl/private/apptoppingfrozen.key;

    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

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
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOF
    
    print_warning "Configurado con certificado autofirmado"
    print_warning "El navegador mostrará advertencia de seguridad"
fi

print_step "8. Verificando configuración final de Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    print_status "Nginx reconfigurado con SSL"
else
    print_error "Error en configuración final de Nginx"
    exit 1
fi

print_step "9. Configurando renovación automática..."
# Agregar tarea cron para renovación automática
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

print_step "10. Verificando SSL..."
echo "Probando conexión HTTPS..."
if curl -k -s https://apptoppingfrozen.com/api/health | grep -q "success"; then
    print_status "HTTPS funcionando correctamente"
else
    print_warning "HTTPS configurado pero API no responde"
fi

echo ""
echo "🔒 CONFIGURACIÓN SSL COMPLETADA"
echo "==============================="
echo ""
echo "📋 RESUMEN:"
echo "   ✅ Certbot instalado"
echo "   ✅ Nginx configurado para SSL"
echo "   ✅ Certificado SSL configurado"
echo "   ✅ Redirección HTTP -> HTTPS habilitada"
echo "   ✅ Renovación automática configurada"
echo ""
echo "🌐 ACCESO:"
echo "   HTTP: http://apptoppingfrozen.com/ (redirige a HTTPS)"
echo "   HTTPS: https://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 COMANDOS ÚTILES:"
echo "   Verificar certificado: certbot certificates"
echo "   Renovar manualmente: certbot renew"
echo "   Ver logs SSL: tail -f /var/log/nginx/topping-frozen.error.log"
echo ""
if [ -f "/etc/ssl/certs/apptoppingfrozen.crt" ]; then
    print_warning "NOTA: Se usó certificado autofirmado"
    print_warning "El navegador mostrará advertencia de seguridad"
    print_warning "Para certificado válido, asegúrate de que el dominio apunte al servidor"
else
    print_status "¡SSL configurado con Let's Encrypt! 🔒"
fi
