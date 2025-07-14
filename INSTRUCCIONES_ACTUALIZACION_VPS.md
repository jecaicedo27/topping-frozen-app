# 🚀 Instrucciones para Actualizar el VPS con las Correcciones

## Cambios Realizados (Commit: 4647c1b)

### ✅ Correcciones Implementadas:
- **Base de datos**: Configuración para MySQL local y VPS
- **API URL**: Corregida para usar puerto 3001
- **Autenticación**: Sistema mejorado con manejo de errores
- **Dependencies**: Multer instalado para uploads
- **Logs**: Sistema de depuración implementado
- **Endpoints**: Documentación de API agregada
- **Fallback**: Credenciales de prueba cuando DB no disponible

## 📋 Pasos para Actualizar el VPS

### 1. Conectarse al VPS
```bash
ssh root@tu-servidor-vps
```

### 2. Navegar al directorio del proyecto
```bash
cd /var/www/topping-frozen-app
```

### 3. Hacer pull de los últimos cambios
```bash
git pull origin main
```

### 4. Instalar nuevas dependencias
```bash
# Backend
cd backend
npm install

# Frontend (si es necesario)
cd ..
npm install
```

### 5. Verificar configuración de base de datos
```bash
# Editar archivo .env del backend si es necesario
nano backend/.env
```

**Configuración recomendada para VPS:**
```env
# Database Configuration
DB_HOST=localhost
DB_USER=tu_usuario_mysql
DB_PASSWORD=tu_password_mysql
DB_NAME=topping_frozen_db
DB_PORT=3306

# JWT Configuration
JWT_SECRET=mi-super-secreto-jwt-vps-2024

# Environment
NODE_ENV=production
PORT=3001
```

### 6. Reiniciar servicios
```bash
# Si usas PM2
pm2 restart all

# O si usas systemd
sudo systemctl restart topping-frozen-backend
sudo systemctl restart topping-frozen-frontend
```

### 7. Verificar que todo funcione
```bash
# Verificar backend
curl http://localhost:3001/api/health

# Verificar login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'
```

## 🔧 Configuraciones Específicas del VPS

### Variables de Entorno Importantes:
- `NODE_ENV=production`
- `DB_HOST=localhost` (o IP de tu base de datos)
- `PORT=3001` (backend)
- `FRONTEND_URL=https://tu-dominio.com` (para CORS)

### Base de Datos:
- Asegúrate de que MySQL esté ejecutándose
- Verifica que el usuario tenga permisos correctos
- La base de datos `topping_frozen_db` debe existir

### Nginx (si aplica):
- Verificar que el proxy_pass apunte al puerto 3001
- Configurar CORS si es necesario

## 🚨 Troubleshooting

### Si el backend no se conecta a la base de datos:
1. Verificar credenciales en `.env`
2. Comprobar que MySQL esté ejecutándose
3. Verificar permisos del usuario de base de datos

### Si el frontend no puede conectar al backend:
1. Verificar que el backend esté en puerto 3001
2. Comprobar configuración de CORS
3. Verificar configuración de Nginx/Apache

### Logs útiles:
```bash
# Ver logs del backend
pm2 logs backend

# Ver logs del sistema
sudo journalctl -u topping-frozen-backend -f
```

## ✅ Verificación Final

Después de la actualización, verificar:
- [ ] Backend responde en `/api/health`
- [ ] Login funciona correctamente
- [ ] Frontend carga sin errores
- [ ] Base de datos se conecta correctamente
- [ ] Todos los endpoints funcionan

## 📞 Soporte

Si encuentras problemas durante la actualización:
1. Revisar logs del sistema
2. Verificar configuración de base de datos
3. Comprobar permisos de archivos
4. Reiniciar servicios si es necesario

---
**Fecha de actualización**: 14 de Julio, 2025
**Commit**: 4647c1b
**Versión**: 1.0.0
