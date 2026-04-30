BỘ CÔNG THƯƠNG
TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP.HCM
KHOA CÔNG NGHỆ THÔNG TIN

---

# ĐỒ ÁN TỐT NGHIỆP

**ĐỀ TÀI:** Quản lý quy trình sản xuất nguyên liệu dược phẩm Cao Khô theo tiêu chuẩn GMP-WHO

**Giảng viên hướng dẫn:** Ths. Trần Thị Vân Anh  
**Sinh viên thực hiện:**
1. 2001210163 – Nguyễn Vũ Hiệp
2. 2001215648 – Nguyễn Quốc Cường
3. 2001210178 – Trần Trạch Nguyên

**Năm học:** 2024 - 2025

---

## LỜI CẢM ƠN
Trong khoảng thời gian làm đồ án tốt nghiệp, chúng tôi đã nhận được nhiều sự giúp đỡ, đóng góp ý kiến và sự dẫn dắt chỉ bảo nhiệt tình của thầy cô, gia đình và bạn bè. Chúng tôi xin gửi lời cảm ơn chân thành đến giáo viên hướng dẫn – Ths Trần Thị Vân Anh đã tận tình hướng dẫn, chỉ bảo chúng tôi trong suốt quá trình làm khoá luận.

Đồng thời, chúng tôi xin cảm ơn các thầy cô khoa Công nghệ thông tin trường Đại học Công thương đã truyền đạt kiến thức nền tảng giúp chúng tôi thực hiện thành công đề tài này.

---

