# 🌐 Configuración de Dominio y SSL - apptoppingfrozen.com

Guía completa para configurar tu dominio personalizado con certificado SSL gratuito en tu VPS Ubuntu.

## 📋 **INFORMACIÓN DEL DOMINIO**

### **Dominio:** `apptoppingfrozen.com`
### **Subdominio recomendado:** `www.apptoppingfrozen.com`
### **SSL:** Let's Encrypt (Gratuito)

---

## 🎯 **PASO 1: CONFIGURAR DNS**

### **En tu proveedor de dominio (donde compraste apptoppingfrozen.com):**

#### **Registros DNS necesarios:**
```
Tipo    Nombre              Valor               TTL
A       @                   TU_IP_DEL_VPS       3600
A       www                 TU_IP_DEL_VPS       3600
CNAME   api                 apptoppingfrozen.com 3600
```

#### **Ejemplo con IP 192.168.1.100:**
```
A       @                   192.168.1.100       3600
A       www                 192.168.1.100       3600
CNAME   api                 apptoppingfrozen.com 3600
```

### **Verificar propagación DNS:**
```bash
# Verificar desde tu computadora local
nslookup apptoppingfrozen.com
nslookup www.apptoppingfrozen.com

# O usar herramientas online:
# https://dnschecker.org
```

---

## 🔧 **PASO 2: ACTUALIZAR CONFIGURACIÓN DEL VPS**

### **Conectar al VPS:**
```bash
ssh root@TU_IP_DEL_VPS
# O si tienes usuario específico:
ssh usuario@TU_IP_DEL_VPS
```

### **Actualizar variables de entorno:**
```bash
# Cambiar a usuario toppingapp
sudo su - toppingapp

# Editar archivo .env del backend
cd /home/toppingapp/topping-frozen-app/backend
nano .env
```

### **Actualizar .env con el dominio:**
```env
# Database Configuration
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=mi-super-secreto-jwt-vps-2024

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL - ACTUALIZADO CON DOMINIO
FRONTEND_URL=https://apptoppingfrozen.com

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
```

---

## 🌐 **PASO 3: ACTUALIZAR CONFIGURACIÓN DE NGINX**

### **Editar configuración de Nginx:**
```bash
# Volver a usuario root
exit

# Editar configuración
sudo nano /etc/nginx/sites-available/topping-frozen
```

### **Nueva configuración con dominio:**
```nginx
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Redirigir HTTP a HTTPS (se configurará después)
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Certificados SSL (se configurarán con Certbot)
    ssl_certificate /etc/letsencrypt/live/apptoppingfrozen.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apptoppingfrozen.com/privkey.pem;

    # Configuración SSL moderna
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Headers de seguridad
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Servir archivos estáticos del frontend
    location / {
        root /home/toppingapp/topping-frozen-app/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache para archivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Proxy para API del backend
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Servir archivos subidos
    location /uploads/ {
        alias /home/toppingapp/topping-frozen-app/backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs específicos del dominio
    access_log /var/log/nginx/apptoppingfrozen.access.log;
    error_log /var/log/nginx/apptoppingfrozen.error.log;
}
```

---

## 🔒 **PASO 4: INSTALAR CERTIFICADO SSL**

### **Instalar Certbot:**
```bash
# Instalar Certbot y plugin de Nginx
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Verificar instalación
certbot --version
```

### **Obtener certificado SSL:**
```bash
# Detener Nginx temporalmente
sudo systemctl stop nginx

# Obtener certificado para el dominio principal y www
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com

# Seguir las instrucciones:
# 1. Ingresar email para notificaciones
# 2. Aceptar términos de servicio
# 3. Decidir si compartir email con EFF (opcional)
```

### **Verificar certificados:**
```bash
# Verificar que los certificados se crearon
sudo ls -la /etc/letsencrypt/live/apptoppingfrozen.com/

# Deberías ver:
# cert.pem -> ../../archive/apptoppingfrozen.com/cert1.pem
# chain.pem -> ../../archive/apptoppingfrozen.com/chain1.pem
# fullchain.pem -> ../../archive/apptoppingfrozen.com/fullchain1.pem
# privkey.pem -> ../../archive/apptoppingfrozen.com/privkey1.pem
```

---

## 🔄 **PASO 5: APLICAR CONFIGURACIÓN**

### **Verificar y reiniciar Nginx:**
```bash
# Verificar configuración de Nginx
sudo nginx -t

# Si todo está bien, reiniciar Nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# Verificar estado
sudo systemctl status nginx
```

