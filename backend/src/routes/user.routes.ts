import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Admin-only routes
router.get('/', authorize(['admin']), UserController.getAllUsers);
router.post('/', authorize(['admin']), UserController.getAllUsers); // This should be handled by auth/register

// Get user by ID (admin or self)
router.get('/:id', UserController.getUserById);

// Update user (admin or self)
router.put('/:id', UserController.updateUser);

// Delete user (admin only)
router.delete('/:id', authorize(['admin']), UserController.deleteUser);

// Change password (self only)
router.post('/:id/change-password', UserController.changePassword);

export default router;
