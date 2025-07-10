const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

// Configuración por defecto para MySQL local
const defaultConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  port: 3306,
  database: 'gestionPedidos'
};

async function setupLocalMySQL() {
  console.log('🔧 Configurando conexión a MySQL local...');
  
  try {
    // Intentar conectar sin especificar base de datos
    const connection = await mysql.createConnection({
      host: defaultConfig.host,
      user: defaultConfig.user,
      password: defaultConfig.password,
      port: defaultConfig.port
    });
    
    console.log('✅ Conexión a MySQL establecida correctamente');
    
    // Crear base de datos si no existe
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${defaultConfig.database}`);
    console.log(`✅ Base de datos '${defaultConfig.database}' creada/verificada`);
    
    // Cerrar conexión
    await connection.end();
    
    // Verificar archivos .env
    const envFiles = ['.env', 'backend/.env'];
    
    for (const envFile of envFiles) {
      if (fs.existsSync(envFile)) {
        console.log(`✅ Archivo ${envFile} configurado correctamente`);
      } else {
        console.log(`⚠️  Archivo ${envFile} no encontrado`);
      }
    }
    
    console.log('\n🎉 Configuración completada exitosamente!');
    console.log('\n📋 Configuración actual:');
    console.log(`   Host: ${defaultConfig.host}`);
    console.log(`   Usuario: ${defaultConfig.user}`);
    console.log(`   Puerto: ${defaultConfig.port}`);
    console.log(`   Base de datos: ${defaultConfig.database}`);
    console.log(`   Contraseña: ${defaultConfig.password ? '[CONFIGURADA]' : '[VACÍA]'}`);
    
    console.log('\n🚀 Para iniciar la aplicación:');
    console.log('   1. npm run dev (en el directorio backend)');
    console.log('   2. npm start (en el directorio raíz para el frontend)');
    
  } catch (error) {
    console.error('❌ Error al configurar MySQL:', error.message);
    console.log('\n🔍 Posibles soluciones:');
    console.log('   1. Verificar que MySQL esté instalado y ejecutándose');
    console.log('   2. Verificar usuario y contraseña de MySQL');
    console.log('   3. Verificar que el puerto 3306 esté disponible');
    console.log('   4. Ejecutar: mysql -u root -p (para probar conexión manual)');
  }
}

// Ejecutar configuración
setupLocalMySQL();
