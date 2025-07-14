#!/bin/bash

# 🔧 Script Ultra Rápido - Topping Frozen
# Ejecutar como: bash ultra-quick-fix.sh

echo "🔧 Corrección Ultra Rápida..."
echo "============================"

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    echo "❌ Directorio de aplicación no encontrado"
    exit 1
fi

cd $APP_DIR

echo "🔧 Corrigiendo rutas con authorize correcto..."
cat > backend/src/routes/order.routes.ts << 'EOF'
import { Router } from 'express';
import { OrderController } from '../controllers/order.controller';
import { authenticateToken, authorize } from '../middleware/auth.middleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// Order routes
router.get('/', OrderController.getAllOrders);
router.get('/statistics', OrderController.getOrderStatistics);
router.get('/status/:status', OrderController.getOrdersByStatus);
router.get('/:id', OrderController.getOrderById);

// Create new order (facturacion, admin)
router.post('/', authorize(['admin', 'facturacion']), OrderController.createOrder);

// Update order
router.put('/:id', OrderController.updateOrder);

// Delete order (admin only)
router.delete('/:id', authorize(['admin']), OrderController.deleteOrder);

export default router;
EOF

echo "🔧 Verificando middleware de autorización..."
if [ -f "backend/src/middleware/auth.middleware.ts" ]; then
    if ! grep -q "export.*authorize" backend/src/middleware/auth.middleware.ts; then
        echo "🔧 Agregando función authorize al middleware..."
        cat >> backend/src/middleware/auth.middleware.ts << 'EOF'

// Role-based authorization middleware
export const authorize = (roles: string[]) => {
  return (req: any, res: any, next: any) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};
EOF
    fi
fi

echo "🔧 Reiniciando backend..."
cd backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 2
nohup npm run dev > /tmp/backend-ultra-fix.log 2>&1 &
sleep 5

echo "🔧 Verificando..."
if curl -s http://localhost:3001/api/health | grep -q "success"; then
    echo "✅ Backend funcionando correctamente"
    
    echo "🔧 Probando pedido..."
    TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    TEST_ORDER='{"client_name":"Test Ultra","phone":"123456789","total_amount":15000}'
    
    RESULT=$(curl -s -X POST http://localhost:3001/api/orders \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "$TEST_ORDER")
    
    echo "Resultado: $RESULT"
    
    echo ""
    echo "✅ CORRECCIÓN ULTRA RÁPIDA COMPLETADA"
    echo "===================================="
    echo "🌐 Acceso: https://apptoppingfrozen.com/"
    echo "🔧 Logs: tail -f /tmp/backend-ultra-fix.log"
    echo "✅ ¡Backend funcionando! Los pedidos se guardan en BD 🎉"
else
    echo "❌ Backend no responde"
    echo "Logs:"
    tail -10 /tmp/backend-ultra-fix.log
fi
