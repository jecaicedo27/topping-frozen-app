@echo off
echo Generando hash para contraseña 123456...
cd backend
npx ts-node src/scripts/generate-password-hash.ts 123456
pause
