import { Request, Response } from 'express';
import { OrderModel, Order } from '../models/order.model';

export class OrderController {
  // Get all orders
  static async getAllOrders(req: Request, res: Response): Promise<void> {
    try {
      const orders = await OrderModel.findAll();
      
      res.status(200).json({
        success: true,
        data: orders
      });
    } catch (error) {
      console.error('Error fetching orders:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get orders by status
  static async getOrdersByStatus(req: Request, res: Response): Promise<void> {
    try {
      const { status } = req.params;
      
      // Validate status
      const validStatuses = ['pending_wallet', 'pending_logistics', 'pending', 'delivered'];
      if (!validStatuses.includes(status)) {
        res.status(400).json({
          success: false,
          message: 'Invalid status'
        });
        return;
      }
      
      const orders = await OrderModel.findByStatus(status as Order['status']);
      
      res.status(200).json({
        success: true,
        data: orders
      });
    } catch (error) {
      console.error('Error fetching orders by status:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get order by ID
  static async getOrderById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const order = await OrderModel.findById(parseInt(id));
      
      if (!order) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        data: order
      });
    } catch (error) {
      console.error('Error fetching order by ID:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Create new order
  static async createOrder(req: Request, res: Response): Promise<void> {
    try {
      const orderData = req.body;
      
      // Validate required fields
      const requiredFields = [
        'invoice_code', 'client_name', 'date', 'time', 'delivery_method',
        'payment_method', 'total_amount', 'status', 'payment_status', 'billed_by'
      ];
      
      for (const field of requiredFields) {
        if (!orderData[field]) {
          res.status(400).json({
            success: false,
            message: `${field} is required`
          });
          return;
        }
      }
      
      // Check if invoice code already exists
      const existingOrder = await OrderModel.findByInvoiceCode(orderData.invoice_code);
      
      if (existingOrder) {
        res.status(409).json({
          success: false,
          message: 'Invoice code already exists'
        });
        return;
      }
      
      // Create order
      const orderId = await OrderModel.create(orderData);
      
      // Get created order
      const order = await OrderModel.findById(orderId);
      
      res.status(201).json({
        success: true,
        message: 'Order created successfully',
        data: order
      });
    } catch (error) {
      console.error('Error creating order:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Update order
  static async updateOrder(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const orderData = req.body;
      const username = (req as any).user?.username || 'system';
      
      // Check if order exists
      const existingOrder = await OrderModel.findById(parseInt(id));
      
      if (!existingOrder) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }
      
      // Update order
      const updated = await OrderModel.update(parseInt(id), orderData, username);
      
      if (!updated) {
        res.status(400).json({
          success: false,
          message: 'Failed to update order'
        });
        return;
      }
      
      // Get updated order
      const order = await OrderModel.findById(parseInt(id));
      
      res.status(200).json({
        success: true,
        message: 'Order updated successfully',
        data: order
      });
    } catch (error) {
      console.error('Error updating order:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Delete order
  static async deleteOrder(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      // Check if order exists
      const existingOrder = await OrderModel.findById(parseInt(id));
      
      if (!existingOrder) {
        res.status(404).json({
          success: false,
          message: 'Order not found'
        });
        return;
      }
      
      // Delete order
      const deleted = await OrderModel.delete(parseInt(id));
      
      if (!deleted) {
        res.status(400).json({
          success: false,
          message: 'Failed to delete order'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        message: 'Order deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting order:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get order statistics
  static async getOrderStatistics(req: Request, res: Response): Promise<void> {
    try {
      const statistics = await OrderModel.getStatistics();
      
      res.status(200).json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Error fetching order statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}
