# 🔧 Solución: Error "No ejecutar como root"

## ❌ Error Común
```
[ERROR] Este script no debe ejecutarse como root. Usa un usuario con sudo.
```

## ✅ Solución

### Opción 1: Crear usuario con sudo (Recomendado)
```bash
# Si estás como root, crea un usuario normal
adduser toppinguser
usermod -aG sudo toppinguser

# Cambiar a ese usuario
su - toppinguser

# Ahora ejecutar la instalación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash
```

### Opción 2: Usar usuario existente
```bash
# Si ya tienes un usuario (ejemplo: ubuntu)
su - ubuntu

# Ejecutar instalación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash
```

### Opción 3: Conectar directamente con usuario correcto
```bash
# Desconectarse del VPS y reconectar con usuario correcto
exit

# Conectar con usuario que tenga sudo (no root)
ssh ubuntu@tu-ip-del-vps
# o
ssh toppinguser@tu-ip-del-vps

# Ejecutar instalación
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash
```

## 🔍 Verificar Usuario Actual
```bash
# Ver usuario actual
whoami

# Ver si tienes permisos sudo
sudo -l
```

## ⚠️ ¿Por qué no como root?

El script está diseñado para **NO ejecutarse como root** por seguridad:
- Evita permisos excesivos
- Previene errores de configuración
- Sigue mejores prácticas de seguridad
- PM2 funciona mejor con usuarios normales

## 🎯 Usuarios Recomendados por Proveedor

- **DigitalOcean**: `root` → crear usuario
- **AWS EC2**: `ubuntu` o `ec2-user`
- **Google Cloud**: `tu-nombre-usuario`
- **Hostinger VPS**: `root` → crear usuario
- **Vultr**: `root` → crear usuario

## 📝 Comando Completo de Ejemplo

```bash
# 1. Crear usuario (si estás como root)
adduser appuser
usermod -aG sudo appuser

# 2. Cambiar a usuario
su - appuser

# 3. Instalar
curl -fsSL https://raw.githubusercontent.com/jecaicedo27/topping-frozen-app/main/install-vps-ubuntu.sh | bash
```

---
**Nota**: Este error es **normal y esperado** - es una característica de seguridad del script.
