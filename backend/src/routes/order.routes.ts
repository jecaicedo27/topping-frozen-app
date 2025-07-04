import { Router } from 'express';
import { OrderController } from '../controllers/order.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Get order statistics
router.get('/statistics', OrderController.getOrderStatistics);

// Get all orders
router.get('/', OrderController.getAllOrders);

// Get orders by status
router.get('/status/:status', OrderController.getOrdersByStatus);

// Get order by ID
router.get('/:id', OrderController.getOrderById);

// Create new order (facturacion, admin)
router.post('/', authorize(['admin', 'facturacion']), OrderController.createOrder);

// Update order
router.put('/:id', OrderController.updateOrder);

// Delete order (admin only)
router.delete('/:id', authorize(['admin']), OrderController.deleteOrder);

export default router;
