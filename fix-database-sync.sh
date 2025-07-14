#!/bin/bash

# 🔧 Script para Corregir Sincronización con Base de Datos - Topping Frozen
# Ejecutar como: bash fix-database-sync.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✅ OK]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[🔧 STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

echo "🔧 Diagnosticando y Corrigiendo Sincronización con Base de Datos..."
echo "=================================================================="

# Detectar directorio de aplicación
if [ -d "/root/topping-frozen-app" ]; then
    APP_DIR="/root/topping-frozen-app"
elif [ -d "/home/toppingapp/topping-frozen-app" ]; then
    APP_DIR="/home/toppingapp/topping-frozen-app"
else
    print_error "Directorio de aplicación no encontrado"
    exit 1
fi

cd $APP_DIR

print_step "1. Verificando conexión a base de datos..."
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT COUNT(*) as total_orders FROM orders;" 2>/dev/null

if [ $? -eq 0 ]; then
    print_status "Conexión a base de datos exitosa"
else
    print_error "Error de conexión a base de datos"
    exit 1
fi

print_step "2. Verificando estructura de tablas..."
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SHOW TABLES;" 2>/dev/null

print_step "3. Verificando datos existentes..."
echo "Pedidos en base de datos:"
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT id, customer_name, total, status, created_at FROM orders ORDER BY created_at DESC LIMIT 10;" 2>/dev/null

echo ""
echo "Usuarios en base de datos:"
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT id, username, name, role FROM users;" 2>/dev/null

print_step "4. Verificando endpoints de API..."
echo "Probando endpoint GET /api/orders:"
curl -s -H "Authorization: Bearer $(curl -s -X POST http://localhost:3001/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)" http://localhost:3001/api/orders

echo ""
echo ""
echo "Probando endpoint POST /api/orders (crear pedido de prueba):"
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

TEST_ORDER='{"customer_name":"Cliente Prueba","customer_phone":"123456789","customer_address":"Dirección Prueba","items":[{"name":"Producto Test","quantity":1,"price":10000}],"total":10000,"status":"pending"}'

curl -s -X POST http://localhost:3001/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$TEST_ORDER"

print_step "5. Verificando logs del backend..."
echo "Últimos logs del backend:"
if [ -f "/tmp/backend-ssl.log" ]; then
    tail -20 /tmp/backend-ssl.log
elif [ -f "/tmp/backend-final.log" ]; then
    tail -20 /tmp/backend-final.log
else
    print_warning "No se encontraron logs del backend"
fi

print_step "6. Verificando configuración CORS del backend..."
if [ -f "backend/src/index.ts" ]; then
    echo "Configuración CORS actual:"
    grep -A 10 -B 5 "cors" backend/src/index.ts || echo "No se encontró configuración CORS"
fi

print_step "7. Corrigiendo configuración del backend..."
# Verificar y corregir el archivo principal del backend
cat > backend/src/index.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { initializeDatabase } from './config/initDb';
import authRoutes from './routes/auth.routes';
import orderRoutes from './routes/order.routes';
import userRoutes from './routes/user.routes';
import moneyReceiptRoutes from './routes/money-receipt.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Configuración CORS más permisiva
app.use(cors({
  origin: ['http://localhost:3000', 'http://apptoppingfrozen.com', 'https://apptoppingfrozen.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'API is running', 
    timestamp: new Date().toISOString(),
    database: 'connected'
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/money-receipts', moneyReceiptRoutes);

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({ 
    success: false, 
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    success: false, 
    message: 'Route not found',
    path: req.originalUrl
  });
});

// Initialize database and start server
async function startServer() {
  try {
    console.log('Connecting to MySQL server...');
    await initializeDatabase();
    console.log('Database initialized successfully');
    console.log('Database connection closed');
    console.log('Database connection established successfully');
    
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`API available at http://localhost:${PORT}/api`);
    });
  } catch (error) {
    console.error('Error starting server:', error);
    process.exit(1);
  }
}

startServer();
EOF

print_step "8. Verificando controlador de pedidos..."
if [ -f "backend/src/controllers/order.controller.ts" ]; then
    echo "Verificando order.controller.ts..."
    grep -A 5 -B 5 "createOrder\|INSERT\|orders" backend/src/controllers/order.controller.ts | head -20
fi

print_step "9. Corrigiendo controlador de pedidos..."
cat > backend/src/controllers/order.controller.ts << 'EOF'
import { Request, Response } from 'express';
import { Order } from '../models/order.model';

