import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert } from 'react-bootstrap';
import { DeliveryMethod, PaymentMethod, PaymentStatus } from '../types/user';
import { OrderStatus } from '../types/order';
import { useOrders } from '../context/OrderContext';
import { useAuth } from '../context/AuthContext';

interface InvoiceFormData {
  invoiceCode: string;
  clientName: string;
  deliveryMethod: DeliveryMethod;
  paymentMethod: PaymentMethod;
  estimatedDeliveryDate: string;
  totalAmount: string;
  notes: string;
}

const Facturacion: React.FC = () => {
  const { createOrder, refreshOrders } = useOrders();
  const { authState } = useAuth();
  const { user } = authState;

  const [formData, setFormData] = useState<InvoiceFormData>({
    invoiceCode: '',
    clientName: '',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    estimatedDeliveryDate: '',
    totalAmount: '',
    notes: ''
  });

  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.invoiceCode) {
      setError('El código de factura es obligatorio');
      return false;
    }
    
    if (!formData.clientName) {
      setError('El nombre del cliente es obligatorio');
      return false;
    }
    
    if (!formData.totalAmount || isNaN(parseFloat(formData.totalAmount))) {
      setError('El monto total debe ser un número válido');
      return false;
    }
    
    if (!formData.estimatedDeliveryDate) {
      setError('La fecha estimada de entrega es obligatoria');
      return false;
    }
    
    // Check if estimated delivery date is not in the past
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const deliveryDate = new Date(formData.estimatedDeliveryDate);
    
    if (deliveryDate < today) {
      setError('La fecha estimada de entrega no puede ser anterior a hoy');
      return false;
    }
    
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    
    if (!validateForm()) {
      setIsSubmitting(false);
      return;
    }
    
    try {
      // Get current date and time
      const now = new Date();
      
      // Create order data in the format expected by the OrderContext
      const orderData = {
        invoiceCode: formData.invoiceCode,
        clientName: formData.clientName,
        deliveryMethod: formData.deliveryMethod,
        paymentMethod: formData.paymentMethod,
        totalAmount: parseFloat(formData.totalAmount),
        notes: formData.notes,
        address: '',
        phone: '',
        paymentStatus: PaymentStatus.PENDIENTE,
        billedBy: user?.name || 'Usuario Facturación'
      };
      
      // Save order to database using OrderContext
      await createOrder(orderData);
      
      // Reset form and show success message
      setFormData({
        invoiceCode: '',
        clientName: '',
        deliveryMethod: DeliveryMethod.DOMICILIO,
        paymentMethod: PaymentMethod.EFECTIVO,
        estimatedDeliveryDate: '',
        totalAmount: '',
        notes: ''
      });
      
      setShowSuccess(true);
      setTimeout(() => setShowSuccess(false), 5000);
    } catch (err) {
      console.error('Error creating order:', err);
      setError('Error al crear la factura. Por favor intente nuevamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Container>
      <h1 className="mb-4">Facturación</h1>
      
      {showSuccess && (
        <Alert variant="success" onClose={() => setShowSuccess(false)} dismissible>
          Factura creada exitosamente. El pedido ha sido enviado a Cartera para verificación.
        </Alert>
      )}
      
      {error && (
        <Alert variant="danger" onClose={() => setError(null)} dismissible>
          {error}
        </Alert>
      )}
      
      <Row>
        <Col lg={8}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Nueva Factura</Card.Title>
              <Form onSubmit={handleSubmit}>
                <Row className="mb-3">
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Código de Factura</Form.Label>
                      <Form.Control
                        type="text"
                        name="invoiceCode"
                        value={formData.invoiceCode}
                        onChange={handleChange}
                        placeholder="Ej. FAC-001"
                        required
                      />
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Nombre del Cliente</Form.Label>
                      <Form.Control
                        type="text"
                        name="clientName"
                        value={formData.clientName}
                        onChange={handleChange}
                        placeholder="Nombre completo"
                        required
                      />
                    </Form.Group>
                  </Col>
                </Row>
                
                <Row className="mb-3">
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Método de Entrega</Form.Label>
                      <Form.Select 
                        name="deliveryMethod"
                        value={formData.deliveryMethod}
                        onChange={handleChange}
                        required
                      >
                        <option value={DeliveryMethod.DOMICILIO}>Domicilio</option>
                        <option value={DeliveryMethod.RECOGIDA_TIENDA}>Recogida en Tienda</option>
                        <option value={DeliveryMethod.ENVIO_NACIONAL}>Envío Nacional</option>
                        <option value={DeliveryMethod.ENVIO_INTERNACIONAL}>Envío Internacional</option>
                      </Form.Select>
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Método de Pago</Form.Label>
                      <Form.Select 
                        name="paymentMethod"
                        value={formData.paymentMethod}
                        onChange={handleChange}
                        required
                      >
                        <option value={PaymentMethod.EFECTIVO}>Efectivo</option>
                        <option value={PaymentMethod.TRANSFERENCIA}>Transferencia Bancaria</option>
                        <option value={PaymentMethod.TARJETA_CREDITO}>Tarjeta de Crédito</option>
                        <option value={PaymentMethod.PAGO_ELECTRONICO}>Pago Electrónico</option>
                      </Form.Select>
                    </Form.Group>
                  </Col>
                </Row>
                
                <Row className="mb-3">
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Fecha Estimada de Entrega</Form.Label>
                      <Form.Control
                        type="date"
                        name="estimatedDeliveryDate"
                        value={formData.estimatedDeliveryDate}
                        onChange={handleChange}
                        required
                      />
                    </Form.Group>
                  </Col>
                  <Col md={6}>
                    <Form.Group className="mb-3">
                      <Form.Label>Monto Total</Form.Label>
                      <Form.Control
                        type="number"
                        name="totalAmount"
                        value={formData.totalAmount}
                        onChange={handleChange}
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                        required
                      />
                    </Form.Group>
                  </Col>
                </Row>
                
                <Form.Group className="mb-3">
                  <Form.Label>Notas Adicionales</Form.Label>
                  <Form.Control
                    as="textarea"
                    name="notes"
                    value={formData.notes}
                    onChange={handleChange}
                    rows={3}
                    placeholder="Instrucciones especiales, detalles del pedido, etc."
                  />
                </Form.Group>
                
                <div className="d-grid gap-2 mt-4">
                  <Button 
                    variant="primary" 
                    type="submit"
                    disabled={isSubmitting}
                  >
                    {isSubmitting ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                        Guardando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-save me-2"></i>
                        Crear Factura
                      </>
                    )}
                  </Button>
                </div>
              </Form>
            </Card.Body>
          </Card>
        </Col>
        
        <Col lg={4}>
          <Card className="shadow-sm mb-4">
            <Card.Body>
              <Card.Title>Información</Card.Title>
              <Card.Text>
                Crea una nueva factura para iniciar el proceso de pedido. Una vez creada, el pedido pasará a Cartera para verificación de pago.
              </Card.Text>
              
              <hr />
              
              <h6>Métodos de Entrega</h6>
              <ul className="small">
                <li><strong>Domicilio:</strong> Entrega local por mensajero</li>
                <li><strong>Recogida en Tienda:</strong> El cliente recoge en el local</li>
                <li><strong>Envío Nacional:</strong> Envío a otras ciudades</li>
                <li><strong>Envío Internacional:</strong> Envío fuera del país</li>
              </ul>
              
              <h6>Métodos de Pago</h6>
              <ul className="small">
                <li><strong>Efectivo:</strong> Pago en efectivo al entregar</li>
                <li><strong>Transferencia:</strong> Pago por transferencia bancaria</li>
                <li><strong>Tarjeta de Crédito:</strong> Pago con tarjeta</li>
                <li><strong>Pago Electrónico:</strong> Nequi, Daviplata, etc.</li>
              </ul>
              
              <Alert variant="info" className="mt-3 mb-0">
                <i className="bi bi-info-circle me-2"></i>
                Recuerda que para recogida en tienda, el pago debe estar verificado antes de pasar a logística.
              </Alert>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default Facturacion;
