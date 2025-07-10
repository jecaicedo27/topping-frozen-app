#!/bin/bash

# 🔧 Script para Solucionar Instalación de Node.js en VPS
# Este script soluciona problemas comunes con la instalación de Node.js

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si estamos ejecutando como root o con sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

print_status "🔧 Solucionando instalación de Node.js..."

# Limpiar instalaciones previas problemáticas
print_status "🧹 Limpiando instalaciones previas..."
$SUDO apt remove -y nodejs npm || true
$SUDO apt autoremove -y || true

# Actualizar sistema
print_status "📦 Actualizando sistema..."
$SUDO apt update

# Método alternativo para instalar Node.js usando snap
print_status "🟢 Instalando Node.js usando snap..."
$SUDO apt install -y snapd
$SUDO snap install node --classic

# Verificar instalación
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    print_success "Node.js instalado correctamente: $NODE_VERSION"
else
    print_warning "Snap falló, intentando método manual..."
    
    # Método manual de instalación
    print_status "📥 Descargando Node.js manualmente..."
    cd /tmp
    wget https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.xz
    tar -xf node-v18.19.0-linux-x64.tar.xz
    $SUDO mv node-v18.19.0-linux-x64 /opt/nodejs
    
    # Crear enlaces simbólicos
    $SUDO ln -sf /opt/nodejs/bin/node /usr/local/bin/node
    $SUDO ln -sf /opt/nodejs/bin/npm /usr/local/bin/npm
    $SUDO ln -sf /opt/nodejs/bin/npx /usr/local/bin/npx
    
    # Agregar al PATH
    echo 'export PATH=/opt/nodejs/bin:$PATH' | $SUDO tee -a /etc/profile
    export PATH=/opt/nodejs/bin:$PATH
fi

# Verificar instalación final
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_success "✅ Node.js instalado correctamente: $NODE_VERSION"
    print_success "✅ NPM instalado correctamente: $NPM_VERSION"
    
    # Instalar PM2
    print_status "⚡ Instalando PM2..."
    npm install -g pm2
    
    print_success "🎉 ¡Instalación completada!"
    echo ""
    echo "Ahora puedes continuar con el script de despliegue:"
    echo "./deploy-to-vps.sh"
    
else
    print_error "❌ Error en la instalación de Node.js"
    print_error "Por favor, instala Node.js manualmente o contacta soporte"
fi
