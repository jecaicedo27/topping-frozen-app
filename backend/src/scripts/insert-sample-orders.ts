import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Database connection configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'topping_frozen_db',
  port: parseInt(process.env.DB_PORT || '3306')
};

// Define the type for sample orders
interface SampleOrder {
  invoice_code: string;
  client_name: string;
  date: string;
  time: string;
  delivery_method: string;
  payment_method: string;
  total_amount: number;
  status: string;
  payment_status: string;
  billed_by: string;
  weight?: string;
  recipient?: string;
  address?: string;
  phone?: string;
  payment_proof?: string;
  delivery_proof?: string;
  amount_collected?: number;
  delivery_date?: string;
  delivered_by?: string;
  notes?: string;
}

// Sample orders
const sampleOrders: SampleOrder[] = [
  {
    invoice_code: 'FAC-001',
    client_name: 'Juan Pérez',
    date: '2025-05-15',
    time: '10:30:00',
    delivery_method: 'Domicilio',
    payment_method: 'Efectivo',
    total_amount: 75000,
    status: 'pending_wallet',
    payment_status: 'Pendiente por cobrar',
    billed_by: 'Usuario Facturación',
    address: 'Calle 123 #45-67, Apto 301',
    phone: '3101234567',
    notes: 'Entregar en la dirección principal'
  },
  {
    invoice_code: 'FAC-002',
    client_name: 'María López',
    date: '2025-05-15',
    time: '11:15:00',
    delivery_method: 'Recogida en tienda',
    payment_method: 'Transferencia bancaria',
    total_amount: 120000,
    status: 'pending_wallet',
    payment_status: 'Pendiente por cobrar',
    billed_by: 'Usuario Facturación',
    notes: 'Cliente frecuente'
  },
  {
    invoice_code: 'FAC-003',
    client_name: 'Carlos Rodríguez',
    date: '2025-05-15',
    time: '12:00:00',
    delivery_method: 'Envío nacional',
    payment_method: 'Tarjeta de crédito',
    total_amount: 250000,
    status: 'pending_logistics',
    payment_status: 'Pagado',
    billed_by: 'Usuario Facturación',
    payment_proof: 'proof.jpg',
    notes: 'Enviar a Medellín'
  },
  {
    invoice_code: 'FAC-004',
    client_name: 'Ana Martínez',
    date: '2025-05-15',
    time: '09:30:00',
    delivery_method: 'Domicilio',
    payment_method: 'Efectivo',
    total_amount: 85000,
    status: 'pending',
    payment_status: 'Pendiente por cobrar',
    billed_by: 'Usuario Facturación',
    weight: '750',
    recipient: 'Duban Pineda',
    address: 'Calle 123 #45-67, Apto 301',
    phone: '3101234567',
    notes: 'Llamar antes de llegar'
  },
  {
    invoice_code: 'FAC-005',
    client_name: 'Roberto Gómez',
    date: '2025-05-15',
    time: '10:15:00',
    delivery_method: 'Recogida en tienda',
    payment_method: 'Transferencia bancaria',
    total_amount: 150000,
    status: 'delivered',
    payment_status: 'Pagado',
    billed_by: 'Usuario Facturación',
    weight: '1200',
    payment_proof: 'proof.jpg',
    delivery_proof: 'delivery.jpg',
    delivery_date: '2025-05-15',
    delivered_by: 'Usuario Mensajero',
    amount_collected: 150000,
    notes: 'Cliente frecuente'
  }
];

// Insert sample orders
const insertSampleOrders = async (): Promise<void> => {
  let connection;
  
  try {
    // Create connection
    connection = await mysql.createConnection(dbConfig);
    console.log('Connected to MySQL server');
    
    // Insert sample orders
    console.log('Inserting sample orders...');
    
    for (const order of sampleOrders) {
      try {
        // Check if order already exists
        const [existingOrders] = await connection.query(
          'SELECT * FROM orders WHERE invoice_code = ?',
          [order.invoice_code]
        );
        
        if ((existingOrders as any[]).length > 0) {
          console.log(`Order with invoice code ${order.invoice_code} already exists, skipping...`);
          continue;
        }
        
        // Insert order
        const [result] = await connection.query(
          `INSERT INTO orders (
            invoice_code, client_name, date, time, delivery_method, payment_method,
            total_amount, status, payment_status, billed_by, weight, recipient,
            address, phone, payment_proof, delivery_proof, amount_collected,
            delivery_date, delivered_by, notes
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            order.invoice_code, order.client_name, order.date, order.time,
            order.delivery_method, order.payment_method, order.total_amount,
            order.status, order.payment_status, order.billed_by, order.weight || null,
            order.recipient || null, order.address || null, order.phone || null,
            order.payment_proof || null, order.delivery_proof || null,
            order.amount_collected || null, order.delivery_date || null,
            order.delivered_by || null, order.notes || null
          ]
        );
        
        console.log(`Order ${order.invoice_code} inserted successfully`);
        
        // Insert order history if needed
        if (order.status === 'pending_logistics') {
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Cartera', 'Pendiente Logística', new Date(), 'Usuario Cartera']
          );
        } else if (order.status === 'pending') {
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Cartera', 'Pendiente Logística', new Date(), 'Usuario Cartera']
          );
          
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Logística', 'Pendiente Entrega', new Date(), 'Usuario Logística']
          );
        } else if (order.status === 'delivered') {
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Cartera', 'Pendiente Logística', new Date(), 'Usuario Cartera']
          );
          
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Logística', 'Pendiente Entrega', new Date(), 'Usuario Logística']
          );
          
          await connection.query(
            'INSERT INTO order_history (order_id, field, old_value, new_value, date, user) VALUES (?, ?, ?, ?, ?, ?)',
            [(result as any).insertId, 'Estado', 'Pendiente Entrega', 'Entregado', new Date(), 'Usuario Mensajero']
          );
        }
      } catch (error) {
        console.error(`Error inserting order ${order.invoice_code}:`, error);
      }
    }
    
    console.log('Sample orders inserted successfully');
    
  } catch (error) {
    console.error('Error inserting sample orders:', error);
    throw error;
  } finally {
    if (connection) {
      await connection.end();
      console.log('Database connection closed');
    }
  }
};

// Run if this file is executed directly
if (require.main === module) {
  insertSampleOrders()
    .then(() => {
      console.log('Sample orders insertion completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Sample orders insertion failed:', error);
      process.exit(1);
    });
}

export default insertSampleOrders;
