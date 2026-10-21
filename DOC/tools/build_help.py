"""Build UTF-8 HTML topics and ASCII CHM navigation. Compile HELP/HomeFix.hhp with hhc.exe."""
from pathlib import Path
from html import escape
import shutil, json, unicodedata

root=Path(__file__).resolve().parents[2]
helpdir=root/'HELP'; html=helpdir/'html'; images=html/'images'
images.mkdir(parents=True,exist_ok=True)
src=root/'DOC/evidence/20261016-report/screenshots'
topics=[]
def p(s): return '<p>'+escape(s)+'</p>'
def h(s): return '<h2>'+escape(s)+'</h2>'
def steps(xs): return '<ol>'+''.join('<li>'+escape(s)+'</li>' for s in xs)+'</ol>'
def table(headers,rows):
    return '<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+escape(x)+'</th>' for x in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+escape(str(x))+'</td>' for x in row)+'</tr>' for row in rows)+'</tbody></table></div>'
def shot(name,caption):
    shutil.copy2(src/name,images/name)
    return '<div class="figure"><a href="images/'+name+'"><img src="images/'+name+'" alt="'+escape(caption)+'"></a><p>'+escape(caption)+' — bấm ảnh để xem kích thước gốc.</p></div>'
def topic(file,title,body): topics.append((file,title,body))
def code(s): return '<pre>'+escape(s)+'</pre>'

topic('index','Bắt đầu sử dụng HomeFix',
 p('HomeFix quản lý dịch vụ sửa chữa và bảo trì tại nhà: đặt dịch vụ, báo giá, phân công, sửa chữa, nghiệm thu, thanh toán, đối soát và hỗ trợ. Hướng dẫn này dành cho bản đồ án DBMS330284 của Nhóm 08, cập nhật ngày 16/10/2026.')+
 h('Chọn hướng dẫn phù hợp')+p('Người cài hệ thống bắt đầu ở mục Cài đặt. Người dùng chọn bộ phận của mình trong mục lục bên trái. Mỗi hướng dẫn nêu điều kiện, thao tác và dấu hiệu hoàn tất. Tài liệu dùng dữ liệu demo; số tiền và mã đơn trên máy của bạn có thể khác ảnh.')+
 table(['Vai trò','Công việc chính'],[['Khách hàng','Đặt dịch vụ; duyệt chi phí; nghiệm thu; thanh toán; đánh giá'],['Điều phối viên','Tiếp nhận; lập báo giá; chọn kỹ thuật viên phù hợp'],['Kỹ thuật viên','Nhận việc; cập nhật tiến độ; vật tư; nghiệm thu; ví'],['Kế toán','Xác minh chuyển khoản; đối soát; duyệt nạp/rút ví'],['CSKH','Tiếp nhận hỗ trợ; ghi kết quả; theo dõi chất lượng'],['Quản trị viên','Tài khoản, dịch vụ, cấu hình, hồ sơ KTV, nhật ký'],['Giám đốc','Báo cáo hoạt động; hoa hồng; quyết định chính sách']])+
 h('Cách đọc tài liệu')+p('Kéo mép phân chia để thay đổi độ rộng mục lục; phóng to cửa sổ để đọc theo khung ngang. Nội dung tự giãn theo phần trống của khung đọc. Các trang và ảnh nằm trong tệp CHM, không cần Internet; đường dẫn vào ứng dụng cần máy chủ HomeFix đang chạy.')+
 '<p><a href="caidat.html">Cài đặt hệ thống</a> · <a href="dangnhap.html">Đăng nhập</a> · <a href="quytrinh.html">Quy trình tổng thể</a></p>')

