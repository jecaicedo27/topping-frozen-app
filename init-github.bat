@echo off
echo ========================================
echo   INICIALIZANDO REPOSITORIO GITHUB
echo   Topping Frozen Order Management System
echo ========================================
echo.

echo 1. Inicializando Git...
git init

echo.
echo 2. Agregando archivos al repositorio...
git add .

echo.
echo 3. Creando commit inicial...
git commit -m "Initial commit - Topping Frozen Order Management System with photo receipt history"

echo.
echo 4. Configurando rama principal...
git branch -M main

echo.
echo ========================================
echo   CONFIGURACION COMPLETADA
echo ========================================
echo.
echo SIGUIENTE PASO:
echo 1. Crea un repositorio en GitHub.com
echo 2. Copia la URL del repositorio
echo 3. Ejecuta: git remote add origin [URL_DEL_REPOSITORIO]
echo 4. Ejecuta: git push -u origin main
echo.
echo EJEMPLO:
echo git remote add origin https://github.com/TU_USUARIO/topping-frozen-app.git
echo git push -u origin main
echo.
echo ========================================
echo   OPCIONES DE DESPLIEGUE DISPONIBLES:
echo ========================================
echo.
echo 1. VERCEL + PLANETSCALE (Recomendado)
echo    - Frontend: Gratis en Vercel
echo    - Base de datos: Gratis en PlanetScale (5GB)
echo    - Facil de configurar
echo.
echo 2. RAILWAY (Mas simple)
echo    - Todo en uno: ~$5/mes
echo    - MySQL incluido
echo    - Deploy automatico
echo.
echo 3. RENDER + SUPABASE
echo    - Gratis con limitaciones
echo    - PostgreSQL en Supabase
echo.
echo Ver DEPLOYMENT_GUIDE.md para instrucciones detalladas
echo.
pause