## MỤC LỤC
1. [Chương 1: Tổng Quan](#chương-1-tổng-quan)
2. [Chương 2: Phân Tích Hệ Thống](#chương-2-phân-tích-hệ-thống)
3. [Chương 3: Thiết Kế Hệ Thống](#chương-3-thiết-kế-hệ-thống)
4. [Chương 4: Kết Luận](#chương-4-kết-luận)

---

## CHƯƠNG 1: TỔNG QUAN

### 1.1. Giới thiệu
Hệ thống quản lý sản xuất cao khô là một quy trình tổng thể bao gồm các bước từ việc thu thập nguyên liệu đầu vào cho đến sản phẩm hoàn thiện. Quy trình này không chỉ đảm bảo sản phẩm đạt chất lượng theo tiêu chuẩn GMP-WHO mà còn tối ưu hóa hiệu suất sản xuất, giảm thiểu lãng phí và tăng cường khả năng truy xuất nguồn gốc. Việc áp dụng công nghệ thông tin vào quản lý sản xuất đã trở thành một yêu cầu cấp thiết để nâng cao năng lực cạnh tranh trong ngành dược phẩm và thực phẩm chức năng.

### 1.2. Mục tiêu và phạm vi đề tài
- Khảo sát và đánh giá quy trình sản xuất cao khô hiện tại.
- Mô hình hóa các nghiệp vụ của hoạt động sản xuất.
- Đề xuất giải pháp phần mềm quản lý để cải thiện quy trình, theo dõi và kiểm soát sản xuất, đảm bảo chất lượng, phân quyền người dùng và kết xuất báo cáo thống kê.
- Xây dựng ứng dụng hoàn chỉnh trên 2 nền tảng: Web (React, .NET 8) và Mobile (Flutter).

### 1.3. Khảo sát hệ thống (Quy trình nghiệp vụ)
Quy trình sản xuất cao khô thực tế bao gồm các bước:
1. **Cân nguyên liệu:** Cân chính xác NLC 2 và TD 1.
2. **Trộn ướt:** Trộn bột nhão bằng máy MTU-1 trong 20 phút.
3. **Xát hạt ướt:** Xát bột qua lưới 2 mm bằng máy KBC-SHU-100.
4. **Sấy hạt ướt:** Sấy tầng sôi KBC-TS-50 (Lần 1: 60°C/30 phút, Lần 2: 50°C/20 phút).
5. **Sửa hạt khô:** Sửa hạt qua máy KBC-XB-300 lưới 2mm và 1mm để đạt độ đồng nhất.
6. **Đóng gói:** Đóng gói vào thùng inox có lót túi PE, dán nhãn biệt trữ.

---

## CHƯƠNG 2: PHÂN TÍCH HỆ THỐNG

### 2.1. Phân tích nghiệp vụ
Việc phân tích giúp hệ thống đáp ứng đúng các quy định khắt khe của GMP-WHO, kiểm soát chặt chẽ trạng thái của lệnh sản xuất và dữ liệu môi trường.

#### Các Use-case chính:
1. **Kiểm tra môi trường:** 
   - Đo nhiệt độ (21°C - 25°C), Độ ẩm (45% - 70%), Áp lực phòng (≥ 10 Pa).
   - Kiểm tra vệ sinh phòng pha chế.
2. **Kiểm tra thiết bị sử dụng:**
   - Nhân viên bảo trì kiểm tra các thiết bị (Cân IW2-60, Máy trộn MTU-1, Máy xát, Máy sấy, Máy sửa hạt).
3. **Quản lý nguyên liệu:** 
   - Cập nhật số lượng xuất/nhập, tự động cảnh báo khi thiếu hụt vật tư.
4. **Chế biến cao khô:** 
   - Kiểm soát từng bước theo công thức (BOM) định sẵn, cảnh báo độ lệch khối lượng. Người vận hành phải nhập PIN (chữ ký số) để xác nhận.
5. **Đóng gói và Giao kho:** 
   - Cân lại khối lượng thành phẩm, lấy mẫu kiểm nghiệm, giao kho biệt trữ và phát hành phiếu.

### 2.2. Đặc tả hệ thống (Quy định dữ liệu)
Mô hình hệ thống được số hóa sử dụng quy tắc **State Machine**: 
Lệnh sản xuất trải qua các trạng thái: `Draft -> Approved -> InProcess -> Hold -> Completed`.
Mọi sự thay đổi (INSERT/UPDATE/DELETE) đều được lưu lại lịch sử (Audit Trail) để truy xuất nguồn gốc.

---

## CHƯƠNG 3: THIẾT KẾ HỆ THỐNG

### 3.1. Kiến trúc hệ thống
Hệ thống sử dụng kiến trúc Backend là .NET 8 (API) và Frontend là React (Web Admin) + Flutter (Mobile App cho công nhân xưởng). Các thành phần được triển khai trên nền tảng Docker với SQL Server 2022.

### 3.2. Thiết kế Cơ sở dữ liệu (Mô hình thực thể)
Các nhóm bảng chính:
- **Master Data:** Users, Vật tư (Material), Thiết bị (Equipment).
- **Process Definition:** Công thức (Recipe BOM) và Các bước quy trình.
- **Production Execution:** Lệnh sản xuất (ProductionOrder) và Mẻ sản xuất (Batch).
- **Audit & Immutability:** Bảng ghi nhận vết (Audit Logs) đảm bảo tính toàn vẹn dữ liệu.

### 3.3. Thiết kế Giao diện người dùng
Giao diện được thiết kế trực quan, dễ sử dụng cho các phòng ban:
- **Giao diện Quản lý (Web):** Dashboards thống kê, Lập lệnh sản xuất, Quản lý vật tư, Đối chiếu sai lệch, Phê duyệt.
- **Giao diện Vận hành (Mobile):** Các thao tác thực tế tại xưởng như Cân, Trộn, Xát, Sấy, Sửa hạt. Có màn hình cảnh báo đỏ nếu phát hiện sai lệch quá 5%.

---

## CHƯƠNG 4: KẾT LUẬN

### 4.1. Kết quả đạt được
Dự án **Quản lý sản xuất cao khô** đã hoàn thành và đáp ứng tốt các yêu cầu nghiệp vụ theo chuẩn GMP-WHO:
- Tăng hiệu quả và độ chính xác trong quản lý.
- Giảm thiểu lỗi phát sinh nhờ chức năng cảnh báo sai lệch BOM tự động.
- Cải thiện khả năng truy xuất nguồn gốc và Audit Trail minh bạch.
- Giao diện hai nền tảng Web & Mobile đáp ứng được nhu cầu thực tế của khối Quản lý và Vận hành.

### 4.2. Hạn chế
- Hệ thống cần được kiểm thử kịch bản ngoại tuyến (Offline) cho Mobile sâu hơn trong các vùng xưởng sóng yếu.
- Chưa tích hợp trực tiếp lấy thông số tự động từ các máy móc công nghiệp (PLC, SCADA).

### 4.3. Hướng phát triển
- Tích hợp công nghệ IoT vào quy trình để tự động thu thập thông số (nhiệt độ, độ ẩm, khối lượng cân) theo thời gian thực thay vì nhập tay.
- Sử dụng AI để dự đoán sai lệch chất lượng dựa trên dữ liệu sản xuất lịch sử.
- Tiếp tục hoàn thiện tính năng Offline Sync cho thiết bị di động bằng SQLite.
