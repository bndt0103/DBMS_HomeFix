@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0SRC"
where node >nul 2>nul
if errorlevel 1 goto missing_node
where npm.cmd >nul 2>nul
if errorlevel 1 goto missing_node
node -e "const [major,minor]=process.versions.node.split('.').map(Number); process.exit(major<22 || (major===22 && minor<12) ? 1 : 0)"
if errorlevel 1 goto old_node
echo HOMEFIX - CÀI ĐẶT
echo Cấu hình mặc định: localhost\SQLEXPRESS, Windows Authentication.
echo Nếu dùng instance khác, cấu hình SRC\backend\.env theo README trước.
echo.
echo [1/3] Cài thư viện...
call npm.cmd ci
if errorlevel 1 goto failed
echo [2/3] Khởi tạo cơ sở dữ liệu...
call npm.cmd run db:init
if errorlevel 1 goto failed
echo [3/3] Build giao diện...
call npm.cmd run build
if errorlevel 1 goto failed
echo Cài đặt thành công. Chạy CHAY_HOMEFIX_DBMS.bat để mở server.
echo Địa chỉ mặc định: http://localhost:3000
pause
exit /b 0
:missing_node
echo Chưa tìm thấy Node.js hoặc npm. Cài Node.js 22.12 trở lên rồi chạy lại.
pause
exit /b 1
:old_node
echo Yêu cầu Node.js 22.12 trở lên. Cập nhật Node.js rồi chạy lại.
pause
exit /b 1
:failed
echo Cài đặt chưa hoàn tất. Xem lỗi phía trên và README.md.
echo Nếu lỗi CSDL, kiểm tra SQL Server đang chạy và cấu hình backend\.env.
pause
exit /b 1
