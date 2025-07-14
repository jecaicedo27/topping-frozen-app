# 🚀 Instrucciones para Actualizar el Servidor VPS

## Paso 1: Conectar al Servidor VPS

Abre una terminal y conecta a tu servidor:

```bash
ssh root@46.202.93.54
```

## Paso 2: Ir al Directorio del Proyecto

```bash
cd /var/www/topping-frozen-app
```

## Paso 3: Actualizar desde Git

```bash
# Descargar los últimos cambios
git pull origin main

# Hacer los scripts ejecutables
chmod +x fix-server-issues.sh
chmod +x quick-vps-fix.sh
```

## Paso 4: Ejecutar la Corrección Rápida

```bash
sudo ./quick-vps-fix.sh
```

**O si prefieres la corrección completa:**

```bash
sudo ./fix-server-issues.sh
```

## Paso 5: Verificar que Todo Funcione

Después de ejecutar el script, verifica:

```bash
# Ver estado de servicios
sudo systemctl status nginx
sudo systemctl status mysql
pm2 status

# Probar endpoints
curl http://46.202.93.54/api/health
curl http://46.202.93.54
```

## 🌐 URLs para Probar en el Navegador

- **Frontend**: http://46.202.93.54
- **Backend Health**: http://46.202.93.54/api/health
- **phpMyAdmin**: http://46.202.93.54:8080

## 🔐 Credenciales de Prueba

- **Usuario**: admin
- **Contraseña**: 123456

## 🔧 Comandos de Diagnóstico (Si Hay Problemas)

```bash
# Ver logs del backend
pm2 logs topping-frozen-backend --lines 20

# Ver logs de Nginx
sudo tail -f /var/log/nginx/topping-frozen.error.log

# Reiniciar servicios manualmente
sudo systemctl restart nginx
pm2 restart topping-frozen-backend

# Verificar puertos abiertos
sudo netstat -tlnp | grep -E ':(80|3001|8080)'

# Verificar base de datos
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT COUNT(*) FROM users;"
```

## 📋 Resumen de lo que Hace el Script

1. ✅ **Detiene servicios conflictivos** (Apache)
2. ✅ **Libera puertos** ocupados
3. ✅ **Recompila el backend** correctamente
4. ✅ **Reconstruye el frontend** si es necesario
5. ✅ **Configura Nginx** apropiadamente
6. ✅ **Establece variables de entorno** correctas
7. ✅ **Reinicia todos los servicios** con PM2
8. ✅ **Corrige permisos** de archivos
9. ✅ **Verifica que todo funcione** correctamente

## 🚨 Si Algo Sale Mal

### Problema: Backend no inicia
```bash
cd /var/www/topping-frozen-app/backend
npm install
npx tsc
pm2 restart topping-frozen-backend
```

### Problema: Nginx da error
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Problema: Base de datos no conecta
```bash
sudo systemctl restart mysql
mysql -u root -p -e "SHOW DATABASES;"
```

### Problema: Permisos
```bash
sudo chown -R www-data:www-data /var/www/topping-frozen-app
sudo chmod -R 755 /var/www/topping-frozen-app
```

## 📞 Contacto

Si necesitas ayuda adicional, revisa los logs y ejecuta los comandos de diagnóstico mencionados arriba.

---

**¡Listo! Tu servidor debería estar funcionando correctamente después de seguir estos pasos.**
