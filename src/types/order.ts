import { DeliveryMethod, PaymentMethod, PaymentStatus } from './user';

export enum OrderStatus {
  PENDING_WALLET = 'pending_wallet',
  PENDING_LOGISTICS = 'pending_logistics',
  PENDING = 'pending',
  DELIVERED = 'delivered'
}

export interface OrderHistoryEntry {
  field: string;
  oldValue: string;
  newValue: string;
  date: string;
  user: string;
}

export interface Order {
  id: string;
  invoiceCode: string;
  clientName: string;
  date: string;
  time: string;
  deliveryMethod: DeliveryMethod;
  paymentMethod: PaymentMethod;
  totalAmount: number;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  billedBy: string;
  weight?: string | null;
  recipient?: string | null;
  address?: string | null;
  phone?: string | null;
  paymentProof?: string | null;
  deliveryProof?: string | null;
  amountCollected?: number | null;
  deliveryDate?: string | null;
  deliveredBy?: string | null;
  notes?: string;
  history: OrderHistoryEntry[];
}

// Mock data for demonstration
export const mockOrders: Order[] = [
  {
    id: '1',
    invoiceCode: 'FAC-001',
    clientName: 'Juan Pérez',
    date: '2025-05-15',
    time: '10:30:00',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    totalAmount: 75000,
    status: OrderStatus.PENDING_WALLET,
    paymentStatus: PaymentStatus.PENDIENTE,
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
    deliveryMethod: DeliveryMethod.RECOGIDA_TIENDA,
    paymentMethod: PaymentMethod.TRANSFERENCIA,
    totalAmount: 120000,
    status: OrderStatus.PENDING_WALLET,
    paymentStatus: PaymentStatus.PENDIENTE,
    billedBy: 'Depto. Facturación',
    notes: 'Cliente frecuente',
    history: []
  },
  {
    id: '3',
    invoiceCode: 'FAC-003',
    clientName: 'Carlos Rodríguez',
    date: '2025-05-15',
    time: '12:00:00',
    deliveryMethod: DeliveryMethod.ENVIO_NACIONAL,
    paymentMethod: PaymentMethod.TARJETA_CREDITO,
    totalAmount: 250000,
    status: OrderStatus.PENDING_LOGISTICS,
    paymentStatus: PaymentStatus.PAGADO,
    billedBy: 'Depto. Facturación',
    paymentProof: 'proof.jpg',
    notes: 'Enviar a Medellín',
    history: [
      {
        field: 'Estado',
        oldValue: 'Pendiente Cartera',
        newValue: 'Pendiente Logística',
        date: '2025-05-15T12:30:00',
        user: 'Depto. Cartera'
      }
    ]
  },
  {
    id: '4',
    invoiceCode: 'FAC-004',
    clientName: 'Ana Martínez',
    date: '2025-05-15',
    time: '09:30:00',
    deliveryMethod: DeliveryMethod.DOMICILIO,
    paymentMethod: PaymentMethod.EFECTIVO,
    totalAmount: 85000,
    status: OrderStatus.PENDING,
    paymentStatus: PaymentStatus.PENDIENTE,
    billedBy: 'Depto. Facturación',
    weight: '750',
    recipient: 'Duban Pineda',
    address: 'Calle 123 #45-67, Apto 301',
    phone: '3101234567',
    notes: 'Llamar antes de llegar',
    history: [
      {
        field: 'Estado',
        oldValue: 'Pendiente Cartera',
        newValue: 'Pendiente Logística',
        date: '2025-05-15T10:00:00',
        user: 'Depto. Cartera'
      },
      {
        field: 'Estado',
        oldValue: 'Pendiente Logística',
        newValue: 'Pendiente Entrega',
        date: '2025-05-15T10:30:00',
        user: 'Depto. Logística'
      }
    ]
  },
  {
    id: '5',
    invoiceCode: 'FAC-005',
    clientName: 'Roberto Gómez',
    date: '2025-05-15',
    time: '10:15:00',
    deliveryMethod: DeliveryMethod.RECOGIDA_TIENDA,
    paymentMethod: PaymentMethod.TRANSFERENCIA,
    totalAmount: 150000,
    status: OrderStatus.DELIVERED,
    paymentStatus: PaymentStatus.PAGADO,
    billedBy: 'Depto. Facturación',
    weight: '1200',
    paymentProof: 'proof.jpg',
    deliveryProof: 'delivery.jpg',
    deliveryDate: '2025-05-15',
    deliveredBy: 'Depto. Logística',
    notes: 'Cliente frecuente',
    history: [
      {
        field: 'Estado',
        oldValue: 'Pendiente Cartera',
        newValue: 'Pendiente Logística',
        date: '2025-05-15T10:30:00',
        user: 'Depto. Cartera'
      },
      {
        field: 'Estado',
        oldValue: 'Pendiente Logística',
        newValue: 'Pendiente Entrega en Tienda',
        date: '2025-05-15T11:00:00',
        user: 'Depto. Logística'
      },
      {
        field: 'Estado',
        oldValue: 'Pendiente Entrega en Tienda',
        newValue: 'Entregado',
        date: '2025-05-15T12:00:00',
        user: 'Depto. Logística'
      }
    ]
  }
];
