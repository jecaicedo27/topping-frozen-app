import { RowDataPacket, ResultSetHeader } from 'mysql2';
import db from '../config/db';
import bcrypt from 'bcrypt';

export interface User {
  id?: number;
  username: string;
  password?: string;
  name: string;
  role: 'admin' | 'facturacion' | 'cartera' | 'logistica' | 'mensajero' | 'regular';
  created_at?: Date;
  updated_at?: Date;
}

export class UserModel {
  // Get all users
  static async findAll(): Promise<User[]> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT id, username, name, role, created_at, updated_at FROM users'
      );
      return rows as User[];
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  }

  // Get user by ID
  static async findById(id: number): Promise<User | null> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT id, username, name, role, created_at, updated_at FROM users WHERE id = ?',
        [id]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      return rows[0] as User;
    } catch (error) {
      console.error(`Error fetching user with ID ${id}:`, error);
      throw error;
    }
  }

  // Get user by username
  static async findByUsername(username: string): Promise<User | null> {
    try {
      const [rows] = await db.query<RowDataPacket[]>(
        'SELECT * FROM users WHERE username = ?',
        [username]
      );
      
      if (rows.length === 0) {
        return null;
      }
      
      return rows[0] as User;
    } catch (error) {
      console.error(`Error fetching user with username ${username}:`, error);
      throw error;
    }
  }

  // Create new user
  static async create(user: User): Promise<number> {
    try {
      // Hash password
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(user.password || '123456', saltRounds);
      
      const [result] = await db.query<ResultSetHeader>(
        'INSERT INTO users (username, password, name, role) VALUES (?, ?, ?, ?)',
        [user.username, hashedPassword, user.name, user.role]
      );
      
      return result.insertId;
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  // Update user
  static async update(id: number, user: Partial<User>): Promise<boolean> {
    try {
      // If password is provided, hash it
      if (user.password) {
        const saltRounds = 10;
        user.password = await bcrypt.hash(user.password, saltRounds);
      }
      
      // Build update query dynamically based on provided fields
      const fields: string[] = [];
      const values: any[] = [];
      
      Object.entries(user).forEach(([key, value]) => {
        if (value !== undefined && key !== 'id') {
          fields.push(`${key} = ?`);
          values.push(value);
        }
      });
      
      if (fields.length === 0) {
        return false;
      }
      
      values.push(id);
      
      const [result] = await db.query<ResultSetHeader>(
        `UPDATE users SET ${fields.join(', ')} WHERE id = ?`,
        values
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error(`Error updating user with ID ${id}:`, error);
      throw error;
    }
  }

  // Delete user
  static async delete(id: number): Promise<boolean> {
    try {
      const [result] = await db.query<ResultSetHeader>(
        'DELETE FROM users WHERE id = ?',
        [id]
      );
      
      return result.affectedRows > 0;
    } catch (error) {
      console.error(`Error deleting user with ID ${id}:`, error);
      throw error;
    }
  }

  // Verify password
  static async verifyPassword(username: string, password: string): Promise<User | null> {
    try {
      const user = await this.findByUsername(username);
      
      if (!user || !user.password) {
        return null;
      }
      
      const isMatch = await bcrypt.compare(password, user.password);
      
      if (!isMatch) {
        return null;
      }
      
      // Remove password from returned user object
      const { password: _, ...userWithoutPassword } = user;
      return userWithoutPassword as User;
    } catch (error) {
      console.error('Error verifying password:', error);
      throw error;
    }
  }
}
