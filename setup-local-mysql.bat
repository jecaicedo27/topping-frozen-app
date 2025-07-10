@echo off
echo.
echo ========================================
echo   CONFIGURACION MYSQL LOCAL
echo ========================================
echo.

echo Configurando conexion a MySQL local...
node setup-local-mysql.js

echo.
echo Presiona cualquier tecla para continuar...
pause >nul
