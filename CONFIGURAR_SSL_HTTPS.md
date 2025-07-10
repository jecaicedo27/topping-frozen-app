# 🔒 Configurar SSL/HTTPS - apptoppingfrozen.com

Guía paso a paso para configurar certificado SSL gratuito y tener HTTPS funcionando.

## 📋 **ESTADO ACTUAL**

### **✅ Lo que funciona:**
- **HTTP funcionando** ✅ (http://apptoppingfrozen.com)
- **Aplicación corriendo** ✅
- **DNS configurado** ✅
- **Nginx funcionando** ✅

### **🎯 Objetivo:**
- **HTTPS funcionando** con candado verde
- **Certificado SSL** válido y gratuito
- **Redirección automática** HTTP → HTTPS

---

## 🚀 **CONFIGURAR SSL PASO A PASO**

### **PASO 1: Instalar Certbot**
```bash
# Instalar Certbot y plugin de Nginx
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

### **PASO 2: Obtener certificado SSL**
```bash
# Detener Nginx temporalmente
sudo systemctl stop nginx

# Obtener certificado para tu dominio
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com

# Seguir las instrucciones:
# 1. Ingresar tu email para notificaciones
# 2. Aceptar términos de servicio (Y)
# 3. Compartir email con EFF (Y/N - opcional)
```

### **PASO 3: Configurar Nginx con SSL**
```bash
# Editar configuración de Nginx
sudo nano /etc/nginx/sites-available/topping-frozen
```

### **Reemplazar toda la configuración con esta:**
```nginx
# Redirección HTTP a HTTPS
server {
    listen 80;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;
    return 301 https://$server_name$request_uri;
}

# Configuración HTTPS
server {
    listen 443 ssl http2;
    server_name apptoppingfrozen.com www.apptoppingfrozen.com;

    # Certificados SSL
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

    # Configuración de la aplicación
    root /home/toppingapp/topping-frozen-app/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }

    location /uploads/ {
        alias /home/toppingapp/topping-frozen-app/backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs
    error_log /var/log/nginx/topping-frozen-ssl.error.log;
    access_log /var/log/nginx/topping-frozen-ssl.access.log;
}
```

### **PASO 4: Verificar y reiniciar Nginx**
```bash
# Verificar configuración
sudo nginx -t

# Si todo está bien, iniciar Nginx
sudo systemctl start nginx
sudo systemctl reload nginx
```

### **PASO 5: Configurar renovación automática**
```bash
# Editar crontab para renovación automática
sudo crontab -e

# Agregar esta línea al final:
0 12 * * * /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
```

---

## 🔍 **VERIFICACIÓN**

### **Probar HTTPS:**
```bash
# Desde el VPS
curl -I https://apptoppingfrozen.com

# Verificar certificado
openssl s_client -connect apptoppingfrozen.com:443 -servername apptoppingfrozen.com
```

### **En tu navegador:**
- **https://apptoppingfrozen.com** ← Debe mostrar candado verde
- **http://apptoppingfrozen.com** ← Debe redirigir a HTTPS

---

## 🆘 **TROUBLESHOOTING**

### **Error: "Failed to obtain certificate"**
```bash
# Verificar que el puerto 80 esté libre
sudo netstat -tlnp | grep :80

# Asegurar que Nginx esté detenido
sudo systemctl stop nginx

# Intentar de nuevo
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
```

### **Error: "Certificate not found"**
```bash
# Verificar que los certificados existen
sudo ls -la /etc/letsencrypt/live/apptoppingfrozen.com/

# Debe mostrar:
# fullchain.pem
# privkey.pem
```

### **Error: "Nginx configuration test failed"**
```bash
# Verificar sintaxis
sudo nginx -t

# Ver errores específicos
sudo journalctl -u nginx
```

---

## ⚡ **COMANDOS RÁPIDOS PARA EJECUTAR**

```bash
# 1. Instalar Certbot
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# 2. Detener Nginx
sudo systemctl stop nginx

# 3. Obtener certificado
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com

# 4. Configurar Nginx (usar la configuración de arriba)
sudo nano /etc/nginx/sites-available/topping-frozen

# 5. Verificar y reiniciar
sudo nginx -t
sudo systemctl start nginx
```

---

## 🎯 **RESULTADO ESPERADO**

Después de configurar SSL:

### **✅ URLs con HTTPS:**
- **https://apptoppingfrozen.com** ← Con candado verde
- **https://www.apptoppingfrozen.com** ← Con candado verde

### **✅ Redirecciones automáticas:**
- **http://apptoppingfrozen.com** → **https://apptoppingfrozen.com**
- **http://www.apptoppingfrozen.com** → **https://www.apptoppingfrozen.com**

### **✅ Seguridad:**
- **Certificado válido** Let's Encrypt
- **Renovación automática** cada 90 días
- **Headers de seguridad** configurados
- **Protocolo TLS 1.2/1.3** moderno

---

## 🎉 **¡HTTPS FUNCIONANDO!**

Una vez completado:

### **🔒 Tu aplicación será:**
- **Completamente segura** con HTTPS
- **Confiable** con candado verde
- **SEO optimizada** (Google prefiere HTTPS)
- **Profesional** con certificado válido

**¡Ejecuta los comandos y tendrás HTTPS funcionando en 10 minutos! 🚀**
