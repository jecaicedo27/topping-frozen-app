# Topping Frozen Backend API

Backend API for the Topping Frozen Order Management System.

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Configure environment variables:
   - Copy `.env.example` to `.env` (if not already done)
   - Update the database connection details in `.env`

3. Initialize the database:
   ```
   npm run init-db
   ```

4. Start the development server:
   ```
   npm run dev
   ```

## API Endpoints

### Authentication

- `POST /api/auth/login` - Login with username and password
- `GET /api/auth/me` - Get current user (requires authentication)
- `POST /api/auth/register` - Register a new user (admin only)

### Users

- `GET /api/users` - Get all users (admin only)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user (admin only)
- `POST /api/users/:id/change-password` - Change user password

### Orders

- `GET /api/orders` - Get all orders
- `GET /api/orders/statistics` - Get order statistics
- `GET /api/orders/status/:status` - Get orders by status
- `GET /api/orders/:id` - Get order by ID
- `POST /api/orders` - Create a new order
- `PUT /api/orders/:id` - Update order
- `DELETE /api/orders/:id` - Delete order (admin only)

## Default Users

The system comes with the following default users (all with password: `123456`):

- `admin` - Administrator
- `facturacion` - Facturación
- `cartera` - Cartera
- `logistica` - Logística
- `mensajero` - Mensajero
- `regular` - Regular user

## Database Schema

The database consists of the following tables:

- `users` - User accounts
- `orders` - Order information
- `order_history` - History of changes to orders

See `src/config/database.sql` for the complete schema.
