# 🚀 Guía de Despliegue en VPS Hostinger

Esta guía te ayudará a configurar tu aplicación de gestión de pedidos en un VPS de Hostinger desde cero.

## 📋 Prerrequisitos

- VPS de Hostinger activo
- Acceso SSH al servidor
- Dominio configurado (opcional)

## 🔧 Paso 1: Configuración Inicial del Servidor

### 1.1 Conectar al VPS via SSH

```bash
# Conectar al servidor (reemplaza con tu IP)
ssh root@TU_IP_DEL_VPS

# O si tienes usuario específico:
ssh usuario@TU_IP_DEL_VPS
```

### 1.2 Actualizar el Sistema

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 1.3 Instalar Herramientas Básicas

```bash
# Ubuntu/Debian
sudo apt install -y curl wget git unzip software-properties-common

# CentOS/RHEL
sudo yum install -y curl wget git unzip
```

## 🟢 Paso 2: Instalar Node.js

### 2.1 Instalar Node.js 18+ (Recomendado)

```bash
# Instalar NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Instalar Node.js
sudo apt install -y nodejs

# Verificar instalación
node --version
npm --version
```

### 2.2 Instalar PM2 (Process Manager)

```bash
sudo npm install -g pm2
```

## 🗄️ Paso 3: Instalar y Configurar MySQL

### 3.1 Instalar MySQL Server

```bash
# Ubuntu/Debian
sudo apt install -y mysql-server

# Iniciar MySQL
sudo systemctl start mysql
sudo systemctl enable mysql
```

### 3.2 Configurar MySQL

```bash
# Ejecutar configuración segura
sudo mysql_secure_installation

# Responder las preguntas:
# - Set root password: YES (elige una contraseña segura)
# - Remove anonymous users: YES
# - Disallow root login remotely: YES
# - Remove test database: YES
# - Reload privilege tables: YES
```

### 3.3 Crear Base de Datos y Usuario

```bash
# Conectar a MySQL
sudo mysql -u root -p

# Dentro de MySQL, ejecutar:
CREATE DATABASE gestionPedidos;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'tu_password_seguro';
GRANT ALL PRIVILEGES ON gestionPedidos.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 📦 Paso 4: Clonar y Configurar la Aplicación

### 4.1 Clonar el Repositorio

```bash
# Ir al directorio home
cd /home

# Clonar el repositorio
git clone https://github.com/jecaicedo27/topping-frozen-app.git
cd topping-frozen-app
```

### 4.2 Instalar Dependencias

```bash
# Instalar dependencias del frontend
npm install

# Instalar dependencias del backend
cd backend
npm install
cd ..
```

### 4.3 Configurar Variables de Entorno

```bash
# Crear archivo .env en la raíz
cp .env.example .env
nano .env
```

**Configurar .env:**
```env
# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=tu_password_seguro
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo

# Environment
NODE_ENV=production
PORT=3001

# Frontend URL (reemplaza con tu dominio)
FRONTEND_URL=http://TU_DOMINIO_O_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
```

```bash
# Crear archivo .env del backend
cp backend/.env.example backend/.env
nano backend/.env
```

**Configurar backend/.env:**
```env
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=tu_password_seguro
DB_NAME=gestionPedidos
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu-jwt-secret-super-seguro-y-largo

