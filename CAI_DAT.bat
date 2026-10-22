@echo off
cd /d "%~dp0SRC"
call npm.cmd install
if errorlevel 1 exit /b %errorlevel%
node backend\tools\setup-environment.js
echo Kiem tra DB_SERVER va DB_NAME trong backend\.env truoc khi chay npm.cmd run db:init.
call npm.cmd run sql:build
call npm.cmd run build
pause
