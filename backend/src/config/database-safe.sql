-- Safe database initialization (does not drop existing tables)
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS topping_frozen_db;

-- Use the database
USE topping_frozen_db;

-- Users table (only create if not exists)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero') NOT NULL,
  email VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Orders table (only create if not exists)
CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  customer_name VARCHAR(100) NOT NULL,
  customer_phone VARCHAR(20),
  customer_address TEXT,
  items JSON NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending', 'confirmed', 'in_preparation', 'ready', 'delivered', 'cancelled') DEFAULT 'pending',
  payment_status ENUM('pending', 'paid', 'partial', 'refunded') DEFAULT 'pending',
  delivery_date DATE,
  delivery_time TIME,
  notes TEXT,
  created_by INT,
  assigned_to INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (assigned_to) REFERENCES users(id)
);

-- Money receipts table (only create if not exists)
CREATE TABLE IF NOT EXISTS money_receipts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  receipt_number VARCHAR(50) UNIQUE NOT NULL,
  order_id INT,
  amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL,
  reference_number VARCHAR(100),
  description TEXT,
  receipt_image VARCHAR(255),
  status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
  created_by INT,
  verified_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- Insert admin user only if it doesn't exist
INSERT IGNORE INTO users (username, password, full_name, role, email) 
VALUES ('admin', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrador', 'admin', 'admin@toppingfrozen.com');

-- Note: The password hash above is for '123456'