### **Reiniciar aplicación con nuevo dominio:**
```bash
# Cambiar a usuario toppingapp
sudo su - toppingapp

# Reiniciar aplicación para aplicar nuevas variables de entorno
cd /home/toppingapp/topping-frozen-app
pm2 restart topping-backend

# Verificar estado
pm2 status
```

---

## 🔄 **PASO 6: CONFIGURAR RENOVACIÓN AUTOMÁTICA SSL**

### **Configurar cron para renovación automática:**
```bash
# Volver a usuario root
exit

# Editar crontab
sudo crontab -e

# Agregar línea para renovación automática (2 veces al día)
0 12,0 * * * /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
```

### **Probar renovación:**
```bash
# Probar renovación en modo dry-run
sudo certbot renew --dry-run

# Debería mostrar: "Congratulations, all renewals succeeded"
```

---

## 🌐 **PASO 7: VERIFICACIÓN FINAL**

### **Probar el sitio web:**
```bash
# Desde el VPS, probar conectividad
curl -I https://apptoppingfrozen.com
curl -I https://www.apptoppingfrozen.com
curl -I https://apptoppingfrozen.com/api/health
```

### **Verificar SSL:**
```bash
# Verificar certificado SSL
openssl s_client -connect apptoppingfrozen.com:443 -servername apptoppingfrozen.com
```

---

## 📱 **PASO 8: ACTUALIZAR FRONTEND (OPCIONAL)**

### **Si quieres actualizar URLs en el frontend:**
```bash
# Cambiar a usuario toppingapp
sudo su - toppingapp
cd /home/toppingapp/topping-frozen-app

# Editar archivo de configuración API
nano src/services/api.ts
```

### **Actualizar baseURL en api.ts:**
```typescript
// Cambiar de:
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'http://TU_IP_DEL_VPS/api' 
  : 'http://localhost:3001/api';

// A:
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://apptoppingfrozen.com/api' 
  : 'http://localhost:3001/api';
```

### **Recompilar frontend:**
```bash
# Recompilar frontend con nueva configuración
npm run build:frontend

# Reiniciar aplicación
pm2 restart topping-backend
```

---

## 🎯 **URLS FINALES**

### **Tu aplicación estará disponible en:**
- **Principal:** https://apptoppingfrozen.com
- **Con www:** https://www.apptoppingfrozen.com
- **API:** https://apptoppingfrozen.com/api

### **Redirecciones automáticas:**
- `http://apptoppingfrozen.com` → `https://apptoppingfrozen.com`
- `http://www.apptoppingfrozen.com` → `https://www.apptoppingfrozen.com`

---

## 🔧 **COMANDOS ÚTILES**

### **Verificar estado de servicios:**
```bash
# Estado de Nginx
sudo systemctl status nginx

# Estado de la aplicación
sudo -u toppingapp pm2 status

# Ver logs de Nginx
sudo tail -f /var/log/nginx/apptoppingfrozen.access.log
sudo tail -f /var/log/nginx/apptoppingfrozen.error.log

# Ver logs de la aplicación
sudo -u toppingapp pm2 logs topping-backend
```

### **Verificar certificados SSL:**
```bash
# Ver información del certificado
sudo certbot certificates

# Renovar manualmente
sudo certbot renew

# Verificar configuración SSL online
# https://www.ssllabs.com/ssltest/
```

---

## 🆘 **TROUBLESHOOTING**

### **Problema: DNS no resuelve**
```bash
# Verificar propagación DNS
nslookup apptoppingfrozen.com
dig apptoppingfrozen.com

# Esperar hasta 24-48 horas para propagación completa
```

### **Problema: Error de certificado SSL**
```bash
# Verificar que Nginx esté detenido antes de obtener certificado
sudo systemctl stop nginx
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
sudo systemctl start nginx
```

### **Problema: 502 Bad Gateway**
```bash
# Verificar que la aplicación esté corriendo
sudo -u toppingapp pm2 status

# Reiniciar aplicación
sudo -u toppingapp pm2 restart topping-backend

# Verificar logs
sudo -u toppingapp pm2 logs topping-backend
```

---

## 🎉 **¡DOMINIO CONFIGURADO!**

Una vez completados estos pasos, tendrás:

- ✅ **Dominio personalizado:** apptoppingfrozen.com
- ✅ **SSL gratuito** con Let's Encrypt
- ✅ **Renovación automática** de certificados
- ✅ **Redirección HTTP → HTTPS** automática
- ✅ **Headers de seguridad** configurados
- ✅ **Cache optimizado** para archivos estáticos

**¡Tu aplicación Topping Frozen ahora tiene un dominio profesional con SSL! 🚀**
