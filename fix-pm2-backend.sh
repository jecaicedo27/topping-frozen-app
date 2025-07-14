#!/bin/bash

# Script para solucionar problemas de PM2 con el backend
echo "🔧 Solucionando problemas de PM2 con el backend..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Ir al directorio del proyecto
cd /var/www/topping-frozen-app

# 1. Detener PM2 si está ejecutándose
print_status "Deteniendo PM2..."
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# 2. Limpiar y reinstalar dependencias del backend
print_status "Limpiando y reinstalando dependencias del backend..."
cd backend
rm -rf node_modules package-lock.json
npm install

# 3. Compilar backend
print_status "Compilando backend..."
npm run build

# Verificar que se compiló correctamente
if [ ! -f "dist/index.js" ]; then
    print_error "Error: No se pudo compilar el backend"
    print_warning "Intentando compilación manual..."
    npx tsc
    
    if [ ! -f "dist/index.js" ]; then
        print_error "Compilación fallida. Verificando tsconfig.json..."
        
        # Crear tsconfig.json básico si no existe
        if [ ! -f "tsconfig.json" ]; then
            print_status "Creando tsconfig.json..."
            cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": false,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
            npx tsc
        fi
    fi
fi

cd ..

# 4. Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# 5. Verificar archivo .env
print_status "Verificando configuración del backend..."
if [ ! -f "backend/.env" ]; then
    print_warning "Archivo .env no encontrado, creando..."
    cat > backend/.env << EOF
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

# Frontend URL - Solo IP, sin DNS
FRONTEND_URL=http://$SERVER_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts

# CORS Configuration - Solo IP
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF
fi

# 6. Crear configuración PM2 simplificada
print_status "Creando configuración PM2 simplificada..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'topping-frozen-backend',
      script: 'backend/dist/index.js',
      cwd: '/var/www/topping-frozen-app',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: '/var/log/pm2/topping-frozen-backend-error.log',
      out_file: '/var/log/pm2/topping-frozen-backend-out.log',
      log_file: '/var/log/pm2/topping-frozen-backend.log',
      time: true
    }
  ]
};
EOF

# 7. Crear directorio de logs
mkdir -p /var/log/pm2

# 8. Probar el backend directamente primero
print_status "Probando backend directamente..."
cd backend
timeout 10s node dist/index.js &
BACKEND_PID=$!
sleep 5

# Verificar si el backend inicia correctamente
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "Backend funciona correctamente en modo directo"
    kill $BACKEND_PID 2>/dev/null || true
else
    print_error "Backend no funciona en modo directo"
    kill $BACKEND_PID 2>/dev/null || true
    print_warning "Verificando logs..."
    
    # Intentar ejecutar y mostrar errores
    node dist/index.js &
    BACKEND_PID=$!
    sleep 3
    kill $BACKEND_PID 2>/dev/null || true
fi

cd ..

# 9. Iniciar con PM2
print_status "Iniciando con PM2..."
pm2 start ecosystem.config.js

# 10. Verificar estado
sleep 5
pm2 status

# 11. Verificar funcionamiento
print_status "Verificando funcionamiento..."
if curl -s http://localhost:3001/api/health > /dev/null; then
    print_status "✅ Backend funcionando correctamente con PM2"
    
    # Probar login
    if curl -s -X POST http://localhost:3001/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"123456"}' | grep -q "success"; then
        print_status "✅ Sistema de login funcionando"
    else
        print_warning "⚠️ Sistema de login no responde correctamente"
    fi
else
    print_error "❌ Backend no responde"
    print_warning "Mostrando logs de PM2..."
    pm2 logs topping-frozen-backend --lines 20
fi

# 12. Guardar configuración PM2
pm2 save
pm2 startup

print_status "🎉 Proceso completado!"
echo ""
echo "📋 Comandos útiles:"
echo "   pm2 status                    # Ver estado"
echo "   pm2 logs topping-frozen-backend  # Ver logs"
echo "   pm2 restart topping-frozen-backend  # Reiniciar"
echo "   pm2 monit                     # Monitor en tiempo real"
echo ""
echo "🧪 Probar:"
echo "   curl http://localhost:3001/api/health"
echo "   curl http://$SERVER_IP/api/health"
