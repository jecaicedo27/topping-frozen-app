import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Table, Badge, Button, Form, Modal } from 'react-bootstrap';
import { DeliveryMethod, PaymentMethod, PaymentStatus } from '../types/user';
import { OrderStatus, Order } from '../types/order';
import { useOrders } from '../context/OrderContext';

interface VerificationModalProps {
  show: boolean;
  order: any;
  onHide: () => void;
  onVerify: (orderId: string, paymentStatus: PaymentStatus, hasProof: boolean, creditApproved: boolean) => void;
}

const VerificationModal: React.FC<VerificationModalProps> = ({ show, order, onHide, onVerify }) => {
  const [paymentStatus, setPaymentStatus] = useState<PaymentStatus>(PaymentStatus.PENDIENTE);
  const [hasPaymentProof, setHasPaymentProof] = useState(false);
  const [creditApproved, setCreditApproved] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
      setHasPaymentProof(true);
    } else {
      setFile(null);
      setHasPaymentProof(false);
    }
  };

  const validateVerification = (): boolean => {
    // Reset error
    setError(null);
    
    // For store pickup, payment must be verified
    if (order.deliveryMethod === DeliveryMethod.RECOGIDA_TIENDA && paymentStatus !== PaymentStatus.PAGADO) {
      setError('Para recogida en tienda, el pago debe estar verificado');
      return false;
    }
    
    // For national/international shipping, payment must be verified or credit approved
    if ((order.deliveryMethod === DeliveryMethod.ENVIO_NACIONAL || 
         order.deliveryMethod === DeliveryMethod.ENVIO_INTERNACIONAL) && 
        paymentStatus !== PaymentStatus.PAGADO && !creditApproved) {
      setError('Para envíos nacionales o internacionales, el pago debe estar verificado o el crédito aprobado');
      return false;
    }
    
    // If payment is marked as paid, must have proof
    if (paymentStatus === PaymentStatus.PAGADO && !hasPaymentProof) {
      setError('Si el pago está marcado como verificado, debe adjuntar un comprobante');
      return false;
    }
    
    return true;
  };

  const handleVerify = () => {
    if (validateVerification()) {
      onVerify(order.id, paymentStatus, hasPaymentProof, creditApproved);
      onHide();
    }
  };

  return (
    <Modal show={show} onHide={onHide} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Verificar Pago - {order?.invoiceCode}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && (
          <div className="alert alert-danger">{error}</div>
        )}
        
        <Row className="mb-4">
          <Col md={6}>
            <p><strong>Cliente:</strong> {order?.clientName}</p>
            <p><strong>Monto:</strong> ${order?.totalAmount ? order?.totalAmount.toLocaleString() : '0'}</p>
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
            <p><strong>Fecha Estimada:</strong> {order?.estimatedDeliveryDate ? new Date(order?.estimatedDeliveryDate).toLocaleDateString() : 'No disponible'}</p>
            <p><strong>Notas:</strong> {order?.notes || 'Sin notas'}</p>
          </Col>
        </Row>
        
        <Form>
          <Form.Group className="mb-3">
            <Form.Label>Estado de Pago</Form.Label>
            <Form.Select 
              value={paymentStatus}
              onChange={(e) => setPaymentStatus(e.target.value as PaymentStatus)}
            >
              <option value={PaymentStatus.PENDIENTE}>Pendiente</option>
              <option value={PaymentStatus.PAGADO}>Pagado</option>
            </Form.Select>
          </Form.Group>
          
          {paymentStatus === PaymentStatus.PAGADO && (
            <Form.Group className="mb-3">
              <Form.Label>Comprobante de Pago</Form.Label>
              <Form.Control 
                type="file" 
                accept="image/*,.pdf" 
                onChange={handleFileChange}
                required
              />
              <Form.Text className="text-muted">
                Adjunte una imagen o PDF del comprobante de pago
              </Form.Text>
            </Form.Group>
          )}
          
          {(order?.deliveryMethod === DeliveryMethod.ENVIO_NACIONAL || 
            order?.deliveryMethod === DeliveryMethod.ENVIO_INTERNACIONAL) && (
            <Form.Group className="mb-3">
              <Form.Check 
                type="checkbox"
                id="credit-approved"
                label="Aprobar Crédito para este Cliente"
                checked={creditApproved}
                onChange={(e) => setCreditApproved(e.target.checked)}
              />
              <Form.Text className="text-muted">
                Marque esta opción si el cliente tiene crédito aprobado para envíos nacionales o internacionales
              </Form.Text>
            </Form.Group>
          )}
        </Form>
        
        <div className="alert alert-info mt-3">
          <i className="bi bi-info-circle me-2"></i>
          <strong>Recordatorio de Reglas:</strong>
          <ul className="mb-0 mt-2">
            <li>Para recogida en tienda: el pedido DEBE estar pagado</li>
            <li>Para envío nacional/internacional: el pedido debe estar pagado O el cliente debe tener crédito aprobado</li>
            <li>Si el pago está marcado como "Pagado", debe adjuntarse un comprobante</li>
            <li>Para pedidos a domicilio, puede pasar a logística con cualquier estado de pago</li>
          </ul>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Cancelar
        </Button>
        <Button variant="primary" onClick={handleVerify}>
          Verificar y Enviar a Logística
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

