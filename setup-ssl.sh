#!/bin/bash

# 🔐 Script para Configurar SSL/HTTPS Automáticamente
# Este script configura certificados SSL gratuitos usando Let's Encrypt

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

print_status "🔐 Configurando SSL/HTTPS para tu aplicación"
echo "=================================================="

# Solicitar dominio
read -p "Ingresa tu dominio (ej: miapp.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    print_error "Debes proporcionar un dominio válido"
    exit 1
fi

# Verificar que el dominio apunte al servidor
print_status "🔍 Verificando que el dominio apunte a este servidor..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    print_warning "⚠️  El dominio $DOMAIN no apunta a este servidor"
    print_warning "   Dominio apunta a: $DOMAIN_IP"
    print_warning "   Este servidor: $SERVER_IP"
    read -p "¿Continuar de todos modos? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        print_error "Configuración cancelada"
        exit 1
    fi
fi

# Instalar Certbot
print_status "📦 Instalando Certbot..."
$SUDO apt update
$SUDO apt install -y certbot python3-certbot-nginx

# Verificar configuración de Nginx
print_status "🔧 Verificando configuración de Nginx..."
if ! $SUDO nginx -t; then
    print_error "Error en la configuración de Nginx"
    exit 1
fi

# Actualizar configuración de Nginx con el dominio
print_status "🌐 Actualizando configuración de Nginx..."
$SUDO sed -i "s/server_name .*/server_name $DOMAIN;/" /etc/nginx/sites-available/gestion-pedidos
$SUDO nginx -t && $SUDO systemctl reload nginx

# Obtener certificado SSL
print_status "🔐 Obteniendo certificado SSL..."
$SUDO certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Verificar renovación automática
print_status "🔄 Configurando renovación automática..."
$SUDO systemctl status certbot.timer

# Actualizar variables de entorno con HTTPS
print_status "⚙️ Actualizando variables de entorno..."
cd /home/gestionPedidos

# Actualizar .env principal
sed -i "s|FRONTEND_URL=.*|FRONTEND_URL=https://$DOMAIN|" .env

# Actualizar backend/.env
sed -i "s|FRONTEND_URL=.*|FRONTEND_URL=https://$DOMAIN|" backend/.env

# Reiniciar aplicación
print_status "🔄 Reiniciando aplicación..."
pm2 restart gestion-pedidos-backend

# Verificar SSL
print_status "✅ Verificando configuración SSL..."
if curl -s -I https://$DOMAIN | grep -q "HTTP/2 200"; then
    print_success "SSL configurado correctamente"
else
    print_warning "Puede haber un problema con la configuración SSL"
fi

echo ""
echo "=================================================="
print_success "🎉 ¡SSL configurado exitosamente!"
echo "=================================================="
echo ""
print_status "📋 Información:"
echo "• URL segura: https://$DOMAIN"
echo "• Certificado válido por 90 días"
echo "• Renovación automática configurada"
echo ""
print_status "🔧 Comandos útiles:"
echo "• Verificar certificado: sudo certbot certificates"
echo "• Renovar manualmente: sudo certbot renew"
echo "• Ver logs de renovación: sudo journalctl -u certbot.timer"
echo ""
print_success "¡Tu aplicación ahora es segura con HTTPS! 🔒"
