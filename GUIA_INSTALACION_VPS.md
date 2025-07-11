# 🚀 Guía de Instalación en VPS Ubuntu

Esta guía te ayudará a instalar la aplicación Topping Frozen en tu servidor VPS Ubuntu de manera automatizada.

## 📋 Requisitos Previos

- **VPS Ubuntu 20.04 o superior**
- **Acceso SSH al servidor**
- **Usuario con permisos sudo** (no root)
- **Al menos 2GB de RAM** (recomendado)
- **10GB de espacio libre** en disco

## 🔧 Paso 1: Conectar al VPS

Conéctate a tu VPS usando SSH:

```bash
ssh usuario@tu-ip-del-vps
```

Reemplaza:
- `usuario`: Tu nombre de usuario en el VPS
- `tu-ip-del-vps`: La dirección IP de tu servidor

## 📥 Paso 2: Descargar el Script de Instalación

Una vez conectado al VPS, descarga el script de instalación:

```bash
# Descargar el script desde GitHub
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh

# Dar permisos de ejecución
chmod +x install-vps-ubuntu.sh
```

## ⚡ Paso 3: Ejecutar la Instalación

Ejecuta el script de instalación:

```bash
./install-vps-ubuntu.sh
```

### ⏱️ Tiempo de Instalación
La instalación completa toma aproximadamente **15-20 minutos** dependiendo de la velocidad de tu VPS.

### 🔐 Configuración de MySQL
Durante la instalación, se te pedirá configurar MySQL:

1. **Contraseña de root**: Elige una contraseña segura
2. **Eliminar usuarios anónimos**: Presiona `Y`
3. **Deshabilitar login remoto de root**: Presiona `Y`
4. **Eliminar base de datos de prueba**: Presiona `Y`
5. **Recargar tablas de privilegios**: Presiona `Y`

## 🎯 Paso 4: Verificar la Instalación

Después de la instalación, verifica que todo esté funcionando:

### Verificar servicios:
```bash
# Estado de la aplicación
pm2 status

# Estado de Nginx
sudo systemctl status nginx

# Estado de MySQL
sudo systemctl status mysql
```

### Verificar la aplicación:
- **Frontend**: `http://tu-ip-del-vps`
- **API Backend**: `http://tu-ip-del-vps/api`

## 📊 Información de la Base de Datos

El script crea automáticamente:
- **Base de datos**: `topping_frozen`
- **Usuario**: `toppinguser`
- **Contraseña**: `ToppingFrozen2024!`

## 🛠️ Comandos Útiles Post-Instalación

### Gestión de la aplicación con PM2:
```bash
# Ver estado
pm2 status

# Ver logs
pm2 logs topping-frozen-backend

# Reiniciar aplicación
pm2 restart topping-frozen-backend

# Parar aplicación
pm2 stop topping-frozen-backend

# Iniciar aplicación
pm2 start topping-frozen-backend
```

### Gestión de Nginx:
```bash
# Reiniciar Nginx
sudo systemctl restart nginx

# Ver estado
sudo systemctl status nginx

# Ver logs de error
sudo tail -f /var/log/nginx/error.log
```

### Gestión de MySQL:
```bash
# Conectar a MySQL
mysql -u toppinguser -p topping_frozen

# Ver logs de MySQL
sudo tail -f /var/log/mysql/error.log
```

## 🔒 Configuración de Seguridad (Recomendado)

### 1. Cambiar contraseñas por defecto:
```bash
# Cambiar contraseña de la base de datos
mysql -u root -p
ALTER USER 'toppinguser'@'localhost' IDENTIFIED BY 'tu_nueva_contraseña_segura';
FLUSH PRIVILEGES;
EXIT;

# Actualizar archivo .env del backend
sudo nano /var/www/topping-frozen/backend/.env
# Cambiar DB_PASSWORD y JWT_SECRET
```

### 2. Configurar firewall adicional:
```bash
# Cerrar puertos innecesarios
sudo ufw deny 3000
sudo ufw deny 5000
sudo ufw reload
```

## 🌐 Configurar Dominio (Opcional)

Si tienes un dominio, edita la configuración de Nginx:

```bash
sudo nano /etc/nginx/sites-available/topping-frozen
```

Cambia `server_name _;` por `server_name tu-dominio.com www.tu-dominio.com;`

Luego reinicia Nginx:
```bash
sudo systemctl restart nginx
```

## 🔐 Instalar SSL/HTTPS con Let's Encrypt

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obtener certificado SSL
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# Configurar renovación automática
sudo crontab -e
# Agregar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📱 Acceder a la Aplicación

Una vez completada la instalación:

1. **Abre tu navegador**
2. **Ve a**: `http://tu-ip-del-vps` (o tu dominio)
3. **Deberías ver la aplicación Topping Frozen**

### Credenciales por defecto:
- **Usuario**: `admin`
- **Contraseña**: `123456`

⚠️ **IMPORTANTE**: Cambia estas credenciales inmediatamente después del primer login.

## 🆘 Solución de Problemas

### La aplicación no carga:
```bash
# Verificar logs
pm2 logs topping-frozen-backend
sudo tail -f /var/log/nginx/error.log
```

### Error de base de datos:
```bash
# Verificar conexión a MySQL
mysql -u toppinguser -p topping_frozen
```

### Error 502 Bad Gateway:
```bash
# Verificar que el backend esté corriendo
pm2 status
pm2 restart topping-frozen-backend
```

## 📞 Soporte

Si encuentras problemas durante la instalación:

1. **Revisa los logs** con los comandos mencionados arriba
2. **Verifica que todos los servicios estén corriendo**
3. **Asegúrate de que los puertos estén abiertos**

## 🎉 ¡Listo!

Tu aplicación Topping Frozen ahora está instalada y ejecutándose en tu VPS Ubuntu. 

**Próximos pasos recomendados:**
- [ ] Cambiar contraseñas por defecto
- [ ] Configurar dominio personalizado
- [ ] Instalar certificado SSL
- [ ] Configurar backups automáticos
- [ ] Monitorear el rendimiento del servidor