topic('caidat','Cài đặt và khởi động',h('1. Chuẩn bị')+
 table(['Thành phần','Yêu cầu'],[['Windows','Máy x64 có quyền cài phần mềm; khuyến nghị RAM 8 GB trở lên'],['Node.js','Từ 22.12, kèm npm'],['SQL Server','Cài Database Engine; instance mặc định localhost\\SQLEXPRESS'],['ODBC','ODBC Driver 17 for SQL Server x64 khi dùng Windows Authentication'],['Công cụ SQL','SSMS hoặc sqlcmd để kiểm tra và quản trị'],['Trình duyệt','Edge/Chrome; dùng Edge khi chạy bộ kiểm thử tự động']])+
 p('Cài SSMS không đồng nghĩa đã cài Database Engine. Mở services.msc và kiểm tra SQL Server (SQLEXPRESS) đang Running. Kết nối Windows phải có quyền tạo CSDL khi cài lần đầu.')+
 h('2. Cài từ mã nguồn')+steps(['Giải nén hoặc clone repository DBMS_HomeFix. Mở thư mục có CAI_DAT.bat và CHAY_HOMEFIX_DBMS.bat.','Nếu dùng cấu hình mặc định, chạy CAI_DAT.bat và chờ hoàn tất. Script cài thư viện, tạo .env nếu thiếu, sinh khóa JWT, khởi tạo CSDL và build giao diện.','Nếu dùng instance hoặc CSDL riêng, tạo/chỉnh SRC/backend/.env theo .env.example trước bước khởi tạo. Không chia sẻ file chứa khóa và mật khẩu.','Chạy CHAY_HOMEFIX_DBMS.bat. Giữ cửa sổ máy chủ mở trong thời gian dùng.','Mở http://localhost:3000. Kiểm tra đăng nhập và danh mục dịch vụ.'])+
 h('3. Cài thủ công')+p('Chạy terminal tại SRC. Tạo backend/.env theo file mẫu và đặt JWT_SECRET ngẫu nhiên trước khi start.')+code('npm.cmd install\nnpm.cmd run db:init\nnpm.cmd run build\nnpm.cmd start')+
 h('4. Những lần sử dụng sau')+p('Chạy CHAY_HOMEFIX_DBMS.bat; dừng bằng Ctrl+C. Khi sửa frontend, build lại. Khi nâng cấp CSDL đã có dữ liệu, sao lưu trước khi db:init. Không chạy bộ SQL tạo mới để ghi đè CSDL đang sử dụng.')+
 '<p><a href="cauhinh.html">Cấu hình kết nối</a> · <a href="loi.html">Xử lý lỗi</a></p>')

topic('cauhinh','Cấu hình kết nối và kiểm tra sau cài đặt',
 table(['Biến trong SRC/backend/.env','Ý nghĩa / ví dụ'],[['PORT','3000; đổi URL truy cập nếu đổi cổng'],['DB_SERVER','localhost\\SQLEXPRESS hoặc instance thực tế'],['DB_NAME','HomeFix_DBMS_Nhom08 mặc định; máy demo có thể đặt tên riêng'],['DB_AUTH','windows hoặc sql'],['DB_ODBC_DRIVER','ODBC Driver 17 for SQL Server cho Windows Authentication'],['DB_USER / DB_PASSWORD','Chỉ điền khi dùng SQL Authentication'],['JWT_SECRET','Khóa riêng đủ dài; không dùng chuỗi ví dụ'],['CLIENT_ORIGINS','Các origin frontend được chấp nhận, gồm đúng giao thức và cổng']])+
 p('Thông tin kết nối thực tế lấy từ .env. Tên HomeFix_DBMS_Nhom08_TiengViet trong một số ảnh là tên trên máy kiểm thử; không bắt buộc máy khác dùng đúng tên đó.')+
 h('Kiểm tra')+steps(['Mở http://localhost:3000/api/health, kết quả phải có status: ok.','Đăng nhập tài khoản mẫu, mở danh mục dịch vụ và một trang nội bộ đúng vai trò.','Nếu cài mới, báo cáo chưa có đơn/doanh thu có thể rỗng. Tạo nghiệp vụ để kiểm chứng thay vì sửa số liệu trực tiếp.','Email OTP cần cấu hình Gmail hoặc Resend hợp lệ. Dùng tài khoản demo để thử luồng nếu chưa cấu hình email.'])+
 h('Bộ SQL độc lập')+p('CSDL_HomeFix.sql hoặc CSDL_HomeFix_Modules.sql dùng để tạo một CSDL mới, chỉ chọn một bộ. Bật SQLCMD Mode trong SSMS, chọn TenCSDL chưa tồn tại. Với bộ module, đặt ThuMucSQL là đường dẫn tuyệt đối đến SQL. Ứng dụng phải trỏ DB_NAME tới CSDL muốn dùng.') )

