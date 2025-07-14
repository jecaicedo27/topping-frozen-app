// Script para agregar pedidos entregados en efectivo para probar el control de dinero
const mysql = require('mysql2/promise');

async function addCashOrders() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'topping_frozen_db'
  });

  try {
    console.log('Agregando pedidos entregados en efectivo...');
    
    // Insertar pedidos de prueba entregados en efectivo
    const orders = [
      {
        invoice_code: 'TF-001',
        client_name: 'Juan Pérez',
        date: '2025-06-20',
        time: '10:00:00',
        delivery_method: 'domicilio',
        payment_method: 'efectivo',
        total_amount: 15000,
        status: 'delivered',
        payment_status: 'pagado',
        billed_by: 'admin',
        delivered_by: 'Usuario Mensajero',
        delivery_date: '2025-06-20',
        amount_collected: 15000
      },
      {
        invoice_code: 'TF-002',
        client_name: 'María García',
        date: '2025-06-20',
        time: '11:30:00',
        delivery_method: 'domicilio',
        payment_method: 'efectivo',
        total_amount: 25000,
        status: 'delivered',
        payment_status: 'pagado',
        billed_by: 'admin',
        delivered_by: 'Usuario Mensajero',
        delivery_date: '2025-06-20',
        amount_collected: 25000
      },
      {
        invoice_code: 'TF-003',
        client_name: 'Carlos López',
        date: '2025-06-20',
        time: '14:15:00',
        delivery_method: 'domicilio',
        payment_method: 'efectivo',
        total_amount: 18500,
        status: 'delivered',
        payment_status: 'pagado',
        billed_by: 'admin',
        delivered_by: 'Pedro Mensajero',
        delivery_date: '2025-06-20',
        amount_collected: 18500
      },
      {
        invoice_code: 'TF-004',
        client_name: 'Ana Rodríguez',
        date: '2025-06-20',
        time: '16:45:00',
        delivery_method: 'domicilio',
        payment_method: 'efectivo',
        total_amount: 12000,
        status: 'delivered',
        payment_status: 'pagado',
        billed_by: 'admin',
        delivered_by: 'Pedro Mensajero',
        delivery_date: '2025-06-20',
        amount_collected: 12000
      }
    ];

    for (const order of orders) {
      await connection.execute(`
        INSERT INTO orders (
          invoice_code, client_name, date, time, delivery_method, payment_method,
          total_amount, status, payment_status, billed_by, delivered_by, 
          delivery_date, amount_collected
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        order.invoice_code, order.client_name, order.date, order.time,
        order.delivery_method, order.payment_method, order.total_amount,
        order.status, order.payment_status, order.billed_by, order.delivered_by,
        order.delivery_date, order.amount_collected
      ]);
      
      console.log(`✅ Pedido ${order.invoice_code} agregado - ${order.client_name} - $${order.total_amount.toLocaleString()}`);
    }
    
    console.log('');
    console.log('✅ Pedidos de prueba agregados exitosamente!');
    console.log('');
    console.log('Resumen:');
    console.log('- Usuario Mensajero: $40,000 (2 entregas)');
    console.log('- Pedro Mensajero: $30,500 (2 entregas)');
    console.log('- Total: $70,500 (4 entregas)');
    console.log('');
    console.log('Ahora puedes probar el control de dinero factura por factura en la página de Cartera.');
    
  } catch (error) {
    console.error('❌ Error al agregar pedidos:', error);
  } finally {
    await connection.end();
  }
}

addCashOrders();
