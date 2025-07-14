// Script para limpiar y agregar datos de prueba realistas
const mysql = require('mysql2/promise');

async function fixSampleData() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'topping_frozen_db'
  });

  try {
    console.log('Limpiando datos existentes...');
    
    // Limpiar datos existentes
    await connection.execute('DELETE FROM orders');
    
    console.log('Insertando datos de prueba realistas...');
    
    // Insertar datos de prueba más realistas
    const sampleOrders = [
      {
        invoice_code: 'TF-001',
        client_name: 'María González',
        date: '2025-06-20',
        time: '10:30:00',
        delivery_method: 'DOMICILIO',
        payment_method: 'EFECTIVO',
        total_amount: 45000,
        status: 'DELIVERED',
        payment_status: 'PAGADO',
        billed_by: 'Usuario Facturación',
        delivered_by: 'Duban Pineda',
        amount_collected: 45000,
        delivery_date: '2025-06-20',
        address: 'Calle 123 #45-67',
        phone: '3001234567'
      },
      {
        invoice_code: 'TF-002',
        client_name: 'Carlos Rodríguez',
        date: '2025-06-20',
        time: '11:15:00',
        delivery_method: 'DOMICILIO',
        payment_method: 'EFECTIVO',
        total_amount: 32000,
        status: 'DELIVERED',
        payment_status: 'PAGADO',
        billed_by: 'Usuario Facturación',
        delivered_by: 'Duban Pineda',
        amount_collected: 32000,
        delivery_date: '2025-06-20',
        address: 'Carrera 78 #12-34',
        phone: '3009876543'
      },
      {
        invoice_code: 'TF-003',
        client_name: 'Ana Martínez',
        date: '2025-06-20',
        time: '14:20:00',
        delivery_method: 'DOMICILIO',
        payment_method: 'EFECTIVO',
        total_amount: 28500,
        status: 'DELIVERED',
        payment_status: 'PAGADO',
        billed_by: 'Usuario Facturación',
        delivered_by: 'Usuario Mensajero',
        amount_collected: 28500,
        delivery_date: '2025-06-20',
        address: 'Avenida 45 #89-12',
        phone: '3005551234'
      },
      {
        invoice_code: 'TF-004',
        client_name: 'Luis Fernández',
        date: '2025-06-20',
        time: '16:45:00',
        delivery_method: 'DOMICILIO',
        payment_method: 'TRANSFERENCIA',
        total_amount: 67000,
        status: 'DELIVERED',
        payment_status: 'PAGADO',
        billed_by: 'Usuario Facturación',
        delivered_by: 'Usuario Mensajero',
        amount_collected: 0, // No cobró efectivo porque fue transferencia
        delivery_date: '2025-06-20',
        address: 'Calle 56 #23-45',
        phone: '3007778888'
      },
      {
        invoice_code: 'TF-005',
        client_name: 'Patricia López',
        date: '2025-06-20',
        time: '09:30:00',
        delivery_method: 'RECOGIDA_TIENDA',
        payment_method: 'EFECTIVO',
        total_amount: 15000,
        status: 'PENDING_WALLET',
        payment_status: 'PENDIENTE',
        billed_by: 'Usuario Facturación',
        address: 'Tienda Principal',
        phone: '3002223333'
      }
    ];

    for (const order of sampleOrders) {
      await connection.execute(`
        INSERT INTO orders (
          invoice_code, client_name, date, time, delivery_method, payment_method,
          total_amount, status, payment_status, billed_by, delivered_by,
          amount_collected, delivery_date, address, phone, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        order.invoice_code,
        order.client_name,
        order.date,
        order.time,
        order.delivery_method,
        order.payment_method,
        order.total_amount,
        order.status,
        order.payment_status,
        order.billed_by,
        order.delivered_by || null,
        order.amount_collected || null,
        order.delivery_date || null,
        order.address,
        order.phone,
        ''
      ]);
    }

    console.log('Datos de prueba insertados correctamente!');
    console.log('- 3 pedidos entregados en efectivo (para control de dinero)');
    console.log('- 1 pedido entregado por transferencia');
    console.log('- 1 pedido pendiente en cartera');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await connection.end();
  }
}

fixSampleData();
