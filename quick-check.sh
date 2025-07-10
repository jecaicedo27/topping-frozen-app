#!/bin/bash

echo "🔍 Verificación Rápida del Sistema"
echo "=================================="

cd /home/gestionPedidos

echo "1. Estado de PM2:"
pm2 status

echo ""
echo "2. Últimos logs del backend:"
pm2 logs gestion-pedidos-backend --lines 10

echo ""
echo "3. Verificando puerto 5000:"
netstat -tlnp | grep :5000

echo ""
echo "4. Verificando usuarios en BD:"
mysql -u appuser -papppassword123 -e "USE gestionPedidos; SELECT username, role FROM users;" 2>/dev/null

echo ""
echo "5. Test de API directa:"
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' 2>/dev/null || echo "Error en API"

echo ""
echo "6. Verificando configuración Nginx:"
sudo nginx -t

echo ""
echo "7. Logs de Nginx:"
sudo tail -3 /var/log/nginx/error.log
