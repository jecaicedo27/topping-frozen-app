-- Tabla para historial de recepciones de dinero
CREATE TABLE IF NOT EXISTS money_receipts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  messenger_name VARCHAR(100) NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  invoice_codes TEXT NOT NULL, -- JSON array de códigos de factura
  receipt_photo VARCHAR(255) NULL, -- Ruta de la foto de recepción
  received_by VARCHAR(100) NOT NULL, -- Usuario que recibió el dinero
  received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agregar campos a la tabla orders para tracking de recepciones
ALTER TABLE orders 
ADD COLUMN money_received_at TIMESTAMP NULL,
ADD COLUMN money_received_by VARCHAR(100) NULL,
ADD COLUMN receipt_id INT NULL,
ADD FOREIGN KEY (receipt_id) REFERENCES money_receipts(id);
