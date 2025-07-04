import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Table, Badge, Button, Form, Modal } from 'react-bootstrap';
import { DeliveryMethod, PaymentMethod, PaymentStatus } from '../types/user';
import { OrderStatus, Order } from '../types/order';
import { useOrders } from '../context/OrderContext';

// Mock data for demonstration
const mockOrders = [
  {
    id: '4',
    invoiceCode: 'FAC-004',
    clientName: 'Ana Martínez',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    estimatedDeliveryDate: '2025-05-21',
    totalAmount: 85000,
    status: OrderStatus.PENDING_LOGISTICS,
    createdAt: '2025-05-15T09:30:00',
    paymentStatus: PaymentStatus.PENDIENTE,
    notes: 'Entregar en horario de la tarde'
  },
  {
    id: '5',
    invoiceCode: 'FAC-005',
    clientName: 'Roberto Gómez',
    deliveryMethod: DeliveryMethod.RECOGIDA_TIENDA,
    paymentMethod: PaymentMethod.TRANSFERENCIA,
    estimatedDeliveryDate: '2025-05-19',
    totalAmount: 150000,
    status: OrderStatus.PENDING_LOGISTICS,
    createdAt: '2025-05-15T10:15:00',
    paymentStatus: PaymentStatus.PAGADO,
    paymentProof: 'proof.jpg',
    notes: 'Cliente frecuente'
  },
  {
    id: '6',
    invoiceCode: 'FAC-006',
    clientName: 'Laura Sánchez',
    deliveryMethod: DeliveryMethod.ENVIO_NACIONAL,
    paymentMethod: PaymentMethod.TARJETA_CREDITO,
    estimatedDeliveryDate: '2025-05-23',
    totalAmount: 320000,
    status: OrderStatus.PENDING_LOGISTICS,
    createdAt: '2025-05-15T11:00:00',
    paymentStatus: PaymentStatus.PAGADO,
    paymentProof: 'proof.jpg',
    notes: 'Enviar a Cali'
  }
];

// Available delivery personnel/services
const deliveryOptions = {
  local: [
    { id: 'dp1', name: 'Duban Pineda' },
    { id: 'picap', name: 'Picap' },
    { id: 'didi', name: 'Didi' },
    { id: 'bodega', name: 'Bodega' }
  ],
  national: [
    { id: 'inter', name: 'Interrapidisimo' },
    { id: 'picap-nacional', name: 'Picap' },
    { id: 'bodega-nacional', name: 'Bodega' }
  ]
};

interface ProcessModalProps {
  show: boolean;
  order: any;
  onHide: () => void;
  onProcess: (orderId: string, weight: string | null, assignedTo: string | null) => void;
}

