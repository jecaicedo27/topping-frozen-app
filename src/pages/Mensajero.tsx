import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Table, Badge, Button, Form, Modal } from 'react-bootstrap';
import { DeliveryMethod, PaymentMethod, PaymentStatus } from '../types/user';
import { OrderStatus, Order } from '../types/order';
import { useOrders } from '../context/OrderContext';

// Mock data for demonstration
const mockOrders = [
  {
    id: '7',
    invoiceCode: 'FAC-007',
    clientName: 'Pedro Ramírez',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    estimatedDeliveryDate: '2025-05-17',
    totalAmount: 95000,
    status: OrderStatus.PENDING,
    createdAt: '2025-05-15T08:30:00',
    paymentStatus: PaymentStatus.PENDIENTE,
    assignedTo: 'dp1', // Duban Pineda
    weight: '750',
    address: 'Calle 123 #45-67, Apto 301',
    phone: '3101234567',
    notes: 'Llamar antes de llegar'
  },
  {
    id: '8',
    invoiceCode: 'FAC-008',
    clientName: 'Sofía Torres',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    estimatedDeliveryDate: '2025-05-17',
    totalAmount: 120000,
    status: OrderStatus.PENDING,
    createdAt: '2025-05-15T09:15:00',
    paymentStatus: PaymentStatus.PENDIENTE,
    assignedTo: 'dp1', // Duban Pineda
    weight: '1200',
    address: 'Carrera 78 #23-45',
    phone: '3209876543',
    notes: 'Edificio con portería'
  }
];

interface DeliveryModalProps {
  show: boolean;
  order: any;
  onHide: () => void;
  onComplete: (orderId: string, amountCollected: number, hasProof: boolean) => void;
}

