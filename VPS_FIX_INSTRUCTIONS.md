# Instrucciones para Corregir el Servidor VPS

## Paso 1: Conectar al VPS via SSH

Abre una terminal (PowerShell, CMD, o Git Bash) en Windows y conecta a tu VPS:

```bash
ssh root@46.202.93.54
```

O si tienes un usuario específico:
```bash
ssh usuario@46.202.93.54
```

## Paso 2: Ir al directorio del proyecto

Una vez conectado al VPS, navega al directorio del proyecto:

```bash
cd /var/www/topping-frozen-app
```

## Paso 3: Crear el script de corrección

Crea el archivo de corrección directamente en el VPS:

```bash
nano fix-server-issues.sh
```

Luego copia y pega todo el contenido del script que está en tu archivo local `fix-server-issues.sh`.

## Paso 4: Hacer el script ejecutable

```bash
chmod +x fix-server-issues.sh
```

## Paso 5: Ejecutar el script de corrección

```bash
sudo ./fix-server-issues.sh
```

## Paso 6: Verificar que todo funcione

Después de que el script termine, verifica:

```bash
# Verificar estado de servicios
sudo systemctl status nginx
sudo systemctl status mysql
pm2 status

# Probar endpoints
curl http://46.202.93.54/api/health
curl http://46.202.93.54

# Ver logs si hay problemas
pm2 logs topping-frozen-backend
sudo tail -f /var/log/nginx/topping-frozen.error.log
```

## URLs para probar en el navegador:

- **Frontend**: http://46.202.93.54
- **Backend Health**: http://46.202.93.54/api/health
- **phpMyAdmin**: http://46.202.93.54:8080

## Credenciales de prueba:

- **Usuario**: admin
- **Contraseña**: 123456

## Si necesitas ayuda adicional:

1. **Ver logs del backend**:
   ```bash
   pm2 logs topping-frozen-backend --lines 50
   ```

2. **Reiniciar servicios**:
   ```bash
   sudo systemctl restart nginx
   pm2 restart topping-frozen-backend
   ```

3. **Verificar puertos**:
   ```bash
   sudo netstat -tlnp | grep -E ':(80|3001|8080)'
   ```

## Problemas comunes y soluciones:

### Si el backend no inicia:
```bash
cd /var/www/topping-frozen-app/backend
npm install
npx tsc
pm2 restart topping-frozen-backend
```

### Si nginx da error:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Si la base de datos no conecta:
```bash
mysql -u toppinguser -pToppingPass2024! topping_frozen_db -e "SELECT 1;"
