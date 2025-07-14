import fs from 'fs';
import path from 'path';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Database connection configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'toppinguser',
  password: process.env.DB_PASSWORD || 'ToppingPass2024!',
  database: process.env.DB_NAME || 'topping_frozen_db',
  port: parseInt(process.env.DB_PORT || '3306'),
  multipleStatements: true
};

// Initialize database
const initializeDatabase = async (): Promise<void> => {
  let connection;
  
  try {
    // Create connection
    connection = await mysql.createConnection(dbConfig);
    console.log('Connected to MySQL server');
    
    // Read SQL file (use safe version that doesn't drop tables)
    const sqlFilePath = path.join(__dirname, 'database-safe.sql');
    const sqlScript = fs.readFileSync(sqlFilePath, 'utf8');
    
    // Execute SQL script
    console.log('Initializing database...');
    await connection.query(sqlScript);
    console.log('Database initialized successfully');
    
  } catch (error) {
    console.error('Error initializing database:', error);
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
  initializeDatabase()
    .then(() => {
      console.log('Database initialization completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Database initialization failed:', error);
      process.exit(1);
    });
}

export default initializeDatabase;
