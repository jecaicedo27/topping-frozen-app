# 🔧 Solucionar "ERR_CONNECTION_TIMED_OUT" - apptoppingfrozen.com

El dominio está resolviendo correctamente, pero el servidor no responde. Aquí está la solución paso a paso.

## 📋 **DIAGNÓSTICO ACTUAL**

### **✅ Lo que funciona:**
- **DNS configurado correctamente** (el dominio aparece en el navegador)
- **Namecheap configurado bien** (apptoppingfrozen.com → 46.202.93.54)

### **❌ El problema:**
- **Servidor no responde** en los puertos 80/443
- **Aplicación no instalada** en el VPS
- **Nginx no está corriendo** o no configurado

---

## 🚀 **SOLUCIÓN: INSTALAR APLICACIÓN EN VPS**

### **PASO 1: Conectar al VPS**
```bash
# Desde tu computadora (CMD o PowerShell)
ssh root@46.202.93.54
```

### **PASO 2: Verificar estado del servidor**
```bash
# Una vez conectado al VPS, verificar servicios
systemctl status nginx
systemctl status mysql

# Si no están instalados, verás errores
```

### **PASO 3: Instalar aplicación automáticamente**
```bash
# Ejecutar script de instalación completa
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
```

### **PASO 4: Verificar instalación**
```bash
# Verificar que Nginx esté corriendo
systemctl status nginx

# Verificar que la aplicación esté corriendo
sudo -u toppingapp pm2 status

# Probar desde el servidor
curl http://localhost
```

---

## 🔧 **DIAGNÓSTICO DETALLADO**

### **Verificar conectividad básica:**
```bash
# Desde tu computadora, probar ping
ping 46.202.93.54

# Probar puertos específicos
telnet 46.202.93.54 80
telnet 46.202.93.54 443
telnet 46.202.93.54 22
```

### **Si ping funciona pero puertos no:**
- **Puerto 22 (SSH):** Debe funcionar (ya te conectaste)
- **Puerto 80 (HTTP):** No funciona → Nginx no instalado/corriendo
- **Puerto 443 (HTTPS):** No funciona → SSL no configurado

---

## 🎯 **INSTALACIÓN PASO A PASO**

### **1. Conectar al VPS:**
```bash
ssh root@46.202.93.54
# Ingresar contraseña cuando te la pida
```

### **2. Actualizar sistema:**
```bash
sudo apt update && sudo apt upgrade -y
```

### **3. Instalar aplicación:**
```bash
# Opción A: Script automático (recomendado)
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash

# Opción B: Paso a paso
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh
chmod +x install-vps.sh
sudo bash install-vps.sh
```

### **4. Configurar Nginx para el dominio:**
```bash
# Editar configuración de Nginx
sudo nano /etc/nginx/sites-available/topping-frozen
```

**Pegar esta configuración:**
```nginx
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com 46.202.93.54;

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

### **5. Activar configuración:**
```bash
# Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# Remover sitio por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### **6. Verificar firewall:**
```bash
# Verificar estado del firewall
sudo ufw status

# Permitir puertos necesarios
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable
```

---

## 🔍 **VERIFICACIÓN FINAL**

### **Desde el VPS:**
```bash
# Probar que Nginx responde
curl http://localhost
curl http://46.202.93.54

# Verificar servicios
systemctl status nginx
systemctl status mysql
sudo -u toppingapp pm2 status
```

### **Desde tu computadora:**
```bash
# Probar conectividad
curl -I http://46.202.93.54
curl -I http://apptoppingfrozen.com

# En navegador:
# http://46.202.93.54
# http://apptoppingfrozen.com
```

---

## 🆘 **TROUBLESHOOTING ESPECÍFICO**

### **Error: "Connection refused"**
```bash
# Nginx no está corriendo
sudo systemctl start nginx
sudo systemctl enable nginx
```

### **Error: "No route to host"**
```bash
# Firewall bloqueando
sudo ufw allow 80
sudo ufw allow 443
sudo ufw reload
```

### **Error: "Permission denied"**
```bash
# Problemas de permisos
sudo chown -R www-data:www-data /home/toppingapp/topping-frozen-app/dist
sudo chmod -R 755 /home/toppingapp/topping-frozen-app/dist
```

### **Error: Script no se descarga**
```bash
# Problemas de conectividad del VPS
ping google.com

# Instalar herramientas básicas
sudo apt update
sudo apt install -y curl wget git
```

---

## ⏱️ **TIEMPO ESTIMADO**

### **Instalación completa:** 15-30 minutos
### **Verificación:** 5 minutos
### **Total:** 20-35 minutos

---

## 🎯 **RESULTADO ESPERADO**

Después de la instalación:

### **✅ URLs funcionando:**
- **http://46.202.93.54** ← Debe cargar la aplicación
- **http://apptoppingfrozen.com** ← Debe cargar la aplicación

### **✅ Login disponible:**
- **Usuario:** admin
- **Contraseña:** 123456

### **✅ Servicios corriendo:**
- **Nginx:** Servidor web
- **MySQL:** Base de datos
- **PM2:** Aplicación Node.js

---

## 🚀 **PRÓXIMO PASO: SSL**

Una vez que la aplicación funcione en HTTP:

```bash
# Instalar SSL para HTTPS
sudo apt install -y certbot python3-certbot-nginx
sudo systemctl stop nginx
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
sudo systemctl start nginx
```

---

## 🎉 **¡EMPEZAR AHORA!**

**Ejecuta estos comandos en orden:**

1. **Conectar al VPS:**
   ```bash
   ssh root@46.202.93.54
   ```

2. **Instalar aplicación:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
   ```

3. **Probar en navegador:**
   - http://46.202.93.54
   - http://apptoppingfrozen.com

**¡El error de timeout se solucionará una vez que instales la aplicación! 🚀**
