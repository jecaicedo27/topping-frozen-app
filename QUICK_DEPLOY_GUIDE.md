# 🚀 Guía Rápida de Despliegue - jecaicedo27

## 📋 **PASO 1: Subir a GitHub**

### **Ejecutar Script Automático:**
```bash
# Ejecutar el script personalizado
./upload-to-github.bat

# Te pedirá el nombre del repositorio
# Ejemplo: topping-frozen-app
```

### **O Manualmente:**
```bash
# Configurar Git
git config user.email "jecaicedo27@gmail.com"
git config user.name "jecaicedo27"

# Inicializar y subir
git init
git add .
git commit -m "Initial commit - Topping Frozen System"
git branch -M main
git remote add origin https://github.com/jecaicedo27/TU_REPOSITORIO.git
git push -u origin main
```

---

## 🌟 **PASO 2: Desplegar en Vercel (GRATIS)**

### **1. Crear cuenta en Vercel:**
- Ve a https://vercel.com
- Click "Continue with GitHub"
- Autoriza acceso a tu cuenta jecaicedo27

### **2. Importar proyecto:**
- Click "New Project"
- Busca tu repositorio: `topping-frozen-app`
- Click "Import"

### **3. Configurar variables de entorno:**
En Vercel Dashboard > Settings > Environment Variables:

```
DB_HOST=tu-host-planetscale
DB_USER=tu-usuario-planetscale  
DB_PASSWORD=tu-password-planetscale
DB_NAME=topping_frozen_db
DB_PORT=3306
JWT_SECRET=mi-super-secreto-jwt-2024
NODE_ENV=production
```

### **4. Deploy:**
- Click "Deploy"
- Espera 2-3 minutos
- ¡Tu app estará en: `https://tu-proyecto.vercel.app`!

---

## 💾 **PASO 3: Configurar Base de Datos (PlanetScale)**

### **1. Crear cuenta:**
- Ve a https://planetscale.com
- Regístrate con jecaicedo27@gmail.com

### **2. Crear base de datos:**
- Click "New Database"
- Nombre: `topping-frozen-db`
- Región: `us-east-1`

### **3. Obtener credenciales:**
- Ve a Settings > Passwords
- Click "New Password"
- Copia: HOST, USERNAME, PASSWORD

### **4. Crear tablas:**
- Ve a Console
- Pega el contenido de `backend/src/config/database.sql`
- Ejecuta las queries

---

## 🎯 **PASO 4: Configurar Usuario Admin**

### **En PlanetScale Console:**
```sql
-- Crear usuario admin
INSERT INTO users (username, password, role, created_at) 
VALUES ('admin', '$2b$10$pg4mTjSKYjmWgOVdWncMfex2rIl7kjNHz3sfs//N.i7xYFh7G3FbS', 'admin', NOW());
```

### **Credenciales:**
- **Usuario:** admin
- **Contraseña:** 123456

---

## ⚡ **ALTERNATIVA RÁPIDA: Railway ($5/mes)**

### **1. Crear cuenta:**
- Ve a https://railway.app
- Conecta con GitHub (jecaicedo27)

### **2. Deploy:**
- Click "New Project"
- "Deploy from GitHub repo"
- Selecciona tu repositorio
- Railway configurará TODO automáticamente

### **3. Agregar MySQL:**
- En tu proyecto Railway
- Click "New" > "Database" > "Add MySQL"
- Variables de entorno se configuran automáticamente

---

## 🔧 **URLs de tu Proyecto:**

### **GitHub:**
```
https://github.com/jecaicedo27/TU_REPOSITORIO
```

### **Vercel (después del deploy):**
```
https://tu-proyecto.vercel.app
```

### **Railway (después del deploy):**
```
https://tu-proyecto.up.railway.app
```

---

## 📱 **Probar la Aplicación:**

### **1. Abrir URL de tu app**
### **2. Login con:**
- Usuario: `admin`
- Contraseña: `123456`

### **3. Navegar a Cartera:**
- Probar sistema de historial
- Verificar funcionalidad de fotos

---

## 🆘 **Si algo falla:**

### **Error de Base de Datos:**
- Verificar variables de entorno en Vercel/Railway
- Confirmar que las tablas se crearon en PlanetScale

### **Error de Login:**
- Verificar que el usuario admin se creó correctamente
- Confirmar hash de contraseña

### **Error de Build:**
- Revisar logs en Vercel/Railway Dashboard
- Verificar que package.json tiene scripts correctos

---

## 🎉 **¡Listo!**

Tu sistema Topping Frozen estará funcionando en la nube con:
- ✅ **Acceso global** 24/7
- ✅ **Base de datos** en la nube
- ✅ **Sistema de fotos** funcional
- ✅ **Historial de recepciones** completo
- ✅ **Login seguro** admin/123456

**¡Tu negocio digitalizado en menos de 1 hora! 🚀**
