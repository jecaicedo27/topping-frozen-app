# 🎯 Comandos Finales para Completar la Corrección

## Ya estás conectado al VPS, ahora ejecuta:

```bash
# Asegurarte de estar en el directorio correcto
cd /var/www/topping-frozen-app

# Hacer ejecutables los scripts descargados
chmod +x *.sh

# Ejecutar la corrección rápida
./quick-vps-fix.sh
```

## O ejecutar el script completo de actualización:

```bash
./update-and-fix-server.sh
```

## Después de que termine, verifica:

```bash
# Ver estado de servicios
systemctl status nginx
pm2 status

# Probar endpoints
curl http://46.202.93.54/api/health
curl http://46.202.93.54
```

## 🌐 Probar en el navegador:
- **Frontend**: http://46.202.93.54
- **Login**: admin / 123456

## 🔧 Si hay problemas:
```bash
# Ver logs
pm2 logs topping-frozen-backend --lines 20

# Reiniciar servicios
systemctl restart nginx
pm2 restart topping-frozen-backend
