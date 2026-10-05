@echo off
setlocal
cd /d "%~dp0SRC"
call npm start
if errorlevel 1 pause
