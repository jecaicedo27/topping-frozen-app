import db from '../config/db';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

export interface MoneyReceipt {
  id?: number;
  messenger_name: string;
  total_amount: number;
  invoice_codes: string; // JSON string
  receipt_photo?: string;
  received_by: string;
  received_at?: Date;
  notes?: string;
  created_at?: Date;
}

export class MoneyReceiptModel {
  // Create a new money receipt
  static async create(receipt: MoneyReceipt): Promise<number> {
    const query = `
      INSERT INTO money_receipts (
        messenger_name, total_amount, invoice_codes, receipt_photo, 
        received_by, notes
      ) VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.execute<ResultSetHeader>(query, [
      receipt.messenger_name,
      receipt.total_amount,
      receipt.invoice_codes,
      receipt.receipt_photo || null,
      receipt.received_by,
      receipt.notes || null
    ]);
    
    return result.insertId;
  }

  // Get all money receipts
  static async findAll(): Promise<MoneyReceipt[]> {
    const query = `
      SELECT * FROM money_receipts 
      ORDER BY received_at DESC
    `;
    
    const [rows] = await db.execute<RowDataPacket[]>(query);
    return rows as MoneyReceipt[];
  }

  // Get money receipts by date range
  static async findByDateRange(startDate: string, endDate: string): Promise<MoneyReceipt[]> {
    const query = `
      SELECT * FROM money_receipts 
      WHERE DATE(received_at) BETWEEN ? AND ?
      ORDER BY received_at DESC
    `;
    
    const [rows] = await db.execute<RowDataPacket[]>(query, [startDate, endDate]);
    return rows as MoneyReceipt[];
  }

  // Get money receipts by messenger
  static async findByMessenger(messengerName: string): Promise<MoneyReceipt[]> {
    const query = `
      SELECT * FROM money_receipts 
      WHERE messenger_name = ?
      ORDER BY received_at DESC
    `;
    
    const [rows] = await db.execute<RowDataPacket[]>(query, [messengerName]);
    return rows as MoneyReceipt[];
  }

  // Get money receipt by ID
  static async findById(id: number): Promise<MoneyReceipt | null> {
    const query = `SELECT * FROM money_receipts WHERE id = ?`;
    
    const [rows] = await db.execute<RowDataPacket[]>(query, [id]);
    
    if (rows.length === 0) {
      return null;
    }
    
    return rows[0] as MoneyReceipt;
  }

  // Get today's receipts
  static async findToday(): Promise<MoneyReceipt[]> {
    const query = `
      SELECT * FROM money_receipts 
      WHERE DATE(received_at) = CURDATE()
      ORDER BY received_at DESC
    `;
    
    const [rows] = await db.execute<RowDataPacket[]>(query);
    return rows as MoneyReceipt[];
  }

  // Get receipts statistics
  static async getStatistics(): Promise<any> {
    const query = `
      SELECT 
        COUNT(*) as total_receipts,
        SUM(total_amount) as total_amount,
        COUNT(DISTINCT messenger_name) as unique_messengers,
        DATE(received_at) as receipt_date
      FROM money_receipts 
      WHERE DATE(received_at) = CURDATE()
      GROUP BY DATE(received_at)
    `;
    
    const [rows] = await db.execute<RowDataPacket[]>(query);
    
    if (rows.length === 0) {
      return {
        total_receipts: 0,
        total_amount: 0,
        unique_messengers: 0,
        receipt_date: new Date().toISOString().split('T')[0]
      };
    }
    
    return rows[0];
  }

  // Delete a money receipt
  static async delete(id: number): Promise<boolean> {
    const query = `DELETE FROM money_receipts WHERE id = ?`;
    
    const [result] = await db.execute<ResultSetHeader>(query, [id]);
    
    return result.affectedRows > 0;
  }
}
