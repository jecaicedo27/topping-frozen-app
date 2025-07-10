# 📦 Gestión de Pedidos - Sistema Multi-Empresa

Sistema completo de gestión de pedidos configurable para múltiples empresas, con historial de recepciones de dinero y captura de fotos para evidencia.

## 🏢 **NUEVO: Sistema Multi-Empresa**

Esta aplicación ahora soporta configuración personalizada para diferentes empresas:

- **🎨 Branding Personalizado**: Logo, colores y nombre de empresa
- **🌐 Dominio Específico**: Cada empresa puede usar su propio dominio
- **💾 Base de Datos Separada**: Configuración independiente por empresa
- **⚙️ Instalación Guiada**: Script interactivo para configuración inicial

### 🚀 **Instalación Rápida para Empresas**

```bash
# Windows
install-company.bat

# Linux/Mac/Multiplataforma
node install-company.js
```

Ver [EMPRESA_SETUP_GUIDE.md](EMPRESA_SETUP_GUIDE.md) para guía completa.

## 🚀 Características Principales

### ✅ **Sistema de Pedidos Completo**
- **Dashboard administrativo** con métricas en tiempo real
- **Gestión de facturas** con estados dinámicos
- **Control logístico** de entregas
- **Sistema de mensajería** para coordinación

### 📸 **Sistema de Historial con Fotos (NUEVO)**
- **Captura de fotos** por mensajeros al recibir pagos
- **Historial completo** de recepciones de dinero
- **Evidencia fotográfica** de cada transacción
- **Control de cartera** con timestamps precisos

### 🔐 **Autenticación y Seguridad**
- **Login seguro** con JWT tokens
- **Roles de usuario** (Admin, Facturación, Cartera, Logística, Mensajero)
- **Rutas protegidas** por rol
- **Encriptación de contraseñas** con bcrypt

### 💾 **Base de Datos Robusta**
- **MySQL** con esquema optimizado
- **Relaciones normalizadas** entre entidades
- **Migraciones automáticas** de base de datos
- **Datos de prueba** incluidos

## 🛠️ Tecnologías Utilizadas

### **Frontend**
- **React 19** con TypeScript
- **React Router** para navegación
- **Bootstrap 5** para UI responsiva
- **Axios** para comunicación con API
- **Webpack** para bundling

### **Backend**
- **Node.js** con Express
- **TypeScript** para tipado estático
- **MySQL2** para base de datos
- **Multer** para subida de archivos
- **JWT** para autenticación
- **bcrypt** para encriptación

## 📦 Instalación Local

### **Prerrequisitos**
- Node.js 18+
- MySQL 8.0+
- Git

### **Pasos de Instalación**

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/gestion-pedidos.git
cd gestion-pedidos

# 2. Instalar dependencias del frontend
npm install

# 3. Instalar dependencias del backend
cd backend
npm install
cd ..

# 4. Configurar base de datos MySQL
# Crear base de datos 'gestion_pedidos_db'
# Ejecutar: backend/src/config/database.sql

# 5. Configurar variables de entorno
cp .env.example .env
cp backend/.env.example backend/.env
# Editar archivos .env con tus credenciales

# 6. Inicializar base de datos
npm run backend:init-db

# 7. Crear usuario admin
node create-admin-user.js

# 8. Ejecutar aplicación
npm run dev
```

### **Credenciales por Defecto**
- **Usuario:** admin
- **Contraseña:** 123456

## 🌐 Despliegue en la Nube

### **🌟 Opción 1: Vercel + PlanetScale (Recomendado)**

#### **1. Preparar GitHub**
```bash
# Ejecutar script de inicialización
./init-github.bat