topic('dangnhap','Đăng nhập, hồ sơ và mật khẩu',
 steps(['Mở ứng dụng. Nhập Số điện thoại hoặc email và Mật khẩu; chọn Đăng nhập.','Kiểm tra tên vai trò ở đầu màn hình. Nếu sai vai trò, đăng xuất và dùng đúng tài khoản.','Mở Hồ sơ để cập nhật thông tin được phép. Đổi email khôi phục yêu cầu mật khẩu hiện tại.','Khi đổi hoặc khôi phục mật khẩu bằng OTP, nhập đúng mã gửi đến email và dùng trong thời hạn. Mã đã sử dụng không dùng lại được.','Đăng xuất khi kết thúc, đặc biệt trên máy dùng chung.'])+
 table(['Vai trò','Email demo'],[['KH','kh@homefix.local'],['KTV','ktv@homefix.local'],['DPV','dpv@homefix.local'],['CSKH','cskh@homefix.local'],['KT','kt@homefix.local'],['ADMIN','admin@homefix.local'],['GD','gd@homefix.local']])+
 p('Mật khẩu khởi tạo: HomeFix@123. Nếu đã đổi, khởi tạo lại không đặt lại mật khẩu cũ. Các tài khoản này chỉ phục vụ demo cục bộ. Đăng ký công khai không cho người dùng tự cấp vai trò quản trị.')+
 shot('01-login-desktop.png','Màn hình đăng nhập')+
 h('Không nhận được OTP')+p('Kiểm tra đúng email và thư rác; chờ theo hướng dẫn trước khi gửi lại. Nếu có lỗi gửi, báo người quản trị kiểm tra provider. Không dùng mã của lần đăng ký cho thao tác đổi mật khẩu. Sai nhiều lần có thể làm mã bị khóa; không tiếp tục đoán mã.'))

topic('quytrinh','Quy trình dịch vụ và ý nghĩa trạng thái',
 table(['Trạng thái','Người xử lý tiếp theo','Điều kiện chuyển'],[['Chờ tiếp nhận','Điều phối viên','Lập và gửi báo giá sơ bộ'],['Chờ duyệt báo giá','Khách hàng','Đồng ý báo giá'],['Chờ phân công','Điều phối viên','Chọn KTV đủ điều kiện'],['Chờ thợ nhận','Kỹ thuật viên','Chấp nhận lệnh còn hiệu lực'],['Thợ đã nhận','Kỹ thuật viên','Bắt đầu di chuyển'],['Đang di chuyển','Kỹ thuật viên','Xác nhận đã đến nơi'],['Đã đến nơi','Kỹ thuật viên','Bắt đầu xử lý'],['Đang sửa chữa','KTV và KH','Duyệt vật tư nếu có; lập phiếu nghiệm thu'],['Chờ nghiệm thu','Khách hàng','Kiểm tra kết quả và ký xác nhận'],['Hoàn thành','KTV/KT/KH','Thanh toán, đối soát và đánh giá theo điều kiện'],['Đã hủy','Các bên liên quan','Theo dõi phí phát sinh nếu có']])+
 p('Hoàn thành công việc không có nghĩa tiền đã được thu; đã thanh toán cũng không có nghĩa hoa hồng đã đối soát. Luôn đọc riêng trạng thái đơn, thanh toán và đối soát.')+
 h('Thao tác khi dữ liệu thay đổi')+p('Nếu hệ thống báo phiên bản cũ hoặc trạng thái không hợp lệ, tải lại đơn để xem thay đổi của người khác. Không cố gửi lại bằng tab cũ. Hủy đơn có thể phát sinh phí theo giai đoạn; đọc thông tin xác nhận trước khi đồng ý.'))

topic('kh','Khách hàng: đặt dịch vụ và theo dõi',
 h('Đặt yêu cầu mới')+steps(['Vào Dịch vụ, chọn dịch vụ đúng nhu cầu.','Điền địa chỉ thực hiện, mô tả thiết bị gặp vấn đề và thời gian hẹn nếu cần; kiểm tra thông tin liên hệ.','Bấm Gửi yêu cầu đặt dịch vụ. Ghi lại mã HF-xxxxxx để tra cứu.','Mở chi tiết đơn, kiểm tra trạng thái Chờ tiếp nhận và thông tin vừa gửi.'])+
 h('Duyệt báo giá và vật tư')+steps(['Khi có báo giá sơ bộ, đọc phí kiểm tra, tiền công và nội dung chẩn đoán. Chọn Đồng ý báo giá khi chấp nhận; đơn chuyển Chờ phân công.','Khi KTV đề xuất vật tư, kiểm tra tên, số lượng, đơn giá, bảo hành và ghi chú.','Chỉ chọn Đồng ý thay vật tư nếu chấp nhận chi phí; nếu cần làm rõ, trao đổi qua chức năng hỗ trợ và từ chối theo lựa chọn hiển thị.'])+
 shot('kh-home-desktop.png','Trang chủ khách hàng')+
 h('Vị trí và hỗ trợ')+p('Cập nhật GPS của tôi gửi tọa độ hiện tại khi bạn cho phép trình duyệt truy cập vị trí. Đây là thao tác cập nhật theo yêu cầu, không theo dõi liên tục. Nếu từ chối quyền, vị trí đã lưu trước đó được giữ. Dùng mục Hỗ trợ để tạo yêu cầu và theo dõi phản hồi.')+
 '<p><a href="nghiemthu.html">Nghiệm thu, thanh toán và đánh giá</a></p>')

