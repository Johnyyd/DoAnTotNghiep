1. Nhóm Use-case Quản lý Hệ thống & Tài khoản
Đăng nhập/Đăng xuất (Login/Logout): Xác thực người dùng dựa trên Role (Admin, QC, Operator).
Quản lý Tài khoản người dùng: Khởi tạo, phân quyền và cấp mã PIN chữ ký số cho nhân sự.
Cấu hình Khu vực sản xuất: Thiết lập các phòng pha chế, phòng cân, phòng sấy sạch.
2. Nhóm Use-case Quản lý Dữ liệu nguồn (Master Data)
Quản lý Nguyên liệu (Materials): Khai báo danh mục Cao khô, tá dược, bao bì.
Quản lý Thiết bị (Equipments): Quản lý tình trạng vệ sinh và hoạt động của máy sấy tầng sôi, máy trộn, cân điện tử.
Thiết lập Công thức (Recipe Management): Định nghĩa định mức (BOM) và quy trình sản xuất (Routing) cho từng loại Cao khô.
3. Nhóm Use-case Lập kế hoạch & Sản xuất (Web Admin)
Lập Lệnh sản xuất (Production Order): Tạo lệnh mới, tự động tính toán nguyên liệu theo cỡ lô.
Duyệt Lệnh sản xuất: QC/Manager thẩm định và chuyển trạng thái từ Draft sang Approved.
Quản lý Mẻ sản xuất (Batch Management): Chia lệnh thành các mẻ nhỏ để thực thi.
Theo dõi tiến độ thời gian thực: Giám sát trạng thái lệnh (In-Process, Hold, Completed).
4. Nhóm Use-case Thực thi Sản xuất (Mobile - eBMR)
Đây là nhóm Use-case quan trọng nhất, thực hiện trên Tablet tại xưởng:

Kiểm tra môi trường (Pre-check): Ghi nhận Nhiệt độ, Độ ẩm, Áp suất phòng trước khi làm việc.
Thực thi công đoạn Cân (Weighing): Cân chi tiết từng nguyên liệu, đối chiếu sai lệch ±5%.
Thực thi công đoạn Trộn (Mixing): Ghi nhận thời gian trộn, tốc độ máy và kiểm tra vệ sinh.
Thực thi công đoạn Sấy (Drying): Theo dõi nhiệt độ sấy, thời gian và độ ẩm sau sấy.
Ký xác nhận điện tử (Digital Signature): Sử dụng mã PIN để xác thực trách nhiệm sau mỗi bước.
5. Nhóm Use-case Kiểm soát & Truy xuất
Quản lý Sai lệch (Deviation): Hệ thống tự động bẫy lỗi khi dữ liệu nhập vào vượt ngưỡng an toàn và chuyển trạng thái sang Hold.
Duyệt xử lý sai lệch: QC điều tra nguyên nhân và quyết định Tiếp tục (Resume) hoặc Hủy lô (Reject).
Truy xuất nguồn gốc (Traceability): Truy ngược từ số lô thành phẩm ra toàn bộ chuỗi nguyên liệu và nhân sự đã thao tác.
Quản lý Phiếu kiểm nghiệm (Certificates): Đính kèm kết quả kiểm nghiệm chất lượng cho từng lô nguyên liệu/thành phẩm.