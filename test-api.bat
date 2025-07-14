@echo off
echo Probando API de money receipts...

echo.
echo 1. Health check:
curl -X GET http://localhost:5000/api/health

echo.
echo.
echo 2. Test money receipts endpoint (sin auth):
curl -X GET http://localhost:5000/api/money-receipts/today

echo.
echo.
echo 3. Test POST money receipt (sin auth):
curl -X POST http://localhost:5000/api/money-receipts ^
  -H "Content-Type: application/json" ^
  -d "{\"messenger_name\":\"Test\",\"total_amount\":\"100\",\"invoice_codes\":\"[\\\"TEST-001\\\"]\",\"notes\":\"test\"}"

echo.
echo.
pause
