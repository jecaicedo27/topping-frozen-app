@echo off
echo ========================================
echo    INICIANDO APLICACION EMPRESARIAL
echo ========================================
echo.

REM Verificar que existe la configuracion
if not exist ".env" (
    echo ERROR: Archivo .env no encontrado.
    echo Por favor ejecuta 'install-company.bat' primero.
    pause
    exit /b 1
)

if not exist "backend\.env" (
    echo ERROR: Archivo backend\.env no encontrado.
    echo Por favor ejecuta 'install-company.bat' primero.
    pause
    exit /b 1
)

REM Leer configuracion basica del archivo .env
for /f "tokens=2 delims==" %%a in ('findstr "COMPANY_NAME" .env') do set COMPANY_NAME=%%a
for /f "tokens=2 delims==" %%a in ('findstr "APP_TITLE" .env') do set APP_TITLE=%%a
for /f "tokens=2 delims==" %%a in ('findstr "COMPANY_DOMAIN" .env') do set COMPANY_DOMAIN=%%a
for /f "tokens=2 delims==" %%a in ('findstr "PORT" backend\.env') do set PORT=%%a

if "%COMPANY_NAME%"=="" set COMPANY_NAME=Empresa
if "%APP_TITLE%"=="" set APP_TITLE=Sistema de Pedidos
if "%COMPANY_DOMAIN%"=="" set COMPANY_DOMAIN=localhost
if "%PORT%"=="" set PORT=5000

echo Iniciando %COMPANY_NAME% - %APP_TITLE%
echo Dominio: %COMPANY_DOMAIN%
echo Puerto: %PORT%
echo.

REM Verificar Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js no esta instalado.
    pause
    exit /b 1
)

REM Instalar dependencias si es necesario
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

REM Construir la aplicacion
echo Construyendo la aplicacion...
npm run build
if %errorlevel% neq 0 (
    echo ERROR: Fallo la construccion de la aplicacion.
    echo Intentando continuar...
)

REM Inicializar base de datos
echo Inicializando base de datos...
cd backend
npm run init-db
if %errorlevel% neq 0 (
    echo ADVERTENCIA: Fallo la inicializacion de la base de datos.
    echo Verifica que MySQL este ejecutandose y la configuracion sea correcta.
    echo Presiona cualquier tecla para continuar o Ctrl+C para cancelar...
    pause >nul
)
cd ..

echo.
echo ========================================
echo    INICIANDO SERVIDOR
echo ========================================
echo.
echo Servidor iniciandose en puerto %PORT%
echo Accede a: http://%COMPANY_DOMAIN%:%PORT%
echo.
echo Presiona Ctrl+C para detener el servidor
echo.

REM Iniciar el servidor
cd backend
npm start

REM Si llegamos aqui, el servidor se detuvo
echo.
echo Servidor detenido.
pause
