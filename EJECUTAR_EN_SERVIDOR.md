# 🚀 Cómo Ejecutar en tu Servidor VPS

Guía paso a paso para instalar y configurar tu aplicación Topping Frozen en tu servidor VPS Ubuntu con el dominio apptoppingfrozen.com.

## 📋 **INFORMACIÓN NECESARIA**

Antes de empezar, necesitas:
- **IP de tu VPS:** (ejemplo: 192.168.1.100)
- **Usuario SSH:** root o tu usuario con sudo
- **Contraseña SSH:** de tu VPS
- **Dominio:** apptoppingfrozen.com (ya lo tienes)

---

## 🎯 **OPCIÓN 1: INSTALACIÓN AUTOMÁTICA (RECOMENDADA)**

### **Paso 1: Conectar a tu VPS**
```bash
# Desde tu computadora local (CMD o PowerShell)
ssh root@TU_IP_DEL_VPS

# Ejemplo:
# ssh root@192.168.1.100
```

### **Paso 2: Ejecutar Script de Instalación Automática**
```bash
# Descargar e instalar todo automáticamente
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh
chmod +x install-vps.sh
sudo bash install-vps.sh
```

### **¡Eso es todo! El script instalará:**
- ✅ Node.js, MySQL, Nginx
- ✅ Tu aplicación desde GitHub
- ✅ Base de datos configurada
- ✅ Usuario admin creado
- ✅ Todo funcionando automáticamente

---

## 🎯 **OPCIÓN 2: COMANDO ÚNICO (MÁS RÁPIDO)**

### **Ejecuta este comando único en tu VPS:**
```bash
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
```

---

## 🌐 **CONFIGURAR TU DOMINIO apptoppingfrozen.com**

### **Paso 1: Configurar DNS**
En tu proveedor de dominio, agrega estos registros:

```
Tipo    Nombre    Valor (tu IP del VPS)    TTL
A       @         192.168.1.100           3600
A       www       192.168.1.100           3600
```

### **Paso 2: Instalar SSL (después de la instalación)**
```bash
# Conectar a tu VPS
ssh root@TU_IP_DEL_VPS

# Instalar certificado SSL
sudo apt install -y certbot python3-certbot-nginx
sudo systemctl stop nginx
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
```

### **Paso 3: Configurar Nginx para el dominio**
```bash
# Crear nueva configuración
sudo nano /etc/nginx/sites-available/topping-frozen
```

**Pegar esta configuración:**
```nginx
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    ssl_certificate /etc/letsencrypt/live/apptoppingfrozen.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apptoppingfrozen.com/privkey.pem;

    location / {
        root /home/toppingapp/topping-frozen-app/dist;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /uploads/ {
        alias /home/toppingapp/topping-frozen-app/backend/uploads/;
    }
}
```

### **Paso 4: Activar configuración**
```bash
# Reiniciar Nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# Verificar que funciona
curl -I https://apptoppingfrozen.com
```

---

## 🔧 **COMANDOS ÚTILES PARA TU SERVIDOR**

### **Ver estado de la aplicación:**
```bash
sudo -u toppingapp pm2 status
```

### **Ver logs de la aplicación:**
```bash
sudo -u toppingapp pm2 logs
```

### **Reiniciar aplicación:**
```bash
sudo -u toppingapp pm2 restart topping-backend
```

### **Actualizar aplicación desde GitHub:**
```bash
sudo -u toppingapp /home/toppingapp/deploy.sh
```

### **Ver logs de Nginx:**
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 🎯 **VERIFICAR QUE TODO FUNCIONA**

### **1. Verificar servicios:**
```bash
# MySQL
sudo systemctl status mysql

# Nginx
sudo systemctl status nginx

# Aplicación
sudo -u toppingapp pm2 status
```

### **2. Probar la aplicación:**
```bash
# Probar API
curl http://TU_IP_DEL_VPS/api/health

# O con dominio (después de configurar SSL)
curl https://apptoppingfrozen.com/api/health
```

### **3. Acceder desde el navegador:**
- **Con IP:** `http://TU_IP_DEL_VPS`
- **Con dominio:** `https://apptoppingfrozen.com`

### **4. Login:**
- **Usuario:** admin
- **Contraseña:** 123456

---

## 🆘 **SI ALGO FALLA**

### **Error: No se puede conectar al VPS**
```bash
# Verificar que el VPS esté encendido
# Verificar la IP correcta
# Verificar que SSH esté habilitado
```

### **Error: Script no se descarga**
```bash
# Verificar conexión a internet del VPS
ping google.com

# Instalar wget si no está
sudo apt update
sudo apt install -y wget curl
```

### **Error: MySQL no funciona**
```bash
# Reiniciar MySQL
sudo systemctl restart mysql

# Ver logs
sudo journalctl -u mysql
```

### **Error: Aplicación no inicia**
```bash
# Ver logs detallados
sudo -u toppingapp pm2 logs topping-backend

# Reiniciar aplicación
sudo -u toppingapp pm2 restart topping-backend
```

### **Error: No se puede acceder por dominio**
```bash
# Verificar DNS
nslookup apptoppingfrozen.com

# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx
```

---

## 📱 **RESULTADO FINAL**

Después de ejecutar todo, tendrás:

### **✅ Aplicación funcionando en:**
- **IP:** `http://TU_IP_DEL_VPS`
- **Dominio:** `https://apptoppingfrozen.com`

### **✅ Funcionalidades completas:**
- **Sistema de pedidos** completo
- **Historial de fotos** de recepciones
- **Control de cartera** con timestamps
- **Dashboard** con métricas
- **Login seguro** con roles

### **✅ Infraestructura profesional:**
- **SSL gratuito** con Let's Encrypt
- **Base de datos** MySQL segura
- **Backup automático** configurado
- **Monitoreo** con PM2
- **Logs centralizados**

---

## 🎉 **¡LISTO PARA USAR!**

Tu sistema Topping Frozen estará funcionando profesionalmente en:

**🌐 https://apptoppingfrozen.com**

Con todas las funcionalidades:
- 📸 **Fotos de recepciones** de dinero
- 💰 **Control de cartera** completo
- 📊 **Dashboard** en tiempo real
- 🔐 **Login seguro** (admin/123456)
- 📱 **Responsive** para móviles

**¡Tu negocio digitalizado y en la nube! 🚀**
