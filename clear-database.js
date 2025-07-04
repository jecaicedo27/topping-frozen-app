// Script para limpiar completamente la base de datos
const mysql = require('mysql2/promise');

async function clearDatabase() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'topping_frozen_db'
  });

  try {
    console.log('Limpiando base de datos...');
    
    // Eliminar todos los pedidos
    await connection.execute('DELETE FROM orders');
    
    // Reiniciar el auto_increment para que los IDs empiecen desde 1
    await connection.execute('ALTER TABLE orders AUTO_INCREMENT = 1');
    
    console.log('✅ Base de datos limpiada exitosamente!');
    console.log('✅ Todos los pedidos han sido eliminados');
    console.log('✅ Los IDs se reiniciarán desde 1');
    console.log('');
    console.log('La base de datos está ahora completamente vacía y lista para usar.');
    
  } catch (error) {
    console.error('❌ Error al limpiar la base de datos:', error);
  } finally {
    await connection.end();
  }
}

clearDatabase();
