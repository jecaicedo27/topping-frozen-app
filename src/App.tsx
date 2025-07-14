import React from 'react';
import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { Container } from 'react-bootstrap';

// Components
import Navigation from './components/Navigation';
import ProtectedRoute from './components/ProtectedRoute';

// Pages
import Dashboard from './pages/Dashboard';
import Facturacion from './pages/Facturacion';
import Cartera from './pages/Cartera';
import Logistica from './pages/Logistica';
import Mensajero from './pages/Mensajero';
import NotFound from './pages/NotFound';
import Login from './pages/Login';

// Context
import { AuthProvider } from './context/AuthContext';
import { OrderProvider } from './context/OrderContext';

// Types
import { UserRole } from './types/user';

const App: React.FC = () => {
  return (
    <AuthProvider>
      <OrderProvider>
        <Routes>
        {/* Public Routes */}
        <Route path="/login" element={<Login />} />
        <Route path="/404" element={<NotFound />} />

        {/* Protected Routes */}
        <Route element={<ProtectedRoute />}>
          {/* Layout wrapper for all protected routes */}
          <Route
            element={
              <>
                <Navigation />
                <Container fluid className="mt-4 mb-5 pb-5">
                  <Outlet />
                </Container>
              </>
            }
          >
            {/* Dashboard - accessible to all authenticated users */}
            <Route path="/" element={<Dashboard />} />
            
            {/* Role-specific routes */}
            <Route 
              path="/facturacion" 
              element={
                <ProtectedRoute allowedRoles={[UserRole.ADMIN, UserRole.FACTURACION]}>
                  <Facturacion />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/cartera" 
              element={
                <ProtectedRoute allowedRoles={[UserRole.ADMIN, UserRole.CARTERA, UserRole.FACTURACION]}>
                  <Cartera />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/logistica" 
              element={
                <ProtectedRoute allowedRoles={[UserRole.ADMIN, UserRole.LOGISTICA]}>
                  <Logistica />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/mensajero" 
              element={
                <ProtectedRoute allowedRoles={[UserRole.ADMIN, UserRole.MENSAJERO]}>
                  <Mensajero />
                </ProtectedRoute>
              } 
            />
          </Route>
        </Route>

        {/* Catch All Route */}
        <Route path="*" element={<Navigate to="/404" replace />} />
        </Routes>
      </OrderProvider>
    </AuthProvider>
  );
};

export default App;
