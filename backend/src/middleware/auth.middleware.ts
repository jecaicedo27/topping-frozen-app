import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// JWT secret key
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Interface for decoded token
interface DecodedToken {
  id: number;
  username: string;
  role: string;
  iat: number;
  exp: number;
}

// Authentication middleware
export const authenticate = (req: Request, res: Response, next: NextFunction): void => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        message: 'Authentication token is required'
      });
      return;
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET) as DecodedToken;
    
    // Attach user to request
    (req as any).user = {
      id: decoded.id,
      username: decoded.username,
      role: decoded.role
    };
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    
    if ((error as any).name === 'TokenExpiredError') {
      res.status(401).json({
        success: false,
        message: 'Token expired'
      });
      return;
    }
    
    res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
};

// Authorization middleware
export const authorize = (roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const userRole = (req as any).user?.role;
      
      if (!userRole) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }
      
      if (!roles.includes(userRole)) {
        res.status(403).json({
          success: false,
          message: 'Forbidden: Insufficient permissions'
        });
        return;
      }
      
      next();
    } catch (error) {
      console.error('Authorization error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  };
};
