import { Request, Response } from 'express';
import { UserModel } from '../models/user.model';

export class UserController {
  // Get all users
  static async getAllUsers(req: Request, res: Response): Promise<void> {
    try {
      const users = await UserModel.findAll();
      
      res.status(200).json({
        success: true,
        data: users
      });
    } catch (error) {
      console.error('Error fetching users:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get user by ID
  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      const user = await UserModel.findById(parseInt(id));
      
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
      console.error('Error fetching user by ID:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Update user
  static async updateUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userData = req.body;
      
      // Check if user exists
      const existingUser = await UserModel.findById(parseInt(id));
      
      if (!existingUser) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }
      
      // If username is being updated, check if it already exists
      if (userData.username && userData.username !== existingUser.username) {
        const userWithUsername = await UserModel.findByUsername(userData.username);
        
        if (userWithUsername) {
          res.status(409).json({
            success: false,
            message: 'Username already exists'
          });
          return;
        }
      }
      
      // Update user
      const updated = await UserModel.update(parseInt(id), userData);
      
      if (!updated) {
        res.status(400).json({
          success: false,
          message: 'Failed to update user'
        });
        return;
      }
      
      // Get updated user
      const user = await UserModel.findById(parseInt(id));
      
      res.status(200).json({
        success: true,
        message: 'User updated successfully',
        data: user
      });
    } catch (error) {
      console.error('Error updating user:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Delete user
  static async deleteUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      // Check if user exists
      const existingUser = await UserModel.findById(parseInt(id));
      
      if (!existingUser) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }
      
      // Delete user
      const deleted = await UserModel.delete(parseInt(id));
      
      if (!deleted) {
        res.status(400).json({
          success: false,
          message: 'Failed to delete user'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        message: 'User deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting user:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Change password
  static async changePassword(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { currentPassword, newPassword } = req.body;
      
      // Validate request
      if (!currentPassword || !newPassword) {
        res.status(400).json({
          success: false,
          message: 'Current password and new password are required'
        });
        return;
      }
      
      // Check if user exists
      const user = await UserModel.findById(parseInt(id));
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }
      
      // Verify current password
      const isValid = await UserModel.verifyPassword(user.username, currentPassword);
      
      if (!isValid) {
        res.status(401).json({
          success: false,
          message: 'Current password is incorrect'
        });
        return;
      }
      
      // Update password
      const updated = await UserModel.update(parseInt(id), { password: newPassword });
      
      if (!updated) {
        res.status(400).json({
          success: false,
          message: 'Failed to change password'
        });
        return;
      }
      
      res.status(200).json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error) {
      console.error('Error changing password:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}
