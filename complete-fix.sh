#!/bin/bash

# 🔧 Script Completo de Reparación - Topping Frozen
# Ejecutar como: bash complete-fix.sh

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🚀 Reparación Completa de Topping Frozen..."
echo "============================================"

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

print_step "1. Configurando MySQL para IPv4..."
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

sudo systemctl restart mysql
sleep 3
print_status "MySQL configurado para IPv4"

print_step "2. Creando archivo .env correcto..."
cat > $APP_DIR/backend/.env << 'EOF'
DB_HOST=127.0.0.1
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-vps-2024-final
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost
EOF
print_status "Archivo .env creado"

print_step "3. Verificando conexión MySQL..."
if mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT 1;" &>/dev/null; then
    print_status "Conexión MySQL exitosa"
else
    print_error "Error de conexión MySQL"
    exit 1
fi

print_step "4. Compilando backend..."
cd $APP_DIR/backend
npm run build
print_status "Backend compilado"

print_step "5. Compilando frontend..."
cd $APP_DIR
npm run build:frontend
print_status "Frontend compilado"

print_step "6. Configurando Nginx..."
# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

sudo tee /etc/nginx/sites-available/topping-frozen > /dev/null << EOF
server {
    listen 80;
    server_name ${SERVER_IP} localhost;

    # Servir archivos estáticos del frontend
    location / {
        root $APP_DIR/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Proxy para API del backend
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Servir archivos subidos
    location /uploads/ {
        alias $APP_DIR/backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
EOF

# Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t
sudo systemctl restart nginx
print_status "Nginx configurado y reiniciado"

print_step "7. Limpiando procesos PM2..."
pm2 stop all &>/dev/null || true
pm2 delete all &>/dev/null || true
print_status "Procesos PM2 limpiados"

print_step "8. Iniciando backend con PM2..."
cd $APP_DIR
pm2 start ecosystem.config.js
sleep 5

# Verificar que PM2 esté corriendo
if pm2 list | grep -q "online"; then
    print_status "Backend iniciado con PM2"
else
    print_warning "PM2 no está online, intentando inicio manual..."
    pm2 stop all &>/dev/null || true
    pm2 delete all &>/dev/null || true
    
    # Crear script de inicio manual
    cat > $APP_DIR/start-backend-manual.sh << 'EOF'
#!/bin/bash
cd /root/topping-frozen-app/backend
export DB_HOST=127.0.0.1
export DB_USER=toppinguser
export DB_PASSWORD=ToppingPass2024!
export DB_NAME=topping_frozen_db
export DB_PORT=3306
export JWT_SECRET=mi-super-secreto-jwt-vps-2024-final
export NODE_ENV=production
export PORT=3001
npm run dev
EOF
    chmod +x $APP_DIR/start-backend-manual.sh
    print_warning "Script manual creado: $APP_DIR/start-backend-manual.sh"
fi

print_step "9. Verificando servicios..."
# Verificar MySQL
if systemctl is-active --quiet mysql; then
    print_status "MySQL está corriendo"
else
    print_error "MySQL no está corriendo"
fi

# Verificar Nginx
if systemctl is-active --quiet nginx; then
    print_status "Nginx está corriendo"
else
    print_error "Nginx no está corriendo"
fi

# Verificar backend
sleep 3
if curl -s http://localhost:3001/api/health &>/dev/null; then
    print_status "Backend respondiendo"
else
    print_warning "Backend no responde en puerto 3001"
fi

echo ""
echo "🎉 REPARACIÓN COMPLETADA"
echo "========================"
echo ""
echo "📋 ESTADO DE SERVICIOS:"
echo "   MySQL: $(systemctl is-active mysql)"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   Backend PM2: $(pm2 list | grep -q "online" && echo "online" || echo "offline")"
echo ""
echo "🚀 COMANDOS PARA GESTIONAR:"
echo ""
echo "   Ver estado PM2:"
echo "   pm2 status"
echo ""
echo "   Ver logs PM2:"
echo "   pm2 logs topping-backend"
echo ""
echo "   Reiniciar backend:"
echo "   pm2 restart topping-backend"
echo ""
echo "   Inicio manual (si PM2 falla):"
echo "   $APP_DIR/start-backend-manual.sh"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: http://$SERVER_IP"
echo "   API: http://$SERVER_IP/api"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 TROUBLESHOOTING:"
echo "   Ver logs Nginx: sudo tail -f /var/log/nginx/topping-frozen.error.log"
echo "   Ver logs MySQL: sudo journalctl -u mysql -f"
echo "   Probar API: curl http://localhost:3001/api/health"
echo ""
print_status "¡Sistema completamente configurado! 🚀"
