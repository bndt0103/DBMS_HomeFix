@echo off
setlocal
cd /d "%~dp0SRC"
call npm ci
if errorlevel 1 goto failed
call npm run db:init
if errorlevel 1 goto failed
call npm run build
if errorlevel 1 goto failed
echo Cai dat HomeFix - He quan tri co so du lieu hoan tat.
pause
exit /b 0
:failed
echo Cai dat chua thanh cong. Xem loi phia tren va README.md.
pause
exit /b 1
