const mysql = require('mysql2/promise');

async function createAdminUser() {
  let connection;
  
  try {
    // Create connection
    connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'topping_frozen_db'
    });

    console.log('Connected to MySQL database');

    // Check if admin user already exists
    const [existingUsers] = await connection.execute(
      'SELECT * FROM users WHERE username = ?',
      ['admin']
    );

    if (existingUsers.length > 0) {
      console.log('Admin user already exists, updating password...');
      
      // Update existing admin user
      await connection.execute(
        'UPDATE users SET password = ? WHERE username = ?',
        ['$2b$10$pg4mTjSKYjmWgOVdWncMfex2rIl7kjNHz3sfs//N.i7xYFh7G3FbS', 'admin']
      );
      
      console.log('Admin user password updated successfully');
    } else {
      console.log('Creating new admin user...');
      
      // Insert new admin user
      await connection.execute(
        'INSERT INTO users (username, password, role, full_name, email, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
        [
          'admin',
          '$2b$10$pg4mTjSKYjmWgOVdWncMfex2rIl7kjNHz3sfs//N.i7xYFh7G3FbS',
          'admin',
          'Administrador',
          'admin@toppingfrozen.com'
        ]
      );
      
      console.log('Admin user created successfully');
    }

    // Verify the user was created/updated
    const [users] = await connection.execute(
      'SELECT id, username, role FROM users WHERE username = ?',
      ['admin']
    );

    console.log('Admin user details:', users[0]);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('Database connection closed');
    }
  }
}

createAdminUser();
