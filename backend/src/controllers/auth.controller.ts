import { Request, Response } from 'express';
import { UserModel } from '../models/user.model';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// JWT secret key
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

export class AuthController {
  // Login
  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { username, password } = req.body;
      
      // Validate request
      if (!username || !password) {
        res.status(400).json({
          success: false,
          message: 'Username and password are required'
        });
        return;
      }
      
      // Temporary hardcoded users for testing (when database is not available)
      const testUsers = [
        { id: 1, username: 'admin', password: '123456', name: 'Administrador', role: 'admin' },
        { id: 2, username: 'facturacion', password: '123456', name: 'Usuario Facturación', role: 'facturacion' },
        { id: 3, username: 'cartera', password: '123456', name: 'Usuario Cartera', role: 'cartera' },
        { id: 4, username: 'logistica', password: '123456', name: 'Usuario Logística', role: 'logistica' },
        { id: 5, username: 'mensajero', password: '123456', name: 'Usuario Mensajero', role: 'mensajero' }
      ];
      
      let user = null;
      
      try {
        // Try to verify credentials with database first
        user = await UserModel.verifyPassword(username, password);
      } catch (dbError) {
        console.log('Database not available, using test credentials');
        // If database fails, use hardcoded credentials
        user = testUsers.find(u => u.username === username && u.password === password);
      }
      
      if (!user) {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
        return;
      }
      
      // Generate JWT token
      const token = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      // Return user and token (exclude password)
      const { password: _, ...userWithoutPassword } = user;
      
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: userWithoutPassword,
          token
        }
      });
    } catch (error) {
      console.error('Error in login:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get current user
  static async getCurrentUser(req: Request, res: Response): Promise<void> {
    try {
      // User is attached to request by auth middleware
      const userId = (req as any).user?.id;
      
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }
      
      const user = await UserModel.findById(userId);
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        data: user
      });
    } catch (error) {
      console.error('Error getting current user:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Register new user (admin only)
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const { username, password, name, role } = req.body;
      
      // Validate request
      if (!username || !name || !role) {
        res.status(400).json({
          success: false,
          message: 'Username, name, and role are required'
        });
        return;
      }
      
      // Check if user already exists
      const existingUser = await UserModel.findByUsername(username);
      
      if (existingUser) {
        res.status(409).json({
          success: false,
          message: 'Username already exists'
        });
        return;
      }
      
      // Create new user
      const userId = await UserModel.create({
        username,
        password,
        name,
        role
      });
      
      // Get created user
      const user = await UserModel.findById(userId);
      
      res.status(201).json({
        success: true,
        message: 'User created successfully',
        data: user
      });
    } catch (error) {
      console.error('Error registering user:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}
