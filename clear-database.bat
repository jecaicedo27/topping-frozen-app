@echo off
echo ========================================
echo    LIMPIAR BASE DE DATOS COMPLETA
echo ========================================
echo.
echo Este script eliminara TODOS los pedidos de la base de datos.
echo.
set /p confirm="¿Estas seguro? (S/N): "
if /i "%confirm%"=="S" (
    echo.
    echo Ejecutando limpieza...
    node clear-database.js
    echo.
    echo Presiona cualquier tecla para continuar...
    pause >nul
) else (
    echo.
    echo Operacion cancelada.
    echo.
    pause
)
