@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0SRC"
where node >nul 2>nul
if errorlevel 1 goto missing_node
where npm.cmd >nul 2>nul
if errorlevel 1 goto missing_node
if not exist "node_modules\express\package.json" goto not_installed
if not exist "backend\.env" goto not_installed
if not exist "frontend\dist\index.html" goto not_installed
echo HOMEFIX - KHỞI ĐỘNG
echo Địa chỉ mặc định: http://localhost:3000
echo Nếu đã đổi PORT trong .env, dùng địa chỉ server in bên dưới.
echo Giữ cửa sổ này mở khi sử dụng. Nhấn Ctrl+C để dừng.
call npm.cmd start
if errorlevel 1 goto failed
exit /b 0
:missing_node
echo Chưa tìm thấy Node.js hoặc npm. Xem README.md.
pause
exit /b 1
:not_installed
echo Thiếu thư viện, cấu hình hoặc giao diện đã build. Chạy CAI_DAT.bat trước.
pause
exit /b 1
:failed
echo Không khởi động được HomeFix. Xem lỗi phía trên và README.md.
pause
exit /b 1
