# 🚀 Guía de Despliegue - Topping Frozen Order Management System

## 📋 Opciones de Despliegue en la Nube

### 🌟 **Opción 1: Vercel + PlanetScale (Recomendado para principiantes)**
- **Frontend:** Vercel (gratis)
- **Backend:** Vercel Serverless Functions
- **Base de datos:** PlanetScale MySQL (gratis hasta 5GB)
- **Archivos:** Vercel Blob Storage

### 🌟 **Opción 2: Railway (Más fácil para full-stack)**
- **Todo en uno:** Railway
- **Base de datos:** MySQL incluido
- **Precio:** ~$5/mes

### 🌟 **Opción 3: Render + Supabase**
- **Frontend/Backend:** Render
- **Base de datos:** Supabase PostgreSQL
- **Precio:** Gratis con limitaciones

---

## 🎯 **OPCIÓN 1: VERCEL + PLANETSCALE (RECOMENDADA)**

### **Paso 1: Preparar el Repositorio GitHub**

```bash
# 1. Inicializar Git (si no está inicializado)
git init

# 2. Agregar archivos
git add .

# 3. Commit inicial
git commit -m "Initial commit - Topping Frozen Order Management System"

# 4. Crear repositorio en GitHub y conectar
git remote add origin https://github.com/TU_USUARIO/topping-frozen-app.git
git branch -M main
git push -u origin main
```

### **Paso 2: Configurar PlanetScale (Base de Datos)**

1. **Crear cuenta en PlanetScale:**
   - Ve a https://planetscale.com
   - Regístrate gratis
   - Crea una nueva base de datos llamada `topping-frozen-db`

2. **Obtener credenciales:**
   - Ve a Settings > Passwords
   - Crea una nueva password
   - Guarda: `HOST`, `USERNAME`, `PASSWORD`, `DATABASE`

3. **Configurar esquema:**
   - Usa el archivo `backend/src/config/database.sql` para crear las tablas

### **Paso 3: Configurar Vercel**

1. **Crear cuenta en Vercel:**
   - Ve a https://vercel.com
   - Conecta con tu cuenta de GitHub

2. **Importar proyecto:**
   - Click "New Project"
   - Selecciona tu repositorio `topping-frozen-app`

3. **Configurar variables de entorno:**
   ```
   DB_HOST=tu-host-planetscale
   DB_USER=tu-usuario-planetscale
   DB_PASSWORD=tu-password-planetscale
   DB_NAME=topping-frozen-db
   DB_PORT=3306
   JWT_SECRET=tu-jwt-secret-super-seguro
   NODE_ENV=production
   ```

### **Paso 4: Configurar Build Settings**

```json
// vercel.json
{
  "version": 2,
  "builds": [
    {
      "src": "backend/src/index.ts",
      "use": "@vercel/node"
    },
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "dist"
      }
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/backend/src/index.ts"
    },
    {
      "src": "/(.*)",
      "dest": "/dist/$1"
    }
  ]
}
```

---

## 🎯 **OPCIÓN 2: RAILWAY (MÁS SIMPLE)**

### **Paso 1: Preparar Railway**

1. **Crear cuenta en Railway:**
   - Ve a https://railway.app
   - Conecta con GitHub

2. **Crear nuevo proyecto:**
   - Click "New Project"
   - Selecciona "Deploy from GitHub repo"
   - Conecta tu repositorio

### **Paso 2: Configurar Variables de Entorno**

```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=MYSQLPASSWORD
DB_NAME=railway
DB_PORT=3306
JWT_SECRET=tu-jwt-secret-super-seguro
NODE_ENV=production
PORT=3000
```

### **Paso 3: Configurar Base de Datos**

1. **Agregar MySQL:**
   - En tu proyecto Railway
   - Click "New" > "Database" > "Add MySQL"
   - Railway generará automáticamente las credenciales

2. **Ejecutar migraciones:**
   - Usa el Query Editor de Railway
   - Ejecuta el contenido de `backend/src/config/database.sql`

---

## 🎯 **OPCIÓN 3: RENDER + SUPABASE**

### **Paso 1: Configurar Supabase**

1. **Crear proyecto en Supabase:**
   - Ve a https://supabase.com
   - Crea nuevo proyecto

2. **Configurar base de datos:**
   - Ve a SQL Editor
   - Ejecuta las migraciones adaptadas para PostgreSQL

### **Paso 2: Configurar Render**

1. **Crear cuenta en Render:**
   - Ve a https://render.com
   - Conecta con GitHub

2. **Crear Web Service:**
   - Selecciona tu repositorio
   - Configura build y start commands

---

## 📁 **Archivos de Configuración Necesarios**

### **1. package.json (raíz del proyecto)**
```json
{
  "name": "topping-frozen-app",
  "version": "1.0.0",
  "scripts": {
    "build": "npm run build:frontend && npm run build:backend",
    "build:frontend": "webpack --mode production",
    "build:backend": "cd backend && npm run build",
    "start": "cd backend && npm start",
    "dev": "concurrently \"npm run dev:frontend\" \"npm run dev:backend\"",
    "dev:frontend": "webpack serve --mode development",
    "dev:backend": "cd backend && npm run dev"
  }
}
```

### **2. .env.example**
```
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=topping_frozen_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key

# Environment
NODE_ENV=development
PORT=3001
```

### **3. .gitignore**
```
node_modules/
dist/
build/
.env
.env.local
.env.production
backend/.env
backend/dist/
backend/uploads/
*.log
.DS_Store
```

---

## 🔧 **Comandos de Despliegue**

### **Para Vercel:**
```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### **Para Railway:**
```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login y deploy
railway login
railway link
railway up
```

### **Para Render:**
```bash
# Solo necesitas hacer push a GitHub
git push origin main
# Render detectará automáticamente los cambios
```

---

## 🛡️ **Consideraciones de Seguridad**

### **Variables de Entorno Críticas:**
- `JWT_SECRET`: Debe ser único y seguro
- `DB_PASSWORD`: Nunca expongas en el código
- `NODE_ENV=production`: Para optimizaciones

### **CORS Configuration:**
```javascript
// En backend/src/index.ts
app.use(cors({
  origin: ['https://tu-dominio.vercel.app', 'https://tu-dominio-personalizado.com'],
  credentials: true
}));
```

---

## 📊 **Monitoreo y Logs**

### **Vercel:**
- Dashboard > Functions > View Logs

### **Railway:**
- Dashboard > Deployments > View Logs

### **Render:**
- Dashboard > Logs

---

## 🚨 **Troubleshooting Común**

### **Error de Base de Datos:**
```bash
# Verificar conexión
curl -X GET https://tu-app.vercel.app/api/health
```

### **Error de CORS:**
```javascript
// Agregar en backend
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000'
}));
```

### **Error de Build:**
```bash
# Limpiar cache
rm -rf node_modules package-lock.json
npm install
```

---

## 🎉 **¡Listo para Producción!**

Una vez desplegado, tu aplicación estará disponible en:
- **Vercel:** `https://tu-proyecto.vercel.app`
- **Railway:** `https://tu-proyecto.up.railway.app`
- **Render:** `https://tu-proyecto.onrender.com`

### **Credenciales por defecto:**
- **Usuario:** admin
- **Contraseña:** 123456

¡Tu sistema de gestión de pedidos Topping Frozen estará funcionando en la nube! 🚀
