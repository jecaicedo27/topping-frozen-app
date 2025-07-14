# 🔧 Resolver Conflictos de Git y Corregir Servidor

## 🚨 Problema Actual:
1. Git tiene conflictos con archivos locales
2. El servidor sigue mostrando 502 Bad Gateway
3. Necesitamos forzar la actualización y ejecutar la corrección

## 🚀 Solución Inmediata - Ejecuta en el VPS:

```bash
# Descartar cambios locales y forzar actualización
git reset --hard HEAD
git clean -fd
git pull origin main

# Verificar que los scripts se descargaron
ls -la *.sh

# Si no aparecen, descargar directamente
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/quick-vps-fix.sh

# Hacer ejecutable y ejecutar
chmod +x quick-vps-fix.sh
./quick-vps-fix.sh
```

## 🔄 Alternativa Directa (Recomendada):

```bash
# Descargar y ejecutar directamente sin Git
cd /var/www/topping-frozen-app
wget -O quick-fix.sh https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/quick-vps-fix.sh
chmod +x quick-fix.sh
./quick-fix.sh
```

## 📋 Comandos Paso a Paso (Copia y Pega):

```bash
cd /var/www/topping-frozen-app
wget -O quick-fix.sh https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/quick-vps-fix.sh
chmod +x quick-fix.sh
./quick-fix.sh
```

## ✅ Esto va a:
- Detener Apache (que está causando el conflicto)
- Recompilar el backend
- Configurar Nginx correctamente
- Reiniciar todos los servicios
- Eliminar el error 502 Bad Gateway

## 🌐 Después podrás acceder a:
- http://46.202.93.54 (Frontend)
- Login: admin / 123456
