import { Router } from 'express';
import { MoneyReceiptController } from '../controllers/money-receipt.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Create new money receipt (cartera, admin)
router.post('/', 
  authorize(['admin', 'cartera']), 
  MoneyReceiptController.uploadMiddleware,
  MoneyReceiptController.createReceipt
);

// Get all money receipts
router.get('/', MoneyReceiptController.getAllReceipts);

// Get today's receipts
router.get('/today', MoneyReceiptController.getTodayReceipts);

// Get receipts statistics
router.get('/statistics', MoneyReceiptController.getStatistics);

// Get receipts by date range
router.get('/date-range', MoneyReceiptController.getReceiptsByDateRange);

// Get receipt by ID
router.get('/:id', MoneyReceiptController.getReceiptById);

// Get receipts by messenger
router.get('/messenger/:messenger_name', MoneyReceiptController.getReceiptsByMessenger);

// Serve receipt photo
router.get('/photo/:filename', MoneyReceiptController.getReceiptPhoto);

// Delete receipt (admin only)
router.delete('/:id', authorize(['admin']), MoneyReceiptController.deleteReceipt);

export default router;