# Crear repositorio en GitHub.com
# Conectar repositorio local
git remote add origin https://github.com/TU_USUARIO/gestion-pedidos.git
git push -u origin main
```

#### **2. Configurar PlanetScale**
1. Crear cuenta en [PlanetScale](https://planetscale.com)
2. Crear base de datos `gestion_pedidos_db`
3. Obtener credenciales de conexión
4. Ejecutar migraciones desde el dashboard

#### **3. Configurar Vercel**
1. Crear cuenta en [Vercel](https://vercel.com)
2. Importar proyecto desde GitHub
3. Configurar variables de entorno:
   ```
   DB_HOST=tu-host-planetscale
   DB_USER=tu-usuario-planetscale
   DB_PASSWORD=tu-password-planetscale
   DB_NAME=gestion_pedidos_db
   DB_PORT=3306
   JWT_SECRET=tu-jwt-secret-super-seguro
   NODE_ENV=production
   ```

### **🌟 Opción 2: Railway (Más Simple)**

1. Crear cuenta en [Railway](https://railway.app)
2. Conectar repositorio GitHub
3. Agregar servicio MySQL
4. Configurar variables de entorno automáticamente
5. Deploy automático

### **🌟 Opción 3: Render + Supabase**

1. Configurar base de datos en [Supabase](https://supabase.com)
2. Crear servicio web en [Render](https://render.com)
3. Conectar repositorio GitHub
4. Configurar variables de entorno

## 📋 Scripts Disponibles

### **Desarrollo**
```bash
npm run dev          # Ejecutar frontend + backend
npm start           # Solo frontend (desarrollo)
npm run backend     # Solo backend (desarrollo)
```

### **Producción**
```bash
npm run build                # Build completo
npm run build:frontend       # Build solo frontend
npm run build:backend        # Build solo backend
```

### **Base de Datos**
```bash
npm run backend:init-db      # Inicializar base de datos
node create-admin-user.js    # Crear usuario admin
node add-mock-data.js        # Agregar datos de prueba
```

### **GitHub**
```bash
./init-github.bat           # Inicializar repositorio Git
```

## 🏗️ Estructura del Proyecto

```
gestion-pedidos/
├── src/                    # Frontend React
│   ├── components/         # Componentes reutilizables
│   ├── pages/             # Páginas principales
│   ├── context/           # Context API (estado global)
│   ├── services/          # Servicios API
│   ├── types/             # Tipos TypeScript
│   └── styles/            # Estilos CSS
├── backend/               # Backend Node.js
│   ├── src/
│   │   ├── controllers/   # Controladores API
│   │   ├── models/        # Modelos de datos
│   │   ├── routes/        # Rutas API
│   │   ├── middleware/    # Middleware personalizado
│   │   ├── config/        # Configuración y migraciones
│   │   └── scripts/       # Scripts utilitarios
│   └── uploads/           # Archivos subidos
├── config/                # Configuración de empresa
├── public/                # Archivos estáticos
├── install-company.js     # Instalador interactivo
├── install-company.bat    # Instalador Windows
├── start-company.bat      # Iniciador Windows
├── EMPRESA_SETUP_GUIDE.md # Guía configuración empresas
├── DEPLOYMENT_GUIDE.md    # Guía detallada de despliegue
├── vercel.json           # Configuración Vercel
├── package.json          # Dependencias principales
└── README.md             # Este archivo
```

## 🔧 API Endpoints

### **Autenticación**
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/logout` - Cerrar sesión

### **Usuarios**
- `GET /api/users` - Listar usuarios
- `POST /api/users` - Crear usuario
- `PUT /api/users/:id` - Actualizar usuario

### **Pedidos**
- `GET /api/orders` - Listar pedidos
- `POST /api/orders` - Crear pedido
- `PUT /api/orders/:id` - Actualizar pedido
- `PUT /api/orders/:id/status` - Cambiar estado

### **Recepciones de Dinero (NUEVO)**
- `GET /api/money-receipts` - Historial de recepciones
- `POST /api/money-receipts` - Registrar recepción
- `GET /api/money-receipts/:id/photo` - Obtener foto

### **Configuración de Empresa (NUEVO)**
- `GET /api/company/info` - Información pública de la empresa
- `GET /api/company/config` - Configuración completa (requiere auth)
- `PUT /api/company/config` - Actualizar configuración (admin)
- `GET /api/company/health` - Estado de salud de la configuración

## 🎯 Flujo de Trabajo

### **1. Mensajero Entrega Pedido**
1. Recibe pago del cliente (efectivo/transferencia)
2. **Captura foto del pago** como evidencia
3. Captura foto de entrega
4. Confirma entrega en el sistema

### **2. Cartera Recibe Dinero**
1. Ve control de dinero pendiente
2. Selecciona facturas específicas
3. **Opcionalmente toma foto** de la recepción
4. Agrega notas sobre la transacción
5. Confirma recepción con timestamp

### **3. Historial Completo**
1. **Registro fotográfico** de cada transacción
2. **Timestamps precisos** de recepciones
3. **Trazabilidad completa** del dinero
4. **Evidencia documental** para auditorías

## 🛡️ Seguridad

- **Autenticación JWT** con expiración
- **Encriptación bcrypt** para contraseñas
- **Validación de entrada** en todos los endpoints
- **CORS configurado** para dominios específicos
- **Variables de entorno** para datos sensibles

## 📊 Monitoreo

- **Logs detallados** en backend
- **Manejo de errores** centralizado
- **Métricas de rendimiento** en dashboard
- **Alertas automáticas** para fallos

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 📞 Soporte

Para soporte técnico o preguntas:
- **Email:** soporte@gestionpedidos.com
- **GitHub Issues:** [Crear issue](https://github.com/TU_USUARIO/gestion-pedidos/issues)

---

**¡Tu sistema de gestión de pedidos está listo para la nube! 🚀**
