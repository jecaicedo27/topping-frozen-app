// Script para probar la API de money receipts
const fetch = require('node-fetch');

async function testMoneyReceiptAPI() {
  try {
    console.log('Probando API de money receipts...');
    
    // Test 1: Health check
    console.log('\n1. Probando health check...');
    const healthResponse = await fetch('http://localhost:5000/api/health');
    const healthData = await healthResponse.json();
    console.log('Health check:', healthData);
    
    // Test 2: Get today's receipts (sin autenticación primero)
    console.log('\n2. Probando GET today receipts...');
    const todayResponse = await fetch('http://localhost:5000/api/money-receipts/today');
    console.log('Status:', todayResponse.status);
    
    if (todayResponse.status === 401) {
      console.log('Necesita autenticación (esperado)');
    } else {
      const todayData = await todayResponse.text();
      console.log('Response:', todayData);
    }
    
    // Test 3: Crear un recibo simple (sin autenticación para ver el error)
    console.log('\n3. Probando POST money receipt...');
    const testData = {
      messenger_name: 'Test Messenger',
      total_amount: '100.00',
      invoice_codes: JSON.stringify(['TEST-001']),
      notes: 'Test receipt'
    };
    
    const createResponse = await fetch('http://localhost:5000/api/money-receipts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testData)
    });
    
    console.log('Create Status:', createResponse.status);
    const createData = await createResponse.text();
    console.log('Create Response:', createData);
    
  } catch (error) {
    console.error('Error testing API:', error);
  }
}

testMoneyReceiptAPI();
