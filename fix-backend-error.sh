#!/bin/bash

# 🔧 Script para Solucionar Backend en Estado "Errored"
# Soluciona problemas específicos del backend

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

echo "🔧 Solucionando Backend en Estado Errored"
echo "========================================="

cd /home/gestionPedidos

# 1. Ver logs específicos del error
print_status "1. Verificando logs del error..."
pm2 logs gestion-pedidos-backend --lines 20

echo ""
print_status "2. Deteniendo y eliminando proceso problemático..."
pm2 delete gestion-pedidos-backend 2>/dev/null || true
pm2 kill 2>/dev/null || true

# 3. Verificar archivos necesarios
print_status "3. Verificando archivos del backend..."
if [ ! -f "backend/dist/index.js" ]; then
    print_warning "Archivo dist/index.js no existe, compilando..."
    cd backend
    npm run build 2>/dev/null || {
        print_error "Error en build, instalando dependencias..."
        npm install
        npm run build
    }
    cd ..
fi

# 4. Verificar ecosystem.config.js
print_status "4. Verificando configuración PM2..."
if [ ! -f "ecosystem.config.js" ]; then
    print_warning "Creando ecosystem.config.js..."
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'gestion-pedidos-backend',
    script: './backend/dist/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
fi

# 5. Crear directorio de logs
print_status "5. Creando directorio de logs..."
mkdir -p logs

# 6. Verificar puerto 5000 libre
print_status "6. Liberando puerto 5000..."
pkill -f ":5000" 2>/dev/null || true
sleep 2

# 7. Verificar variables de entorno
print_status "7. Verificando variables de entorno..."
if [ ! -f "backend/.env" ]; then
    print_error "Archivo backend/.env no existe"
    exit 1
fi

# 8. Test de conexión a base de datos
print_status "8. Verificando conexión a base de datos..."
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT 1;" 2>/dev/null || {
    print_error "Error de conexión a base de datos"
    exit 1
}

# 9. Iniciar backend paso a paso
print_status "9. Iniciando backend paso a paso..."

# Primero intentar ejecutar directamente
print_status "Probando ejecución directa..."
cd backend
timeout 10s node dist/index.js &
DIRECT_PID=$!
sleep 5

if kill -0 $DIRECT_PID 2>/dev/null; then
    print_success "Backend funciona directamente"
    kill $DIRECT_PID 2>/dev/null
else
    print_warning "Backend falló en ejecución directa"
fi
cd ..

# 10. Iniciar con PM2
print_status "10. Iniciando con PM2..."
pm2 start ecosystem.config.js

# 11. Esperar y verificar
print_status "11. Esperando inicialización..."
sleep 10

# 12. Verificar estado
print_status "12. Verificando estado final..."
pm2 status

# 13. Si sigue en error, mostrar logs detallados
if pm2 status | grep -q "errored"; then
    print_error "Backend aún en estado errored"
    print_status "Logs detallados:"
    pm2 logs gestion-pedidos-backend --lines 30
    
    print_status "Intentando reinicio forzado..."
    pm2 restart gestion-pedidos-backend --force
    sleep 5
    pm2 status
fi

# 14. Test de conectividad
print_status "14. Test de conectividad..."
if netstat -tlnp | grep :5000 > /dev/null; then
    print_success "✅ Puerto 5000 activo"
    
    # Test de API
    print_status "Probando API..."
    curl -s http://localhost:5000/api/auth/login > /dev/null && {
        print_success "✅ API responde"
    } || {
        print_warning "⚠️ API no responde correctamente"
    }
else
    print_error "❌ Puerto 5000 no activo"
fi

echo ""
print_status "🔧 Comandos de diagnóstico adicional:"
echo "• Ver logs en tiempo real: pm2 logs gestion-pedidos-backend"
echo "• Reiniciar: pm2 restart gestion-pedidos-backend"
echo "• Ver estado: pm2 status"
echo "• Ejecutar directamente: cd backend && node dist/index.js"
echo "• Verificar puerto: netstat -tlnp | grep :5000"
