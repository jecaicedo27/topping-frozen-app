# 🔧 Solución para Problema de Permisos en Git

## El problema:
Git detectó "dubious ownership" en el repositorio porque el directorio pertenece a un usuario diferente.

## 🚀 Solución Rápida - Ejecuta estos comandos en el VPS:

```bash
# Configurar Git para confiar en el directorio
git config --global --add safe.directory /var/www/topping-frozen-app

# Cambiar propietario del directorio
chown -R root:root /var/www/topping-frozen-app

# Actualizar desde Git
git pull origin main

# Verificar que los archivos se descargaron
ls -la *.sh

# Hacer ejecutables
chmod +x *.sh

# Ejecutar corrección
./quick-vps-fix.sh
```

## 🔄 Alternativa - Descargar directamente:

Si Git sigue dando problemas, descarga el script directamente:

```bash
# Descargar script directamente
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/quick-vps-fix.sh

# Hacer ejecutable
chmod +x quick-vps-fix.sh

# Ejecutar
./quick-vps-fix.sh
```

## 📋 Comandos paso a paso (copia y pega):

```bash
git config --global --add safe.directory /var/www/topping-frozen-app
chown -R root:root /var/www/topping-frozen-app
git pull origin main
chmod +x *.sh
./quick-vps-fix.sh