topic('nghiemthu','Khách hàng: nghiệm thu, thanh toán và đánh giá',
 steps(['Mở đơn Chờ nghiệm thu; đọc nguyên nhân, biện pháp sửa, vật tư, tổng tiền và ảnh minh chứng.','Kiểm tra chữ ký kỹ thuật viên. Chữ ký này không thay thế chữ ký khách hàng.','Nếu đạt yêu cầu, chọn Xác nhận nghiệm thu, đánh dấu đã kiểm tra và cung cấp chữ ký khách hàng theo biểu mẫu. Nếu chưa đạt, sử dụng lựa chọn từ chối để yêu cầu xử lý tiếp.','Với COD, chỉ giao tiền theo số phải thanh toán; KTV xác nhận đã thu. Với chuyển khoản, dùng đúng thông tin tài khoản/nội dung và gửi yêu cầu theo hướng dẫn; kế toán phải xác minh.','Kiểm tra trạng thái đã thanh toán sau khi được xác nhận; tạo QR hoặc gửi chứng từ chưa có nghĩa đã thanh toán.','Sau khi đơn hoàn thành và thanh toán đủ điều kiện, chọn Đánh giá dịch vụ, nhập nhận xét và gửi.'])+
 p('Nếu hủy đơn có phí di chuyển, theo dõi khoản phí riêng. Không xem trạng thái Đã hủy là mặc nhiên không còn nghĩa vụ thanh toán. Chi phí hiển thị trên đơn thực tế là căn cứ, không lấy số tiền từ ảnh hướng dẫn.')+
 shot('report-24.png','Kết quả xác nhận nghiệm thu trong kịch bản kiểm thử'))

topic('dpv','Điều phối viên: tiếp nhận và phân công',
 h('Tiếp nhận và lập báo giá')+steps(['Mở đơn chờ tiếp nhận, đọc mô tả, dịch vụ, địa chỉ và lịch hẹn.','Chọn Lập báo giá sơ bộ. Nhập Chẩn đoán sơ bộ và kiểm tra các khoản phí.','Gửi báo giá; theo dõi khách xác nhận. Không phân công trước khi khách đồng ý.'])+
 h('Phân công kỹ thuật viên')+steps(['Lọc đơn Chờ phân công, mở chi tiết.','Chọn Phân công kỹ thuật viên. Chỉ chọn trong danh sách đủ điều kiện theo dịch vụ/khu vực và tình trạng làm việc.','Xác nhận lệnh; theo dõi Chờ thợ nhận rồi Thợ đã nhận.','Nếu thợ từ chối hoặc lệnh hết hạn, tải lại trạng thái và thực hiện phân công lại theo lựa chọn cho phép.'])+
 p('Nếu không có thợ phù hợp, kiểm tra chuyên môn, khu vực, sẵn sàng, số dư và tài khoản hoạt động. Không sửa CSDL trực tiếp để bỏ qua điều kiện. Nếu đơn đang được người khác cập nhật, tải lại trước khi tiếp tục.')+
 shot('dpv-home-desktop.png','Không gian làm việc của điều phối viên'))

topic('ktv','Kỹ thuật viên: nhận việc và nghiệm thu',
 steps(['Bật Sẵn sàng nhận việc khi có thể nhận ca; kiểm tra hồ sơ, khu vực và ví.','Mở đơn được giao và chọn Chấp nhận đơn → Xác nhận nhận đơn trước khi lệnh hết hiệu lực.','Lần lượt chọn Bắt đầu di chuyển, Xác nhận đã đến nơi và Bắt đầu xử lý đúng tình trạng thực tế.','Nếu cần vật tư, chọn Đề xuất vật tư, điền tên, số lượng, đơn giá, bảo hành và ghi chú; gửi khách hàng duyệt. Chờ khách chấp nhận chi phí.','Chọn Hoàn thành · Lập phiếu nghiệm thu. Nhập nguyên nhân, biện pháp, ảnh; vẽ/lưu chữ ký KTV; Xem lại phiếu rồi Gửi phiếu nghiệm thu.','Chờ khách nghiệm thu. Nếu khách từ chối, đọc lý do và xử lý tiếp.','Với COD, chỉ chọn Xác nhận đã thu COD sau khi thực nhận đủ tiền và kiểm tra số tiền trên biểu mẫu.'])+
 shot('ktv-home-desktop.png','Trang công việc kỹ thuật viên')+
 p('Không dùng chữ ký của mình ở ô chữ ký khách. Không tự nhận tiền chuyển khoản là đã xác minh: kế toán xử lý nghiệp vụ ngân hàng. Chữ ký và ảnh là chứng từ có quyền truy cập theo đơn.')+
 '<p><a href="vi.html">Ví kỹ thuật viên</a></p>')

