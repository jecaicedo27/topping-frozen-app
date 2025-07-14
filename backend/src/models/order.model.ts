import { RowDataPacket, ResultSetHeader } from 'mysql2';
import db from '../config/db';

export interface OrderHistory {
  id?: number;
  order_id: number;
  field: string;
  old_value?: string;
  new_value?: string;
  date: Date;
  user: string;
  created_at?: Date;
}

export interface Order {
  id?: number;
  invoice_code: string;
  client_name: string;
  date: string;
  time: string;
  delivery_method: 'Domicilio' | 'Recogida en tienda' | 'Envío nacional' | 'Envío internacional';
  payment_method: 'Efectivo' | 'Transferencia bancaria' | 'Tarjeta de crédito' | 'Pago electrónico';
  total_amount: number;
  status: 'pending_wallet' | 'pending_logistics' | 'pending' | 'delivered';
  payment_status: 'Pendiente por cobrar' | 'Pagado' | 'Crédito aprobado';
  billed_by: string;
  weight?: string;
  recipient?: string;
  address?: string;
  phone?: string;
  payment_proof?: string;
  delivery_proof?: string;
  amount_collected?: number;
  delivery_date?: string;
  delivered_by?: string;
  notes?: string;
  created_at?: Date;
  updated_at?: Date;
  history?: OrderHistory[];
}

