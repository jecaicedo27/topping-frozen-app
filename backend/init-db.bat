@echo off
cd %~dp0
npx ts-node src/scripts/init-db.ts
