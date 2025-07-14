# 🖥️ Configuración VPS Ubuntu - Topping Frozen

Guía completa para configurar tu VPS Ubuntu desde cero y desplegar la aplicación Topping Frozen.

## 📋 **REQUISITOS DEL VPS**

### **Especificaciones Mínimas:**
- **OS:** Ubuntu 20.04 LTS o superior
- **RAM:** 2GB mínimo (4GB recomendado)
- **Storage:** 20GB mínimo
- **CPU:** 1 vCore mínimo (2 vCores recomendado)

---

## 🚀 **PASO 1: CONEXIÓN INICIAL AL VPS**

### **Conectar por SSH:**
```bash
# Desde tu computadora local
ssh root@TU_IP_DEL_VPS

# O si tienes usuario específico:
ssh usuario@TU_IP_DEL_VPS
```

### **Actualizar Sistema:**
```bash
# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar herramientas básicas
sudo apt install -y curl wget git unzip software-properties-common
```

---

## 🔧 **PASO 2: INSTALAR NODE.JS**

### **Instalar Node.js 18 LTS:**
```bash
# Agregar repositorio NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Instalar Node.js
sudo apt install -y nodejs

# Verificar instalación
node --version
npm --version
```

### **Instalar PM2 (Process Manager):**
```bash
# Instalar PM2 globalmente
sudo npm install -g pm2

# Configurar PM2 para auto-start
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME
```

---

## 🗄️ **PASO 3: INSTALAR MYSQL**

### **Instalar MySQL Server:**
```bash
# Instalar MySQL
sudo apt install -y mysql-server

# Configurar MySQL (seguir prompts)
sudo mysql_secure_installation
```

### **Configurar MySQL:**
```bash
# Conectar a MySQL
sudo mysql

# Crear base de datos
CREATE DATABASE topping_frozen_db;

# Crear usuario para la aplicación
CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';

# Dar permisos
GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';
FLUSH PRIVILEGES;

# Salir
EXIT;
```

---

## 🌐 **PASO 4: INSTALAR NGINX**

### **Instalar y Configurar Nginx:**
```bash
# Instalar Nginx
sudo apt install -y nginx

# Habilitar Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Verificar estado
sudo systemctl status nginx
```

### **Configurar Firewall:**
```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH, HTTP y HTTPS
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 3000
sudo ufw allow 3001

# Verificar estado
sudo ufw status
```

---

## 📁 **PASO 5: CLONAR Y CONFIGURAR APLICACIÓN**

### **Crear Usuario para la Aplicación:**
```bash
# Crear usuario
sudo adduser toppingapp

# Agregar a grupo sudo
sudo usermod -aG sudo toppingapp

# Cambiar a usuario
sudo su - toppingapp
```

### **Clonar Repositorio:**
```bash
# Ir al directorio home
cd /home/toppingapp

# Clonar repositorio
git clone https://github.com/jecaicedo27/topping-frozen-app.git

# Entrar al directorio
cd topping-frozen-app
```

### **Configurar Variables de Entorno:**
```bash
# Crear archivo .env para backend
cd backend
cp .env.example .env

# Editar archivo .env
nano .env
```

### **Contenido del archivo .env:**
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

# Frontend URL
FRONTEND_URL=http://TU_IP_DEL_VPS

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
```

---

## 📦 **PASO 6: INSTALAR DEPENDENCIAS**

### **Instalar Dependencias del Backend:**
```bash
# En directorio backend
cd /home/toppingapp/topping-frozen-app/backend
npm install

# Compilar TypeScript
npm run build
```

### **Instalar Dependencias del Frontend:**
```bash
# En directorio raíz
cd /home/toppingapp/topping-frozen-app
npm install

# Build del frontend
npm run build:frontend
```

---

## 🗃️ **PASO 7: CONFIGURAR BASE DE DATOS**

### **Ejecutar Migraciones:**
```bash
# En directorio backend
cd /home/toppingapp/topping-frozen-app/backend

# Ejecutar script de inicialización
mysql -u toppinguser -p topping_frozen_db < src/config/database.sql

# Crear usuario admin
cd /home/toppingapp/topping-frozen-app
node create-admin-user.js
```

---

## 🚀 **PASO 8: CONFIGURAR PM2**

### **Crear Archivo de Configuración PM2:**
```bash
# En directorio raíz
cd /home/toppingapp/topping-frozen-app

# Crear archivo ecosystem.config.js
nano ecosystem.config.js
```

### **Contenido de ecosystem.config.js:**
```javascript
module.exports = {
  apps: [
    {
      name: 'topping-backend',
      script: './backend/dist/index.js',
      cwd: '/home/toppingapp/topping-frozen-app',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    }
  ]
};
```

### **Iniciar Aplicación con PM2:**
```bash
# Crear directorio de logs
mkdir -p /home/toppingapp/topping-frozen-app/logs

# Iniciar aplicación
pm2 start ecosystem.config.js

# Guardar configuración PM2
pm2 save

