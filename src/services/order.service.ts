import api from './api';
import { Order } from '../types/order';

export interface OrderResponse {
  success: boolean;
  message?: string;
  data?: Order | Order[];
}

export interface OrderStatisticsResponse {
  success: boolean;
  message?: string;
  data?: {
    total: number;
    pendingWallet: number;
    pendingLogistics: number;
    pending: number;
    delivered: number;
  };
}

export const OrderService = {
  // Get all orders
  getAllOrders: async (): Promise<OrderResponse> => {
    try {
      const response = await api.get<OrderResponse>('/orders');
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to fetch orders'
      };
    }
  },
  
  // Get orders by status
  getOrdersByStatus: async (status: string): Promise<OrderResponse> => {
    try {
      const response = await api.get<OrderResponse>(`/orders/status/${status}`);
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || `Failed to fetch ${status} orders`
      };
    }
  },
  
  // Get order by ID
  getOrderById: async (id: string): Promise<OrderResponse> => {
    try {
      const response = await api.get<OrderResponse>(`/orders/${id}`);
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to fetch order'
      };
    }
  },
  
  // Create new order
  createOrder: async (orderData: Partial<Order>): Promise<OrderResponse> => {
    try {
      const response = await api.post<OrderResponse>('/orders', orderData);
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to create order'
      };
    }
  },
  
  // Update order
  updateOrder: async (id: string, orderData: Partial<Order>): Promise<OrderResponse> => {
    try {
      const response = await api.put<OrderResponse>(`/orders/${id}`, orderData);
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to update order'
      };
    }
  },
  
  // Delete order
  deleteOrder: async (id: string): Promise<OrderResponse> => {
    try {
      const response = await api.delete<OrderResponse>(`/orders/${id}`);
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to delete order'
      };
    }
  },
  
  // Get order statistics
  getOrderStatistics: async (): Promise<OrderStatisticsResponse> => {
    try {
      const response = await api.get<OrderStatisticsResponse>('/orders/statistics');
      return response.data;
    } catch (error: any) {
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to fetch order statistics'
      };
    }
  }
};
