import React from 'react';
import { Container, Row, Col, Card, Table, Badge } from 'react-bootstrap';
import { useAuth } from '../context/AuthContext';
import { useOrders } from '../context/OrderContext';
import { UserRole } from '../types/user';
import { OrderStatus } from '../types/order';

const Dashboard: React.FC = () => {
  const { authState } = useAuth();
  const { user } = authState;
  const { 
    orders, 
    getOrderCountByStatus,
    getOrdersByStatus
  } = useOrders();
  
  // Get counts for different order statuses
  const pendingWalletCount = getOrderCountByStatus(OrderStatus.PENDING_WALLET);
  const pendingLogisticsCount = getOrderCountByStatus(OrderStatus.PENDING_LOGISTICS);
  const pendingCount = getOrderCountByStatus(OrderStatus.PENDING);
  const deliveredCount = getOrderCountByStatus(OrderStatus.DELIVERED);
  const totalCount = orders.length;

  return (
    <Container>
      <h1 className="mb-4">Dashboard</h1>
      
      <Row className="mb-4">
        <Col>
          <Card className="shadow-sm">
            <Card.Body>
              <Card.Title>Bienvenido al Sistema de Pedidos</Card.Title>
              <Card.Text>
                Estás viendo el sistema como: <strong>{user?.name || 'Usuario'}</strong> (Rol: {user?.role})
              </Card.Text>
              <Card.Text>
                Este sistema permite gestionar el ciclo completo de pedidos, desde la creación de facturas hasta la entrega y cobro.
              </Card.Text>
            </Card.Body>
          </Card>
        </Col>
      </Row>
      
      {/* Statistics Cards */}
      <Row className="mb-4">
        <Col md={2} className="mb-3">
          <Card className="shadow-sm h-100">
            <Card.Body className="d-flex flex-column">
              <Card.Title>Total Pedidos</Card.Title>
              <div className="text-center my-3">
                <h2 className="mb-0">{totalCount}</h2>
                <small className="text-muted">Registrados</small>
              </div>
              <div className="mt-auto text-center">
                <i className="bi bi-receipt fs-1 text-primary"></i>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={2} className="mb-3">
          <Card className="shadow-sm h-100">
            <Card.Body className="d-flex flex-column">
              <Card.Title>Pendientes Cartera</Card.Title>
              <div className="text-center my-3">
                <h2 className="mb-0">{pendingWalletCount}</h2>
                <small className="text-muted">Por verificar</small>
              </div>
              <div className="mt-auto text-center">
                <i className="bi bi-wallet2 fs-1 text-warning"></i>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={2} className="mb-3">
          <Card className="shadow-sm h-100">
            <Card.Body className="d-flex flex-column">
              <Card.Title>Pendientes Logística</Card.Title>
              <div className="text-center my-3">
                <h2 className="mb-0">{pendingLogisticsCount}</h2>
                <small className="text-muted">Por asignar</small>
              </div>
              <div className="mt-auto text-center">
                <i className="bi bi-box-seam fs-1 text-info"></i>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={2} className="mb-3">
          <Card className="shadow-sm h-100">
            <Card.Body className="d-flex flex-column">
              <Card.Title>Pendientes Entrega</Card.Title>
              <div className="text-center my-3">
                <h2 className="mb-0">{pendingCount}</h2>
                <small className="text-muted">Con mensajero</small>
              </div>
              <div className="mt-auto text-center">
                <i className="bi bi-truck fs-1 text-primary"></i>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={2} className="mb-3">
          <Card className="shadow-sm h-100">
            <Card.Body className="d-flex flex-column">
              <Card.Title>Entregados</Card.Title>
              <div className="text-center my-3">
                <h2 className="mb-0">{deliveredCount}</h2>
                <small className="text-muted">Completados</small>
              </div>
              <div className="mt-auto text-center">
                <i className="bi bi-check-circle fs-1 text-success"></i>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Recent Orders Table */}
      <Row>
        <Col>
          <Card className="shadow-sm">
            <Card.Body>
              <Card.Title>Pedidos Recientes</Card.Title>
              
              {orders.length === 0 ? (
                <div className="text-center py-5">
                  <p className="text-muted">No hay pedidos registrados en el sistema</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <Table hover className="align-middle">
                    <thead>
                      <tr>
                        <th>Factura</th>
                        <th>Cliente</th>
                        <th>Fecha</th>
                        <th>Método Entrega</th>
                        <th>Valor Total</th>
                        <th>Estado</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orders.slice(0, 5).map(order => (
                        <tr key={order.id}>
                          <td>{order.invoiceCode}</td>
                          <td>{order.clientName}</td>
                          <td>{order.date}</td>
                          <td>{order.deliveryMethod}</td>
                          <td>${order.totalAmount ? order.totalAmount.toLocaleString() : '0'}</td>
                          <td>
                            {order.status === OrderStatus.PENDING_WALLET && (
                              <Badge bg="warning" className="status-badge status-pending-wallet">Pendiente Cartera</Badge>
                            )}
                            {order.status === OrderStatus.PENDING_LOGISTICS && (
                              <Badge bg="info" className="status-badge status-pending-logistics">Pendiente Logística</Badge>
                            )}
                            {order.status === OrderStatus.PENDING && (
                              <Badge bg="primary" className="status-badge status-pending">Pendiente Entrega</Badge>
                            )}
                            {order.status === OrderStatus.DELIVERED && (
                              <Badge bg="success" className="status-badge status-delivered">Entregado</Badge>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                </div>
              )}
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Role-specific sections */}
      <Row>
        {/* Facturación Dashboard */}
        {user?.role === UserRole.FACTURACION && (
          <>
            <Col md={6} className="mb-4">
              <Card className="shadow-sm">
                <Card.Body>
                  <Card.Title>Facturas Creadas</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">0</h2>
                    <small className="text-muted">Total</small>
                  </div>
                  <div className="text-center">
                    <i className="bi bi-receipt fs-1 text-primary"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={6} className="mb-4">
              <Card className="shadow-sm">
                <Card.Body>
                  <Card.Title>Acciones Rápidas</Card.Title>
                  <div className="d-grid gap-2 mt-3">
                    <a href="/facturacion" className="btn btn-primary">
                      <i className="bi bi-plus-circle me-2"></i>
                      Nueva Factura
                    </a>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          </>
        )}

        {/* Cartera Dashboard */}
        {user?.role === UserRole.CARTERA && (
          <>
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Pendientes</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">{pendingWalletCount}</h2>
                    <small className="text-muted">Por verificar</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-hourglass-split fs-1 text-warning"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Verificados</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">{pendingLogisticsCount}</h2>
                    <small className="text-muted">En logística</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-check2-all fs-1 text-success"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Acciones Rápidas</Card.Title>
                  <div className="d-grid gap-2 mt-3">
                    <a href="/cartera" className="btn btn-primary">
                      <i className="bi bi-list-check me-2"></i>
                      Ver Pendientes
                    </a>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          </>
        )}

        {/* Logística Dashboard */}
        {user?.role === UserRole.LOGISTICA && (
          <>
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Por Procesar</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">0</h2>
                    <small className="text-muted">Pendientes</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-box-seam fs-1 text-info"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Entregas en Tienda</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">0</h2>
                    <small className="text-muted">Pendientes</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-shop fs-1 text-primary"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Acciones Rápidas</Card.Title>
                  <div className="d-grid gap-2 mt-3">
                    <a href="/logistica" className="btn btn-primary">
                      <i className="bi bi-box-arrow-right me-2"></i>
                      Procesar Pedidos
                    </a>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          </>
        )}

        {/* Mensajero Dashboard */}
        {user?.role === UserRole.MENSAJERO && (
          <>
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Asignados</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">0</h2>
                    <small className="text-muted">Por entregar</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-bicycle fs-1 text-primary"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Cobros Pendientes</Card.Title>
                  <div className="text-center my-3">
                    <h2 className="mb-0">$0</h2>
                    <small className="text-muted">Total</small>
                  </div>
                  <div className="mt-auto text-center">
                    <i className="bi bi-cash-stack fs-1 text-success"></i>
                  </div>
                </Card.Body>
              </Card>
            </Col>
            
            <Col md={4} className="mb-4">
              <Card className="shadow-sm h-100">
                <Card.Body className="d-flex flex-column">
                  <Card.Title>Acciones Rápidas</Card.Title>
                  <div className="d-grid gap-2 mt-3">
                    <a href="/mensajero" className="btn btn-primary">
                      <i className="bi bi-list-ul me-2"></i>
                      Ver Mis Pedidos
                    </a>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          </>
        )}

        {/* Regular User Dashboard */}
        {user?.role === UserRole.REGULAR && (
          <Col md={12} className="mb-4">
            <Card className="shadow-sm">
              <Card.Body>
                <Card.Title>Resumen de Pedidos</Card.Title>
                <Card.Text>
                  Como usuario regular, puedes ver el estado general de los pedidos en el sistema.
                </Card.Text>
                <div className="row text-center mt-4">
                  <div className="col-md-3">
                    <h3>0</h3>
                    <p className="text-muted">Total Pedidos</p>
                  </div>
                  <div className="col-md-3">
                    <h3>0</h3>
                    <p className="text-muted">Pendientes</p>
                  </div>
                  <div className="col-md-3">
                    <h3>0</h3>
                    <p className="text-muted">En Proceso</p>
                  </div>
                  <div className="col-md-3">
                    <h3>0</h3>
                    <p className="text-muted">Entregados</p>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>
        )}
      </Row>
    </Container>
  );
};

export default Dashboard;
