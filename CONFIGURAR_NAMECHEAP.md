# 🌐 Configurar Dominio en Namecheap - apptoppingfrozen.com

Guía paso a paso para configurar tu dominio apptoppingfrozen.com en Namecheap para que apunte a tu VPS.

## 📋 **INFORMACIÓN NECESARIA**

- **Dominio:** apptoppingfrozen.com
- **IP del VPS:** 46.202.93.54
- **Proveedor:** Namecheap

---

## 🎯 **PASO 1: ACCEDER AL PANEL DE NAMECHEAP**

### **1. Iniciar sesión:**
- Ve a: https://www.namecheap.com
- Click en **"Sign In"** (esquina superior derecha)
- Ingresa tu email y contraseña

### **2. Ir a Domain List:**
- Una vez logueado, click en **"Domain List"** en el menú superior
- Busca **apptoppingfrozen.com** en la lista

---

## 🔧 **PASO 2: CONFIGURAR DNS**

### **1. Acceder a DNS Management:**
- Al lado de **apptoppingfrozen.com**, click en **"Manage"**
- En la página del dominio, busca la sección **"DNS"**
- Click en **"Advanced DNS"**

### **2. Eliminar registros existentes (si los hay):**
- Busca cualquier registro **A** existente
- Click en el ícono de **"basura"** 🗑️ para eliminarlos
- Elimina también registros **CNAME** si existen para **@** y **www**

---

## 📝 **PASO 3: AGREGAR NUEVOS REGISTROS DNS**

### **Agregar estos registros exactos:**

#### **Registro 1: Dominio principal**
```
Type: A Record
Host: @
Value: 46.202.93.54
TTL: Automatic (o 3600)
```

#### **Registro 2: Subdominio www**
```
Type: A Record
Host: www
Value: 46.202.93.54
TTL: Automatic (o 3600)
```

### **Cómo agregar cada registro:**

1. **Click en "Add New Record"**
2. **Seleccionar "A Record"** en el dropdown
3. **En "Host"** escribir: `@` (para el primer registro)
4. **En "Value"** escribir: `46.202.93.54`
5. **TTL:** dejar en "Automatic"
6. **Click "Save Changes"** ✅

7. **Repetir para el segundo registro** pero en "Host" escribir: `www`

---

## 📱 **PASO 4: CONFIGURACIÓN FINAL EN NAMECHEAP**

### **Tu configuración DNS debe verse así:**

```
Type        Host    Value           TTL
A Record    @       46.202.93.54    Automatic
A Record    www     46.202.93.54    Automatic
```

### **Verificar configuración:**
- Los registros deben aparecer en la lista
- El estado debe ser **"Active"** o **"✅"**
- No debe haber errores en rojo

---

## ⏱️ **PASO 5: TIEMPO DE PROPAGACIÓN**

### **Tiempos esperados:**
- **Namecheap:** 30 minutos - 2 horas
- **Propagación global:** 2-24 horas (máximo 48 horas)

### **Verificar propagación:**
```bash
# Desde tu computadora
nslookup apptoppingfrozen.com
nslookup www.apptoppingfrozen.com

# Debería mostrar: 46.202.93.54
```

### **Herramientas online para verificar:**
- https://dnschecker.org
- https://whatsmydns.net
- Buscar: **apptoppingfrozen.com**

---

## 🔍 **PASO 6: CONFIGURACIONES ADICIONALES (OPCIONAL)**

### **Si quieres agregar más subdominios:**

#### **Para API (opcional):**
```
Type: CNAME Record
Host: api
Value: apptoppingfrozen.com
TTL: Automatic
```

#### **Para mail (opcional):**
```
Type: MX Record
Host: @
Value: mail.apptoppingfrozen.com
Priority: 10
TTL: Automatic
```

---

## 🆘 **TROUBLESHOOTING NAMECHEAP**

### **Problema: No encuentro "Advanced DNS"**
1. Ve a **Domain List**
2. Click **"Manage"** al lado de tu dominio
3. Busca la pestaña **"Advanced DNS"** (no "Basic DNS")

### **Problema: Error al guardar registros**
- Verificar que la IP sea exactamente: `46.202.93.54`
- No agregar `http://` o `https://` en el valor
- Usar solo números y puntos en la IP

### **Problema: DNS no propaga**
```bash
# Verificar desde diferentes ubicaciones
# Usar: https://dnschecker.org
# Ingresar: apptoppingfrozen.com
# Verificar que muestre: 46.202.93.54
```

### **Problema: Registros duplicados**
- Eliminar TODOS los registros A existentes
- Agregar solo los dos registros nuevos
- No debe haber conflictos

---

## 📋 **CONFIGURACIÓN PASO A PASO CON IMÁGENES**

### **1. Login a Namecheap:**
- Ir a namecheap.com
- Click "Sign In"
- Ingresar credenciales

### **2. Domain List:**
- Click "Domain List" en el menú
- Buscar "apptoppingfrozen.com"
- Click "Manage"

### **3. Advanced DNS:**
- Click pestaña "Advanced DNS"
- Ver lista de registros actuales

### **4. Eliminar registros existentes:**
- Click ícono basura 🗑️ en registros A existentes
- Confirmar eliminación

### **5. Agregar nuevo registro A:**
- Click "Add New Record"
- Type: "A Record"
- Host: "@"
- Value: "46.202.93.54"
- Click "Save Changes"

### **6. Agregar registro www:**
- Click "Add New Record" otra vez
- Type: "A Record"  
- Host: "www"
- Value: "46.202.93.54"
- Click "Save Changes"

---

## ✅ **VERIFICACIÓN FINAL**

### **En Namecheap debe verse:**
```
Host Record    Value           TTL
@              46.202.93.54    Automatic
www            46.202.93.54    Automatic
```

### **Probar desde tu computadora:**
```bash
# Después de 30 minutos - 2 horas
ping apptoppingfrozen.com
ping www.apptoppingfrozen.com

# Ambos deben responder desde: 46.202.93.54
```

---

## 🎯 **PRÓXIMOS PASOS DESPUÉS DE CONFIGURAR DNS**

### **1. Esperar propagación (30 min - 2 horas)**

### **2. Instalar aplicación en VPS:**
```bash
ssh root@46.202.93.54
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps.sh | sudo bash
```

### **3. Configurar SSL:**
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo systemctl stop nginx
sudo certbot certonly --standalone -d apptoppingfrozen.com -d www.apptoppingfrozen.com
```

### **4. Probar aplicación:**
- **IP:** http://46.202.93.54
- **Dominio:** https://apptoppingfrozen.com

---

## 🎉 **RESULTADO FINAL**

Una vez configurado correctamente:

### **✅ URLs funcionando:**
- **https://apptoppingfrozen.com** ← Principal
- **https://www.apptoppingfrozen.com** ← Con www
- **http://46.202.93.54** ← Por IP

### **✅ Redirecciones automáticas:**
- HTTP → HTTPS
- www → sin www (o viceversa)

### **✅ SSL válido:**
- Certificado Let's Encrypt
- Candado verde en navegador
- Renovación automática

**¡Tu dominio apptoppingfrozen.com estará apuntando correctamente a tu VPS! 🚀**
