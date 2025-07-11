# 🚀 Instalación Rápida - Topping Frozen App

## Comandos de Instalación Directa

### 1. Conectar al VPS
```bash
ssh tu-usuario@tu-ip-del-vps
```

**Reemplaza:**
- `tu-usuario`: Tu nombre de usuario del VPS (ejemplo: `root`, `ubuntu`, `admin`)
- `tu-ip-del-vps`: La IP de tu servidor (ejemplo: `192.168.1.100`)

### 2. Ejecutar Instalación Automática
```bash
# Descargar e instalar en un solo comando
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash
```

**O paso a paso:**
```bash
# Descargar script
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh

# Dar permisos
chmod +x install-vps-ubuntu.sh

# Ejecutar
./install-vps-ubuntu.sh
```

## 📋 Información Importante

### Credenciales de la Aplicación:
- **URL**: `http://tu-ip-del-vps`
- **Usuario**: `admin`
- **Contraseña**: `123456`

### Credenciales de Base de Datos:
- **Host**: `localhost`
- **Base de datos**: `topping_frozen`
- **Usuario**: `toppinguser`
- **Contraseña**: `ToppingFrozen2024!`

### Usuarios Comunes de VPS:
- **Ubuntu/Debian**: `ubuntu`
- **CentOS/RHEL**: `centos`
- **Root**: `root` (no recomendado)
- **Personalizado**: El que hayas configurado

## ⚡ Ejemplo Completo

Si tu VPS tiene IP `192.168.1.100` y usuario `ubuntu`:

```bash
# 1. Conectar
ssh ubuntu@192.168.1.100

# 2. Instalar
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash

# 3. Acceder
# Ir a: http://192.168.1.100
# Login: admin / 123456
```

## 🔧 Comandos Post-Instalación

```bash
# Ver estado de la aplicación
pm2 status

# Ver logs
pm2 logs topping-frozen-backend

# Reiniciar aplicación
pm2 restart topping-frozen-backend
```

## 🆘 Si Algo Sale Mal

```bash
# Ver logs de instalación
tail -f /var/log/syslog

# Verificar servicios
sudo systemctl status nginx
sudo systemctl status mysql
pm2 status
```

---
**Tiempo estimado**: 15-20 minutos
**Requisitos**: Ubuntu 20.04+, 2GB RAM, usuario con sudo