# Frontend URL
FRONTEND_URL=http://TU_DOMINIO_O_IP

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
```

### 4.4 Inicializar Base de Datos

```bash
# Ejecutar migraciones
cd backend
npm run build
node dist/scripts/init-db.js
cd ..
```

### 4.5 Crear Usuario Admin

```bash
# Crear usuario administrador
node create-admin-user.js
```

## 🏗️ Paso 5: Build de la Aplicación

### 5.1 Build del Frontend

```bash
npm run build
```

### 5.2 Build del Backend

```bash
cd backend
npm run build
cd ..
```

## 🌐 Paso 6: Configurar Nginx (Servidor Web)

### 6.1 Instalar Nginx

```bash
sudo apt install -y nginx
```

### 6.2 Configurar Nginx

```bash
# Crear configuración del sitio
sudo nano /etc/nginx/sites-available/gestion-pedidos
```

**Contenido del archivo:**
```nginx
server {
    listen 80;
    server_name TU_DOMINIO_O_IP;

    # Frontend (archivos estáticos)
    location / {
        root /home/topping-frozen-app/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Archivos subidos
    location /uploads {
        alias /home/topping-frozen-app/backend/uploads;
    }
}
```

### 6.3 Activar el Sitio

```bash
# Crear enlace simbólico
sudo ln -s /etc/nginx/sites-available/gestion-pedidos /etc/nginx/sites-enabled/

# Eliminar sitio por defecto
sudo rm /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 🚀 Paso 7: Configurar PM2 para Producción

### 7.1 Crear Archivo de Configuración PM2

```bash
nano ecosystem.config.js
```

**Contenido:**
```javascript
module.exports = {
  apps: [{
    name: 'gestion-pedidos-backend',
    script: './backend/dist/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    }
  }]
};
```

### 7.2 Iniciar la Aplicación

```bash
# Iniciar con PM2
pm2 start ecosystem.config.js

# Guardar configuración PM2
pm2 save

# Configurar PM2 para iniciar al boot
pm2 startup
# Ejecutar el comando que PM2 te muestre
```

## 🔒 Paso 8: Configurar Firewall

### 8.1 Configurar UFW (Ubuntu Firewall)

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH
sudo ufw allow ssh

# Permitir HTTP y HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Verificar estado
sudo ufw status
```

## 🔐 Paso 9: Configurar SSL (Opcional pero Recomendado)

### 9.1 Instalar Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 9.2 Obtener Certificado SSL

```bash
# Reemplaza con tu dominio
sudo certbot --nginx -d tu-dominio.com
```

## 📊 Paso 10: Monitoreo y Mantenimiento

### 10.1 Comandos Útiles de PM2

```bash
# Ver estado de aplicaciones
pm2 status

# Ver logs
pm2 logs

# Reiniciar aplicación
pm2 restart gestion-pedidos-backend

# Parar aplicación
pm2 stop gestion-pedidos-backend

# Monitoreo en tiempo real
pm2 monit
```

### 10.2 Comandos Útiles de Sistema

```bash
# Ver uso de recursos
htop

# Ver espacio en disco
df -h

# Ver logs de Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Reiniciar servicios
sudo systemctl restart nginx
sudo systemctl restart mysql
```

## 🔄 Paso 11: Actualizar la Aplicación

### 11.1 Script de Actualización

```bash
# Crear script de actualización
nano update-app.sh
```

**Contenido:**
```bash
#!/bin/bash
echo "🔄 Actualizando aplicación..."

# Ir al directorio de la aplicación
cd /home/topping-frozen-app

# Hacer backup de archivos de configuración
cp .env .env.backup
cp backend/.env backend/.env.backup

# Obtener últimos cambios
git pull origin main

# Instalar dependencias
npm install
cd backend && npm install && cd ..

# Build de la aplicación
npm run build
cd backend && npm run build && cd ..

# Reiniciar aplicación
pm2 restart gestion-pedidos-backend

echo "✅ Aplicación actualizada correctamente"
```

```bash
# Hacer ejecutable
chmod +x update-app.sh
```

## 🆘 Solución de Problemas Comunes

### Error de Conexión a Base de Datos
```bash
# Verificar estado de MySQL
sudo systemctl status mysql

# Verificar logs de MySQL
sudo tail -f /var/log/mysql/error.log
```

### Error de Permisos de Archivos
```bash
# Ajustar permisos
sudo chown -R www-data:www-data /home/topping-frozen-app
sudo chmod -R 755 /home/topping-frozen-app
```

### Error de Nginx
```bash
# Verificar configuración
sudo nginx -t

# Ver logs de error
sudo tail -f /var/log/nginx/error.log
```

## 📞 Información de Contacto

Si necesitas ayuda adicional:
- Revisa los logs con `pm2 logs`
- Verifica el estado con `pm2 status`
- Consulta los logs de Nginx en `/var/log/nginx/`

---

**¡Tu aplicación está lista para producción en tu VPS de Hostinger! 🎉**