topic('vi','Kỹ thuật viên: ví và yêu cầu nạp/rút',
 steps(['Mở Ví để xem số dư và lịch sử biến động; dùng bộ lọc loại/khoảng thời gian nếu cần.','Chọn tạo yêu cầu nạp hoặc rút theo biểu mẫu. Nhập số tiền hợp lệ, thông tin và chứng từ được yêu cầu.','Với nạp tiền, chuyển đúng tài khoản/nội dung hiển thị và gửi chứng từ; chờ kế toán xác nhận.','Với rút tiền, kiểm tra tài khoản nhận tiền và số dư khả dụng; gửi yêu cầu để kế toán xử lý.','Theo dõi kết quả duyệt hoặc lý do từ chối. Nếu đang chờ, không tạo nhiều yêu cầu trùng để thay thế cùng một khoản tiền.'])+
 p('Số dư chỉ thay đổi khi nghiệp vụ đã được duyệt và ghi sổ. COD có thể làm giảm ví phần hoa hồng khi đối soát; tiền chuyển khoản được đối soát theo phần thuộc về KTV. Xem loại giao dịch để phân biệt nạp, rút và đối soát.')+
 p('Nếu số liệu không đúng, gửi mã yêu cầu hoặc mã đơn cho kế toán; không sửa/xóa một dòng sổ ví đã ghi.'))

topic('kt','Kế toán: chuyển khoản, đối soát và ví',
 h('Xác minh giao dịch ngân hàng')+steps(['Mở Tài chính/Giao dịch, chọn yêu cầu chờ xác minh.','Đối chiếu số tiền, nội dung, người gửi và chứng từ với nguồn tiền thực nhận. Ảnh chuyển khoản riêng lẻ chưa phải bằng chứng tiền đã vào tài khoản.','Xác nhận khi phù hợp hoặc từ chối kèm lý do; theo dõi trạng thái cập nhật.'])+
 h('Đối soát doanh thu')+steps(['Tìm đúng mã đơn hoặc mã đối soát, kiểm tra phương thức COD/BANK và số tiền.','Chọn Đối soát, đọc thông tin hoa hồng và xác nhận xử lý.','Kiểm tra kết quả Đã đối soát và biến động ví tương ứng. Nếu báo dữ liệu cũ, tải lại; không duyệt lại cùng chứng từ.'])+
 h('Duyệt ví')+steps(['Mở Duyệt Ví KTV và chọn yêu cầu nạp/rút còn chờ.','Đối chiếu chứng từ, tài khoản, số tiền và điều kiện số dư.','Duyệt hoặc từ chối kèm lý do theo biểu mẫu. Kiểm tra trạng thái và sổ ví sau xử lý.'])+
 shot('kt-finance-desktop.png','Màn hình tài chính')+
 p('Báo cáo giá trị đã thanh toán là tổng tiền giao dịch; hoa hồng đã đối soát là khoản thuộc nền tảng. Không dùng một tỷ lệ cố định nhân toàn bộ khoản thu để gọi là lợi nhuận ròng.'))

topic('cskh','Chăm sóc khách hàng: xử lý hỗ trợ',
 steps(['Mở Hỗ trợ hoặc danh sách công việc, lọc yêu cầu mới/còn xử lý.','Đọc khách hàng, mã đơn liên quan, nội dung và ảnh được phép xem.','Cập nhật sang đang xử lý, ghi nội dung liên hệ hoặc kết quả kiểm tra.','Khi giải quyết xong, ghi kết luận rõ ràng rồi chuyển trạng thái phù hợp. Mỗi cập nhật cần lưu lịch sử.','Dùng báo cáo chất lượng/hiệu suất để theo dõi phản hồi; không tự thay đổi thanh toán hoặc số dư ví.'])+
 p('Phản hồi nên nêu vấn đề đã xác minh, hướng xử lý và điều khách cần thực hiện. Nếu phát sinh tiền, chuyển thông tin cho kế toán theo đúng mã chứng từ. Khi hai nhân viên cùng mở một phiếu, tải lại nếu được báo phiên bản thay đổi.')+
 shot('cskh-home-desktop.png','Không gian chăm sóc khách hàng'))

