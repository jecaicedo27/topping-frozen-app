// Mock data for demonstration
const mockOrders = [
  {
    id: '1',
    invoiceCode: 'FAC-001',
    clientName: 'Juan Pérez',
    date: '2025-05-15',
    time: '10:30:00',
    deliveryMethod: 'Domicilio',
    paymentMethod: 'Efectivo',
    totalAmount: 75000,
    status: 'pending_wallet',
    paymentStatus: 'Pendiente por cobrar',
    billedBy: 'Depto. Facturación',
    address: 'Calle 123 #45-67, Apto 301',
    phone: '3101234567',
    notes: 'Entregar en la dirección principal',
    history: []
  },
  {
    id: '2',
    invoiceCode: 'FAC-002',
    clientName: 'María López',
    date: '2025-05-15',
    time: '11:15:00',
    deliveryMethod: 'Recogida en tienda',
    paymentMethod: 'Transferencia bancaria',
    totalAmount: 120000,
    status: 'pending_wallet',
    paymentStatus: 'Pendiente por cobrar',
    billedBy: 'Depto. Facturación',
    notes: 'Cliente frecuente',
    history: []
  }
];

// Save to localStorage
localStorage.setItem('orders', JSON.stringify(mockOrders));
console.log('Mock data added to localStorage');
