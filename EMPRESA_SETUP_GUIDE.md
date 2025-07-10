# Guía de Configuración Multi-Empresa

Esta guía te ayudará a configurar la aplicación para que funcione con diferentes empresas, permitiendo personalizar el dominio, nombre de la empresa y otras configuraciones específicas.

## 📋 Tabla de Contenidos

1. [Características del Sistema Multi-Empresa](#características-del-sistema-multi-empresa)
2. [Requisitos Previos](#requisitos-previos)
3. [Instalación Rápida](#instalación-rápida)
4. [Instalación Manual](#instalación-manual)
5. [Configuración Avanzada](#configuración-avanzada)
6. [Personalización](#personalización)
7. [Deployment](#deployment)
8. [Troubleshooting](#troubleshooting)

## 🚀 Características del Sistema Multi-Empresa

### ✅ Funcionalidades Incluidas

- **Configuración por Empresa**: Cada instalación puede tener su propia configuración
- **Branding Personalizado**: Logo, colores y nombre de empresa personalizables
- **Dominio Específico**: Cada empresa puede usar su propio dominio
- **Base de Datos Separada**: Cada empresa puede tener su propia base de datos
- **Configuración Flexible**: Variables de entorno y archivos de configuración
- **Multi-tenant Opcional**: Soporte para múltiples empresas en una sola instalación

### 🎨 Personalización Disponible

- Nombre de la empresa
- Dominio personalizado
- Logo de la empresa
- Colores primarios y secundarios
- Título de la aplicación
- Descripción de la aplicación
- Información de contacto
- Características habilitadas/deshabilitadas

## 📋 Requisitos Previos

### Software Necesario

- **Node.js** 16 o superior
- **npm** o **yarn**
- **MySQL** 8.0 o superior
- **Git** (opcional, para clonación)

### Verificar Instalaciones

```bash
# Verificar Node.js
node --version

# Verificar npm
npm --version

# Verificar MySQL
mysql --version
```

## 🚀 Instalación Rápida

### Opción 1: Instalador Automático (Windows)

```cmd
# Ejecutar el instalador completo
install-company.bat
```

### Opción 2: Instalador Interactivo (Multiplataforma)

```bash
# Instalar dependencias
npm install
cd backend && npm install && cd ..

# Ejecutar configurador
node install-company.js
```

### Opción 3: Script de Bash (Linux/Mac)

```bash
# Hacer ejecutable
chmod +x install-vps.sh

# Ejecutar instalación
./install-vps.sh
```

## 🔧 Instalación Manual

### 1. Clonar o Descargar el Proyecto

```bash
git clone <repository-url>
cd appToppingFrozen
```

### 2. Instalar Dependencias

```bash
# Frontend
npm install

# Backend
cd backend
npm install
cd ..
```

### 3. Configurar Variables de Entorno

Crear archivo `.env` en la raíz:

```env
# Configuración de la Empresa
COMPANY_NAME=Mi Empresa
COMPANY_DOMAIN=miempresa.com
COMPANY_EMAIL=admin@miempresa.com
COMPANY_PHONE=+57 300 000 0000
COMPANY_ADDRESS=Dirección de mi empresa
COMPANY_LOGO=/assets/logo.png
COMPANY_PRIMARY_COLOR=#007bff
COMPANY_SECONDARY_COLOR=#6c757d

# Configuración de la Aplicación
APP_TITLE=Sistema de Pedidos
APP_DESCRIPTION=Sistema de gestión de pedidos y logística
APP_VERSION=1.0.0

# Configuración de Base de Datos
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=mi_empresa_db
DB_PORT=3306
DB_PREFIX=mi_empresa_

# Configuración JWT
JWT_SECRET=tu_jwt_secret_muy_seguro

# Configuración del Servidor
NODE_ENV=production
PORT=5000
FRONTEND_URL=https://miempresa.com

# Características
MULTI_TENANT=false
CUSTOM_BRANDING=true
ADVANCED_REPORTING=true

# Configuración de Archivos
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
```

Crear archivo `backend/.env`:

```env
# Server Configuration
PORT=5000
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=mi_empresa_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=tu_jwt_secret_muy_seguro

# Company Configuration
COMPANY_NAME=Mi Empresa
COMPANY_DOMAIN=miempresa.com
```

### 4. Configurar Base de Datos

```bash
# Crear base de datos
mysql -u root -p
CREATE DATABASE mi_empresa_db;
exit

# Inicializar tablas
cd backend
npm run init-db
cd ..
```

### 5. Construir y Ejecutar

```bash
# Construir aplicación
npm run build

# Iniciar servidor
cd backend
npm start
```

## ⚙️ Configuración Avanzada

### Multi-Tenant

Para habilitar múltiples empresas en una sola instalación:

```env
MULTI_TENANT=true
```

### Configuración de Colores Personalizados

Los colores se aplican automáticamente usando CSS custom properties:

```css
:root {
  --primary-color: #007bff;
  --secondary-color: #6c757d;
}
```

### Logo Personalizado

1. Coloca tu logo en `public/assets/logo.png`
2. Actualiza la variable `COMPANY_LOGO=/assets/logo.png`

### Base de Datos con Prefijo

Para evitar conflictos entre empresas:

```env
DB_PREFIX=empresa1_
```

Esto creará tablas como: `empresa1_users`, `empresa1_orders`, etc.

## 🎨 Personalización

### Modificar Colores

Edita las variables en `.env`:

```env
COMPANY_PRIMARY_COLOR=#ff6b35
COMPANY_SECONDARY_COLOR=#004e89
```

### Cambiar Logo

1. Reemplaza el archivo en `public/assets/`
2. Actualiza la ruta en `.env`

### Personalizar Navegación

El componente `Navigation.tsx` usa automáticamente la configuración de la empresa.

### Agregar Características Personalizadas

Modifica `config/company.config.js` para agregar nuevas opciones:

```javascript
module.exports = {
  // ... configuración existente
  customFeatures: {
    enableReports: process.env.ENABLE_REPORTS === 'true',
    enableNotifications: process.env.ENABLE_NOTIFICATIONS === 'true'
  }
};
```

## 🚀 Deployment

### Servidor VPS

1. **Subir archivos al servidor**
2. **Configurar variables de entorno**
3. **Instalar dependencias**
4. **Configurar base de datos**
5. **Configurar proxy reverso (Nginx)**
6. **Configurar SSL**

### Usando PM2

```bash
# Instalar PM2
npm install -g pm2

# Configurar ecosystem
cp ecosystem.config.js ecosystem.production.config.js

# Editar configuración
nano ecosystem.production.config.js

# Iniciar aplicación
pm2 start ecosystem.production.config.js
```

### Docker (Opcional)

```dockerfile
# Dockerfile ejemplo
FROM node:16-alpine

WORKDIR /app

# Copiar package.json
COPY package*.json ./
COPY backend/package*.json ./backend/

# Instalar dependencias
RUN npm install
RUN cd backend && npm install

# Copiar código
COPY . .

# Construir aplicación
RUN npm run build

# Exponer puerto
EXPOSE 5000

# Comando de inicio
CMD ["npm", "start"]
```

## 🔧 Troubleshooting

### Problemas Comunes

#### 1. Error de Conexión a Base de Datos

```bash
# Verificar MySQL
sudo systemctl status mysql

# Verificar credenciales
mysql -u root -p

# Verificar variables de entorno
cat backend/.env | grep DB_
```

#### 2. Puerto en Uso

```bash
# Verificar qué usa el puerto
netstat -tulpn | grep :5000

# Cambiar puerto en .env
PORT=5001
```

#### 3. Problemas de Permisos

```bash
# Dar permisos a scripts
chmod +x start-company.sh
chmod +x install-vps.sh
```

#### 4. Error de Dependencias

```bash
# Limpiar cache
npm cache clean --force

# Reinstalar dependencias
rm -rf node_modules package-lock.json
npm install
```

### Logs y Debugging

```bash
# Ver logs del servidor
tail -f logs/app.log

# Modo debug
NODE_ENV=development npm start

# Verificar configuración
curl http://localhost:5000/api/company/health
```

### Verificar Configuración

```bash
# Endpoint de salud
GET /api/company/health

# Información pública
GET /api/company/info

# Configuración completa (requiere auth)
GET /api/company/config
```

## 📞 Soporte

### Contacto

- **Email**: Configurado en `COMPANY_EMAIL`
- **Teléfono**: Configurado en `COMPANY_PHONE`

### Documentación Adicional

- `README.md` - Información general
- `DEPLOYMENT_GUIDE.md` - Guía de deployment
- `TROUBLESHOOTING.md` - Solución de problemas

### Archivos de Configuración Importantes

- `.env` - Variables de entorno principales
- `backend/.env` - Variables del backend
- `config/company.config.js` - Configuración de empresa
- `ecosystem.config.js` - Configuración PM2

---

**Nota**: Esta aplicación ha sido diseñada para ser fácilmente configurable y adaptable a diferentes empresas. Cada instalación es independiente y puede personalizarse completamente según las necesidades específicas de cada organización.
