# 🖥️ Comandos Exactos para Ejecutar en el VPS

## 🔑 Paso 1: Conectar al VPS

Abre **PowerShell** o **CMD** en tu computadora Windows y ejecuta:

```bash
ssh root@46.202.93.54
```

*Te pedirá la contraseña de tu servidor VPS*

## 📁 Paso 2: Ir al Directorio del Proyecto

Una vez conectado al VPS, ejecuta:

```bash
cd /var/www/topping-frozen-app
```

## 📥 Paso 3: Descargar los Nuevos Scripts desde Git

```bash
git pull origin main
```

## 🔧 Paso 4: Hacer los Scripts Ejecutables

```bash
chmod +x fix-server-issues.sh
chmod +x quick-vps-fix.sh
```

## 🚀 Paso 5: Ejecutar la Corrección

**Opción A - Corrección Rápida (Recomendada):**
```bash
sudo ./quick-vps-fix.sh
```

**Opción B - Corrección Completa:**
```bash
sudo ./fix-server-issues.sh
```

## ✅ Paso 6: Verificar que Funcione

Después de que termine el script, verifica:

```bash
# Ver estado de servicios
sudo systemctl status nginx
pm2 status

# Probar si responde
curl http://46.202.93.54/api/health
```

## 🌐 Paso 7: Probar en el Navegador

Abre tu navegador y ve a:
- **Frontend**: http://46.202.93.54
- **Login**: Usuario `admin`, Contraseña `123456`

---

## 📋 Resumen de Comandos (Copia y Pega)

```bash
# 1. Conectar al VPS (desde tu PC Windows)
ssh root@46.202.93.54

# 2. Una vez conectado al VPS, ejecutar estos comandos:
cd /var/www/topping-frozen-app
git pull origin main
chmod +x fix-server-issues.sh
chmod +x quick-vps-fix.sh
sudo ./quick-vps-fix.sh

# 3. Verificar
curl http://46.202.93.54/api/health
```

## 🚨 Si Algo Sale Mal

```bash
# Ver logs del backend
pm2 logs topping-frozen-backend

# Reiniciar servicios
sudo systemctl restart nginx
pm2 restart topping-frozen-backend

# Ver estado
pm2 status
sudo systemctl status nginx
```

---

**¡Importante!** Todos estos comandos se ejecutan **DENTRO del servidor VPS**, no en tu computadora local.
