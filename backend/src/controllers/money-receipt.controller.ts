import { Request, Response } from 'express';
import { MoneyReceiptModel, MoneyReceipt } from '../models/money-receipt.model';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/receipts';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'receipt-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Solo se permiten archivos de imagen (JPEG, PNG, GIF) o PDF'));
    }
  }
});

export class MoneyReceiptController {
  // Middleware for file upload
  static uploadMiddleware = upload.single('receipt_photo');

  // Create a new money receipt
  static async createReceipt(req: Request, res: Response): Promise<void> {
    try {
      console.log('Creating money receipt...');
      console.log('Request body:', req.body);
      console.log('Request file:', req.file);
      
      const { messenger_name, total_amount, invoice_codes, notes } = req.body;
      const username = (req as any).user?.username || 'system';
      
      console.log('Extracted data:', { messenger_name, total_amount, invoice_codes, notes, username });
      
      // Validate required fields
      if (!messenger_name || !total_amount || !invoice_codes) {
        console.log('Validation failed: missing required fields');
        res.status(400).json({
          success: false,
          message: 'messenger_name, total_amount, and invoice_codes are required',
          received: { messenger_name, total_amount, invoice_codes }
        });
        return;
      }
      
      // Validate invoice_codes is valid JSON
      try {
        JSON.parse(invoice_codes);
        console.log('Invoice codes JSON is valid');
      } catch (error) {
        console.log('Invoice codes JSON validation failed:', error);
        res.status(400).json({
          success: false,
          message: 'invoice_codes must be a valid JSON string',
          received: invoice_codes
        });
        return;
      }
      
      const receiptData: MoneyReceipt = {
        messenger_name,
        total_amount: parseFloat(total_amount),
        invoice_codes,
        receipt_photo: req.file ? req.file.filename : undefined,
        received_by: username,
        notes
      };
      
      console.log('Creating receipt with data:', receiptData);
      
      const receiptId = await MoneyReceiptModel.create(receiptData);
      console.log('Receipt created with ID:', receiptId);
      
      const receipt = await MoneyReceiptModel.findById(receiptId);
      console.log('Retrieved receipt:', receipt);
      
      res.status(201).json({
        success: true,
        message: 'Money receipt created successfully',
        data: receipt
      });
    } catch (error) {
      console.error('Error creating money receipt:', error);
      console.error('Error stack:', (error as Error).stack);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: (error as Error).message
      });
    }
  }

  // Get all money receipts
  static async getAllReceipts(req: Request, res: Response): Promise<void> {
    try {
      const receipts = await MoneyReceiptModel.findAll();
      
      res.status(200).json({
        success: true,
        data: receipts
      });
    } catch (error) {
      console.error('Error fetching money receipts:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get today's receipts
  static async getTodayReceipts(req: Request, res: Response): Promise<void> {
    try {
      const receipts = await MoneyReceiptModel.findToday();
      
      res.status(200).json({
        success: true,
        data: receipts
      });
    } catch (error) {
      console.error('Error fetching today receipts:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get receipts by date range
  static async getReceiptsByDateRange(req: Request, res: Response): Promise<void> {
    try {
      const { start_date, end_date } = req.query;
      
      if (!start_date || !end_date) {
        res.status(400).json({
          success: false,
          message: 'start_date and end_date are required'
        });
        return;
      }
      
      const receipts = await MoneyReceiptModel.findByDateRange(
        start_date as string, 
        end_date as string
      );
      
      res.status(200).json({
        success: true,
        data: receipts
      });
    } catch (error) {
      console.error('Error fetching receipts by date range:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get receipts by messenger
  static async getReceiptsByMessenger(req: Request, res: Response): Promise<void> {
    try {
      const { messenger_name } = req.params;
      
      const receipts = await MoneyReceiptModel.findByMessenger(messenger_name);
      
      res.status(200).json({
        success: true,
        data: receipts
      });
    } catch (error) {
      console.error('Error fetching receipts by messenger:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get receipt by ID
  static async getReceiptById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const receipt = await MoneyReceiptModel.findById(parseInt(id));
      
      if (!receipt) {
        res.status(404).json({
          success: false,
          message: 'Receipt not found'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        data: receipt
      });
    } catch (error) {
      console.error('Error fetching receipt by ID:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get receipts statistics
  static async getStatistics(req: Request, res: Response): Promise<void> {
    try {
      const statistics = await MoneyReceiptModel.getStatistics();
      
      res.status(200).json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Error fetching receipts statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Serve receipt photo
  static async getReceiptPhoto(req: Request, res: Response): Promise<void> {
    try {
      const { filename } = req.params;
      const filePath = path.join(__dirname, '../../uploads/receipts', filename);
      
      if (!fs.existsSync(filePath)) {
        res.status(404).json({
          success: false,
          message: 'Photo not found'
        });
        return;
      }
      
      res.sendFile(filePath);
    } catch (error) {
      console.error('Error serving receipt photo:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Delete a receipt
  static async deleteReceipt(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      // Get receipt to delete photo file
      const receipt = await MoneyReceiptModel.findById(parseInt(id));
      
      if (!receipt) {
        res.status(404).json({
          success: false,
          message: 'Receipt not found'
        });
        return;
      }
      
      // Delete from database
      const deleted = await MoneyReceiptModel.delete(parseInt(id));
      
      if (!deleted) {
        res.status(400).json({
          success: false,
          message: 'Failed to delete receipt'
        });
        return;
      }
      
      // Delete photo file if exists
      if (receipt.receipt_photo) {
        const filePath = path.join(__dirname, '../../uploads/receipts', receipt.receipt_photo);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
      
      res.status(200).json({
        success: true,
        message: 'Receipt deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting receipt:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}