export class OrderModel {
  // Get all orders
  static async findAll(): Promise<Order[]> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM orders ORDER BY created_at DESC'
      );
      
      const orders = rows as Order[];
      
      // Get history for each order
      for (const order of orders) {
        if (order.id) {
          order.history = await this.getOrderHistory(order.id);
        }
      }
      
      return orders;
    } catch (error) {
      console.error('Error fetching orders:', error);
      throw error;
    }
  }

  // Get orders by status
  static async findByStatus(status: Order['status']): Promise<Order[]> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM orders WHERE status = ? ORDER BY created_at DESC',
        [status]
      );
      
      const orders = rows as Order[];
      
      // Get history for each order
      for (const order of orders) {
        if (order.id) {
          order.history = await this.getOrderHistory(order.id);
        }
      }
      
      return orders;
    } catch (error) {
      console.error(`Error fetching orders with status ${status}:`, error);
      throw error;
    }
  }

  // Get order by ID
  static async findById(id: number): Promise<Order | null> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM orders WHERE id = ?',
        [id]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      const order = rows[0] as Order;
      
      // Get order history
      if (order.id) {
        order.history = await this.getOrderHistory(order.id);
      }
      
      return order;
    } catch (error) {
      console.error(`Error fetching order with ID ${id}:`, error);
      throw error;
    }
  }

  // Get order by invoice code
  static async findByInvoiceCode(invoiceCode: string): Promise<Order | null> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM orders WHERE invoice_code = ?',
        [invoiceCode]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      const order = rows[0] as Order;
      
      // Get order history
      if (order.id) {
        order.history = await this.getOrderHistory(order.id);
      }
      
      return order;
    } catch (error) {
      console.error(`Error fetching order with invoice code ${invoiceCode}:`, error);
      throw error;
    }
  }

  // Create new order
  static async create(order: Order): Promise<number> {
    try {
      const [result] = await db.query<ResultSetHeader>(
        `INSERT INTO orders (
          invoice_code, client_name, date, time, delivery_method, payment_method,
          total_amount, status, payment_status, billed_by, weight, recipient,
          address, phone, payment_proof, delivery_proof, amount_collected,
          delivery_date, delivered_by, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          order.invoice_code, order.client_name, order.date, order.time,
          order.delivery_method, order.payment_method, order.total_amount,
          order.status, order.payment_status, order.billed_by, order.weight || null,
          order.recipient || null, order.address || null, order.phone || null,
          order.payment_proof || null, order.delivery_proof || null,
          order.amount_collected || null, order.delivery_date || null,
          order.delivered_by || null, order.notes || null
        ]
      );
      
      const orderId = result.insertId;
      
      // Add history entry for order creation
      if (order.history && order.history.length > 0) {
        for (const historyEntry of order.history) {
          await this.addOrderHistory({
            ...historyEntry,
            order_id: orderId
          });
        }
      }
      
      return orderId;
    } catch (error) {
      console.error('Error creating order:', error);
      throw error;
    }
  }

  // Update order
  static async update(id: number, order: Partial<Order>, username: string): Promise<boolean> {
    try {
      // Get current order to track changes
      const currentOrder = await this.findById(id);
      
      if (!currentOrder) {
        return false;
      }
      
      // Build update query dynamically based on provided fields
      const fields: string[] = [];
      const values: any[] = [];
      const historyEntries: OrderHistory[] = [];
      
      Object.entries(order).forEach(([key, value]) => {
        if (value !== undefined && key !== 'id' && key !== 'history') {
          fields.push(`${key} = ?`);
          values.push(value);
          
          // Track changes for history
          const currentValue = (currentOrder as any)[key];
          if (currentValue !== value) {
            historyEntries.push({
              order_id: id,
              field: key,
              old_value: currentValue?.toString() || undefined,
              new_value: value?.toString() || undefined,
              date: new Date(),
              user: username
            });
          }
        }
      });
      
      if (fields.length === 0) {
        return false;
      }
      
      values.push(id);
      
      const [result] = await db.query<ResultSetHeader>(
        `UPDATE orders SET ${fields.join(', ')} WHERE id = ?`,
        values
      );
      
      // Add history entries
      for (const historyEntry of historyEntries) {
        await this.addOrderHistory(historyEntry);
      }
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error(`Error updating order with ID ${id}:`, error);
      throw error;
    }
  }

  // Delete order
  static async delete(id: number): Promise<boolean> {
    try {
      // Delete order history first (cascade should handle this, but just to be safe)
      await db.query('DELETE FROM order_history WHERE order_id = ?', [id]);
      
      // Delete order
      const [result] = await db.query<ResultSetHeader>(
        'DELETE FROM orders WHERE id = ?',
        [id]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error(`Error deleting order with ID ${id}:`, error);
      throw error;
    }
  }

  // Get order history
  static async getOrderHistory(orderId: number): Promise<OrderHistory[]> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM order_history WHERE order_id = ? ORDER BY date ASC',
        [orderId]
      );
      
      return rows as OrderHistory[];
    } catch (error) {
      console.error(`Error fetching history for order with ID ${orderId}:`, error);
      throw error;
    }
  }

  // Add order history entry
  static async addOrderHistory(historyEntry: OrderHistory): Promise<number> {
    try {
      const [result] = await db.query<ResultSetHeader>(
        'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
        [
          historyEntry.order_id,
          historyEntry.field,
          historyEntry.old_value || null,
          historyEntry.new_value || null,
          historyEntry.date,
          historyEntry.user
        ]
      );
      
      return result.insertId;
    } catch (error) {
      console.error('Error adding order history entry:', error);
      throw error;
    }
  }

  // Get order statistics
  static async getStatistics(): Promise<any> {
    try {
      const [totalResult] = await db.query<RowDataPacket[]>('SELECT COUNT(*) as total FROM orders');
      const [pendingWalletResult] = await db.query<RowDataPacket[]>('SELECT COUNT(*) as count FROM orders WHERE status = "pending_wallet"');
      const [pendingLogisticsResult] = await db.query<RowDataPacket[]>('SELECT COUNT(*) as count FROM orders WHERE status = "pending_logistics"');
      const [pendingResult] = await db.query<RowDataPacket[]>('SELECT COUNT(*) as count FROM orders WHERE status = "pending"');
      const [deliveredResult] = await db.query<RowDataPacket[]>('SELECT COUNT(*) as count FROM orders WHERE status = "delivered"');
      
      return {
        total: totalResult[0].total,
        pendingWallet: pendingWalletResult[0].count,
        pendingLogistics: pendingLogisticsResult[0].count,
        pending: pendingResult[0].count,
        delivered: deliveredResult[0].count
      };
    } catch (error) {
      console.error('Error getting order statistics:', error);
      throw error;
    }
  }
}
