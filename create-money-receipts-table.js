// Script para crear la tabla de historial de recepciones de dinero
const mysql = require('mysql2/promise');
const fs = require('fs');

async function createMoneyReceiptsTable() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'topping_frozen_db'
  });

  try {
    console.log('Creando tabla de historial de recepciones de dinero...');
    
    // Crear tabla money_receipts
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS money_receipts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        messenger_name VARCHAR(100) NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL,
        invoice_codes TEXT NOT NULL,
        receipt_photo VARCHAR(255) NULL,
        received_by VARCHAR(100) NOT NULL,
        received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        notes TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ Tabla money_receipts creada exitosamente');
    
    // Verificar si las columnas ya existen antes de agregarlas
    const [columns] = await connection.execute(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = 'topping_frozen_db' 
      AND TABLE_NAME = 'orders'
      AND COLUMN_NAME IN ('money_received_at', 'money_received_by', 'receipt_id')
    `);
    
    const existingColumns = columns.map(col => col.COLUMN_NAME);
    
    if (!existingColumns.includes('money_received_at')) {
      await connection.execute(`
        ALTER TABLE orders 
        ADD COLUMN money_received_at TIMESTAMP NULL
      `);
      console.log('✅ Columna money_received_at agregada a orders');
    }
    
    if (!existingColumns.includes('money_received_by')) {
      await connection.execute(`
        ALTER TABLE orders 
        ADD COLUMN money_received_by VARCHAR(100) NULL
      `);
      console.log('✅ Columna money_received_by agregada a orders');
    }
    
    if (!existingColumns.includes('receipt_id')) {
      await connection.execute(`
        ALTER TABLE orders 
        ADD COLUMN receipt_id INT NULL
      `);
      console.log('✅ Columna receipt_id agregada a orders');
    }
    
    console.log('');
    console.log('✅ Tabla de historial de recepciones creada exitosamente!');
    console.log('');
    console.log('Estructura creada:');
    console.log('- money_receipts: Tabla principal para historial');
    console.log('- orders: Columnas adicionales para tracking');
    console.log('');
    console.log('Ahora puedes usar el sistema de historial de recepciones con fotos.');
    
  } catch (error) {
    console.error('❌ Error al crear tabla:', error);
  } finally {
    await connection.end();
  }
}

createMoneyReceiptsTable();
