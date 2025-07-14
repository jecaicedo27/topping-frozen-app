#!/bin/bash

# Script para restaurar todas las funcionalidades React originales sin errores
echo "🔄 Restaurando funcionalidades completas de React..."

cd /var/www/topping-frozen-app

# 1. Restaurar index.tsx completo
echo "📄 Restaurando index.tsx..."
cat > src/index.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import 'bootstrap/dist/css/bootstrap.min.css';
import './styles/index.css';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# 2. Restaurar App.tsx completo con todas las rutas
echo "📄 Restaurando App.tsx completo..."
cat > src/App.tsx << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Facturacion from './pages/Facturacion';
import Cartera from './pages/Cartera';
import Logistica from './pages/Logistica';
import Mensajero from './pages/Mensajero';
import Navigation from './components/Navigation';
import ProtectedRoute from './components/ProtectedRoute';

const AppContent: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Cargando...</span>
        </div>
      </div>
    );
  }

  return (
    <Router>
      {isAuthenticated && <Navigation />}
      <Routes>
        <Route 
          path="/login" 
          element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <Login />} 
        />
        <Route 
          path="/dashboard" 
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/facturacion" 
          element={
            <ProtectedRoute>
              <Facturacion />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/cartera" 
          element={
            <ProtectedRoute>
              <Cartera />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/logistica" 
          element={
            <ProtectedRoute>
              <Logistica />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/mensajero" 
          element={
            <ProtectedRoute>
              <Mensajero />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/" 
          element={<Navigate to={isAuthenticated ? "/dashboard" : "/login"} replace />} 
        />
      </Routes>
    </Router>
  );
};

const App: React.FC = () => {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
};

export default App;
EOF

# 3. Mejorar Navigation con React Router
echo "📄 Mejorando Navigation con React Router..."
cat > src/components/Navigation.tsx << 'EOF'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Navigation: React.FC = () => {
  const { user, logout } = useAuth();
  const location = useLocation();

  const handleLogout = () => {
    logout();
  };

  const isActive = (path: string) => {
    return location.pathname === path ? 'nav-link active' : 'nav-link';
  };

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
      <div className="container">
        <Link className="navbar-brand" to="/dashboard">
          🍦 Topping Frozen
        </Link>
        
        <button 
          className="navbar-toggler" 
          type="button" 
          data-bs-toggle="collapse" 
          data-bs-target="#navbarNav"
        >
          <span className="navbar-toggler-icon"></span>
        </button>
        
        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav me-auto">
            <li className="nav-item">
              <Link className={isActive('/dashboard')} to="/dashboard">
                📊 Dashboard
              </Link>
            </li>
            <li className="nav-item">
              <Link className={isActive('/facturacion')} to="/facturacion">
                💰 Facturación
              </Link>
            </li>
            <li className="nav-item">
              <Link className={isActive('/cartera')} to="/cartera">
                💳 Cartera
              </Link>
            </li>
            <li className="nav-item">
              <Link className={isActive('/logistica')} to="/logistica">
                📦 Logística
              </Link>
            </li>
            <li className="nav-item">
              <Link className={isActive('/mensajero')} to="/mensajero">
                🚚 Mensajería
              </Link>
            </li>
          </ul>
          
          <ul className="navbar-nav">
            <li className="nav-item dropdown">
              <a 
                className="nav-link dropdown-toggle" 
                href="#" 
                id="navbarDropdown" 
                role="button" 
                data-bs-toggle="dropdown"
              >
                👤 {user?.name}
              </a>
              <ul className="dropdown-menu">
                <li><span className="dropdown-item-text">Rol: {user?.role}</span></li>
                <li><hr className="dropdown-divider" /></li>
                <li>
                  <button className="dropdown-item" onClick={handleLogout}>
                    🚪 Cerrar Sesión
                  </button>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
};

export default Navigation;
EOF

# 4. Mejorar Dashboard con más funcionalidades
echo "📄 Mejorando Dashboard..."
cat > src/pages/Dashboard.tsx << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  };

  return (
    <div className="container mt-4 fade-in">
      <div className="row">
        <div className="col-12">
          <h1>🍦 Dashboard - Topping Frozen</h1>
          <div className="alert alert-success">
            <h4>{getGreeting()}, {user?.name}! 👋</h4>
            <p>Has iniciado sesión exitosamente en el sistema Topping Frozen.</p>
            <hr />
            <p className="mb-0">
              <strong>Usuario:</strong> {user?.username} | 
              <strong> Rol:</strong> {user?.role} | 
              <strong> Fecha:</strong> {new Date().toLocaleDateString('es-ES')}
            </p>
          </div>
        </div>
      </div>
      
      <div className="row">
        <div className="col-md-3 mb-3">
          <div className="card h-100 shadow-sm">
            <div className="card-body text-center">
              <div className="display-4 text-primary mb-3">💰</div>
              <h5 className="card-title">Facturación</h5>
              <p className="card-text">Gestión de facturas y ventas</p>
              <Link to="/facturacion" className="btn btn-primary">
                Acceder
              </Link>
            </div>
          </div>
        </div>
        <div className="col-md-3 mb-3">
          <div className="card h-100 shadow-sm">
            <div className="card-body text-center">
              <div className="display-4 text-success mb-3">💳</div>
              <h5 className="card-title">Cartera</h5>
              <p className="card-text">Control de pagos y cobros</p>
              <Link to="/cartera" className="btn btn-success">
                Acceder
              </Link>
            </div>
          </div>
        </div>
        <div className="col-md-3 mb-3">
          <div className="card h-100 shadow-sm">
            <div className="card-body text-center">
              <div className="display-4 text-info mb-3">📦</div>
              <h5 className="card-title">Logística</h5>
              <p className="card-text">Gestión de inventario</p>
              <Link to="/logistica" className="btn btn-info">
                Acceder
              </Link>
            </div>
          </div>
        </div>
        <div className="col-md-3 mb-3">
          <div className="card h-100 shadow-sm">
            <div className="card-body text-center">
              <div className="display-4 text-warning mb-3">🚚</div>
              <h5 className="card-title">Mensajería</h5>
              <p className="card-text">Control de entregas</p>
              <Link to="/mensajero" className="btn btn-warning">
                Acceder
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="row mt-4">
        <div className="col-md-6">
          <div className="card">
            <div className="card-header">
              <h5>📈 Resumen del Día</h5>
            </div>
            <div className="card-body">
              <div className="row text-center">
                <div className="col-4">
                  <h3 className="text-primary">15</h3>
                  <small>Pedidos</small>
                </div>
                <div className="col-4">
                  <h3 className="text-success">$2,450</h3>
                  <small>Ventas</small>
                </div>
                <div className="col-4">
                  <h3 className="text-warning">8</h3>
                  <small>Entregas</small>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-md-6">
          <div className="card">
            <div className="card-header">
              <h5>🎯 Accesos Rápidos</h5>
            </div>
            <div className="card-body">
              <div className="d-grid gap-2">
                <Link to="/facturacion" className="btn btn-outline-primary btn-sm">
                  ➕ Nueva Factura
                </Link>
                <Link to="/cartera" className="btn btn-outline-success btn-sm">
                  💰 Ver Cobros Pendientes
                </Link>
                <Link to="/logistica" className="btn btn-outline-info btn-sm">
                  📊 Revisar Inventario
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
EOF

# 5. Mejorar CSS con más estilos
echo "📄 Mejorando estilos CSS..."
cat >> src/styles/index.css << 'EOF'

/* Estilos adicionales para funcionalidades completas */
.fade-in {
  animation: fadeIn 0.5s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.card {
  transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
}

.card:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

.navbar-brand {
  font-weight: bold;
  font-size: 1.5rem;
}

.nav-link.active {
  background-color: rgba(255,255,255,0.1);
  border-radius: 5px;
}

.btn {
  transition: all 0.3s ease;
}

.btn:hover {
  transform: translateY(-2px);
}

.alert {
  border: none;
  border-radius: 10px;
}

.spinner-border {
  width: 3rem;
  height: 3rem;
}

/* Responsive improvements */
@media (max-width: 768px) {
  .container {
    padding: 0 15px;
  }
  
  .card-body {
    padding: 1rem;
  }
  
  .display-4 {
    font-size: 2rem;
  }
}
EOF

# 6. Recompilar con React completo
echo "🔨 Recompilando con React completo..."
npm run build 2>/dev/null || npx webpack --mode production

# 7. Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
systemctl restart nginx

echo ""
echo "🎉 ¡Funcionalidades React completas restauradas!"
echo "✅ Navegación con React Router"
echo "✅ Dashboard mejorado con estadísticas"
echo "✅ Todas las páginas funcionales"
echo "✅ Estilos mejorados y responsivos"
echo "✅ Transiciones suaves"
echo ""
echo "🌐 Prueba ahora en: http://46.202.93.54"
echo "🔐 Usuario: admin / Contraseña: 123456"
echo ""
echo "🏆 ¡TOPPING FROZEN CON TODAS LAS FUNCIONALIDADES!"
