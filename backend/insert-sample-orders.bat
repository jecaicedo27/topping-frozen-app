@echo off
echo Inserting sample orders into the database...
cd %~dp0
npx ts-node src/scripts/insert-sample-orders.ts
pause
