# Topping Frozen Order Management System - Local Version

This document explains how to run the application in local mode, which doesn't require MySQL or the backend server. This is useful for:

1. Testing the frontend without setting up the backend
2. Demonstrating the application's functionality
3. Development when the backend is not available

## How to Run the Local Version

1. Open a command prompt in the project directory
2. Run the following command:

```
start-frontend-local.bat
```

Or manually:

```
npx webpack serve --config webpack.config.local.js --mode development
```

This will start the application on http://localhost:3001

## Features of the Local Version

- Uses localStorage instead of a database for data persistence
- All data is stored in the browser
- No need for MySQL or backend server
- Includes mock users for testing

## Default Users

The system comes with the following default users (all with password: `123456`):

- `admin` - Administrator
- `facturacion` - Facturación
- `cartera` - Cartera
- `logistica` - Logística
- `mensajero` - Mensajero
- `regular` - Regular user

## Limitations

Since this version uses localStorage for data persistence:

1. Data is only stored in the current browser
2. Clearing browser data will delete all orders
3. No synchronization between different browsers or devices
4. Some advanced features may not be available

## Switching to Full Version

When you're ready to use the full version with MySQL and the backend server:

1. Install and configure MySQL as described in the main README.md
2. Run the backend initialization script
3. Start both the frontend and backend servers

```
npm run dev
```

Or start them separately:

```
start-frontend.bat
start-backend.bat
```

## Technical Details

The local version uses modified versions of key files:

- `src/index.local.tsx` - Entry point that uses local components
- `src/App.local.tsx` - Main application component using local providers
- `src/context/AuthContext.local.tsx` - Authentication context using localStorage
- `src/context/OrderContext.local.tsx` - Order management context using localStorage
- `webpack.config.local.js` - Webpack configuration for the local version
