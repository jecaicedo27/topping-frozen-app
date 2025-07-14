import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.post('/login', AuthController.login);

// Protected routes
router.get('/verify', authenticate, AuthController.verifyToken);
router.get('/me', authenticate, AuthController.getCurrentUser);
router.post('/register', authenticate, authorize(['admin']), AuthController.register);

export default router;
