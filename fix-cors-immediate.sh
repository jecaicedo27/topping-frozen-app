#!/bin/bash

# Script para corregir CORS inmediatamente
echo "🔧 Corrigiendo problema de CORS..."

cd /var/www/topping-frozen-app

# 1. Verificar archivo index.js actual
echo "📄 Verificando configuración CORS actual..."
grep -n "cors\|origin" backend/dist/index.js

# 2. Corregir CORS en el código fuente
echo "🔧 Corrigiendo CORS en index.ts..."
cat > backend/src/index.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import orderRoutes from './routes/order.routes';
import moneyReceiptRoutes from './routes/money-receipt.routes';

const app = express();
const PORT = process.env.PORT || 3001;

// CORS configuration - ALLOW ALL ORIGINS
app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/money-receipts', moneyReceiptRoutes);

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`API available at http://localhost:${PORT}/api`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});
EOF

# 3. Recompilar backend
echo "🔨 Recompilando backend..."
cd backend
npx tsc
cd ..

# 4. Reiniciar PM2
echo "🔄 Reiniciando backend..."
pm2 restart topping-frozen-backend
sleep 5

# 5. Verificar que CORS esté corregido
echo "🧪 Verificando corrección de CORS..."
sleep 3

# Probar desde el frontend
CORS_TEST=$(curl -s -H "Origin: http://46.202.93.54" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:3001/api/auth/login)

echo "Respuesta CORS: $CORS_TEST"

# Probar login real
LOGIN_TEST=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://46.202.93.54" \
  -d '{"username":"admin","password":"123456"}')

echo "Login test: $LOGIN_TEST"

if echo "$LOGIN_TEST" | grep -q "token"; then
    echo "🎉 ¡CORS CORREGIDO! Login funcionando"
    echo "🌐 Prueba ahora en: http://46.202.93.54"
    echo "🔐 Usuario: admin / Contraseña: 123456"
else
    echo "⚠️ Verificando logs..."
    pm2 logs topping-frozen-backend --lines 5 --nostream
fi