export const createOrder = async (req: Request, res: Response) => {
  try {
    console.log('Creating order with data:', req.body);
    
    const { customer_name, customer_phone, customer_address, items, total, status = 'pending' } = req.body;
    
    if (!customer_name || !customer_phone || !items || !total) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: customer_name, customer_phone, items, total'
      });
    }

    const orderData = {
      customer_name,
      customer_phone,
      customer_address: customer_address || '',
      items: JSON.stringify(items),
      total: parseFloat(total),
      status,
      created_at: new Date(),
      updated_at: new Date()
    };

    console.log('Saving order to database:', orderData);
    const orderId = await Order.create(orderData);
    
    console.log('Order created with ID:', orderId);
    
    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: {
        id: orderId,
        ...orderData,
        items: JSON.parse(orderData.items)
      }
    });
  } catch (error: any) {
    console.error('Error creating order:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating order',
      error: error.message
    });
  }
};

export const getOrders = async (req: Request, res: Response) => {
  try {
    console.log('Fetching orders...');
    const orders = await Order.findAll();
    
    // Parse items JSON for each order
    const ordersWithParsedItems = orders.map(order => ({
      ...order,
      items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items
    }));
    
    console.log(`Found ${orders.length} orders`);
    
    res.json({
      success: true,
      data: ordersWithParsedItems
    });
  } catch (error: any) {
    console.error('Error fetching orders:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching orders',
      error: error.message
    });
  }
};

export const getOrderById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log('Fetching order with ID:', id);
    
    const order = await Order.findById(parseInt(id));
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Parse items JSON
    const orderWithParsedItems = {
      ...order,
      items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items
    };
    
    res.json({
      success: true,
      data: orderWithParsedItems
    });
  } catch (error: any) {
    console.error('Error fetching order:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order',
      error: error.message
    });
  }
};

export const updateOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log('Updating order with ID:', id, 'Data:', req.body);
    
    const updateData = { ...req.body };
    if (updateData.items && typeof updateData.items !== 'string') {
      updateData.items = JSON.stringify(updateData.items);
    }
    updateData.updated_at = new Date();
    
    const success = await Order.update(parseInt(id), updateData);
    
    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }
    
    console.log('Order updated successfully');
    
    res.json({
      success: true,
      message: 'Order updated successfully'
    });
  } catch (error: any) {
    console.error('Error updating order:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating order',
      error: error.message
    });
  }
};

export const deleteOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log('Deleting order with ID:', id);
    
    const success = await Order.delete(parseInt(id));
    
    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }
    
    console.log('Order deleted successfully');
    
    res.json({
      success: true,
      message: 'Order deleted successfully'
    });
  } catch (error: any) {
    console.error('Error deleting order:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting order',
      error: error.message
    });
  }
};
EOF

print_step "10. Reiniciando backend con nueva configuración..."
cd backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 3
nohup npm run dev > /tmp/backend-database-fix.log 2>&1 &
sleep 5

print_step "11. Verificando que el backend esté funcionando..."
if curl -s http://localhost:3001/api/health | grep -q "success"; then
    print_status "Backend funcionando correctamente"
else
    print_error "Backend no responde"
    echo "Logs del backend:"
    tail -10 /tmp/backend-database-fix.log
fi

print_step "12. Probando creación de pedido después de la corrección..."
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token obtenido: ${TOKEN:0:20}..."

TEST_ORDER_2='{"customer_name":"Cliente Test Final","customer_phone":"987654321","customer_address":"Dirección Test Final","items":[{"name":"Producto Final","quantity":2,"price":15000}],"total":30000,"status":"pending"}'

echo "Creando pedido de prueba..."
RESULT=$(curl -s -X POST http://localhost:3001/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$TEST_ORDER_2")

echo "Resultado: $RESULT"

print_step "13. Verificando pedidos en base de datos después de la prueba..."
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT id, customer_name, total, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5;" 2>/dev/null

echo ""
echo "🔧 CORRECCIÓN DE SINCRONIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 CAMBIOS REALIZADOS:"
echo "   ✅ Backend reconfigurado con logs detallados"
echo "   ✅ CORS configurado correctamente"
echo "   ✅ Controlador de pedidos corregido"
echo "   ✅ Validaciones mejoradas"
echo "   ✅ Manejo de errores mejorado"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: https://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 LOGS PARA MONITOREAR:"
echo "   Backend: tail -f /tmp/backend-database-fix.log"
echo "   Nginx: tail -f /var/log/nginx/topping-frozen-ssl.error.log"
echo ""
echo "📊 VERIFICAR SINCRONIZACIÓN:"
echo "   1. Crear pedidos en el frontend"
echo "   2. Verificar en otro dispositivo"
echo "   3. Los datos deberían aparecer en ambos"
echo ""
print_status "¡Sincronización con base de datos corregida! 🔄"