topic('admin','Quản trị viên: tài khoản, danh mục và cấu hình',
 steps(['Mở Quản lý tài khoản; tìm theo định danh, kiểm tra đúng người trước khi cập nhật.','Khi tạo tài khoản nội bộ, chọn đúng vai trò. Khi khóa/ngừng hoạt động, kiểm tra ảnh hưởng công việc đang xử lý.','Quản lý danh mục dịch vụ: tên, nhóm, phí và tỷ lệ theo dữ liệu hợp lệ. Dịch vụ đã có lịch sử nên ngừng cung cấp thay vì xóa phá quan hệ.','Mở hồ sơ đăng ký KTV, kiểm tra các thông tin/ảnh được yêu cầu trước khi quyết định.','Thay đổi cấu hình theo quyền và kiểm tra phiên bản; mở nhật ký để truy lại tác nhân và thời điểm.'])+
 shot('admin-admin-users-desktop.png','Quản lý tài khoản')+
 p('Quyền ADMIN trên web không tự đồng nghĩa sysadmin của SQL Server. Tác vụ sao lưu/phục hồi do người quản trị CSDL có quyền phù hợp thực hiện. Không công bố .env, mật khẩu, OTP hoặc ảnh định danh trong tài liệu dùng chung.')+
 '<p><a href="backup.html">Sao lưu và phục hồi</a></p>')

topic('gd','Giám đốc: báo cáo và chính sách',
 steps(['Mở Tổng quan điều hành; đọc nhãn của từng chỉ tiêu và khoảng thời gian.','Phân biệt Tổng giá trị đã thanh toán, Doanh thu hoa hồng và số đơn hoàn thành. Hoa hồng dựa trên đối soát đã xác nhận.','Mở báo cáo tài chính, chất lượng hoặc hiệu suất; chọn kỳ và bộ lọc phù hợp. Kỳ không có dữ liệu có thể trả số 0 hoặc danh sách rỗng.','Mở đề xuất chính sách, đọc nội dung và người đề xuất. Chọn quyết định được cho phép, nhập lý do rồi xác nhận.','Tải lại để kiểm tra quyết định được lưu; nếu người khác đã xử lý, dùng trạng thái mới nhất.'])+
 p('Duyệt đề xuất hiện ghi nhận quyết định và thông báo; chưa phải cơ chế tự động áp dụng mức giá hoặc lịch hiệu lực. Không xem nút phê duyệt là đã triển khai chính sách vào toàn bộ đơn mới. Báo cáo chưa có các chỉ tiêu lợi nhuận ròng nếu thiếu dữ liệu chi phí tương ứng.')+
 shot('gd-home-desktop.png','Dashboard giám đốc dùng dữ liệu thực'))

topic('backup','Sao lưu và phục hồi cho quản trị CSDL',
 h('Phân biệt cài lại và phục hồi')+p('Bộ SQL cài mới chỉ tái tạo cấu trúc và dữ liệu mẫu. Muốn giữ đơn, tài khoản và chứng từ đã phát sinh, cần backup CSDL. Ảnh/chữ ký nằm trong SRC/backend/uploads cần sao lưu riêng cùng mốc; backup SQL không chứa các tệp này.')+
 h('Thực hành script có sẵn')+steps(['Mở SQL/CSDL_HomeFix_SaoLuuPhucHoi.sql trong SSMS và bật Query → SQLCMD Mode.','Sửa TenCSDL đúng nguồn HomeFix đang muốn sao lưu. Tài khoản cần quyền BACKUP/RESTORE; dịch vụ SQL cần quyền ghi thư mục đích.','Giữ ThucHienPhucHoi=0 để tạo Full/Diff/Log và VERIFYONLY. Script chuyển recovery model sang FULL.','Để thử phục hồi, đặt ThucHienPhucHoi=1. Đích là tên nguồn có hậu tố _Restore và phải chưa tồn tại. Script không ghi đè nguồn.','Kiểm tra thông báo, trạng thái ONLINE và CHECKDB; đối chiếu số lượng dữ liệu/số dư. Không coi việc tạo được file .bak là đã phục hồi thành công.'])+
 h('Trình tự')+p('Full WITH MOVE, NORECOVERY → Diff WITH NORECOVERY → Log WITH RECOVERY. Diff cần đúng bản Full nền; các bản Log phải liên tục. Bộ cài chuẩn có một file dữ liệu và một file log; cấu trúc nhiều file cần cấu hình MOVE thủ công.')+
 h('Khi cần đưa bản phục hồi vào sử dụng')+steps(['Dừng các thao tác ghi nghiệp vụ và giữ bản hiện trạng nếu còn truy cập được.','Phục hồi sang CSDL mới, khôi phục uploads tương ứng và bảo vệ file cấu hình.','Kiểm tra đơn, thanh toán, ví, quyền và ảnh qua ứng dụng.','Chỉ sau khi kiểm tra đạt mới đổi DB_NAME, khởi động lại API và cho người dùng tiếp tục.'])+
 p('Script không tự lập lịch. Có thể dùng Task Scheduler gọi sqlcmd trên Express. Lịch Full tuần, Diff ngày, Log 15 phút là đề xuất, cần giám sát và thử phục hồi định kỳ. STOPAT có ví dụ trong SQL nhưng chưa nằm trong bài test tự động.'))

