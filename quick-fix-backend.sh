#!/bin/bash

# 🔧 Script de Corrección Rápida del Backend - Topping Frozen
# Ejecutar como: bash quick-fix-backend.sh

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

echo "🔧 Corrección Rápida del Backend..."
echo "=================================="

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

print_step "1. Corrigiendo import en index.ts..."
cat > backend/src/index.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { testConnection } from './config/db';
import initializeDatabase from './config/initDb';

// Import routes
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import orderRoutes from './routes/order.routes';
import moneyReceiptRoutes from './routes/money-receipt.routes';

dotenv.config();

// Create Express app
const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://apptoppingfrozen.com', 'https://apptoppingfrozen.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

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

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/money-receipts', moneyReceiptRoutes);

// Health check route
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'API is running', 
    timestamp: new Date().toISOString(),
    database: 'connected'
  });
});

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
    await testConnection();
    console.log('Database connection established successfully');
    
    await initializeDatabase();
    console.log('Database initialized successfully');
    
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

print_step "2. Verificando modelo de pedidos..."
if [ -f "backend/src/models/order.model.ts" ]; then
    echo "Modelo actual de pedidos:"
    head -30 backend/src/models/order.model.ts
fi

print_step "3. Corrigiendo controlador de pedidos para incluir invoice_code..."
cat > backend/src/controllers/order.controller.ts << 'EOF'
import { Request, Response } from 'express';
import { OrderModel, Order } from '../models/order.model';

export class OrderController {
  // Get all orders
  static async getAllOrders(req: Request, res: Response): Promise<void> {
    try {
      console.log('Fetching all orders...');
      const orders = await OrderModel.findAll();
      console.log(`Found ${orders.length} orders`);
      
      res.status(200).json({
        success: true,
        data: orders
      });
    } catch (error) {
      console.error('Error fetching orders:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Create new order
  static async createOrder(req: Request, res: Response): Promise<void> {
    try {
      console.log('Creating order with data:', req.body);
      
      const { customer_name, customer_phone, customer_address, items, total, status = 'pending' } = req.body;
      
      if (!customer_name || !customer_phone || !items || !total) {
        res.status(400).json({
          success: false,
          message: 'Missing required fields: customer_name, customer_phone, items, total'
        });
        return;
      }

      // Generar invoice_code automáticamente
      const timestamp = Date.now();
      const invoice_code = `INV-${timestamp}`;

      const orderData: Partial<Order> = {
        invoice_code,
        customer_name,
        customer_phone,
        customer_address: customer_address || '',
        items: typeof items === 'string' ? items : JSON.stringify(items),
        total: parseFloat(total.toString()),
        status,
        created_at: new Date(),
        updated_at: new Date()
      };

      console.log('Saving order to database:', orderData);
      const orderId = await OrderModel.create(orderData);
      
      console.log('Order created with ID:', orderId);
      
      res.status(201).json({
        success: true,
        message: 'Order created successfully',
        data: {
          id: orderId,
          ...orderData,
          items: typeof orderData.items === 'string' ? JSON.parse(orderData.items) : orderData.items
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
  }

  // Get order by ID
  static async getOrderById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      console.log('Fetching order with ID:', id);
      
      const order = await OrderModel.findById(parseInt(id));
      
      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }

      // Parse items JSON if it's a string
      const orderWithParsedItems = {
        ...order,
        items: typeof order.items === 'string' ? JSON.parse(order.items) : order.items
      };
      
      res.status(200).json({
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
  }

  // Update order
  static async updateOrder(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      console.log('Updating order with ID:', id, 'Data:', req.body);
      
      const updateData = { ...req.body };
      if (updateData.items && typeof updateData.items !== 'string') {
        updateData.items = JSON.stringify(updateData.items);
      }
      updateData.updated_at = new Date();
      
      const success = await OrderModel.update(parseInt(id), updateData);
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }
      
      console.log('Order updated successfully');
      
      res.status(200).json({
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
  }

  // Delete order
  static async deleteOrder(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      console.log('Deleting order with ID:', id);
      
      const success = await OrderModel.delete(parseInt(id));
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }
      
      console.log('Order deleted successfully');
      
      res.status(200).json({
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
  }
}
EOF

print_step "4. Reiniciando backend..."
cd backend
pkill -f "npm run dev" || true
pkill -f "ts-node-dev" || true
sleep 3
nohup npm run dev > /tmp/backend-quick-fix.log 2>&1 &
sleep 5

print_step "5. Verificando que el backend esté funcionando..."
if curl -s http://localhost:3001/api/health | grep -q "success"; then
    print_status "Backend funcionando correctamente"
else
    print_error "Backend no responde"
    echo "Logs del backend:"
    tail -10 /tmp/backend-quick-fix.log
    exit 1
fi

print_step "6. Probando creación de pedido con invoice_code..."
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token obtenido: ${TOKEN:0:20}..."

TEST_ORDER='{"customer_name":"Cliente Test Rápido","customer_phone":"555123456","customer_address":"Dirección Test","items":[{"name":"Producto Test","quantity":1,"price":25000}],"total":25000,"status":"pending"}'

echo "Creando pedido de prueba..."
RESULT=$(curl -s -X POST http://localhost:3001/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$TEST_ORDER")

echo "Resultado: $RESULT"

print_step "7. Verificando pedidos en base de datos..."
mysql -u toppinguser -pToppingPass2024! -h 127.0.0.1 topping_frozen_db -e "SELECT id, invoice_code, customer_name, total, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5;" 2>/dev/null

echo ""
echo "🔧 CORRECCIÓN RÁPIDA COMPLETADA"
echo "==============================="
echo ""
echo "📋 CAMBIOS REALIZADOS:"
echo "   ✅ Import corregido en index.ts"
echo "   ✅ Controlador actualizado con invoice_code automático"
echo "   ✅ CORS configurado correctamente"
echo "   ✅ Logs detallados habilitados"
echo "   ✅ Backend reiniciado"
echo ""
echo "🌐 ACCESO:"
echo "   Frontend: https://apptoppingfrozen.com/"
echo "   Credenciales: admin / 123456"
echo ""
echo "🔧 LOGS:"
echo "   Backend: tail -f /tmp/backend-quick-fix.log"
echo ""
print_status "¡Backend corregido! Los pedidos ahora deberían guardarse en la BD 🔄"
