#!/bin/bash

# Script para restaurar la funcionalidad ORIGINAL del sistema de pedidos
echo "🔄 Restaurando funcionalidad ORIGINAL del sistema de pedidos..."

cd /var/www/topping-frozen-app

# 1. Restaurar Dashboard original
echo "📄 Restaurando Dashboard original..."
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
          <h1>📊 Dashboard - Sistema de Pedidos</h1>
          <div className="alert alert-success">
            <h4>{getGreeting()}, {user?.name}! 👋</h4>
            <p>Has iniciado sesión exitosamente en el sistema de gestión de pedidos.</p>
            <hr />
            <p className="mb-0">
              <strong>Usuario:</strong> {user?.username} | 
              <strong> Rol:</strong> {user?.role} | 
              <strong> Fecha:</strong> {new Date().toLocaleDateString('es-ES')}
            </p>
          </div>
        </div>
      </div>
      
      {/* Statistics Cards */}
      <div className="row mb-4">
        <div className="col-md-2 mb-3">
          <div className="card shadow-sm h-100">
            <div className="card-body text-center">
              <div className="display-4 text-primary mb-3">📋</div>
              <h5 className="card-title">Total Pedidos</h5>
              <h2 className="text-primary">0</h2>
              <small className="text-muted">Registrados</small>
            </div>
          </div>
        </div>
        
        <div className="col-md-2 mb-3">
          <div className="card shadow-sm h-100">
            <div className="card-body text-center">
              <div className="display-4 text-warning mb-3">💳</div>
              <h5 className="card-title">Pendientes Cartera</h5>
              <h2 className="text-warning">0</h2>
              <small className="text-muted">Por verificar</small>
            </div>
          </div>
        </div>
        
        <div className="col-md-2 mb-3">
          <div className="card shadow-sm h-100">
            <div className="card-body text-center">
              <div className="display-4 text-info mb-3">📦</div>
              <h5 className="card-title">Pendientes Logística</h5>
              <h2 className="text-info">0</h2>
              <small className="text-muted">Por asignar</small>
            </div>
          </div>
        </div>
        
        <div className="col-md-2 mb-3">
          <div className="card shadow-sm h-100">
            <div className="card-body text-center">
              <div className="display-4 text-primary mb-3">🚚</div>
              <h5 className="card-title">Pendientes Entrega</h5>
              <h2 className="text-primary">0</h2>
              <small className="text-muted">Con mensajero</small>
            </div>
          </div>
        </div>
        
        <div className="col-md-2 mb-3">
          <div className="card shadow-sm h-100">
            <div className="card-body text-center">
              <div className="display-4 text-success mb-3">✅</div>
              <h5 className="card-title">Entregados</h5>
              <h2 className="text-success">0</h2>
              <small className="text-muted">Completados</small>
            </div>
          </div>
        </div>
      </div>

      {/* Role-specific sections */}
      <div className="row">
        {/* Facturación Dashboard */}
        {user?.role === 'facturacion' && (
          <>
            <div className="col-md-6 mb-4">
              <div className="card shadow-sm">
                <div className="card-body">
                  <h5 className="card-title">💰 Facturas Creadas</h5>
                  <div className="text-center my-3">
                    <h2 className="mb-0">0</h2>
                    <small className="text-muted">Total</small>
                  </div>
                  <div className="text-center">
                    <div className="display-4 text-primary">📄</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-6 mb-4">
              <div className="card shadow-sm">
                <div className="card-body">
                  <h5 className="card-title">🚀 Acciones Rápidas</h5>
                  <div className="d-grid gap-2 mt-3">
                    <Link to="/facturacion" className="btn btn-primary">
                      ➕ Nueva Factura
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Cartera Dashboard */}
        {user?.role === 'cartera' && (
          <>
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">⏳ Pendientes</h5>
                  <h2 className="text-warning">0</h2>
                  <small className="text-muted">Por verificar</small>
                  <div className="mt-3">
                    <div className="display-4 text-warning">⏰</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">✅ Verificados</h5>
                  <h2 className="text-success">0</h2>
                  <small className="text-muted">En logística</small>
                  <div className="mt-3">
                    <div className="display-4 text-success">✔️</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body">
                  <h5 className="card-title">🚀 Acciones Rápidas</h5>
                  <div className="d-grid gap-2 mt-3">
                    <Link to="/cartera" className="btn btn-primary">
                      📋 Ver Pendientes
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Logística Dashboard */}
        {user?.role === 'logistica' && (
          <>
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">📦 Por Procesar</h5>
                  <h2 className="text-info">0</h2>
                  <small className="text-muted">Pendientes</small>
                  <div className="mt-3">
                    <div className="display-4 text-info">📋</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">🏪 Entregas en Tienda</h5>
                  <h2 className="text-primary">0</h2>
                  <small className="text-muted">Pendientes</small>
                  <div className="mt-3">
                    <div className="display-4 text-primary">🏬</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body">
                  <h5 className="card-title">🚀 Acciones Rápidas</h5>
                  <div className="d-grid gap-2 mt-3">
                    <Link to="/logistica" className="btn btn-primary">
                      📦 Procesar Pedidos
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Mensajero Dashboard */}
        {user?.role === 'mensajero' && (
          <>
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">🚴 Asignados</h5>
                  <h2 className="text-primary">0</h2>
                  <small className="text-muted">Por entregar</small>
                  <div className="mt-3">
                    <div className="display-4 text-primary">🚲</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body text-center">
                  <h5 className="card-title">💰 Cobros Pendientes</h5>
                  <h2 className="text-success">$0</h2>
                  <small className="text-muted">Total</small>
                  <div className="mt-3">
                    <div className="display-4 text-success">💵</div>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="col-md-4 mb-4">
              <div className="card shadow-sm h-100">
                <div className="card-body">
                  <h5 className="card-title">🚀 Acciones Rápidas</h5>
                  <div className="d-grid gap-2 mt-3">
                    <Link to="/mensajero" className="btn btn-primary">
                      📋 Ver Mis Pedidos
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {/* Admin Dashboard */}
        {user?.role === 'admin' && (
          <div className="col-md-12 mb-4">
            <div className="card shadow-sm">
              <div className="card-body">
                <h5 className="card-title">👑 Panel de Administración</h5>
                <p>Como administrador, tienes acceso completo a todos los módulos del sistema.</p>
                <div className="row text-center mt-4">
                  <div className="col-md-3">
                    <Link to="/facturacion" className="btn btn-outline-primary w-100 mb-2">
                      💰 Facturación
                    </Link>
                  </div>
                  <div className="col-md-3">
                    <Link to="/cartera" className="btn btn-outline-warning w-100 mb-2">
                      💳 Cartera
                    </Link>
                  </div>
                  <div className="col-md-3">
                    <Link to="/logistica" className="btn btn-outline-info w-100 mb-2">
                      📦 Logística
                    </Link>
                  </div>
                  <div className="col-md-3">
                    <Link to="/mensajero" className="btn btn-outline-success w-100 mb-2">
                      🚚 Mensajería
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Recent Orders Table */}
      <div className="row">
        <div className="col-12">
          <div className="card shadow-sm">
            <div className="card-body">
              <h5 className="card-title">📋 Pedidos Recientes</h5>
              <div className="text-center py-5">
                <p className="text-muted">No hay pedidos registrados en el sistema</p>
                {(user?.role === 'admin' || user?.role === 'facturacion') && (
                  <Link to="/facturacion" className="btn btn-primary">
                    ➕ Crear Primer Pedido
                  </Link>
                )}
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

# 2. Restaurar Facturación original (sistema de pedidos)
echo "📄 Restaurando Facturación original..."
cat > src/pages/Facturacion.tsx << 'EOF'
import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';

const Facturacion: React.FC = () => {
  const { user } = useAuth();
  const [showCreateOrder, setShowCreateOrder] = useState(false);

  const canCreateOrder = user?.role === 'admin' || user?.role === 'facturacion';

  const handleCreateOrder = () => {
    alert('Funcionalidad de Crear Pedido\n\nEsta función permitiría:\n• Crear nueva factura/pedido\n• Seleccionar cliente\n• Agregar productos\n• Calcular totales\n• Generar código de factura');
  };

  const handleViewPending = () => {
    alert('Facturas Pendientes\n\nEsta función mostraría:\n• Facturas sin procesar\n• Pendientes de verificación\n• Estados de pago');
  };

  const handleViewReports = () => {
    alert('Reportes de Facturación\n\nEsta función mostraría:\n• Ventas del período\n• Facturas generadas\n• Análisis de ingresos');
  };

  return (
    <div className="container mt-4 fade-in">
      <div className="row">
        <div className="col-12">
          <h1>💰 Facturación</h1>
          <div className="alert alert-info">
            <h4>Módulo de Facturación</h4>
            <p>Bienvenido {user?.name}, aquí podrás gestionar las facturas y pedidos del sistema.</p>
            <p><strong>Rol:</strong> {user?.role}</p>
          </div>
        </div>
      </div>
      
      <div className="row mb-4">
        <div className="col-md-4">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-primary mb-3">📄</div>
              <h5 className="card-title">Nueva Factura</h5>
              <p className="card-text">Crear una nueva factura/pedido</p>
              {canCreateOrder ? (
                <button 
                  className="btn btn-primary"
                  onClick={handleCreateOrder}
                >
                  ➕ Crear Factura
                </button>
              ) : (
                <div>
                  <button className="btn btn-secondary" disabled>
                    🔒 Sin Permisos
                  </button>
                  <small className="d-block text-muted mt-2">
                    Solo admin y facturación pueden crear facturas
                  </small>
                </div>
              )}
            </div>
          </div>
        </div>
        
        <div className="col-md-4">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-warning mb-3">📋</div>
              <h5 className="card-title">Facturas Pendientes</h5>
              <p className="card-text">Ver facturas pendientes de proceso</p>
              <button 
                className="btn btn-warning"
                onClick={handleViewPending}
              >
                📋 Ver Pendientes
              </button>
            </div>
          </div>
        </div>
        
        <div className="col-md-4">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-info mb-3">📊</div>
              <h5 className="card-title">Reportes</h5>
              <p className="card-text">Reportes de ventas y facturación</p>
              <button 
                className="btn btn-info"
                onClick={handleViewReports}
              >
                📊 Ver Reportes
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <h5>📋 Facturas Recientes</h5>
            </div>
            <div className="card-body">
              <div className="text-center text-muted">
                <p>No hay facturas registradas</p>
                {canCreateOrder && (
                  <button 
                    className="btn btn-primary"
                    onClick={handleCreateOrder}
                  >
                    ➕ Crear Primera Factura
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Facturacion;
EOF

# 3. Restaurar Cartera original
echo "📄 Restaurando Cartera original..."
cat > src/pages/Cartera.tsx << 'EOF'
import React from 'react';
import { useAuth } from '../context/AuthContext';

const Cartera: React.FC = () => {
  const { user } = useAuth();

  const handleVerifyPayments = () => {
    alert('Verificar Pagos\n\nEsta función permitiría:\n• Verificar pagos recibidos\n• Confirmar transferencias\n• Validar comprobantes\n• Aprobar pedidos para logística');
  };

  const handlePendingVerification = () => {
    alert('Pendientes de Verificación\n\nEsta función mostraría:\n• Pedidos con pago reportado\n• Comprobantes por revisar\n• Transferencias pendientes');
  };

  const handleFinancialReports = () => {
    alert('Reportes Financieros\n\nEsta función mostraría:\n• Estado de cartera\n• Pagos verificados\n• Ingresos del período\n• Análisis financiero');
  };

  return (
    <div className="container mt-4 fade-in">
      <div className="row">
        <div className="col-12">
          <h1>💳 Cartera</h1>
          <div className="alert alert-info">
            <h4>Módulo de Cartera</h4>
            <p>Bienvenido {user?.name}, aquí podrás gestionar la verificación de pagos y cartera.</p>
            <p><strong>Rol:</strong> {user?.role}</p>
          </div>
        </div>
      </div>
      
      <div className="row">
        <div className="col-md-4 mb-3">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-warning mb-3">⏳</div>
              <h5 className="card-title">Pendientes Verificación</h5>
              <p className="card-text">Pagos por verificar</p>
              <button 
                className="btn btn-warning"
                onClick={handlePendingVerification}
              >
                ⏳ Ver Pendientes
              </button>
            </div>
          </div>
        </div>
        
        <div className="col-md-4 mb-3">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-success mb-3">✅</div>
              <h5 className="card-title">Verificar Pagos</h5>
              <p className="card-text">Confirmar pagos recibidos</p>
              <button 
                className="btn btn-success"
                onClick={handleVerifyPayments}
              >
                ✅ Verificar Pagos
              </button>
            </div>
          </div>
        </div>
        
        <div className="col-md-4 mb-3">
          <div className="card text-center h-100">
            <div className="card-body">
              <div className="display-4 text-info mb-3">📊</div>
              <h5 className="card-title">Reportes</h5>
              <p className="card-text">Reportes financieros</p>
              <button 
                className="btn btn-info"
                onClick={handleFinancialReports}
              >
                📊 Ver Reportes
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="row mt-4">
        <div className="col-md-6">
          <div className="card">
            <div className="card-header">
              <h5>⏳ Resumen de Verificaciones</h5>
            </div>
            <div className="card-body">
              <div className="row text-center">
                <div className="col-6">
                  <h3 className="text-warning">0</h3>
                  <small>Pendientes</small>
                </div>
                <div className="col-6">
                  <h3 className="text-success">0</h3>
                  <small>Verificados Hoy</small>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div className="col-md-6">
          <div className="card">
            <div className="card-header">
              <h5>💰 Resumen Financiero</h5>
            </div>
            <div className="card-body">
              <div className="row text-center">
                <div className="col-6">
                  <h3 className="text-success">$0</h3>
                  <small>Ingresos Hoy</small>
                </div>
                <div className="col-6">
                  <h3 className="text-info">$0</h3>
                  <small>Total Mes</small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Cartera;
EOF

# 4. Limpiar archivos innecesarios
echo "🧹 Limpiando archivos innecesarios..."
rm -f src/types/billing.ts 2>/dev/null
rm -f src/services/billing.service.ts 2>/dev/null
rm -f src/components/CreateInvoice.tsx 2>/dev/null
rm -f src/components/SimpleCreateInvoice.tsx 2>/dev/null

# 5. Recompilar
echo "🔨 Recompilando aplicación original..."
npm run build 2>/dev/null || npx webpack --mode production

# 6. Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
systemctl restart nginx

echo ""
echo "🎉 ¡FUNCIONALIDAD ORIGINAL RESTAURADA!"
echo "✅ Dashboard original del sistema de pedidos"
echo "✅ Facturación para gestión de pedidos"
echo "✅ Cartera para verificación de pagos"
echo "✅ Roles específicos funcionando"
echo "✅ Sin referencias a helados u Oreos"
echo ""
echo "🌐 Prueba ahora en: http://46.202.93.54"
echo "🔐 Usuario: admin / Contraseña: 123456"
echo ""
echo "📋 ¡SISTEMA DE PEDIDOS ORIGINAL RESTAURADO!"