const ProcessModal: React.FC<ProcessModalProps> = ({ show, order, onHide, onProcess }) => {
  const [weight, setWeight] = useState<string>('');
  const [noWeight, setNoWeight] = useState<boolean>(false);
  const [assignedTo, setAssignedTo] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  // Reset form when modal opens with a new order
  useEffect(() => {
    if (show && order) {
      setWeight('');
      setNoWeight(false);
      setAssignedTo('');
      setError(null);
    }
  }, [show, order]);

  const isStorePickup = order?.deliveryMethod === DeliveryMethod.RECOGIDA_TIENDA;
  
  // Determine which delivery options to show based on delivery method
  const getDeliveryOptions = () => {
    if (order?.deliveryMethod === DeliveryMethod.DOMICILIO) {
      return deliveryOptions.local;
    } else if (
      order?.deliveryMethod === DeliveryMethod.ENVIO_NACIONAL || 
      order?.deliveryMethod === DeliveryMethod.ENVIO_INTERNACIONAL
    ) {
      return deliveryOptions.national;
    }
    return [];
  };

  const validateProcess = (): boolean => {
    // Reset error
    setError(null);
    
    // Weight must be provided or "no weight" must be checked
    if (!weight && !noWeight) {
      setError('Debe ingresar el peso o marcar "Sin peso"');
      return false;
    }
    
    // For non-store pickup, must assign to someone
    if (!isStorePickup && !assignedTo) {
      setError('Debe asignar el pedido a un mensajero o servicio de entrega');
      return false;
    }
    
    return true;
  };

  const handleProcess = () => {
    if (validateProcess()) {
      onProcess(
        order.id, 
        noWeight ? null : weight, 
        isStorePickup ? null : assignedTo
      );
      onHide();
    }
  };

  const handleWeightChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setWeight(e.target.value);
    if (e.target.value) {
      setNoWeight(false);
    }
  };

  const handleNoWeightChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setNoWeight(e.target.checked);
    if (e.target.checked) {
      setWeight('');
    }
  };

  return (
    <Modal show={show} onHide={onHide} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Procesar Pedido - {order?.invoiceCode}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && (
          <div className="alert alert-danger">{error}</div>
        )}
        
        <Row className="mb-4">
          <Col md={6}>
            <p><strong>Cliente:</strong> {order?.clientName}</p>
            <p><strong>Monto:</strong> ${order?.totalAmount?.toLocaleString()}</p>
            <p>
              <strong>Método de Entrega:</strong> {' '}
              {order?.deliveryMethod === DeliveryMethod.DOMICILIO && 'Domicilio'}
              {order?.deliveryMethod === DeliveryMethod.RECOGIDA_TIENDA && 'Recogida en Tienda'}
              {order?.deliveryMethod === DeliveryMethod.ENVIO_NACIONAL && 'Envío Nacional'}
              {order?.deliveryMethod === DeliveryMethod.ENVIO_INTERNACIONAL && 'Envío Internacional'}
            </p>
          </Col>
          <Col md={6}>
            <p>
              <strong>Método de Pago:</strong> {' '}
              {order?.paymentMethod === PaymentMethod.EFECTIVO && 'Efectivo'}
              {order?.paymentMethod === PaymentMethod.TRANSFERENCIA && 'Transferencia Bancaria'}
              {order?.paymentMethod === PaymentMethod.TARJETA_CREDITO && 'Tarjeta de Crédito'}
              {order?.paymentMethod === PaymentMethod.PAGO_ELECTRONICO && 'Pago Electrónico'}
            </p>
            <p>
              <strong>Estado de Pago:</strong> {' '}
              {order?.paymentStatus === PaymentStatus.PAGADO && (
                <Badge bg="success">Pagado</Badge>
              )}
              {order?.paymentStatus === PaymentStatus.PENDIENTE && (
                <Badge bg="warning" text="dark">Pendiente</Badge>
              )}
              {order?.paymentStatus === PaymentStatus.CREDITO_APROBADO && (
                <Badge bg="info">Crédito Aprobado</Badge>
              )}
            </p>
            <p><strong>Fecha Estimada:</strong> {new Date(order?.estimatedDeliveryDate).toLocaleDateString()}</p>
          </Col>
        </Row>
        
        {order?.paymentProof && (
          <div className="mb-4">
            <p><strong>Comprobante de Pago:</strong></p>
            <div className="border p-2 text-center">
              <p className="text-muted">[Imagen de comprobante]</p>
              <Button variant="outline-secondary" size="sm">
                <i className="bi bi-eye me-1"></i>
                Ver Comprobante
              </Button>
            </div>
          </div>
        )}
        
        <Form>
          <Row className="mb-3">
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Peso del Paquete (gramos)</Form.Label>
                <Form.Control
                  type="number"
                  value={weight}
                  onChange={handleWeightChange}
                  placeholder="Ej. 500"
                  disabled={noWeight}
                />
              </Form.Group>
            </Col>
            <Col md={6} className="d-flex align-items-end mb-3">
              <Form.Check 
                type="checkbox"
                id="no-weight"
                label="Sin peso"
                checked={noWeight}
                onChange={handleNoWeightChange}
                className="mb-2"
              />
            </Col>
          </Row>
          
          {!isStorePickup && (
            <Form.Group className="mb-3">
              <Form.Label>Asignar a</Form.Label>
              <Form.Select 
                value={assignedTo}
                onChange={(e) => setAssignedTo(e.target.value)}
                required
              >
                <option value="">Seleccionar...</option>
                {getDeliveryOptions().map(option => (
                  <option key={option.id} value={option.id}>
                    {option.name}
                  </option>
                ))}
              </Form.Select>
            </Form.Group>
          )}
          
          <Form.Group className="mb-3">
            <Form.Label>Notas</Form.Label>
            <Form.Control
              as="textarea"
              rows={2}
              defaultValue={order?.notes || ''}
              readOnly
            />
          </Form.Group>
        </Form>
        
        <div className="alert alert-info mt-3">
          <i className="bi bi-info-circle me-2"></i>
          <strong>Recordatorio de Reglas:</strong>
          <ul className="mb-0 mt-2">
            <li>Para método de entrega "Domicilio": asignar solo a mensajeros locales</li>
            <li>Para "Envío nacional/internacional": asignar solo a servicios nacionales</li>
            <li>Para "Recogida en tienda": no se asigna destinatario</li>
            <li>Todo pedido debe tener peso registrado o ser marcado como "sin peso"</li>
          </ul>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Cancelar
        </Button>
        <Button variant="primary" onClick={handleProcess}>
          {isStorePickup ? 'Preparar para Entrega en Tienda' : 'Asignar y Procesar'}
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

