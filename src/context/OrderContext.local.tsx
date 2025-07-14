import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { Order, OrderStatus, OrderHistoryEntry } from '../types/order';
import { PaymentStatus } from '../types/user';
import { useAuth } from './AuthContext.local'; // Using local version

// Define the context type
interface OrderContextType {
  orders: Order[];
  createOrder: (order: Omit<Order, 'id' | 'date' | 'time' | 'status' | 'history'>) => void;
  approvePayment: (orderId: string, paymentStatus: PaymentStatus, paymentProof: string | null) => void;
  assignOrder: (orderId: string, weight: string | null, recipient: string | null) => void;
  markAsDelivered: (orderId: string, amountCollected: number | null, deliveryProof: string | null) => void;
  getOrdersByStatus: (status: OrderStatus) => Order[];
  getOrdersByUser: (username: string) => Order[];
  getOrderById: (id: string) => Order | undefined;
  getOrderCountByStatus: (status: OrderStatus) => number;
}

// Create the context
const OrderContext = createContext<OrderContextType | undefined>(undefined);

// Define action types
type OrderAction =
  | { type: 'SET_ORDERS'; payload: Order[] }
  | { type: 'CREATE_ORDER'; payload: Order }
  | { type: 'UPDATE_ORDER'; payload: Order }
  | { type: 'DELETE_ORDER'; payload: string };

// Reducer function
const orderReducer = (state: Order[], action: OrderAction): Order[] => {
  switch (action.type) {
    case 'SET_ORDERS':
      return action.payload;
    case 'CREATE_ORDER':
      return [...state, action.payload];
    case 'UPDATE_ORDER':
      return state.map(order => 
        order.id === action.payload.id ? action.payload : order
      );
    case 'DELETE_ORDER':
      return state.filter(order => order.id !== action.payload);
    default:
      return state;
  }
};

// Provider component
export const OrderProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [orders, dispatch] = useReducer(orderReducer, []);
  const { authState } = useAuth();
  const { user } = authState;

  // Load orders from localStorage on mount
  useEffect(() => {
    const loadOrders = () => {
      try {
        const savedOrders = localStorage.getItem('orders');
        if (savedOrders) {
          dispatch({ type: 'SET_ORDERS', payload: JSON.parse(savedOrders) });
        } else {
          // Initialize with empty array if no data available
          dispatch({ type: 'SET_ORDERS', payload: [] });
        }
      } catch (error) {
        console.error('Error loading orders:', error);
        dispatch({ type: 'SET_ORDERS', payload: [] });
      }
    };

    loadOrders();
  }, []);

  // Save orders to localStorage whenever they change
  useEffect(() => {
    if (orders.length > 0) {
      localStorage.setItem('orders', JSON.stringify(orders));
    }
  }, [orders]);

  // Create a new order
  const createOrder = (orderData: Omit<Order, 'id' | 'date' | 'time' | 'status' | 'history'>) => {
    if (!user) return;

    const now = new Date();
    const newOrder: Order = {
      id: Date.now().toString(),
      date: now.toISOString().split('T')[0],
      time: now.toTimeString().split(' ')[0],
      status: OrderStatus.PENDING_WALLET,
      history: [],
      ...orderData,
      billedBy: user.name
    };

    dispatch({ type: 'CREATE_ORDER', payload: newOrder });
  };

  // Add an entry to order history
  const addHistoryEntry = (order: Order, field: string, oldValue: string, newValue: string): Order => {
    if (!user) return order;

    const now = new Date();
    const historyEntry: OrderHistoryEntry = {
      field,
      oldValue,
      newValue,
      date: now.toISOString(),
      user: user.name
    };

    return {
      ...order,
      history: [...order.history, historyEntry]
    };
  };

  // Approve payment and move to logistics
  const approvePayment = (orderId: string, paymentStatus: PaymentStatus, paymentProof: string | null) => {
    const order = orders.find(o => o.id === orderId);
    if (!order || !user) return;

    let updatedOrder: Order = {
      ...order,
      status: OrderStatus.PENDING_LOGISTICS,
      paymentStatus,
      paymentProof: paymentProof
    };

    // Add history entry
    updatedOrder = addHistoryEntry(
      updatedOrder,
      'Estado',
      'Pendiente Cartera',
      'Pendiente Logística'
    );

    dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
  };

  // Assign order to messenger/service
  const assignOrder = (orderId: string, weight: string | null, recipient: string | null) => {
    const order = orders.find(o => o.id === orderId);
    if (!order || !user) return;

    let updatedOrder: Order = {
      ...order,
      status: OrderStatus.PENDING,
      weight: weight,
      recipient: recipient
    };

    // Add history entry
    updatedOrder = addHistoryEntry(
      updatedOrder,
      'Estado',
      'Pendiente Logística',
      'Pendiente Entrega'
    );

    dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
  };

  // Mark order as delivered
  const markAsDelivered = (orderId: string, amountCollected: number | null, deliveryProof: string | null) => {
    const order = orders.find(o => o.id === orderId);
    if (!order || !user) return;

    const now = new Date();
    let updatedOrder: Order = {
      ...order,
      status: OrderStatus.DELIVERED,
      amountCollected: amountCollected,
      deliveryProof: deliveryProof,
      deliveryDate: now.toISOString().split('T')[0],
      deliveredBy: user.name
    };

    // Add history entry
    updatedOrder = addHistoryEntry(
      updatedOrder,
      'Estado',
      'Pendiente Entrega',
      'Entregado'
    );

    dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
  };

  // Get orders by status
  const getOrdersByStatus = (status: OrderStatus): Order[] => {
    return orders.filter(order => order.status === status);
  };

  // Get orders by user
  const getOrdersByUser = (username: string): Order[] => {
    return orders.filter(order => order.billedBy === username);
  };

  // Get order by ID
  const getOrderById = (id: string): Order | undefined => {
    return orders.find(order => order.id === id);
  };

  // Get count of orders by status
  const getOrderCountByStatus = (status: OrderStatus): number => {
    return orders.filter(order => order.status === status).length;
  };

  return (
    <OrderContext.Provider
      value={{
        orders,
        createOrder,
        approvePayment,
        assignOrder,
        markAsDelivered,
        getOrdersByStatus,
        getOrdersByUser,
        getOrderById,
        getOrderCountByStatus
      }}
    >
      {children}
    </OrderContext.Provider>
  );
};

// Custom hook to use the order context
export const useOrders = () => {
  const context = useContext(OrderContext);
  if (context === undefined) {
    throw new Error('useOrders must be used within an OrderProvider');
  }
  return context;
};