# Verificar estado
pm2 status
pm2 logs
```

---

## 🌐 **PASO 9: CONFIGURAR NGINX**

### **Crear Configuración de Nginx:**
```bash
# Crear archivo de configuración
sudo nano /etc/nginx/sites-available/topping-frozen
```

### **Contenido de la configuración:**
```nginx
server {
    listen 80;
    server_name TU_IP_DEL_VPS TU_DOMINIO.com;

    # Servir archivos estáticos del frontend
    location / {
        root /home/toppingapp/topping-frozen-app/dist;
        try_files $uri $uri/ /index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
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
    }

    # Servir archivos subidos
    location /uploads/ {
        alias /home/toppingapp/topping-frozen-app/backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logs
    access_log /var/log/nginx/topping-frozen.access.log;
    error_log /var/log/nginx/topping-frozen.error.log;
}
```

### **Habilitar Sitio:**
```bash
# Crear enlace simbólico
sudo ln -s /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/

# Remover sitio por defecto
sudo rm /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

---

## 🔒 **PASO 10: CONFIGURAR SSL (OPCIONAL)**

### **Instalar Certbot:**
```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado SSL
sudo certbot --nginx -d TU_DOMINIO.com

# Configurar renovación automática
sudo crontab -e
# Agregar línea:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

---

## 📊 **PASO 11: MONITOREO Y LOGS**

### **Comandos Útiles:**
```bash
# Ver logs de la aplicación
pm2 logs topping-backend

# Ver estado de PM2
pm2 status

# Reiniciar aplicación
pm2 restart topping-backend

# Ver logs de Nginx
sudo tail -f /var/log/nginx/topping-frozen.access.log
sudo tail -f /var/log/nginx/topping-frozen.error.log

# Ver logs del sistema
sudo journalctl -u nginx
sudo journalctl -u mysql
```

### **Monitoreo de Recursos:**
```bash
# Instalar htop
sudo apt install -y htop

# Ver uso de recursos
htop

# Ver espacio en disco
df -h

# Ver uso de memoria
free -h
```

---

## 🔄 **PASO 12: SCRIPT DE ACTUALIZACIÓN**

### **Crear Script de Deploy:**
```bash
# Crear script de actualización
nano /home/toppingapp/deploy.sh
```

### **Contenido del script:**
```bash
#!/bin/bash

echo "🚀 Iniciando deploy de Topping Frozen..."

# Ir al directorio de la aplicación
cd /home/toppingapp/topping-frozen-app

# Hacer backup de la base de datos
echo "📦 Creando backup de base de datos..."
mysqldump -u toppinguser -p topping_frozen_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Actualizar código desde GitHub
echo "📥 Actualizando código..."
git pull origin main

# Instalar dependencias del backend
echo "📦 Instalando dependencias del backend..."
cd backend
npm install
npm run build

# Instalar dependencias del frontend
echo "📦 Instalando dependencias del frontend..."
cd ..
npm install
npm run build:frontend

# Reiniciar aplicación
echo "🔄 Reiniciando aplicación..."
pm2 restart topping-backend

# Verificar estado
echo "✅ Verificando estado..."
pm2 status

echo "🎉 Deploy completado!"
```

### **Hacer ejecutable:**
```bash
chmod +x /home/toppingapp/deploy.sh
```

---

## 🎯 **VERIFICACIÓN FINAL**

### **Verificar que todo funciona:**
```bash
# Verificar servicios
sudo systemctl status nginx
sudo systemctl status mysql
pm2 status

# Verificar puertos
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3001

# Probar aplicación
curl http://TU_IP_DEL_VPS
curl http://TU_IP_DEL_VPS/api/health
```

---

## 🌐 **ACCEDER A LA APLICACIÓN**

### **URLs:**
- **Frontend:** `http://TU_IP_DEL_VPS`
- **API:** `http://TU_IP_DEL_VPS/api`

### **Credenciales:**
- **Usuario:** admin
- **Contraseña:** 123456

---

## 🆘 **TROUBLESHOOTING**

### **Problemas Comunes:**

#### **Error de conexión a MySQL:**
```bash
# Verificar estado de MySQL
sudo systemctl status mysql

# Reiniciar MySQL
sudo systemctl restart mysql

# Verificar logs
sudo journalctl -u mysql
```

#### **Error 502 Bad Gateway:**
```bash
# Verificar que el backend esté corriendo
pm2 status

# Verificar logs del backend
pm2 logs topping-backend

# Reiniciar backend
pm2 restart topping-backend
```

#### **Archivos no se suben:**
```bash
# Verificar permisos del directorio uploads
sudo chown -R toppingapp:toppingapp /home/toppingapp/topping-frozen-app/backend/uploads
sudo chmod -R 755 /home/toppingapp/topping-frozen-app/backend/uploads
```

---

## 🎉 **¡LISTO!**

Tu aplicación Topping Frozen está ahora funcionando en tu VPS Ubuntu con:

- ✅ **Node.js** y **PM2** para el backend
- ✅ **MySQL** para la base de datos
- ✅ **Nginx** como proxy reverso
- ✅ **SSL** opcional para HTTPS
- ✅ **Monitoreo** y logs configurados
- ✅ **Script de deploy** automatizado

**¡Tu negocio está ahora en tu propio servidor! 🚀**
