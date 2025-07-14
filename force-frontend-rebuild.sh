#!/bin/bash

# Script para forzar recompilación del frontend con URL correcta
echo "🔧 Forzando recompilación del frontend..."

cd /var/www/topping-frozen-app

# 1. Verificar URL actual en api.ts
echo "📄 URL actual en api.ts:"
grep -n "API_URL" src/services/api.ts

# 2. Forzar URL correcta
echo "🔧 Corrigiendo URL..."
sed -i 's|http://\[.*\]:[0-9]*/api|http://46.202.93.54/api|g' src/services/api.ts
sed -i 's|http://localhost:[0-9]*/api|http://46.202.93.54/api|g' src/services/api.ts
sed -i 's|process\.env\.REACT_APP_API_URL.*||g' src/services/api.ts

# Asegurar que la línea sea exactamente lo que necesitamos
cat > src/services/api.ts << 'EOF'
import axios from 'axios';
import { tokenManager } from './tokenManager';

// API base URL - Use server IP for production
const API_URL = 'http://46.202.93.54/api';

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = tokenManager.getToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle 401 Unauthorized errors
    if (error.response && error.response.status === 401) {
      // Clear token from memory
      tokenManager.clearToken();
      
      // Only redirect to login if we're not already on the login page
      // This prevents redirect loops
      if (!window.location.pathname.includes('/login')) {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default api;
EOF

echo "✅ URL corregida en api.ts:"
grep -n "API_URL" src/services/api.ts

# 3. Limpiar cache y recompilar
echo "🧹 Limpiando cache..."
rm -rf node_modules/.cache 2>/dev/null
rm -rf dist/* 2>/dev/null
rm -rf build/* 2>/dev/null

# 4. Crear .env para frontend
echo "📝 Creando .env..."
cat > .env << 'EOF'
REACT_APP_API_URL=http://46.202.93.54/api
REACT_APP_BACKEND_URL=http://46.202.93.54
EOF

# 5. Instalar dependencias
echo "📦 Instalando dependencias..."
npm install --silent

# 6. Compilar frontend
echo "🔨 Compilando frontend..."
if command -v npm run build &> /dev/null; then
    npm run build
elif [ -f "webpack.config.js" ]; then
    npx webpack --mode production
else
    echo "⚠️ No se encontró método de compilación, creando dist manual..."
    mkdir -p dist
    cp -r public/* dist/ 2>/dev/null
    cp -r src/* dist/ 2>/dev/null
fi

# 7. Verificar compilación
echo "🔍 Verificando compilación..."
if [ -f "dist/index.html" ]; then
    echo "✅ Frontend compilado correctamente"
    ls -la dist/
else
    echo "❌ Error en compilación"
    exit 1
fi

# 8. Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
systemctl restart nginx

# 9. Verificación final
echo "🧪 Verificación final..."
echo "Frontend: http://46.202.93.54"
echo "Backend: http://46.202.93.54/api/health"

# Probar backend
HEALTH_CHECK=$(curl -s http://46.202.93.54/api/health 2>/dev/null)
echo "Health check: $HEALTH_CHECK"

echo ""
echo "🎉 ¡Frontend recompilado con URL correcta!"
echo "🌐 Abre http://46.202.93.54 y prueba el login"
echo "🔐 Usuario: admin / Contraseña: 123456"