const DeliveryModal: React.FC<DeliveryModalProps> = ({ show, order, onHide, onComplete }) => {
  const [amountCollected, setAmountCollected] = useState<string>('');
  const [hasDeliveryProof, setHasDeliveryProof] = useState(false);
  const [hasPaymentProof, setHasPaymentProof] = useState(false);
  const [deliveryFile, setDeliveryFile] = useState<File | null>(null);
  const [paymentFile, setPaymentFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showCamera, setShowCamera] = useState(false);
  const [cameraMode, setCameraMode] = useState<'delivery' | 'payment'>('delivery');

  const handleDeliveryFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setDeliveryFile(e.target.files[0]);
      setHasDeliveryProof(true);
    } else {
      setDeliveryFile(null);
      setHasDeliveryProof(false);
    }
  };

  const handlePaymentFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setPaymentFile(e.target.files[0]);
      setHasPaymentProof(true);
    } else {
      setPaymentFile(null);
      setHasPaymentProof(false);
    }
  };

  const validateDelivery = (): boolean => {
    // Reset error
    setError(null);
    
    // If payment method is cash, must collect amount
    if (order?.paymentMethod === PaymentMethod.EFECTIVO && 
        (!amountCollected || parseFloat(amountCollected) <= 0)) {
      setError('Debe ingresar el monto cobrado');
      return false;
    }
    
    // Must have delivery proof
    if (!hasDeliveryProof) {
      setError('Debe adjuntar una foto como evidencia de entrega');
      return false;
    }
    
    return true;
  };

  const handleComplete = () => {
    if (validateDelivery()) {
      onComplete(
        order.id, 
        amountCollected ? parseFloat(amountCollected) : 0, 
        hasDeliveryProof
      );
      onHide();
    }
  };

  const toggleCamera = () => {
    setShowCamera(!showCamera);
  };

  const takePicture = () => {
    // In a real app, this would capture an image from the camera
    if (cameraMode === 'payment') {
      setHasPaymentProof(true);
    } else {
      setHasDeliveryProof(true);
    }
    setShowCamera(false);
  };

  return (
    <Modal show={show} onHide={onHide} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Registrar Entrega - {order?.invoiceCode}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && (
          <div className="alert alert-danger">{error}</div>
        )}
        
        <Row className="mb-4">
          <Col md={6}>
            <p><strong>Cliente:</strong> {order?.clientName}</p>
            <p><strong>Dirección:</strong> {order?.address}</p>
            <p><strong>Teléfono:</strong> {order?.phone}</p>
          </Col>
          <Col md={6}>
            <p>
              <strong>Método de Pago:</strong> {' '}
              {order?.paymentMethod === PaymentMethod.EFECTIVO && 'Efectivo'}
              {order?.paymentMethod === PaymentMethod.TRANSFERENCIA && 'Transferencia Bancaria'}
              {order?.paymentMethod === PaymentMethod.TARJETA_CREDITO && 'Tarjeta de Crédito'}
              {order?.paymentMethod === PaymentMethod.PAGO_ELECTRONICO && 'Pago Electrónico'}
            </p>
            {order?.paymentMethod === PaymentMethod.EFECTIVO && (
              <p className="amount-to-collect">
                <strong>Monto a Cobrar:</strong> ${order?.totalAmount?.toLocaleString()}
              </p>
            )}
            <p><strong>Notas:</strong> {order?.notes || 'Sin notas'}</p>
          </Col>
        </Row>
        
        <Form>
          {order?.paymentMethod === PaymentMethod.EFECTIVO && (
            <Form.Group className="mb-4">
              <Form.Label>Monto Cobrado</Form.Label>
              <Form.Control
                type="number"
                value={amountCollected}
                onChange={(e) => setAmountCollected(e.target.value)}
                placeholder="0.00"
                min="0"
                step="0.01"
                required
              />
              <Form.Text className="text-muted">
                Ingrese el monto exacto recibido del cliente
              </Form.Text>
              
              {amountCollected && parseFloat(amountCollected) !== order?.totalAmount && (
                <div className={`alert ${parseFloat(amountCollected) > order?.totalAmount ? 'alert-success' : 'alert-danger'} mt-2`}>
                  <strong>
                    {parseFloat(amountCollected) > order?.totalAmount ? 'Sobra:' : 'Falta:'} $
                    {Math.abs(parseFloat(amountCollected) - order?.totalAmount).toLocaleString()}
                  </strong>
                </div>
              )}
            </Form.Group>
          )}

          {/* Payment Photo Section - for cash or transfer payments */}
          {(order?.paymentMethod === PaymentMethod.EFECTIVO || order?.paymentMethod === PaymentMethod.TRANSFERENCIA) && (
            <Form.Group className="mb-4">
              <Form.Label>
                <i className="bi bi-cash-stack me-2"></i>
                Foto del Pago Recibido
              </Form.Label>
              <div className="d-flex mb-2">
                <Button 
                  variant="outline-success" 
                  className="me-2" 
                  onClick={() => {
                    setCameraMode('payment');
                    setShowCamera(true);
                  }}
                >
                  <i className="bi bi-camera me-2"></i>
                  Foto del {order?.paymentMethod === PaymentMethod.EFECTIVO ? 'Efectivo' : 'Comprobante'}
                </Button>
                <div className="flex-grow-1">
                  <Form.Control 
                    type="file" 
                    accept="image/*" 
                    onChange={handlePaymentFileChange}
                  />
                </div>
              </div>
              <Form.Text className="text-muted">
                {order?.paymentMethod === PaymentMethod.EFECTIVO 
                  ? 'Tome una foto del dinero en efectivo recibido del cliente'
                  : 'Tome una foto del comprobante de transferencia'
                }
              </Form.Text>
              
              {hasPaymentProof && (
                <div className="mt-3 text-center">
                  <p className="text-success">
                    <i className="bi bi-check-circle me-2"></i>
                    Foto del pago adjuntada correctamente
                  </p>
                  {paymentFile && (
                    <p className="text-muted small">Archivo: {paymentFile.name}</p>
                  )}
                </div>
              )}
            </Form.Group>
          )}
          
          <Form.Group className="mb-4">
            <Form.Label>Evidencia de Entrega</Form.Label>
            
            {showCamera ? (
              <div className="camera-container mb-3">
                <div className="camera-preview border rounded p-3 bg-dark text-center">
                  <p className="text-light mb-0">Vista previa de cámara</p>
                  <div className="py-5 text-center">
                    <i className="bi bi-camera text-light" style={{ fontSize: '3rem' }}></i>
                  </div>
                </div>
                <div className="camera-controls">
                  <Button variant="primary" onClick={takePicture}>
                    <i className="bi bi-camera me-2"></i>
                    Tomar Foto
                  </Button>
                  <Button variant="secondary" onClick={toggleCamera}>
                    Cancelar
                  </Button>
                </div>
              </div>
            ) : (
              <>
                <div className="d-flex mb-2">
                  <Button variant="outline-primary" className="me-2" onClick={toggleCamera}>
                    <i className="bi bi-camera me-2"></i>
                    Usar Cámara
                  </Button>
                  <div className="flex-grow-1">
                    <Form.Control 
                      type="file" 
                      accept="image/*" 
                      onChange={handleDeliveryFileChange}
                    />
                  </div>
                </div>
                <Form.Text className="text-muted">
                  Tome una foto o adjunte una imagen como evidencia de entrega
                </Form.Text>
              </>
            )}
            
            {hasDeliveryProof && !showCamera && (
              <div className="mt-3 text-center">
                <p className="text-success">
                  <i className="bi bi-check-circle me-2"></i>
                  Evidencia adjuntada correctamente
                </p>
                {deliveryFile && (
                  <p className="text-muted small">Archivo: {deliveryFile.name}</p>
                )}
              </div>
            )}
          </Form.Group>
        </Form>
        
        <div className="alert alert-info mt-3">
          <i className="bi bi-info-circle me-2"></i>
          <strong>Recordatorio:</strong>
          <ul className="mb-0 mt-2">
            <li>Debe registrar el monto exacto recibido del cliente</li>
            <li>Debe tomar una foto como evidencia de entrega</li>
            <li>Verifique que el monto cobrado coincida con el valor a cobrar</li>
          </ul>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Cancelar
        </Button>
        <Button variant="success" onClick={handleComplete}>
          Confirmar Entrega
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