const Logistica: React.FC = () => {
  const { orders: allOrders, getOrdersByStatus, assignOrder, markAsDelivered, refreshOrders } = useOrders();
  const [pendingOrders, setPendingOrders] = useState<Order[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);
  const [showProcessModal, setShowProcessModal] = useState(false);
  const [storePickupOrders, setStorePickupOrders] = useState<any[]>([]);

  useEffect(() => {
    // Get orders with PENDING_LOGISTICS status
    const logisticsOrders = getOrdersByStatus(OrderStatus.PENDING_LOGISTICS);
    setPendingOrders(logisticsOrders);
  }, [allOrders, getOrdersByStatus]);

  const handleProcessClick = (order: any) => {
    setSelectedOrder(order);
    setShowProcessModal(true);
  };

  const handleProcess = (orderId: string, weight: string | null, assignedTo: string | null) => {
    const order = pendingOrders.find(o => o.id === orderId);
    
    if (order?.deliveryMethod === DeliveryMethod.RECOGIDA_TIENDA) {
      // For store pickup, mark as delivered directly (no messenger needed)
      markAsDelivered(orderId, order.totalAmount, 'store_pickup.jpg');
    } else {
      // For other delivery methods, assign to messenger/service
      assignOrder(orderId, weight, assignedTo);
    }
    
    // Update local state to remove the processed order
    setPendingOrders(prev => prev.filter(order => order.id !== orderId));
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

  const getDeliveryMethodText = (method: DeliveryMethod) => {
    switch (method) {
      case DeliveryMethod.DOMICILIO:
        return 'Domicilio';
      case DeliveryMethod.RECOGIDA_TIENDA:
        return 'Recogida en Tienda';
      case DeliveryMethod.ENVIO_NACIONAL:
        return 'Envío Nacional';
      case DeliveryMethod.ENVIO_INTERNACIONAL:
        return 'Envío Internacional';
      default:
        return 'Desconocido';
    }
  };

  const getPaymentStatusBadge = (status: PaymentStatus) => {
    switch (status) {
      case PaymentStatus.PAGADO:
        return <Badge bg="success">Pagado</Badge>;
      case PaymentStatus.PENDIENTE:
        return <Badge bg="warning" text="dark">Pendiente</Badge>;
      case PaymentStatus.CREDITO_APROBADO:
        return <Badge bg="info">Crédito Aprobado</Badge>;
      default:
        return <Badge bg="secondary">Desconocido</Badge>;
    }
  };

  const handleCompleteStorePickup = (orderId: string) => {
    // In a real app, we would update the database
    // For now, we'll just update the local state
    setStorePickupOrders(prev => 
      prev.map(order => 
        order.id === orderId 
          ? { ...order, status: OrderStatus.DELIVERED }
          : order
      ).filter(order => order.id !== orderId) // Remove the completed order
    );
  };

  return (
    <Container>
      <h1 className="mb-4">Logística</h1>
      
      <Row>
        <Col lg={8}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Pedidos Pendientes de Procesamiento</Card.Title>
              
              {pendingOrders.length === 0 ? (
                <div className="text-center py-5">
                  <i className="bi bi-check-circle text-success fs-1"></i>
                  <p className="mt-3">No hay pedidos pendientes de procesamiento</p>
                </div>
              ) : (
                <div className="table-responsive">
                  <Table hover className="align-middle">
                    <thead>
                      <tr>
                        <th>Código</th>
                        <th>Cliente</th>
                        <th>Entrega</th>
                        <th>Pago</th>
                        <th>Monto</th>
                        <th>Acciones</th>
                      </tr>
                    </thead>
                    <tbody>
                      {pendingOrders.map((order: Order) => (
                        <tr key={order.id}>
                          <td>{order.invoiceCode}</td>
                          <td>{order.clientName}</td>
                          <td>{getDeliveryMethodText(order.deliveryMethod as DeliveryMethod)}</td>
                          <td>{getPaymentStatusBadge(order.paymentStatus as PaymentStatus)}</td>
                          <td>${order.totalAmount.toLocaleString()}</td>
                          <td>
                            <Button 
                              variant="primary" 
                              size="sm"
                              onClick={() => handleProcessClick(order)}
                            >
                              <i className="bi bi-box-seam me-1"></i>
                              Procesar
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
        </Col>
        
        <Col lg={4}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Resumen</Card.Title>
              
              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center">
                  <span>Por Procesar:</span>
                  <Badge bg="info" className="fs-6">{pendingOrders.length}</Badge>
                </div>
              </div>
              
              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center">
                  <span>Entregas en Tienda:</span>
                  <Badge bg="secondary" className="fs-6">
                    {pendingOrders.filter(order => order.deliveryMethod === DeliveryMethod.RECOGIDA_TIENDA).length}
                  </Badge>
                </div>
              </div>
              
              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center">
                  <span>Domicilios:</span>
                  <Badge bg="primary" className="fs-6">
                    {pendingOrders.filter(order => order.deliveryMethod === DeliveryMethod.DOMICILIO).length}
                  </Badge>
                </div>
              </div>
              
              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center">
                  <span>Envíos Nacionales:</span>
                  <Badge bg="warning" className="fs-6">
                    {pendingOrders.filter(order => 
                      order.deliveryMethod === DeliveryMethod.ENVIO_NACIONAL || 
                      order.deliveryMethod === DeliveryMethod.ENVIO_INTERNACIONAL
                    ).length}
                  </Badge>
                </div>
              </div>
            </Card.Body>
          </Card>
          
          <Card className="shadow-sm">
            <Card.Body>
              <Card.Title>Información</Card.Title>
              <Card.Text>
                Procesa los pedidos verificados por Cartera. Asigna peso y mensajero según el método de entrega.
              </Card.Text>
              
              <hr />
              
              <h6>Asignación de Pedidos</h6>
              <ul className="small">
                <li><strong>Domicilio:</strong> Asignar a mensajeros locales</li>
                <li><strong>Envío Nacional/Internacional:</strong> Asignar a servicios de envío</li>
                <li><strong>Recogida en Tienda:</strong> Preparar para entrega en tienda</li>
              </ul>
              
              <h6>Mensajeros Locales</h6>
              <ul className="small">
                <li>Duban Pineda</li>
                <li>Picap</li>
                <li>Didi</li>
                <li>Bodega</li>
              </ul>
              
              <h6>Servicios de Envío</h6>
              <ul className="small">
                <li>Interrapidisimo</li>
                <li>Picap</li>
                <li>Bodega</li>
              </ul>
            </Card.Body>
          </Card>
        </Col>
      </Row>
      
      {/* Process Modal */}
      <ProcessModal 
        show={showProcessModal}
        order={selectedOrder}
        onHide={() => setShowProcessModal(false)}
        onProcess={handleProcess}
      />
    </Container>
  );
};

export default Logistica;