topic('loi','Xử lý lỗi thường gặp',table(['Tình huống','Cách xử lý'],[
['Không mở được localhost:3000','Kiểm tra cửa sổ server, cổng PORT và lỗi khởi động; chạy CHAY_HOMEFIX_DBMS.bat'],['Kết nối SQL lỗi','Kiểm tra dịch vụ, instance, driver và quyền tài khoản; không sửa dữ liệu để khắc phục kết nối'],['Đăng nhập thất bại','Kiểm tra định danh/mật khẩu, trạng thái tài khoản; dùng khôi phục email nếu đã cấu hình'],['Không thấy nút nghiệp vụ','Kiểm tra đúng vai trò, đúng đơn và điều kiện trạng thái; không tìm cách bỏ qua quyền'],['Dữ liệu đã được người khác cập nhật','Tải lại đơn/phiếu, đọc trạng thái mới rồi quyết định'],['Không gợi ý KTV','Kiểm tra chuyên môn, khu vực, sẵn sàng, ví và khóa tài khoản'],['Chuyển khoản còn chờ','Chờ kế toán xác minh; gửi mã giao dịch để đối chiếu, không nộp lại tiền chỉ vì chưa cập nhật'],['GPS không cập nhật','Cấp quyền vị trí nếu muốn; kiểm tra trình duyệt và kết nối; có thể tiếp tục dùng địa chỉ đã lưu'],['CHM trắng hoặc báo chặn','Chép CHM về ổ cục bộ; Properties → Unblock nếu có. Hoặc mở HELP/html/index.html'],['Tiếng Việt trong CHM lỗi','Dùng bản CHM mới; nội dung UTF-8. Mục lục không dấu là thiết kế, không phải lỗi'],['Ảnh không mở','Kiểm tra đúng tài khoản/quyền và uploads; ảnh trong tài liệu mở offline']])+
 p('Khi báo lỗi, cung cấp vai trò, mã đơn/yêu cầu, thời điểm, thao tác vừa làm và thông điệp. Không gửi mật khẩu, OTP hoặc nội dung .env.'))

topic('kiemthu','Kiểm chứng và giới hạn phiên bản',
 p('Lượt chạy ngày 16/10/2026 đạt 108 ca API/SQL, 92 lượt mở màn hình desktop/mobile và 17 thao tác trong quy trình xuyên suốt. Bộ SQL nguyên khối/module và phục hồi Full–Diff–Log đã được kiểm thử trên CSDL tách biệt.')+
 code('cd SRC\nnpm.cmd run sql:check\nnpm.cmd run test:sql-usage')+
 p('Bộ kiểm thử cần SQL Server và quyền quản trị phù hợp để tạo/xóa CSDL tạm, backup/restore và Extended Events. Đây là lệnh dành cho người phát triển/quản trị, không phải thao tác thường ngày của khách hàng.')+
 p('Chưa kiểm thử tải sản xuất; email provider được giả lập và AI ngoài hệ thống không được gọi trong kiểm thử. Mobile dùng viewport giả lập, không khẳng định đã thử mọi điện thoại. Ảnh trong hướng dẫn chụp từ hệ thống thật với dữ liệu kiểm thử.')+
 p('Nguồn đối chiếu: README.md, SQL/README.md, SQL/HUONG_DAN_VAN_DAP.md và DOC/evidence/20261016-report trong gói dự án.'))

