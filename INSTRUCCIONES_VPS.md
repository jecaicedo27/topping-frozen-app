# 🚀 Instrucciones Rápidas para Desplegar en VPS Hostinger

## 📋 Pasos Simples para Desplegar tu Aplicación

### 1️⃣ **Conectar al VPS**
```bash
# Conectar via SSH (reemplaza con tu IP)
ssh root@TU_IP_DEL_VPS
```

### 2️⃣ **Descargar y Ejecutar Script Automático**
```bash
# Descargar el script de despliegue
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/deploy-to-vps.sh

# Hacer ejecutable
chmod +x deploy-to-vps.sh

# Ejecutar instalación automática
./deploy-to-vps.sh
```

### 3️⃣ **Información que te Pedirá el Script**
- **Usuario MySQL:** `appuser` (recomendado)
- **Contraseña MySQL:** Una contraseña segura
- **JWT Secret:** Mínimo 32 caracteres aleatorios
- **Dominio/IP:** Tu dominio o IP del servidor

### 4️⃣ **Configurar SSL (Opcional pero Recomendado)**
```bash
# Si tienes un dominio configurado
./setup-ssl.sh
```

### 5️⃣ **Verificar que Todo Funcione**
- Visita: `http://TU_IP_O_DOMINIO`
- Login: `admin` / `123456`

---

## 🔧 Comandos Útiles Post-Instalación

### **Monitoreo de la Aplicación**
```bash
# Ver estado de la aplicación
pm2 status

# Ver logs en tiempo real
pm2 logs

# Monitoreo completo
pm2 monit
```

### **Gestión de Servicios**
```bash
# Reiniciar aplicación
pm2 restart gestion-pedidos-backend

# Reiniciar Nginx
sudo systemctl restart nginx

# Reiniciar MySQL
sudo systemctl restart mysql
```

### **Actualizar la Aplicación**
```bash
# Ir al directorio de la aplicación
cd /home/topping-frozen-app

# Ejecutar script de actualización
./update-app.sh
```

### **Ver Logs del Sistema**
```bash
# Logs de Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs de MySQL
sudo tail -f /var/log/mysql/error.log

# Uso de recursos del servidor
htop
```

---

## 🆘 Solución de Problemas

### **La aplicación no carga**
```bash
# Verificar estado de PM2
pm2 status

# Ver logs de errores
pm2 logs gestion-pedidos-backend

# Reiniciar aplicación
pm2 restart gestion-pedidos-backend
```

### **Error 502 Bad Gateway**
```bash
# Verificar que el backend esté corriendo
pm2 status

# Verificar configuración de Nginx
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

### **Error de Base de Datos**
```bash
# Verificar estado de MySQL
sudo systemctl status mysql

# Conectar a MySQL para verificar
mysql -u appuser -p gestionPedidos
```

### **Problemas de Permisos**
```bash
# Ajustar permisos de archivos
sudo chown -R www-data:www-data /home/topping-frozen-app
sudo chmod -R 755 /home/topping-frozen-app
```

---

## 📊 Información del Sistema

### **Archivos Importantes**
- **Aplicación:** `/home/topping-frozen-app/`
- **Configuración Nginx:** `/etc/nginx/sites-available/gestion-pedidos`
- **Logs Nginx:** `/var/log/nginx/`
- **Variables de entorno:** `/home/topping-frozen-app/.env`

### **Puertos Utilizados**
- **80:** HTTP (Nginx)
- **443:** HTTPS (Nginx + SSL)
- **5000:** Backend Node.js (interno)
- **3306:** MySQL (interno)

### **Servicios Activos**
- **nginx:** Servidor web
- **mysql:** Base de datos
- **pm2:** Gestor de procesos Node.js

---

## 🔐 Seguridad Post-Instalación

### **Tareas Importantes**
1. **Cambiar contraseña admin:** Login → Configuración → Cambiar contraseña
2. **Configurar SSL:** Ejecutar `./setup-ssl.sh` si tienes dominio
3. **Configurar MySQL:** Ejecutar `sudo mysql_secure_installation`
4. **Actualizar sistema:** `sudo apt update && sudo apt upgrade`

### **Firewall Configurado**
- SSH (22) ✅
- HTTP (80) ✅  
- HTTPS (443) ✅
- Otros puertos bloqueados ✅

---

## 📞 Soporte

### **Si necesitas ayuda:**
1. Revisa los logs: `pm2 logs`
2. Verifica servicios: `sudo systemctl status nginx mysql`
3. Consulta esta documentación
4. Contacta soporte técnico

---

**¡Tu aplicación está lista para producción! 🎉**

### **Credenciales por Defecto:**
- **URL:** http://TU_IP_O_DOMINIO
- **Usuario:** admin
- **Contraseña:** 123456

**⚠️ IMPORTANTE: Cambia la contraseña después del primer login**
