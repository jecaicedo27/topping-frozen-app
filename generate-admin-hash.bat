@echo off
echo Generando hash para contraseña admin123...
cd backend
npx ts-node src/scripts/generate-password-hash.ts admin123
pause
