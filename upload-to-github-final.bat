@echo off
echo ========================================
echo   SUBIENDO CODIGO A GITHUB
echo   Repositorio: topping-frozen-app
echo ========================================
echo.

echo IMPORTANTE: Asegurate de haber creado el repositorio en GitHub primero
echo Ve a: https://github.com/jecaicedo27/topping-frozen-app
echo.
echo Si no existe, sigue las instrucciones en CREAR_REPOSITORIO_GITHUB.md
echo.
pause

echo.
echo 1. Configurando URL del repositorio remoto...
git remote set-url origin https://github.com/jecaicedo27/topping-frozen-app.git

echo.
echo 2. Verificando conexion...
git remote -v

echo.
echo 3. Subiendo codigo a GitHub...
echo Te pedira autenticacion en el navegador...
git push -u origin main

echo.
echo ========================================
echo   CODIGO SUBIDO EXITOSAMENTE!
echo ========================================
echo.
echo Tu proyecto esta disponible en:
echo https://github.com/jecaicedo27/topping-frozen-app
echo.
echo PROXIMOS PASOS PARA DESPLIEGUE:
echo.
echo 1. RAILWAY (Mas facil - $5/mes):
echo    - Ve a https://railway.app
echo    - Login with GitHub
echo    - New Project > Deploy from GitHub repo
echo    - Selecciona: topping-frozen-app
echo    - Deploy automatico!
echo.
echo 2. VERCEL (Gratis):
echo    - Ve a https://vercel.com
echo    - Continue with GitHub
echo    - New Project > Import topping-frozen-app
echo    - Configura variables de entorno
echo    - Deploy
echo.
echo Ver DEPLOYMENT_GUIDE.md para instrucciones completas
echo.
pause