const Cartera: React.FC = () => {
  const { orders: allOrders, getOrdersByStatus, approvePayment, refreshOrders } = useOrders();
  const [pendingOrders, setPendingOrders] = useState<Order[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [showVerificationModal, setShowVerificationModal] = useState(false);
  const [messengerSummary, setMessengerSummary] = useState<any[]>([]);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedMessenger, setSelectedMessenger] = useState<any>(null);
  const [selectedInvoices, setSelectedInvoices] = useState<Set<string>>(new Set());
  const [totalSummary, setTotalSummary] = useState({
    totalAmount: 0,
    messengerCount: 0,
    deliveryCount: 0
  });
  const [forceUpdate, setForceUpdate] = useState(0);
  const [showPhotoModal, setShowPhotoModal] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [moneyReceipts, setMoneyReceipts] = useState<any[]>([]);

  // Load money receipts history
  const loadMoneyReceipts = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/money-receipts/today', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });

      if (response.ok) {
        const result = await response.json();
        setMoneyReceipts(result.data);
      }
    } catch (error) {
      console.error('Error loading money receipts:', error);
    }
  };

  const handleViewHistory = () => {
    loadMoneyReceipts();
    setShowHistoryModal(true);
  };
  
  useEffect(() => {
    // Get orders with PENDING_WALLET status
    const walletOrders = getOrdersByStatus(OrderStatus.PENDING_WALLET);
    setPendingOrders(walletOrders);
    
    // Calculate messenger summary from delivered orders
    const deliveredOrders = getOrdersByStatus(OrderStatus.DELIVERED);
    const today = new Date().toISOString().split('T')[0];
    
    // Filter delivered orders that were paid in cash
    const todayDelivered = deliveredOrders.filter(order => 
      order.paymentMethod === PaymentMethod.EFECTIVO &&
      order.amountCollected && order.amountCollected > 0
    );
    
    // Group by messenger (deliveredBy field)
    const messengerGroups = todayDelivered.reduce((acc: any, order) => {
      const messenger = order.deliveredBy || 'Sin asignar';
      if (!acc[messenger]) {
        acc[messenger] = {
          name: messenger,
          orders: [],
          totalAmount: 0,
          deliveryCount: 0
        };
      }
      acc[messenger].orders.push(order);
      // Ensure we're adding numbers, not concatenating strings
      const amount = typeof order.amountCollected === 'number' ? order.amountCollected : parseFloat(String(order.amountCollected || 0)) || 0;
      acc[messenger].totalAmount += amount;
      acc[messenger].deliveryCount += 1;
      return acc;
    }, {});
    
    // Convert to array for display
    const summary = Object.values(messengerGroups);
    setMessengerSummary(summary);
  }, [allOrders, getOrdersByStatus]);

  // Update total summary whenever messengerSummary changes
  useEffect(() => {
    const totalAmount = messengerSummary.reduce((total, messenger) => total + messenger.totalAmount, 0);
    const messengerCount = messengerSummary.length;
    const deliveryCount = messengerSummary.reduce((total, messenger) => total + messenger.deliveryCount, 0);
    
    setTotalSummary({
      totalAmount,
      messengerCount,
      deliveryCount
    });
  }, [messengerSummary, forceUpdate]);

  // Function to recalculate totals immediately
  const recalculateTotals = (newMessengerSummary: any[]) => {
    const totalAmount = newMessengerSummary.reduce((total, messenger) => total + messenger.totalAmount, 0);
    const messengerCount = newMessengerSummary.length;
    const deliveryCount = newMessengerSummary.reduce((total, messenger) => total + messenger.deliveryCount, 0);
    
    setTotalSummary({
      totalAmount,
      messengerCount,
      deliveryCount
    });
  };

  const handleVerifyClick = (order: any) => {
    setSelectedOrder(order);
    setShowVerificationModal(true);
  };

  const handleVerify = (orderId: string, paymentStatus: PaymentStatus, hasProof: boolean, creditApproved: boolean) => {
    // Call the approvePayment function from OrderContext
    approvePayment(orderId, paymentStatus, hasProof ? 'proof.jpg' : null);
    
    // Update local state to remove the verified order
    setPendingOrders(prevOrders => prevOrders.filter(order => order.id !== orderId));
  };

  const handleViewDetail = (messenger: any) => {
    setSelectedMessenger(messenger);
    setSelectedInvoices(new Set()); // Clear previous selections
    setShowDetailModal(true);
  };

  const handleReceiveMoney = (messenger: any) => {
    // In a real app, this would update the database to mark money as received
    alert(`Dinero recibido de ${messenger.name}: $${messenger.totalAmount.toLocaleString()}`);
    // For now, we'll just remove the messenger from the summary
    setMessengerSummary(prev => prev.filter(m => m.name !== messenger.name));
  };

  const handleReceiveAll = () => {
    const totalAmount = messengerSummary.reduce((total, messenger) => total + messenger.totalAmount, 0);
    alert(`Dinero total recibido: $${totalAmount.toLocaleString()}`);
    // Clear all messengers
    setMessengerSummary([]);
  };

  const handleInvoiceToggle = (invoiceCode: string) => {
    setSelectedInvoices(prev => {
      const newSet = new Set(prev);
      if (newSet.has(invoiceCode)) {
        newSet.delete(invoiceCode);
      } else {
        newSet.add(invoiceCode);
      }
      return newSet;
    });
  };

  const handleReceiveSelectedInvoices = async () => {
    if (selectedInvoices.size === 0) {
      alert('Por favor seleccione al menos una factura para recibir el dinero.');
      return;
    }

    // Show photo capture modal
    setShowPhotoModal(true);
  };

  const handlePhotoCapture = async (photoFile: File | null, notes: string = '') => {
    // Capture selected invoices before clearing them
    const invoicesToProcess = new Set(selectedInvoices);
    
    const selectedOrders = selectedMessenger.orders.filter((order: any) => 
      invoicesToProcess.has(order.invoiceCode)
    );
    
    const totalAmount = selectedOrders.reduce((total: number, order: any) => {
      const amount = typeof order.amountCollected === 'number' ? order.amountCollected : parseFloat(String(order.amountCollected || 0)) || 0;
      return total + amount;
    }, 0);

    const invoiceList = Array.from(invoicesToProcess);
    
    try {
      // Create money receipt with photo
      const formData = new FormData();
      formData.append('messenger_name', selectedMessenger.name);
      formData.append('total_amount', totalAmount.toString());
      formData.append('invoice_codes', JSON.stringify(invoiceList));
      formData.append('notes', notes);
      
      if (photoFile) {
        formData.append('receipt_photo', photoFile);
      }

      const receiptResponse = await fetch('http://localhost:5000/api/money-receipts', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: formData
      });

      if (!receiptResponse.ok) {
        throw new Error('Error al crear el recibo de dinero');
      }

      const receiptResult = await receiptResponse.json();
      const receiptId = receiptResult.data.id;

      // Update each selected order to mark money as received
      for (const order of selectedOrders) {
        const response = await fetch(`http://localhost:5000/api/orders/${order.id}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          },
          body: JSON.stringify({
            amount_collected: 0,
            money_received_at: new Date().toISOString(),
            money_received_by: localStorage.getItem('user') ? JSON.parse(localStorage.getItem('user')!).username : 'system',
            receipt_id: receiptId
          }),
        });
        
        if (!response.ok) {
          throw new Error(`Error updating order ${order.id}`);
        }
      }
      
      alert(`Dinero recibido de ${selectedMessenger.name}:\nFacturas: ${invoiceList.join(', ')}\nTotal: $${totalAmount.toLocaleString()}\n${photoFile ? 'Con foto de recepción' : 'Sin foto'}`);
      
      // Refresh orders from context to get updated data
      await refreshOrders();
      
      // Clear selections and close modals
      setSelectedInvoices(new Set());
      setShowDetailModal(false);
      setShowPhotoModal(false);
      
    } catch (error) {
      console.error('Error processing receipt:', error);
      alert(`Error al procesar la recepción: ${error instanceof Error ? error.message : 'Error desconocido'}`);
    }
  };

  const selectAllInvoices = () => {
    if (selectedMessenger) {
      const allInvoices = new Set<string>(selectedMessenger.orders.map((order: any) => order.invoiceCode));
      setSelectedInvoices(allInvoices);
    }
  };

  const clearAllSelections = () => {
    setSelectedInvoices(new Set());
  };

  const getStatusBadge = (status: string) => {
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

  const getDeliveryMethodText = (method: string) => {
    return method || 'Desconocido';
  };

  const getPaymentMethodText = (method: string) => {
    return method || 'Desconocido';
  };

  return (
    <Container>
      <h1 className="mb-4">Cartera</h1>
      
      <Card className="shadow-sm mb-4">
        <Card.Body>
          <Card.Title>Pedidos Pendientes de Verificación</Card.Title>
          
          {pendingOrders.length === 0 ? (
            <div className="text-center py-5">
              <i className="bi bi-check-circle text-success fs-1"></i>
              <p className="mt-3">No hay pedidos pendientes de verificación</p>
            </div>
          ) : (
            <div className="table-responsive">
              <Table hover className="align-middle">
                <thead>
                  <tr>
                    <th>Código</th>
                    <th>Cliente</th>
                    <th>Método Entrega</th>
                    <th>Método Pago</th>
                    <th>Monto</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingOrders.map((order: Order) => (
                    <tr key={order.id}>
                      <td>{order.invoiceCode}</td>
                      <td>{order.clientName}</td>
                      <td>{getDeliveryMethodText(order.deliveryMethod)}</td>
                      <td>{getPaymentMethodText(order.paymentMethod)}</td>
                      <td>${order.totalAmount ? order.totalAmount.toLocaleString() : '0'}</td>
                      <td>{getStatusBadge(order.status)}</td>
                      <td>
                        <Button 
                          variant="primary" 
                          size="sm"
                          onClick={() => handleVerifyClick(order)}
                        >
                          <i className="bi bi-check-circle me-1"></i>
                          Verificar
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
      
      <Row>
        <Col lg={8}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Control de Dinero - Mensajeros</Card.Title>
              
              <div className="table-responsive">
                <Table hover className="align-middle">
                  <thead>
                    <tr>
                      <th>Mensajero</th>
                      <th>Entregas Hoy</th>
                      <th>Total a Recibir</th>
                      <th>Estado</th>
                      <th>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {messengerSummary.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="text-center py-4">
                          <p className="text-muted">No hay entregas en efectivo registradas hoy</p>
                        </td>
                      </tr>
                    ) : (
                      messengerSummary.map((messenger: any, index: number) => (
                        <tr key={index}>
                          <td>
                            <div>
                              <strong>{messenger.name}</strong>
                              <br />
                              <small className="text-muted">Mensajero</small>
                            </div>
                          </td>
                          <td>
                            <Badge bg="info">{messenger.deliveryCount} entregas</Badge>
                          </td>
                          <td>
                            <span className="fs-5 fw-bold text-success">
                              ${messenger.totalAmount.toLocaleString()}
                            </span>
                          </td>
                          <td>
                            <Badge bg="warning" text="dark">Pendiente</Badge>
                          </td>
                          <td>
                            <Button 
                              variant="success" 
                              size="sm" 
                              className="me-2"
                              onClick={() => handleReceiveMoney(messenger)}
                            >
                              <i className="bi bi-cash-stack me-1"></i>
                              Recibir Dinero
                            </Button>
                            <Button 
                              variant="outline-primary" 
                              size="sm"
                              onClick={() => handleViewDetail(messenger)}
                            >
                              <i className="bi bi-list-ul me-1"></i>
                              Ver Detalle
                            </Button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </Table>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col lg={4}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Resumen Total</Card.Title>
              
              <div className="text-center my-4">
                <h3 className="mb-0 text-success">
                  ${totalSummary.totalAmount.toLocaleString()}
                </h3>
                <p className="text-muted">Total a Recibir Hoy</p>
              </div>
              
              <div className="mb-3">
                <div className="d-flex justify-content-between align-items-center mb-2">
                  <span>Mensajeros Activos:</span>
                  <Badge bg="primary" className="fs-6">{totalSummary.messengerCount}</Badge>
                </div>
                <div className="d-flex justify-content-between align-items-center mb-2">
                  <span>Entregas Completadas:</span>
                  <Badge bg="success" className="fs-6">
                    {totalSummary.deliveryCount}
                  </Badge>
                </div>
                <div className="d-flex justify-content-between align-items-center">
                  <span>Dinero Pendiente:</span>
                  <Badge bg="warning" className="fs-6">
                    ${totalSummary.totalAmount.toLocaleString()}
                  </Badge>
                </div>
              </div>
              
              <div className="d-grid gap-2">
                <Button variant="primary">
                  <i className="bi bi-printer me-2"></i>
                  Reporte General
                </Button>
                <Button variant="outline-info" onClick={handleViewHistory}>
                  <i className="bi bi-clock-history me-2"></i>
                  Ver Historial
                </Button>
                <Button variant="outline-success" onClick={handleReceiveAll}>
                  <i className="bi bi-cash-stack me-2"></i>
                  Recibir Todo
                </Button>
              </div>
            </Card.Body>
          </Card>
          
          <Card className="shadow-sm">
            <Card.Body>
              <Card.Title>Información</Card.Title>
              <Card.Text>
                Controla el dinero que deben entregar los mensajeros por cobros en efectivo.
              </Card.Text>
              
              <hr />
              
              <h6>Estados</h6>
              <ul className="small">
                <li><Badge bg="warning" text="dark">Pendiente</Badge> - Dinero por recibir</li>
                <li><Badge bg="success">Entregado</Badge> - Dinero ya recibido</li>
              </ul>
              
              <div className="alert alert-info mt-3 mb-0">
                <i className="bi bi-info-circle me-2"></i>
                Solo se muestran pedidos pagados en efectivo.
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Verification Modal */}
      <VerificationModal 
        show={showVerificationModal}
        order={selectedOrder}
        onHide={() => setShowVerificationModal(false)}
        onVerify={handleVerify}
      />

      {/* Detail Modal */}
      <Modal show={showDetailModal} onHide={() => setShowDetailModal(false)} size="lg" centered>
        <Modal.Header closeButton>
          <Modal.Title>Detalle de Entregas - {selectedMessenger?.name}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedMessenger && (
            <>
              <div className="mb-4">
                <Row>
                  <Col md={4}>
                    <div className="text-center">
                      <h4 className="text-success">${selectedMessenger.totalAmount.toLocaleString()}</h4>
                      <p className="text-muted">Total a Recibir</p>
                    </div>
                  </Col>
                  <Col md={4}>
                    <div className="text-center">
                      <h4 className="text-primary">{selectedMessenger.deliveryCount}</h4>
                      <p className="text-muted">Entregas</p>
                    </div>
                  </Col>
                  <Col md={4}>
                    <div className="text-center">
                      <h4 className="text-info">{selectedMessenger.orders.length}</h4>
                      <p className="text-muted">Pedidos</p>
                    </div>
                  </Col>
                </Row>
              </div>

              <div className="d-flex justify-content-between align-items-center mb-3">
                <h6 className="mb-0">Pedidos Entregados:</h6>
                <div>
                  <Button variant="outline-secondary" size="sm" className="me-2" onClick={selectAllInvoices}>
                    <i className="bi bi-check-all me-1"></i>
                    Seleccionar Todo
                  </Button>
                  <Button variant="outline-secondary" size="sm" onClick={clearAllSelections}>
                    <i className="bi bi-x-circle me-1"></i>
                    Limpiar
                  </Button>
                </div>
              </div>
              
              <div className="table-responsive">
                <Table striped hover size="sm">
                  <thead>
                    <tr>
                      <th style={{width: '50px'}}>
                        <Form.Check 
                          type="checkbox"
                          checked={selectedInvoices.size === selectedMessenger.orders.length && selectedMessenger.orders.length > 0}
                          onChange={(e) => {
                            if (e.target.checked) {
                              selectAllInvoices();
                            } else {
                              clearAllSelections();
                            }
                          }}
                        />
                      </th>
                      <th>Factura</th>
                      <th>Cliente</th>
                      <th>Fecha Entrega</th>
                      <th>Monto Cobrado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedMessenger.orders.map((order: any, index: number) => (
                      <tr key={index} className={selectedInvoices.has(order.invoiceCode) ? 'table-success' : ''}>
                        <td>
                          <Form.Check 
                            type="checkbox"
                            checked={selectedInvoices.has(order.invoiceCode)}
                            onChange={() => handleInvoiceToggle(order.invoiceCode)}
                          />
                        </td>
                        <td>
                          <strong>{order.invoiceCode}</strong>
                        </td>
                        <td>{order.clientName}</td>
                        <td>{order.deliveryDate ? new Date(order.deliveryDate).toLocaleDateString() : 'Hoy'}</td>
                        <td className="text-success fw-bold">
                          ${order.amountCollected?.toLocaleString() || '0'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </div>
              
              {selectedInvoices.size > 0 && (
                <div className="alert alert-info mt-3">
                  <i className="bi bi-info-circle me-2"></i>
                  <strong>Facturas seleccionadas:</strong> {selectedInvoices.size} de {selectedMessenger.orders.length}
                  <br />
                  <strong>Total seleccionado:</strong> ${selectedMessenger.orders
                    .filter((order: any) => selectedInvoices.has(order.invoiceCode))
                    .reduce((total: number, order: any) => {
                      const amount = typeof order.amountCollected === 'number' ? order.amountCollected : parseFloat(String(order.amountCollected || 0)) || 0;
                      return total + amount;
                    }, 0).toLocaleString()}
                </div>
              )}
            </>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowDetailModal(false)}>
            Cerrar
          </Button>
          <Button 
            variant="success" 
            onClick={handleReceiveSelectedInvoices}
            disabled={selectedInvoices.size === 0}
          >
            <i className="bi bi-cash-stack me-1"></i>
            Recibir Facturas Seleccionadas ({selectedInvoices.size})
          </Button>
        </Modal.Footer>
      </Modal>

      {/* Photo Capture Modal */}
      <PhotoCaptureModal 
        show={showPhotoModal}
        onHide={() => setShowPhotoModal(false)}
        onCapture={handlePhotoCapture}
        messengerName={selectedMessenger?.name || ''}
        totalAmount={selectedMessenger?.orders
          ?.filter((order: any) => selectedInvoices.has(order.invoiceCode))
          ?.reduce((total: number, order: any) => {
            const amount = typeof order.amountCollected === 'number' ? order.amountCollected : parseFloat(String(order.amountCollected || 0)) || 0;
            return total + amount;
          }, 0) || 0}
        invoiceCount={selectedInvoices.size}
      />

      {/* History Modal */}
      <HistoryModal 
        show={showHistoryModal}
        onHide={() => setShowHistoryModal(false)}
        receipts={moneyReceipts}
      />
    </Container>
  );
};

// Photo Capture Modal Component
interface PhotoCaptureModalProps {
  show: boolean;
  onHide: () => void;
  onCapture: (photoFile: File | null, notes: string) => void;
  messengerName: string;
  totalAmount: number;
  invoiceCount: number;
}

const PhotoCaptureModal: React.FC<PhotoCaptureModalProps> = ({ 
  show, onHide, onCapture, messengerName, totalAmount, invoiceCount 
}) => {
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [notes, setNotes] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      setPhotoFile(file);
      
      // Create preview URL
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    }
  };

  const handleCapture = () => {
    onCapture(photoFile, notes);
    // Reset form
    setPhotoFile(null);
    setNotes('');
    setPreviewUrl(null);
  };

  const handleClose = () => {
    // Clean up preview URL
    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
      setPreviewUrl(null);
    }
    setPhotoFile(null);
    setNotes('');
    onHide();
  };

  return (
    <Modal show={show} onHide={handleClose} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>
          <i className="bi bi-camera me-2"></i>
          Foto de Recepción de Dinero
        </Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <div className="alert alert-info">
          <i className="bi bi-info-circle me-2"></i>
          <strong>Recepción de:</strong> {messengerName}<br />
          <strong>Facturas:</strong> {invoiceCount} seleccionadas<br />
          <strong>Total:</strong> ${totalAmount.toLocaleString()}
        </div>

        <Form>
          <Form.Group className="mb-3">
            <Form.Label>
              <i className="bi bi-camera me-2"></i>
              Foto de Recepción (Opcional)
            </Form.Label>
            <Form.Control 
              type="file" 
              accept="image/*"
              capture="environment"
              onChange={handleFileChange}
            />
            <Form.Text className="text-muted">
              Toma una foto del dinero recibido para el historial
            </Form.Text>
          </Form.Group>

          {previewUrl && (
            <div className="mb-3">
              <Form.Label>Vista Previa:</Form.Label>
              <div className="text-center">
                <img 
                  src={previewUrl} 
                  alt="Preview" 
                  style={{ maxWidth: '100%', maxHeight: '300px' }}
                  className="img-thumbnail"
                />
              </div>
            </div>
          )}

          <Form.Group className="mb-3">
            <Form.Label>
              <i className="bi bi-chat-text me-2"></i>
              Notas (Opcional)
            </Form.Label>
            <Form.Control 
              as="textarea" 
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Observaciones sobre la recepción del dinero..."
            />
          </Form.Group>
        </Form>

        <div className="alert alert-warning">
          <i className="bi bi-exclamation-triangle me-2"></i>
          <strong>Importante:</strong> Una vez confirmada la recepción, las facturas seleccionadas se marcarán como dinero recibido y no aparecerán más en el control de dinero pendiente.
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={handleClose}>
          Cancelar
        </Button>
        <Button variant="success" onClick={handleCapture}>
          <i className="bi bi-check-circle me-1"></i>
          Confirmar Recepción
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

// History Modal Component
interface HistoryModalProps {
  show: boolean;
  onHide: () => void;
  receipts: any[];
}

const HistoryModal: React.FC<HistoryModalProps> = ({ show, onHide, receipts }) => {
  return (
    <Modal show={show} onHide={onHide} size="xl" centered>
      <Modal.Header closeButton>
        <Modal.Title>
          <i className="bi bi-clock-history me-2"></i>
          Historial de Recepciones de Dinero
        </Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {receipts.length === 0 ? (
          <div className="text-center py-5">
            <i className="bi bi-inbox text-muted fs-1"></i>
            <p className="mt-3 text-muted">No hay recepciones registradas</p>
          </div>
        ) : (
          <div className="table-responsive">
            <Table hover>
              <thead>
                <tr>
                  <th>Fecha/Hora</th>
                  <th>Mensajero</th>
                  <th>Monto</th>
                  <th>Facturas</th>
                  <th>Recibido por</th>
                  <th>Foto</th>
                  <th>Notas</th>
                </tr>
              </thead>
              <tbody>
                {receipts.map((receipt, index) => (
                  <tr key={index}>
                    <td>
                      <small>
                        {new Date(receipt.received_at).toLocaleDateString()}<br />
                        {new Date(receipt.received_at).toLocaleTimeString()}
                      </small>
                    </td>
                    <td>
                      <strong>{receipt.messenger_name}</strong>
                    </td>
                    <td>
                      <span className="fw-bold text-success">
                        ${receipt.total_amount.toLocaleString()}
                      </span>
                    </td>
                    <td>
                      <small>
                        {JSON.parse(receipt.invoice_codes).join(', ')}
                      </small>
                    </td>
                    <td>
                      <small>{receipt.received_by}</small>
                    </td>
                    <td>
                      {/* Show payment photo from order (captured by messenger) */}
                      <Button 
                        variant="outline-primary" 
                        size="sm"
                        onClick={() => {
                          // In a real implementation, this would show the payment photo from the order
                          alert('Foto del pago capturada por el mensajero al recibir el dinero del cliente');
                        }}
                      >
                        <i className="bi bi-image me-1"></i>
                        Ver Foto del Pago
                      </Button>
                    </td>
                    <td>
                      <small>{receipt.notes || 'Sin notas'}</small>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </div>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Cerrar
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default Cartera;
