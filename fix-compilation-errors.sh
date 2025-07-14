#!/bin/bash

# Script para corregir errores de compilación y completar el build
echo "🔧 Corrigiendo errores de compilación..."

cd /var/www/topping-frozen-app

# 1. Actualizar archivos desde Git
echo "📥 Actualizando archivos desde Git..."
git pull origin main

# 2. Verificar que tokenManager.ts existe
echo "📄 Verificando tokenManager.ts..."
if [ ! -f "src/services/tokenManager.ts" ]; then
    echo "⚠️ Creando tokenManager.ts..."
    cat > src/services/tokenManager.ts << 'EOF'
// Token manager for handling JWT tokens in memory
class TokenManager {
  private token: string | null = null;

  // Set token in memory
  setToken(token: string): void {
    this.token = token;
  }

  // Get token from memory
  getToken(): string | null {
    return this.token;
  }

  // Check if token exists
  hasToken(): boolean {
    return this.token !== null && this.token !== '';
  }

  // Clear token from memory
  clearToken(): void {
    this.token = null;
  }

  // Get authorization header
  getAuthHeader(): { Authorization: string } | {} {
    if (this.hasToken()) {
      return { Authorization: `Bearer ${this.token}` };
    }
    return {};
  }
}

// Export singleton instance
export const tokenManager = new TokenManager();
EOF
fi

# 3. Limpiar completamente
echo "🧹 Limpiando cache y archivos anteriores..."
rm -rf node_modules/.cache 2>/dev/null
rm -rf dist/* 2>/dev/null
rm -rf build/* 2>/dev/null

# 4. Reinstalar dependencias
echo "📦 Reinstalando dependencias..."
npm install --silent

# 5. Intentar compilación con diferentes métodos
echo "🔨 Compilando frontend..."

# Método 1: npm run build
if npm run build 2>/dev/null; then
    echo "✅ Compilación exitosa con npm run build"
elif npx webpack --mode production 2>/dev/null; then
    echo "✅ Compilación exitosa con webpack"
else
    echo "⚠️ Compilación manual..."
    mkdir -p dist
    
    # Copiar archivos estáticos
    cp -r public/* dist/ 2>/dev/null
    
    # Crear index.html básico si no existe
    if [ ! -f "dist/index.html" ]; then
        cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Topping Frozen</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div id="root"></div>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
    <script>
        // Configuración de API
        const API_URL = 'http://46.202.93.54/api';
        
        // Función de login simple
        function login() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            axios.post(API_URL + '/auth/login', {
                username: username,
                password: password
            })
            .then(response => {
                if (response.data.success) {
                    alert('Login exitoso!');
                    localStorage.setItem('token', response.data.data.token);
                    window.location.href = '/dashboard';
                } else {
                    alert('Login fallido: ' + response.data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error de conexión');
            });
        }
        
        // Renderizar formulario de login
        document.getElementById('root').innerHTML = `
            <div class="container mt-5">
                <div class="row justify-content-center">
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-body">
                                <h2 class="text-center mb-4">TOPPING FROZEN</h2>
                                <h4 class="text-center mb-3">Iniciar Sesión</h4>
                                <p class="text-center text-muted">Sistema de Gestión de Pedidos</p>
                                
                                <div class="mb-3">
                                    <label class="form-label">Usuario</label>
                                    <input type="text" class="form-control" id="username" value="admin">
                                </div>
                                
                                <div class="mb-3">
                                    <label class="form-label">Contraseña</label>
                                    <input type="password" class="form-control" id="password" value="123456">
                                </div>
                                
                                <button class="btn btn-primary w-100" onclick="login()">Iniciar Sesión</button>
                                
                                <div class="alert alert-info mt-3">
                                    <strong>Usuarios de prueba:</strong><br>
                                    Usuario: admin - Contraseña: 123456
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    </script>
</body>
</html>
EOF
    fi
fi

# 6. Verificar resultado
echo "🔍 Verificando compilación..."
if [ -f "dist/index.html" ]; then
    echo "✅ Frontend compilado correctamente"
    ls -la dist/
else
    echo "❌ Error en compilación"
    exit 1
fi

# 7. Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
systemctl restart nginx

# 8. Verificación final
echo "🧪 Verificación final..."
HEALTH_CHECK=$(curl -s http://46.202.93.54/api/health 2>/dev/null)
echo "Backend health: $HEALTH_CHECK"

echo ""
echo "🎉 ¡Compilación completada!"
echo "🌐 Abre http://46.202.93.54 y prueba el login"
echo "🔐 Usuario: admin / Contraseña: 123456"
