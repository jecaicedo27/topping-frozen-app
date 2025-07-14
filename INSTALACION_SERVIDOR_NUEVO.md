# 🚀 Instalación en Servidor Recién Formateado

## 📋 Requisitos del Servidor
- **SO**: Ubuntu 20.04/22.04 o Debian 11/12
- **RAM**: Mínimo 2GB (recomendado 4GB)
- **Disco**: Mínimo 20GB
- **Acceso**: SSH como root o sudo

## ⚡ Instalación Automática (RECOMENDADO)

### 🔥 Un Solo Comando
```bash
# Conectarse al servidor
ssh root@IP_DEL_SERVIDOR

# Descargar y ejecutar script de instalación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-fresh-server.sh | bash
```

### ✅ Lo que hace el script automático:
1. **Sistema Base**:
   - ✅ Actualiza el sistema
   - ✅ Instala dependencias básicas
   - ✅ Configura firewall

2. **Stack de Aplicación**:
   - ✅ Node.js 18.x
   - ✅ PM2 (gestor de procesos)
   - ✅ MySQL Server
   - ✅ Nginx (proxy reverso)

3. **Aplicación**:
   - ✅ Clona repositorio desde GitHub
   - ✅ Instala dependencias
   - ✅ Configura base de datos
   - ✅ Construye frontend
   - ✅ Configura variables de entorno

4. **Servicios**:
   - ✅ Configura Nginx para IP
   - ✅ Inicia backend con PM2
   - ✅ Configura autostart
   - ✅ Verifica funcionamiento

## 📋 Instalación Manual (Paso a Paso)

### 1. Preparar Servidor
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias básicas
sudo apt install -y curl wget git unzip
```

### 2. Instalar Node.js 18.x
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y nodejs
```

### 3. Instalar PM2
```bash
sudo npm install -g pm2
```

### 4. Instalar MySQL
```bash
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# Configurar base de datos
sudo mysql -e "CREATE DATABASE topping_frozen_db;"
sudo mysql -e "CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
sudo mysql -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### 5. Instalar Nginx
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 6. Clonar Proyecto
```bash
cd /var/www
sudo git clone https://github.com/jecaicedo27/topping-frozen-app.git
cd topping-frozen-app
```

### 7. Instalar Dependencias
```bash
# Frontend
npm install

# Backend
cd backend
npm install
cd ..
```

### 8. Configurar Variables de Entorno
```bash
# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)

# Crear archivo .env
cat > backend/.env << EOF
DB_HOST=localhost
DB_USER=toppinguser
DB_PASSWORD=ToppingPass2024!
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-vps-2024
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://$SERVER_IP
ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP
EOF
```

### 9. Construir Frontend
```bash
npm run build
```

### 10. Configurar Nginx
```bash
# Crear configuración
sudo tee /etc/nginx/sites-available/topping-frozen << EOF
server {
    listen 80;
    server_name $(curl -s ifconfig.me);
    
    location / {
        root /var/www/topping-frozen-app/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/topping-frozen /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### 11. Iniciar con PM2
```bash
# Instalar TypeScript globalmente
sudo npm install -g ts-node typescript

# Crear configuración PM2
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'topping-frozen-backend',
    script: 'backend/src/index.ts',
    interpreter: 'node',
    interpreter_args: '--loader ts-node/esm',
    env: { NODE_ENV: 'production', PORT: 3001 }
  }]
};
EOF

# Iniciar aplicación
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 12. Configurar Permisos
```bash
sudo chown -R www-data:www-data /var/www/topping-frozen-app
sudo chmod -R 755 /var/www/topping-frozen-app
```

## 🧪 Verificación

### Verificar Servicios
```bash
# Backend
curl http://localhost:3001/api/health

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'

# Frontend
curl http://$(curl -s ifconfig.me)
```

### Ver Logs
```bash
# Logs del backend
pm2 logs topping-frozen-backend

# Logs de Nginx
sudo tail -f /var/log/nginx/topping-frozen.error.log

# Estado de servicios
pm2 status
sudo systemctl status nginx mysql
```

## 📊 Información del Sistema

### Acceso a la Aplicación
- **Frontend**: `http://IP_DEL_SERVIDOR`
- **Backend API**: `http://IP_DEL_SERVIDOR/api`
- **Health Check**: `http://IP_DEL_SERVIDOR/api/health`

### Credenciales de Base de Datos
- **Usuario**: `toppinguser`
- **Contraseña**: `ToppingPass2024!`
- **Base de datos**: `topping_frozen_db`

### Usuarios de Prueba (Contraseña: `123456`)
- `admin` - Administrador
- `facturacion` - Facturación
- `cartera` - Cartera
- `logistica` - Logística
- `mensajero` - Mensajero

## 🔧 Comandos Útiles

### Gestión de PM2
```bash
pm2 status                    # Ver estado
pm2 restart topping-frozen-backend  # Reiniciar
pm2 logs topping-frozen-backend     # Ver logs
pm2 monit                     # Monitor en tiempo real
```

### Gestión de Nginx
```bash
sudo systemctl status nginx   # Estado
sudo systemctl restart nginx  # Reiniciar
sudo nginx -t                 # Verificar configuración
```

### Gestión de MySQL
```bash
sudo systemctl status mysql   # Estado
sudo mysql -u toppinguser -p  # Conectar a DB
```

### Actualizar Aplicación
```bash
cd /var/www/topping-frozen-app
git pull origin main
npm install
cd backend && npm install && cd ..
npm run build
pm2 restart topping-frozen-backend
```

## 🚨 Troubleshooting

### Backend no inicia
```bash
# Verificar logs
pm2 logs topping-frozen-backend

# Verificar variables de entorno
cat backend/.env

# Verificar base de datos
mysql -u toppinguser -p -e "SHOW DATABASES;"
```

### Frontend no carga
```bash
# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx

# Verificar archivos
ls -la /var/www/topping-frozen-app/dist/
```

### Base de datos no conecta
```bash
# Verificar MySQL
sudo systemctl status mysql

# Verificar usuario
mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='toppinguser';"

# Recrear usuario si es necesario
mysql -u root -e "DROP USER IF EXISTS 'toppinguser'@'localhost';"
mysql -u root -e "CREATE USER 'toppinguser'@'localhost' IDENTIFIED BY 'ToppingPass2024!';"
mysql -u root -e "GRANT ALL PRIVILEGES ON topping_frozen_db.* TO 'toppinguser'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
```

---
**Fecha**: 14 de Julio, 2025  
**Versión**: 1.0.0  
**Repositorio**: https://github.com/jecaicedo27/topping-frozen-app.git
