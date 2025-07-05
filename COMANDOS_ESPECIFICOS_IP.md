# 🚀 Comandos Específicos para tu VPS - IP: 46.202.93.54

Guía con comandos exactos para instalar tu aplicación Topping Frozen en tu servidor.

## 📋 **TU INFORMACIÓN**

- **IP del VPS:** 46.202.93.54
- **Dominio:** apptoppingfrozen.com
- **Usuario:** root (probablemente)

---

## 🎯 **PASO 1: CONECTAR A TU VPS**

### **Desde tu computadora (CMD o PowerShell):**
```bash
ssh root@46.202.93.54
```

**Te pedirá la contraseña de tu VPS. Ingrésala y presiona Enter.**

---

## 🚀 **PASO 2: INSTALAR APLICACIÓN (COMANDO ÚNICO)**

### **Una vez conectado al VPS, ejecuta:**
```bash
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
```

### **O si prefieres paso a paso:**
```bash
# Descargar script
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh

# Dar permisos
chmod +x install-vps.sh

# Ejecutar
sudo bash install-vps.sh
```

---

## 🌐 **PASO 3: CONFIGURAR DNS PARA apptoppingfrozen.com**

### **En tu proveedor de dominio, agrega estos registros:**

```
Tipo    Nombre    Valor           TTL
A       @         46.202.93.54    3600
A       www       46.202.93.54    3600
```

### **Verificar DNS (desde tu computadora):**
```bash
nslookup apptoppingfrozen.com
nslookup www.apptoppingfrozen.com
```

---

## 🔒 **PASO 4: CONFIGURAR SSL (DESPUÉS DE LA INSTALACIÓN)**

### **En tu VPS (después del paso 2):**
```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Detener Nginx temporalmente
sudo systemctl stop nginx

# Obtener certificado SSL
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com

# Configurar Nginx para el dominio
sudo nano /etc/nginx/sites-available/topping-frozen
```

### **Pegar esta configuración en el archivo:**
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

### **Reiniciar Nginx:**
```bash
# Verificar configuración
sudo nginx -t

# Iniciar Nginx
sudo systemctl start nginx
sudo systemctl reload nginx
```

---

## 🎯 **VERIFICAR QUE TODO FUNCIONA**

### **1. Probar con IP:**
```bash
# Desde tu VPS
curl http://46.202.93.54

# Desde tu computadora
# Abrir navegador: http://46.202.93.54
```

### **2. Probar con dominio (después de configurar DNS y SSL):**
```bash
# Desde tu VPS
curl https://apptoppingfrozen.com

# Desde tu computadora
# Abrir navegador: https://apptoppingfrozen.com
```

### **3. Verificar servicios:**
```bash
# Estado de la aplicación
sudo -u toppingapp pm2 status

# Estado de MySQL
sudo systemctl status mysql

# Estado de Nginx
sudo systemctl status nginx
```

---

## 🔧 **COMANDOS ÚTILES PARA TU SERVIDOR**

### **Ver logs de la aplicación:**
```bash
sudo -u toppingapp pm2 logs
```

### **Reiniciar aplicación:**
```bash
sudo -u toppingapp pm2 restart topping-backend
```

### **Ver logs de Nginx:**
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### **Actualizar aplicación desde GitHub:**
```bash
sudo -u toppingapp /home/toppingapp/deploy.sh
```

---

## 📱 **URLS FINALES**

### **Acceso por IP:**
- **Frontend:** http://46.202.93.54
- **API:** http://46.202.93.54/api

### **Acceso por dominio (después de configurar DNS y SSL):**
- **Frontend:** https://apptoppingfrozen.com
- **API:** https://apptoppingfrozen.com/api

### **Login:**
- **Usuario:** admin
- **Contraseña:** 123456

---

## 🆘 **SI ALGO FALLA**

### **Error de conexión SSH:**
```bash
# Verificar que el VPS esté encendido
# Verificar la contraseña
# Intentar con usuario diferente si root no funciona:
ssh ubuntu@46.202.93.54
```

### **Error en la instalación:**
```bash
# Ver logs del script
sudo journalctl -f

# Verificar conexión a internet
ping google.com

# Actualizar sistema
sudo apt update && sudo apt upgrade -y
```

### **Error de DNS:**
```bash
# Esperar propagación (puede tomar hasta 24 horas)
# Verificar configuración en el panel de dominio
nslookup apptoppingfrozen.com
```

---

## 🎉 **RESUMEN DE COMANDOS COMPLETOS**

### **Todo en secuencia:**
```bash
# 1. Conectar al VPS
ssh root@46.202.93.54

# 2. Instalar aplicación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash

# 3. Configurar SSL (después de configurar DNS)
sudo apt install -y certbot python3-certbot-nginx
sudo systemctl stop nginx
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com

# 4. Configurar Nginx (usar la configuración de arriba)
sudo nano /etc/nginx/sites-available/topping-frozen

# 5. Reiniciar servicios
sudo nginx -t
sudo systemctl start nginx
sudo systemctl reload nginx

# 6. Verificar
curl https://apptoppingfrozen.com
```

---

## 🎯 **PRÓXIMOS PASOS**

1. **Ejecutar el comando de instalación** en tu VPS
2. **Configurar DNS** en tu proveedor de dominio
3. **Configurar SSL** una vez que DNS esté propagado
4. **¡Disfrutar tu aplicación en la nube!**

**Tu aplicación estará disponible en:**
- **IP:** http://46.202.93.54
- **Dominio:** https://apptoppingfrozen.com

**¡Con todas las funcionalidades de fotos, cartera y gestión de pedidos! 🚀**
