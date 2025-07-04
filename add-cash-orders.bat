@echo off
echo ========================================
echo    AGREGAR PEDIDOS DE PRUEBA EN EFECTIVO
echo ========================================
echo.
echo Este script agregara pedidos entregados en efectivo para probar
echo el sistema de control de dinero factura por factura.
echo.
echo Datos que se agregaran:
echo - Usuario Mensajero: $40,000 (2 entregas)
echo - Pedro Mensajero: $30,500 (2 entregas)
echo - Total: $70,500 (4 entregas)
echo.
set /p confirm="¿Continuar? (S/N): "
if /i "%confirm%"=="S" (
    echo.
    echo Ejecutando script...
    node add-cash-orders.js
    echo.
    echo Presiona cualquier tecla para continuar...
    pause >nul
) else (
    echo.
    echo Operacion cancelada.
    echo.
    pause
)
