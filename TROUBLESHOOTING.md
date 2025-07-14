# Troubleshooting Guide

This guide provides solutions for common issues you might encounter when running the Topping Frozen Order Management System.

## Blank Login Page

If you see a blank login page when running the application:

### Check Browser Console for Errors

1. Right-click on the blank page and select "Inspect" or press F12
2. Go to the "Console" tab in the developer tools
3. Look for any red error messages

### Common Causes and Solutions

#### 1. Port Conflict

**Symptom:** Error message about port 3000 already being in use

**Solution:**
- Use the alternative webpack configuration:
  ```
  npx webpack serve --config webpack.config.alt.js --mode development
  ```
- Or run the local version:
  ```
  start-frontend-local.bat
  ```

#### 2. Missing Dependencies

**Symptom:** Module not found errors in the console

**Solution:**
- Install dependencies:
  ```
  npm install
  ```
- If specific packages are mentioned in the error, install them:
  ```
  npm install [package-name]
  ```

#### 3. Backend Connection Issues

**Symptom:** Network errors in the console when trying to connect to the backend

**Solution:**
- Make sure the backend server is running:
  ```
  start-backend.bat
  ```
- If MySQL is not installed or configured, use the local version:
  ```
  start-frontend-local.bat
  ```

#### 4. JavaScript Errors

**Symptom:** Syntax errors or other JavaScript errors in the console

**Solution:**
- Check the specific error message for file and line number
- Fix the issue in the mentioned file
- Rebuild the application

## MySQL Connection Issues

If you're having trouble connecting to MySQL:

### Common Causes and Solutions

#### 1. MySQL Not Running

**Solution:**
- Check if MySQL service is running
- Start MySQL service if it's not running

#### 2. Incorrect Credentials

**Solution:**
- Check the credentials in `backend/.env`
- Make sure the username and password are correct

#### 3. Database Not Created

**Solution:**
- Create the database:
  ```sql
  CREATE DATABASE IF NOT EXISTS topping_frozen_db;
  ```
- Run the initialization script:
  ```
  npm run backend:init-db
  ```

## Authentication Issues

If you're having trouble logging in:

### Common Causes and Solutions

#### 1. Using Incorrect Credentials

**Solution:**
- Use one of the default users (all with password: `123456`):
  - `admin`
  - `facturacion`
  - `cartera`
  - `logistica`
  - `mensajero`
  - `regular`

#### 2. Token Issues

**Solution:**
- Clear browser localStorage:
  - Open developer tools (F12)
  - Go to "Application" tab
  - Select "Local Storage" on the left
  - Clear the storage for the site

## Other Common Issues

### 1. Changes Not Reflecting

**Solution:**
- Make sure you're saving the files
- Try restarting the development server
- Clear browser cache (Ctrl+F5 or Cmd+Shift+R)

### 2. Build Errors

**Solution:**
- Check the error message for details
- Make sure all dependencies are installed
- Fix any TypeScript errors mentioned in the output

### 3. Routing Issues

**Solution:**
- Make sure you're using the correct URL
- Check if the route is defined in `App.tsx`
- Verify that the route is accessible for your user role

## Still Having Issues?

If you're still experiencing problems:

1. Try running the local version with `start-frontend-local.bat`
2. Check the browser console for specific error messages
3. Verify that all dependencies are installed correctly
4. Make sure your environment is set up according to the README.md
