import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { Order, OrderStatus, OrderHistoryEntry } from '../types/order';
import { PaymentStatus } from '../types/user';
import { useAuth } from './AuthContext';
import { OrderService } from '../services/order.service';

// Helper function to convert snake_case to camelCase
const convertSnakeToCamel = (obj: any): any => {
  if (obj === null || obj === undefined) return obj;
  
  if (Array.isArray(obj)) {
    return obj.map(convertSnakeToCamel);
  }
  
  if (typeof obj === 'object') {
    const converted: any = {};
    for (const [key, value] of Object.entries(obj)) {
      const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
      converted[camelKey] = convertSnakeToCamel(value);
    }
    return converted;
  }
  
  return obj;
};

// Helper function to convert camelCase to snake_case
const convertCamelToSnake = (obj: any): any => {
  if (obj === null || obj === undefined) return obj;
  
  if (Array.isArray(obj)) {
    return obj.map(convertCamelToSnake);
  }
  
  if (typeof obj === 'object') {
    const converted: any = {};
    for (const [key, value] of Object.entries(obj)) {
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      converted[snakeKey] = convertCamelToSnake(value);
    }
    return converted;
  }
  
  return obj;
};

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
  refreshOrders: () => Promise<void>;
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

  // Refresh orders from API
  const refreshOrders = async (): Promise<void> => {
    if (!user) return;

    try {
      console.log('Refreshing orders from API...');
      const response = await OrderService.getAllOrders();
      
      if (response.success && response.data) {
        console.log('Orders refreshed successfully:', response.data);
        const convertedData = convertSnakeToCamel(response.data);
        dispatch({ 
          type: 'SET_ORDERS', 
          payload: Array.isArray(convertedData) ? convertedData : [convertedData] 
        });
      } else {
        console.log('Failed to refresh orders:', response.message);
      }
    } catch (error) {
      console.error('Error refreshing orders:', error);
    }
  };

  // Load orders from API when user is authenticated
  useEffect(() => {
    const loadOrders = async () => {
      // Only load orders if user is authenticated
      if (!user) {
        dispatch({ type: 'SET_ORDERS', payload: [] });
        return;
      }

      try {
        console.log('Loading orders from API...');
        // Fetch orders from API
        const response = await OrderService.getAllOrders();
        
        if (response.success && response.data) {
          console.log('Orders loaded successfully:', response.data);
          // Convert snake_case data from backend to camelCase for frontend
          const convertedData = convertSnakeToCamel(response.data);
          dispatch({ 
            type: 'SET_ORDERS', 
            payload: Array.isArray(convertedData) ? convertedData : [convertedData] 
          });
        } else {
          console.log('Failed to load orders:', response.message);
          // Initialize with empty array if API fails
          dispatch({ type: 'SET_ORDERS', payload: [] });
        }
      } catch (error) {
        console.error('Error loading orders:', error);
        // Initialize with empty array if there's an error
        dispatch({ type: 'SET_ORDERS', payload: [] });
      }
    };

    loadOrders();
  }, [user]); // Depend on user authentication state

  // Set up automatic refresh every 30 seconds to keep data synchronized across sessions
  useEffect(() => {
    if (!user) return;

    const interval = setInterval(() => {
      refreshOrders();
    }, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
  }, [user, refreshOrders]);

  // Refresh data when user returns to the tab/window (visibility change)
  useEffect(() => {
    if (!user) return;

    const handleVisibilityChange = () => {
      if (!document.hidden) {
        // User returned to the tab, refresh data
        refreshOrders();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', refreshOrders);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', refreshOrders);
    };
  }, [user, refreshOrders]);

  // Create a new order
  const createOrder = async (orderData: Omit<Order, 'id' | 'date' | 'time' | 'status' | 'history'>) => {
    if (!user) return;

    const now = new Date();
    const newOrder: Order = {
      id: Date.now().toString(), // This will be replaced by the server
      date: now.toISOString().split('T')[0],
      time: now.toTimeString().split(' ')[0],
      status: OrderStatus.PENDING_WALLET,
      history: [],
      ...orderData,
      billedBy: user.name
    };

    try {
      // Convert camelCase to snake_case for backend API
      const backendOrderData = {
        invoice_code: newOrder.invoiceCode,
        client_name: newOrder.clientName,
        date: newOrder.date,
        time: newOrder.time,
        delivery_method: newOrder.deliveryMethod,
        payment_method: newOrder.paymentMethod,
        total_amount: newOrder.totalAmount,
        status: newOrder.status,
        payment_status: newOrder.paymentStatus,
        billed_by: newOrder.billedBy,
        notes: newOrder.notes || '',
        address: newOrder.address || '',
        phone: newOrder.phone || ''
      };
      
      // Create order via API
      const response = await OrderService.createOrder(backendOrderData);
      
      if (response.success && response.data) {
        // Convert snake_case data from backend to camelCase for frontend
        const convertedData = convertSnakeToCamel(response.data);
        dispatch({ type: 'CREATE_ORDER', payload: convertedData as Order });
        // Refresh all orders to ensure consistency
        await refreshOrders();
      } else {
        // Fallback to local creation if API fails
        dispatch({ type: 'CREATE_ORDER', payload: newOrder });
      }
    } catch (error) {
      console.error('Error creating order:', error);
      // Fallback to local creation
      dispatch({ type: 'CREATE_ORDER', payload: newOrder });
    }
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
  const approvePayment = async (orderId: string, paymentStatus: PaymentStatus, paymentProof: string | null) => {
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

    try {
      // Convert camelCase to snake_case for backend API
      const backendOrderData = {
        status: updatedOrder.status,
        payment_status: updatedOrder.paymentStatus,
        payment_proof: updatedOrder.paymentProof
      };
      
      // Update order via API
      const response = await OrderService.updateOrder(orderId, backendOrderData);
      
      if (response.success && response.data) {
        // Convert snake_case data from backend to camelCase for frontend
        const convertedData = convertSnakeToCamel(response.data);
        dispatch({ type: 'UPDATE_ORDER', payload: convertedData as Order });
      } else {
        // Fallback to local update if API fails
        dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
      }
    } catch (error) {
      console.error('Error updating order:', error);
      // Fallback to local update
      dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
    }
  };

  // Assign order to messenger/service
  const assignOrder = async (orderId: string, weight: string | null, recipient: string | null) => {
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

    try {
      // Convert camelCase to snake_case for backend API
      const backendOrderData = {
        status: updatedOrder.status,
        weight: updatedOrder.weight,
        recipient: updatedOrder.recipient
      };
      
      // Update order via API
      const response = await OrderService.updateOrder(orderId, backendOrderData);
      
      if (response.success && response.data) {
        // Convert snake_case data from backend to camelCase for frontend
        const convertedData = convertSnakeToCamel(response.data);
        dispatch({ type: 'UPDATE_ORDER', payload: convertedData as Order });
      } else {
        // Fallback to local update if API fails
        dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
      }
    } catch (error) {
      console.error('Error updating order:', error);
      // Fallback to local update
      dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
    }
  };

  // Mark order as delivered
  const markAsDelivered = async (orderId: string, amountCollected: number | null, deliveryProof: string | null) => {
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

    try {
      // Convert camelCase to snake_case for backend API
      const backendOrderData = {
        status: updatedOrder.status,
        amount_collected: updatedOrder.amountCollected,
        delivery_proof: updatedOrder.deliveryProof,
        delivery_date: updatedOrder.deliveryDate,
        delivered_by: updatedOrder.deliveredBy
      };
      
      // Update order via API
      const response = await OrderService.updateOrder(orderId, backendOrderData);
      
      if (response.success && response.data) {
        // Convert snake_case data from backend to camelCase for frontend
        const convertedData = convertSnakeToCamel(response.data);
        dispatch({ type: 'UPDATE_ORDER', payload: convertedData as Order });
      } else {
        // Fallback to local update if API fails
        dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
      }
    } catch (error) {
      console.error('Error updating order:', error);
      // Fallback to local update
      dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
    }
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
        getOrderCountByStatus,
        refreshOrders
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
