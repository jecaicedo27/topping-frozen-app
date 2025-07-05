# 🔍 Cómo Encontrar la IP de tu VPS

Guía rápida para encontrar y usar la IP de tu servidor VPS.

## 📋 **¿DÓNDE ENCONTRAR LA IP DE TU VPS?**

### **1. En el Panel de Control de tu Proveedor**
La IP aparece en:
- **Dashboard** de tu proveedor (DigitalOcean, Vultr, Linode, etc.)
- **Sección "Servers"** o "Droplets"
- **Detalles del servidor**

### **2. En el Email de Confirmación**
Cuando compraste el VPS, recibiste un email con:
- **IP Address:** 192.168.1.100 (ejemplo)
- **Username:** root
- **Password:** tu-contraseña

### **3. Desde el VPS (si ya estás conectado)**
```bash
# Ver IP pública
curl ifconfig.me

# Ver todas las IPs
ip addr show

# Ver IP con hostname
hostname -I
```

---

## 🚀 **CÓMO USAR LA IP PARA CONECTARTE**

### **Ejemplo con IP: 192.168.1.100**

#### **1. Conectar por SSH:**
```bash
# Desde tu computadora (CMD o PowerShell)
ssh root@192.168.1.100

# Te pedirá la contraseña
```

#### **2. Instalar la aplicación:**
```bash
# Una vez conectado al VPS, ejecutar:
wget https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh
chmod +x install-vps.sh
sudo bash install-vps.sh
```

#### **3. Acceder a la aplicación:**
- **En navegador:** `http://192.168.1.100`
- **API:** `http://192.168.1.100/api`

---

## 🌐 **CONFIGURAR DNS PARA apptoppingfrozen.com**

### **Una vez que tengas la IP, configura el DNS:**

```
Tipo    Nombre    Valor (TU IP REAL)      TTL
A       @         192.168.1.100          3600
A       www       192.168.1.100          3600
```

**Reemplaza `192.168.1.100` con tu IP real del VPS**

---

## 📱 **EJEMPLOS COMUNES DE IPs DE VPS**

### **DigitalOcean:**
- `134.122.xxx.xxx`
- `159.89.xxx.xxx`
- `167.71.xxx.xxx`

### **Vultr:**
- `45.76.xxx.xxx`
- `149.28.xxx.xxx`
- `207.148.xxx.xxx`

### **Linode:**
- `172.105.xxx.xxx`
- `139.144.xxx.xxx`
- `45.79.xxx.xxx`

### **AWS EC2:**
- `3.xxx.xxx.xxx`
- `52.xxx.xxx.xxx`
- `54.xxx.xxx.xxx`

---

## 🔧 **COMANDOS CON TU IP REAL**

### **Reemplaza `TU_IP_DEL_VPS` con tu IP real:**

```bash
# Conectar SSH
ssh root@TU_IP_DEL_VPS

# Ejemplo con IP real:
ssh root@192.168.1.100
```

```bash
# Probar aplicación
curl http://TU_IP_DEL_VPS

# Ejemplo con IP real:
curl http://192.168.1.100
```

---

## 🆘 **SI NO ENCUENTRAS LA IP**

### **1. Revisar Email de Confirmación**
Busca en tu email el mensaje de confirmación del VPS con asunto como:
- "Your server is ready"
- "VPS Created Successfully"
- "Server Details"

### **2. Contactar Soporte**
Si no encuentras la IP, contacta el soporte de tu proveedor:
- **DigitalOcean:** support@digitalocean.com
- **Vultr:** support@vultr.com
- **Linode:** support@linode.com

### **3. Panel de Control**
Inicia sesión en el panel de control de tu proveedor y busca:
- "My Servers"
- "Droplets"
- "Instances"
- "Virtual Machines"

---

## 📋 **INFORMACIÓN QUE NECESITAS**

Para conectarte y configurar todo, necesitas:

### **✅ Datos del VPS:**
- **IP Address:** (ejemplo: 192.168.1.100)
- **Username:** root (o tu usuario)
- **Password:** (la que te dieron)

### **✅ Datos del Dominio:**
- **Dominio:** apptoppingfrozen.com ✅ (ya lo tienes)
- **Panel DNS:** donde compraste el dominio

---

## 🎯 **PASOS SIGUIENTES**

### **1. Una vez que tengas la IP:**
```bash
# Conectar al VPS
ssh root@TU_IP_REAL

# Instalar aplicación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
```

### **2. Configurar DNS:**
- Ir al panel de tu dominio
- Agregar registro A: @ → TU_IP_REAL
- Agregar registro A: www → TU_IP_REAL

### **3. Configurar SSL:**
```bash
# En el VPS, después de la instalación
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
```

---

## 🎉 **RESULTADO FINAL**

Con tu IP configurada tendrás:

### **✅ Acceso directo por IP:**
- `http://TU_IP_DEL_VPS`

### **✅ Acceso por dominio:**
- `https://apptoppingfrozen.com`

### **✅ Sistema completo funcionando:**
- Login: admin / 123456
- Todas las funcionalidades activas

**¡Compárteme la IP de tu VPS y te ayudo con los comandos específicos! 🚀**