const Mensajero: React.FC = () => {
  const { orders: allOrders, getOrdersByStatus, markAsDelivered, refreshOrders } = useOrders();
  const [pendingOrders, setPendingOrders] = useState<Order[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);
  const [showDeliveryModal, setShowDeliveryModal] = useState(false);
  const [completedOrders, setCompletedOrders] = useState<any[]>([]);
  const [totalCollected, setTotalCollected] = useState(0);

  useEffect(() => {
    // Get orders with PENDING status (assigned to messenger)
    const messengerOrders = getOrdersByStatus(OrderStatus.PENDING);
    setPendingOrders(messengerOrders);
    
    // Get delivered orders for today (completed by this messenger)
    const deliveredOrders = getOrdersByStatus(OrderStatus.DELIVERED);
    const today = new Date().toISOString().split('T')[0];
    const todayDelivered = deliveredOrders.filter(order => 
      order.deliveryDate === today
    );
    setCompletedOrders(todayDelivered);
    
    // Calculate total collected from cash payments
    const cashTotal = todayDelivered
      .filter(order => order.paymentMethod === PaymentMethod.EFECTIVO)
      .reduce((total, order) => total + (order.amountCollected || 0), 0);
    setTotalCollected(cashTotal);
  }, [allOrders, getOrdersByStatus]);

  const handleDeliverClick = (order: any) => {
    setSelectedOrder(order);
    setShowDeliveryModal(true);
  };

  const handleComplete = (orderId: string, amountCollected: number, hasProof: boolean) => {
    // Use the markAsDelivered function from OrderContext
    markAsDelivered(orderId, amountCollected, hasProof ? 'delivery.jpg' : null);
    
    // Update local state to remove the processed order
    setPendingOrders(prev => prev.filter(order => order.id !== orderId));
    
    // Update total collected for cash payments
    const completedOrder = pendingOrders.find(order => order.id === orderId);
    if (completedOrder && completedOrder.paymentMethod === PaymentMethod.EFECTIVO) {
      setTotalCollected(prev => prev + amountCollected);
    }
  };

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case OrderStatus.PENDING_WALLET:
        return <Badge bg="warning" className="status-badge status-pending-wallet">Pendiente Cartera</Badge>;
      case OrderStatus.PENDING_LOGISTICS:
        return <Badge bg="info" className="status-badge status-pending-logistics">Pendiente Logística</Badge>;
      case OrderStatus.PENDING:
        return <Badge bg="primary" className="status-badge status-pending">Pendiente</Badge>;
      case OrderStatus.DELIVERED:
        return <Badge bg="success" className="status-badge status-delivered">Entregado</Badge>;
      default:
        return <Badge bg="secondary">Desconocido</Badge>;
    }
  };

  return (
    <Container>
      <h1 className="mb-4">Mensajero</h1>
      
      <Row>
        <Col lg={8}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Pedidos Asignados</Card.Title>
              
              {pendingOrders.length === 0 ? (
                <div className="text-center py-5">
                  <i className="bi bi-check-circle text-success fs-1"></i>
                  <p className="mt-3">No hay pedidos pendientes de entrega</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <Table hover className="align-middle">
                    <thead>
                      <tr>
                        <th>Código</th>
                        <th>Cliente</th>
                        <th>Dirección</th>
                        <th>Monto</th>
                        <th>Acciones</th>
                      </tr>
                    </thead>
                    <tbody>
                      {pendingOrders.map((order: Order) => (
                        <tr key={order.id}>
                          <td>{order.invoiceCode}</td>
                          <td>{order.clientName}</td>
                          <td>{order.address}</td>
                          <td>
                            {order.paymentMethod === PaymentMethod.EFECTIVO ? (
                              <span className="amount-to-collect">${order.totalAmount.toLocaleString()}</span>
                            ) : (
                              <Badge bg="secondary">No Cobrar</Badge>
                            )}
                          </td>
                          <td>
                            <Button 
                              variant="success" 
                              size="sm"
                              onClick={() => handleDeliverClick(order)}
                            >
                              <i className="bi bi-check-circle me-1"></i>
                              Entregar
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                </div>
              )}
            </Card.Body>
          </Card>
          
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Entregas Completadas Hoy</Card.Title>
              
              {completedOrders.length === 0 ? (
                <div className="text-center py-4">
                  <p className="text-muted">No hay entregas completadas hoy</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <Table hover className="align-middle">
                    <thead>
                      <tr>
                        <th>Código</th>
                        <th>Cliente</th>
                        <th>Hora</th>
                        <th>Cobrado</th>
                        <th>Estado</th>
                      </tr>
                    </thead>
                    <tbody>
                      {completedOrders.map(order => (
                        <tr key={order.id}>
                          <td>{order.invoiceCode}</td>
                          <td>{order.clientName}</td>
                          <td>{new Date(order.deliveredAt).toLocaleTimeString()}</td>
                          <td>
                            {order.paymentMethod === PaymentMethod.EFECTIVO ? (
                              <span>${order.amountCollected.toLocaleString()}</span>
                            ) : (
                              <Badge bg="secondary">No Aplica</Badge>
                            )}
                          </td>
                          <td>{getStatusBadge(order.status)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                </div>
              )}
            </Card.Body>
          </Card>
        </Col>
        
        <Col lg={4}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Resumen de Caja</Card.Title>
              
              <div className="text-center my-4">
                <h3 className="mb-0">${totalCollected.toLocaleString()}</h3>
                <p className="text-muted">Total Cobrado Hoy</p>
              </div>
              
              <div className="mb-3">
                <h6>Detalle de Cobros:</h6>
                {completedOrders.length === 0 ? (
                  <p className="text-muted small">No hay cobros registrados hoy</p>
                ) : (
                  <div className="table-responsive">
                    <Table size="sm" className="mb-0">
                      <thead>
                        <tr>
                          <th>Factura</th>
                          <th>Monto</th>
                        </tr>
                      </thead>
                      <tbody>
                        {completedOrders
                          .filter(order => order.paymentMethod === PaymentMethod.EFECTIVO)
                          .map(order => (
                          <tr key={order.id}>
                            <td className="small">{order.invoiceCode}</td>
                            <td className="small">${order.amountCollected?.toLocaleString()}</td>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                  </div>
                )}
              </div>
              
              <div className="d-grid gap-2">
                <Button variant="outline-primary">
                  <i className="bi bi-printer me-2"></i>
                  Imprimir Reporte
                </Button>
                <Button variant="success" disabled={totalCollected === 0}>
                  <i className="bi bi-cash-stack me-2"></i>
                  Entregar Dinero
                </Button>
              </div>
            </Card.Body>
          </Card>
          
          <Card className="shadow-sm">
            <Card.Body>
              <Card.Title>Información</Card.Title>
              <Card.Text>
                Gestiona tus entregas y registra los cobros realizados. Recuerda tomar evidencia fotográfica de cada entrega.
              </Card.Text>
              
              <hr />
              
              <h6>Instrucciones</h6>
              <ul className="small">
                <li>Haz clic en "Entregar" para registrar una entrega</li>
                <li>Ingresa el monto exacto cobrado al cliente</li>
                <li>Toma una foto como evidencia de entrega</li>
                <li>Verifica que el monto cobrado coincida con el valor a cobrar</li>
              </ul>
              
              <div className="alert alert-warning mt-3 mb-0">
                <i className="bi bi-exclamation-triangle me-2"></i>
                Recuerda que debes entregar el total cobrado al final de tu turno.
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
      
      {/* Delivery Modal */}
      <DeliveryModal 
        show={showDeliveryModal}
        order={selectedOrder}
        onHide={() => setShowDeliveryModal(false)}
        onComplete={handleComplete}
      />
    </Container>
  );
};

export default Mensajero;
