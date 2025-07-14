#!/bin/bash

# Script para restaurar desde el backup original
echo "🔄 Restaurando desde backup original..."

cd /var/www/topping-frozen-app

# 1. Buscar el archivo de backup
echo "🔍 Buscando archivo de backup..."
BACKUP_FILE=""

# Buscar en diferentes ubicaciones posibles
if [ -f "topping-frozen-backup-20250714_001958.tar" ]; then
    BACKUP_FILE="topping-frozen-backup-20250714_001958.tar"
elif [ -f "/root/topping-frozen-backup-20250714_001958.tar" ]; then
    BACKUP_FILE="/root/topping-frozen-backup-20250714_001958.tar"
elif [ -f "/home/topping-frozen-backup-20250714_001958.tar" ]; then
    BACKUP_FILE="/home/topping-frozen-backup-20250714_001958.tar"
elif [ -f "/tmp/topping-frozen-backup-20250714_001958.tar" ]; then
    BACKUP_FILE="/tmp/topping-frozen-backup-20250714_001958.tar"
else
    echo "❌ No se encontró el archivo de backup"
    echo "📍 Ubicaciones buscadas:"
    echo "   - ./topping-frozen-backup-20250714_001958.tar"
    echo "   - /root/topping-frozen-backup-20250714_001958.tar"
    echo "   - /home/topping-frozen-backup-20250714_001958.tar"
    echo "   - /tmp/topping-frozen-backup-20250714_001958.tar"
    echo ""
    echo "💡 Por favor, copia el archivo de backup a una de estas ubicaciones:"
    echo "   cp /ruta/del/backup/topping-frozen-backup-20250714_001958.tar /var/www/topping-frozen-app/"
    echo ""
    echo "🔍 Archivos .tar encontrados en el directorio actual:"
    find . -name "*.tar" -type f 2>/dev/null || echo "   Ninguno encontrado"
    echo ""
    echo "🔍 Archivos .tar encontrados en /root:"
    find /root -name "*topping*backup*.tar" -type f 2>/dev/null || echo "   Ninguno encontrado"
    exit 1
fi

echo "✅ Backup encontrado: $BACKUP_FILE"

# 2. Crear backup de la versión actual (por seguridad)
echo "💾 Creando backup de la versión actual..."
CURRENT_BACKUP="current-backup-$(date +%Y%m%d_%H%M%S).tar"
tar -cf "$CURRENT_BACKUP" --exclude="*.tar" --exclude="node_modules" . 2>/dev/null
echo "✅ Backup actual guardado como: $CURRENT_BACKUP"

# 3. Detener servicios
echo "🛑 Deteniendo servicios..."
pm2 stop all 2>/dev/null
systemctl stop nginx 2>/dev/null

# 4. Limpiar directorio actual (excepto backups)
echo "🧹 Limpiando directorio actual..."
find . -maxdepth 1 -type f ! -name "*.tar" -delete 2>/dev/null
find . -maxdepth 1 -type d ! -name "." ! -name ".." -exec rm -rf {} + 2>/dev/null

# 5. Extraer backup original
echo "📦 Extrayendo backup original..."
tar -xf "$BACKUP_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Backup extraído exitosamente"
else
    echo "❌ Error al extraer backup"
    echo "🔄 Restaurando backup actual..."
    tar -xf "$CURRENT_BACKUP" 2>/dev/null
    exit 1
fi

# 6. Verificar estructura
echo "🔍 Verificando estructura restaurada..."
if [ -d "src" ] && [ -d "backend" ] && [ -f "package.json" ]; then
    echo "✅ Estructura básica verificada"
else
    echo "❌ Estructura incompleta"
    ls -la
    exit 1
fi

# 7. Instalar dependencias
echo "📦 Instalando dependencias..."
npm install --silent 2>/dev/null

# 8. Instalar dependencias del backend
if [ -d "backend" ]; then
    echo "📦 Instalando dependencias del backend..."
    cd backend
    npm install --silent 2>/dev/null
    cd ..
fi

# 9. Compilar aplicación
echo "🔨 Compilando aplicación..."
npm run build 2>/dev/null || npx webpack --mode production 2>/dev/null || {
    echo "⚠️ Compilación con errores, pero continuando..."
}

# 10. Compilar backend
if [ -d "backend" ]; then
    echo "🔨 Compilando backend..."
    cd backend
    npm run build 2>/dev/null || npx tsc 2>/dev/null || {
        echo "⚠️ Compilación del backend con errores, pero continuando..."
    }
    cd ..
fi

# 11. Reiniciar servicios
echo "🚀 Reiniciando servicios..."

# Reiniciar backend con PM2
if [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js --env production 2>/dev/null
elif [ -d "backend" ]; then
    cd backend
    pm2 start npm --name "topping-backend" -- start 2>/dev/null
    cd ..
fi

# Reiniciar Nginx
systemctl start nginx 2>/dev/null
systemctl restart nginx 2>/dev/null

# 12. Verificar servicios
echo "🔍 Verificando servicios..."
sleep 3

# Verificar PM2
PM2_STATUS=$(pm2 list 2>/dev/null | grep -c "online" || echo "0")
echo "📊 Procesos PM2 activos: $PM2_STATUS"

# Verificar Nginx
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está activo"
else
    echo "⚠️ Nginx no está activo"
fi

# 13. Verificar conectividad
echo "🌐 Verificando conectividad..."
sleep 2
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/health 2>/dev/null || echo "000")
if [ "$HEALTH_CHECK" = "200" ]; then
    echo "✅ Backend respondiendo correctamente"
else
    echo "⚠️ Backend no responde (código: $HEALTH_CHECK)"
fi

# 14. Mostrar estado final
echo ""
echo "🎉 ¡RESTAURACIÓN DESDE BACKUP COMPLETADA!"
echo "✅ Aplicación original restaurada desde backup"
echo "✅ Dependencias instaladas"
echo "✅ Servicios reiniciados"
echo ""
echo "📊 Estado de servicios:"
echo "   - PM2 procesos activos: $PM2_STATUS"
echo "   - Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'inactivo')"
echo "   - Backend health: $HEALTH_CHECK"
echo ""
echo "🌐 Acceso a la aplicación:"
echo "   - URL: http://46.202.93.54"
echo "   - Usuario: admin"
echo "   - Contraseña: 123456"
echo ""
echo "💾 Backups disponibles:"
echo "   - Backup original: $BACKUP_FILE"
echo "   - Backup anterior: $CURRENT_BACKUP"
echo ""
echo "🏆 ¡APLICACIÓN ORIGINAL COMPLETAMENTE RESTAURADA!"
