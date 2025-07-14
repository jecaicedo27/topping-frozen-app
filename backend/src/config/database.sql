-- Create database if not exists
CREATE DATABASE IF NOT EXISTS topping_frozen_db;

-- Use the database
USE topping_frozen_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role ENUM('admin', 'facturacion', 'cartera', 'logistica', 'mensajero', 'regular') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_code VARCHAR(20) NOT NULL UNIQUE,
  client_name VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  delivery_method ENUM('Domicilio', 'Recogida en tienda', 'Envío nacional', 'Envío internacional') NOT NULL,
  payment_method ENUM('Efectivo', 'Transferencia bancaria', 'Tarjeta de crédito', 'Pago electrónico') NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  status ENUM('pending_wallet', 'pending_logistics', 'pending', 'delivered') NOT NULL,
  payment_status ENUM('Pendiente por cobrar', 'Pagado', 'Crédito aprobado') NOT NULL,
  billed_by VARCHAR(100) NOT NULL,
  weight VARCHAR(20) NULL,
  recipient VARCHAR(100) NULL,
  address VARCHAR(255) NULL,
  phone VARCHAR(20) NULL,
  payment_proof VARCHAR(255) NULL,
  delivery_proof VARCHAR(255) NULL,
  amount_collected DECIMAL(10, 2) NULL,
  delivery_date DATE NULL,
  delivered_by VARCHAR(100) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Order history table
CREATE TABLE IF NOT EXISTS order_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  field VARCHAR(50) NOT NULL,
  old_value TEXT NULL,
  new_value TEXT NULL,
  date TIMESTAMP NOT NULL,
  user VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Insert default admin user
INSERT INTO users (username, password, name, role)
VALUES ('admin', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Administrador', 'admin')
ON DUPLICATE KEY UPDATE username = username;

-- Insert other default users
INSERT INTO users (username, password, name, role)
VALUES 
  ('facturacion', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Usuario Facturación', 'facturacion'),
  ('cartera', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Usuario Cartera', 'cartera'),
  ('logistica', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Usuario Logística', 'logistica'),
  ('mensajero', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Usuario Mensajero', 'mensajero'),
  ('regular', '$2b$10$1JlHU4QGmqoEP5yX5bD7UOVnSvQ1jWvmjVfk.qJe5vT9fkRxEjZSa', 'Usuario Regular', 'regular')
ON DUPLICATE KEY UPDATE username = username;

-- Note: The password hash above is for '123456'
