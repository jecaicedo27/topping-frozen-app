@echo off
echo ========================================
echo    INSTALADOR DE EMPRESA
echo    Sistema de Gestion Empresarial
echo ========================================
echo.

REM Verificar si Node.js esta instalado
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js no esta instalado.
    echo Por favor instala Node.js desde https://nodejs.org/
    pause
    exit /b 1
)

REM Verificar si npm esta disponible
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: npm no esta disponible.
    echo Por favor reinstala Node.js.
    pause
    exit /b 1
)

echo Node.js y npm detectados correctamente.
echo.

REM Instalar dependencias si no existen
if not exist "node_modules" (
    echo Instalando dependencias del frontend...
    npm install
    if %errorlevel% neq 0 (
        echo ERROR: Fallo la instalacion de dependencias del frontend.
        pause
        exit /b 1
    )
)

if not exist "backend\node_modules" (
    echo Instalando dependencias del backend...
    cd backend
    npm install
    cd ..
    if %errorlevel% neq 0 (
        echo ERROR: Fallo la instalacion de dependencias del backend.
        pause
        exit /b 1
    )
)

echo.
echo Dependencias instaladas correctamente.
echo.

REM Ejecutar el instalador interactivo
echo Iniciando configuracion de empresa...
echo.
node install-company.js

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Fallo la configuracion de la empresa.
    pause
    exit /b 1
)

echo.
echo ========================================
echo    INSTALACION COMPLETADA
echo ========================================
echo.
echo La aplicacion ha sido configurada exitosamente.
echo.
echo Proximos pasos:
echo 1. Asegurate de que MySQL este ejecutandose
echo 2. Crea la base de datos si no existe
echo 3. Ejecuta: start-company.bat
echo.
echo Para desarrollo, usa: npm run dev
echo Para produccion, usa: start-company.bat
echo.
pause
