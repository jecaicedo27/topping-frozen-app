@echo off
echo.
echo ===================================================
echo    TOPPING FROZEN ORDER MANAGEMENT SYSTEM
echo ===================================================
echo.
echo Please select an option:
echo.
echo 1. Run full application (frontend + backend with MySQL)
echo 2. Run frontend only (requires MySQL backend)
echo 3. Run backend only (requires MySQL)
echo 4. Run local version (no MySQL required)
echo 5. Open test page (check browser compatibility)
echo 6. Open debug guide
echo 7. Exit
echo.

set /p choice=Enter your choice (1-7): 

if "%choice%"=="1" (
    echo.
    echo Starting full application (frontend + backend)...
    echo.
    npm run dev
    goto end
)

if "%choice%"=="2" (
    echo.
    echo Starting frontend only...
    echo.
    npm start
    goto end
)

if "%choice%"=="3" (
    echo.
    echo Starting backend only...
    echo.
    npm run backend
    goto end
)

if "%choice%"=="4" (
    echo.
    echo Starting local version (no MySQL required)...
    echo.
    start-frontend-local.bat
    goto end
)

if "%choice%"=="5" (
    echo.
    echo Opening test page...
    echo.
    start test.html
    goto end
)

if "%choice%"=="6" (
    echo.
    echo Opening debug guide...
    echo.
    start debug.html
    goto end
)

if "%choice%"=="7" (
    echo.
    echo Exiting...
    goto end
)

echo.
echo Invalid choice. Please try again.
echo.
pause
cls
goto start

:end
echo.
echo Thank you for using Topping Frozen Order Management System!
echo.
