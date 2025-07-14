@echo off
echo ========================================
echo   SUBIENDO PROYECTO A GITHUB
echo   Usuario: jecaicedo27@gmail.com
echo ========================================
echo.

echo ¿Cual es el nombre de tu repositorio en GitHub?
echo Ejemplo: topping-frozen-app
set /p REPO_NAME="Nombre del repositorio: "

echo.
echo ========================================
echo   CONFIGURANDO GIT
echo ========================================
echo.

echo 1. Configurando usuario Git...
git config user.email "jecaicedo27@gmail.com"
git config user.name "jecaicedo27"

echo.
echo 2. Inicializando repositorio Git...
git init

echo.
echo 3. Agregando archivos al repositorio...
git add .

echo.
echo 4. Creando commit inicial...
git commit -m "Initial commit - Topping Frozen Order Management System with photo receipt history"

echo.
echo 5. Configurando rama principal...
git branch -M main

echo.
echo 6. Conectando con repositorio remoto...
git remote add origin https://github.com/jecaicedo27/%REPO_NAME%.git

echo.
echo 7. Subiendo archivos a GitHub...
git push -u origin main

echo.
echo ========================================
echo   PROYECTO SUBIDO EXITOSAMENTE!
echo ========================================
echo.
echo Tu proyecto esta disponible en:
echo https://github.com/jecaicedo27/%REPO_NAME%
echo.
echo PROXIMOS PASOS PARA DESPLIEGUE:
echo.
echo 1. VERCEL (Recomendado - Gratis):
echo    - Ve a https://vercel.com
echo    - Conecta con GitHub
echo    - Importa tu repositorio: %REPO_NAME%
echo    - Configura variables de entorno
echo.
echo 2. RAILWAY (Mas simple - $5/mes):
echo    - Ve a https://railway.app
echo    - Conecta con GitHub
echo    - Selecciona tu repositorio: %REPO_NAME%
echo    - Deploy automatico
echo.
echo 3. RENDER (Gratis con limitaciones):
echo    - Ve a https://render.com
echo    - Conecta con GitHub
echo    - Crea Web Service desde tu repositorio
echo.
echo Ver DEPLOYMENT_GUIDE.md para instrucciones detalladas
echo.
pause