css='''html,body{margin:0;padding:0;background:#fff;color:#18342d;font-family:"Segoe UI",Arial,sans-serif;font-size:16px;line-height:1.6}*{box-sizing:border-box}.top{background:#087b4b;color:#fff;padding:15px 22px}.top a{color:#fff}.content{width:100%;margin:0;padding:18px 24px 30px}h1{font-size:28px;margin:0 0 18px;line-height:1.3}h2{font-size:21px;border-bottom:1px solid #dbe8df;padding-bottom:6px;margin-top:26px}p,li{max-width:none}li{margin-bottom:10px}a{color:#086c48}.figure{margin:20px 0;padding:12px;border:1px solid #dbe8df;background:#f7faf8}.figure img{display:block;width:100%;height:auto;border:1px solid #ccdcd3}.figure p{font-size:14px;margin:8px 0 0}.table-wrap{width:100%;overflow-x:auto}table{border-collapse:collapse;width:100%;table-layout:fixed}th,td{border:1px solid #ccdad2;padding:10px;vertical-align:top;word-wrap:break-word}th{background:#e7f1ec;text-align:left}pre{white-space:pre-wrap;word-wrap:break-word;background:#f0f4f2;padding:14px;font-family:Consolas,monospace;color:#18342d}.footer{border-top:1px solid #dbe8df;padding-top:15px;font-size:14px}.quicklinks a{display:inline-block;margin:4px 18px 4px 0}@media(max-width:650px){.content{padding:12px}.top{padding:12px}h1{font-size:24px}th,td{padding:6px}}'''
(html/'style.css').write_text(css,encoding='utf-8')
def ascii_title(s): return ''.join(c for c in unicodedata.normalize('NFD',s.replace('đ','d').replace('Đ','D')) if not unicodedata.combining(c)).replace('–','-').replace('—','-')
nav='<div class="quicklinks">'+''.join('<a href="'+f+'.html">'+escape(t)+'</a>' for f,t,b in topics)+'</div>'
for i,(f,t,b) in enumerate(topics):
    if f=='index': b+=h('Toàn bộ chủ đề')+nav
    pager=('<a href="'+topics[i-1][0]+'.html">← '+escape(topics[i-1][1])+'</a> · ' if i else '')+'<a href="index.html">Trang đầu</a>'+(' · <a href="'+topics[i+1][0]+'.html">'+escape(topics[i+1][1])+' →</a>' if i+1<len(topics) else '')
    doc='<!DOCTYPE html><html lang="vi"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+escape(t)+'</title><link rel="stylesheet" href="style.css"></head><body><div class="top"><strong>HOMEFIX</strong> · Hướng dẫn sử dụng · <a href="index.html">Danh mục</a></div><div class="content"><h1>'+escape(t)+'</h1>'+b+'<div class="footer">'+pager+'<p>Nhóm 08 · DBMS330284 · 16/10/2026</p></div></div></body></html>'
    (html/(f+'.html')).write_text(doc,encoding='utf-8-sig')

items='\n'.join('<LI><OBJECT type="text/sitemap"><param name="Name" value="'+escape(ascii_title(t),quote=True)+'"><param name="Local" value="html/'+f+'.html"></OBJECT>' for f,t,b in topics)
toc='<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><HTML><HEAD><meta http-equiv="Content-Type" content="text/html; charset=Windows-1252"></HEAD><BODY><UL>'+items+'</UL></BODY></HTML>'
(helpdir/'contents.hhc').write_text(toc,encoding='ascii')
(helpdir/'index.hhk').write_text(toc,encoding='ascii')
files='\n'.join(str(p.relative_to(helpdir)).replace('/','\\') for p in sorted(html.rglob('*')) if p.is_file())
(helpdir/'HomeFix.hhp').write_text('''[OPTIONS]
Compatibility=1.1 or later
Compiled file=HomeFix_HuongDan.chm
Contents file=contents.hhc
Index file=index.hhk
Default topic=html/index.html
Default Window=main
Display compile progress=No
Full-text search=Yes
Language=0x409 English (United States)
Title=HomeFix - Huong dan su dung
Error log file=compile.log

[WINDOWS]
main="HomeFix - Huong dan su dung","contents.hhc","index.hhk","html/index.html","html/index.html",,,,,0x63520,270,0x104e,[20,20,1380,900],,,,,,,0

[FILES]
'''+files+'\n',encoding='ascii')
(helpdir/'README.md').write_text('''# Hướng dẫn HomeFix

Mở **HomeFix_HuongDan.chm** trên Windows. Mục lục bên trái dùng tiếng Việt không dấu; các trang nội dung dùng tiếng Việt có dấu. Cửa sổ mặc định nằm ngang, phần nội dung giãn theo khung đọc. Có thể kéo mép ngăn để đổi độ rộng mục lục.

Nếu Windows chặn tệp tải từ Internet, chép về ổ cục bộ và mở Properties → Unblock nếu có. Bản dự phòng: [html/index.html](html/index.html).

Nguồn sinh: `DOC/tools/build_help.py`; dự án biên dịch: `HomeFix.hhp`. Chạy trình HTML Help Workshop `hhc.exe HomeFix.hhp` tại thư mục HELP. Bản CHM dùng toàn bộ ảnh nội bộ, không cần kết nối mạng để đọc. Liên kết vào ứng dụng cần máy chủ HomeFix đang hoạt động.
''',encoding='utf-8')
print('Built',len(topics),'topics and',len(list(images.glob('*.png'))),'images')
