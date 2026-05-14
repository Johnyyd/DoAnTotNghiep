# ĐẶC TẢ CHI TIẾT USE-CASE HỆ THỐNG (GMP-WHO SYSTEM)

Dưới đây là bộ tài liệu đặc tả chi tiết cho toàn bộ các Use-case trong dự án, được biên soạn dựa trên logic xử lý thực tế của Codebase và tuân thủ định dạng chuẩn của báo cáo đồ án.

---

## NHÓM 1: QUẢN LÝ HỆ THỐNG & TÀI KHOẢN

### 1. Đặc tả Use-case: Đăng nhập hệ thống
**Use case nghiệp vụ:** Xác thực người dùng và phân quyền.
**Mô tả:** Quy trình người dùng (Admin, QC, Operator) truy cập vào hệ thống để thực hiện các chức năng theo vai trò được cấp phép.
**Các dòng cơ bản:**
1. **Nhập thông tin xác thực:**
   - Người dùng nhập Username và Password tại màn hình đăng nhập.
2. **Xác thực tài khoản:**
   - Hệ thống thực hiện đối chiếu thông tin với bảng `AppUsers` (sử dụng cơ chế băm mật khẩu Bcrypt).
3. **Phân quyền và cấp Token:**
   - Nếu thông tin đúng, hệ thống trả về mã JWT Token chứa thông tin vai trò.
4. **Điều hướng:**
   - Hệ thống chuyển người dùng vào Dashboard tương ứng (Web Admin cho Quản lý/QC hoặc Mobile Dashboard cho Công nhân).
**Các dòng thay thế:**
- **Tại bước 2:** 
  - Nếu thông tin sai, hệ thống báo lỗi: "Tài khoản hoặc mật khẩu không chính xác".
  - Nếu tài khoản bị khóa, hệ thống báo lỗi: "Tài khoản đã bị đình chỉ".

### 2. Đặc tả Use-case: Quản lý Tài khoản người dùng
**Use case nghiệp vụ:** Quản lý nhân sự và định danh số.
**Mô tả:** Cho phép quản trị viên quản lý thông tin nhân viên và thiết lập mã PIN chữ ký số.
**Các dòng cơ bản:**
1. **Chọn nhân sự:** Quản trị viên chọn nhân viên cần cập nhật từ danh sách.
2. **Cập nhật thông tin:** Thay đổi họ tên, vai trò (Role) hoặc thiết lập mã PIN (6 chữ số).
3. **Lưu thay đổi:** Hệ thống cập nhật bảng `AppUsers` và lưu vết Audit Log.
**Các dòng thay thế:**
- **Tại bước 2:** Nếu mã PIN không đủ 6 chữ số hoặc chứa ký tự chữ, hệ thống yêu cầu nhập lại.

---

## NHÓM 2: QUẢN LÝ DỮ LIỆU NGUỒN (MASTER DATA)

### 3. Đặc tả Use-case: Quản lý Nguyên liệu (Materials)
**Use case nghiệp vụ:** Quản lý danh mục vật tư sản xuất.
**Mô tả:** Quản lý danh mục các loại cao khô, tá dược, bao bì dùng trong quá trình chế biến thuốc.
**Các dòng cơ bản:**
1. **Khai báo mới:** Nhập mã nguyên liệu, tên, đơn vị tính (kg, g, viên).
2. **Thiết lập điều kiện bảo quản:** Ghi chú nhiệt độ/độ ẩm tối ưu.
3. **Lưu trữ:** Dữ liệu được lưu vào bảng `Materials`.
**Các dòng thay thế:**
- **Tại bước 1:** Nếu mã nguyên liệu đã tồn tại, hệ thống báo lỗi trùng lặp.

### 4. Đặc tả Use-case: Thiết lập Công thức (Recipe Management)
**Use case nghiệp vụ:** Định nghĩa quy trình sản xuất gốc.
**Mô tả:** Thiết lập bộ khung định mức (BOM) và các bước thực hiện (Routing) cho một sản phẩm.
**Các dòng cơ bản:**
1. **Khai báo Recipe:** Nhập tên sản phẩm và cỡ lô tiêu chuẩn.
2. **Thiết lập BOM:** Chọn các nguyên liệu và nhập khối lượng định mức lý thuyết.
3. **Thiết lập Routing:** Thêm các công đoạn tuần tự: Cân -> Trộn -> Sấy -> Đóng gói.
4. **Phê duyệt:** Trạng thái chuyển sang `Approved`, khóa chỉnh sửa để chuẩn bị cho lệnh sản xuất.
**Các dòng thay thế:**
- **Tại bước 4:** Nếu công thức thiếu định mức nguyên liệu chính, hệ thống ngăn chặn việc phê duyệt.

---

## NHÓM 3: LẬP KẾ HOẠCH & QUẢN LÝ LỆNH SẢN XUẤT

### 5. Đặc tả Use-case: Lập Lệnh sản xuất (Production Order)
**Use case nghiệp vụ:** Khởi tạo kế hoạch sản xuất cụ thể.
**Mô tả:** Tạo lệnh sản xuất dựa trên một công thức gốc và quy mô mẻ thực tế.
**Các dòng cơ bản:**
1. **Chọn Recipe:** Người dùng chọn công thức đã được duyệt.
2. **Nhập quy mô:** Nhập số lượng cần sản xuất. Hệ thống tự động tính toán khối lượng nguyên liệu cần cấp phát dựa trên BOM gốc.
3. **Lưu dự thảo:** Lệnh được tạo ở trạng thái `Draft`.
**Các dòng thay thế:**
- **Tại bước 2:** Nếu quy mô nhập vào vượt quá năng lực thiết bị, hệ thống hiển thị cảnh báo.

### 6. Đặc tả Use-case: Duyệt Lệnh sản xuất
**Use case nghiệp vụ:** Thẩm định và cấp phép sản xuất.
**Mô tả:** QC kiểm tra tính hợp lệ và cho phép thực thi lệnh sản xuất.
**Các dòng cơ bản:**
1. **Kiểm duyệt:** QC xem chi tiết lệnh và BOM đã tính toán.
2. **Xác nhận ký số:** QC chọn "Duyệt" và nhập mã PIN cá nhân.
3. **Khóa dữ liệu:** Hệ thống Snapshot toàn bộ công thức vào lệnh và chuyển trạng thái sang `Approved`.
**Các dòng thay thế:**
- **Tại bước 2:** Nếu mã PIN sai, lệnh không được duyệt và hệ thống ghi lại hành động thất bại vào Audit Log.

---

## NHÓM 4: THỰC THI SẢN XUẤT (MOBILE - eBMR)

### 7. Đặc tả Use-case: Kiểm tra môi trường (Pre-check)
**Use case nghiệp vụ:** Kiểm tra điều kiện môi trường.
**Mô tả:** Ghi nhận vệ sinh và các thông số kỹ thuật phòng sạch trước khi bắt đầu công đoạn.
**Các dòng cơ bản:**
1. **Kiểm tra vệ sinh:** Xác nhận trạng thái "Sạch" cho phòng và thiết bị.
2. **Ghi nhận thông số:** Đo nhiệt độ (21-25°C), Độ ẩm (45-70%), Áp lực (≥10 Pa).
3. **Xác nhận:** Hệ thống lưu dữ liệu vào nhật ký mẻ và cho phép bắt đầu sản xuất.
**Các dòng thay thế:**
- **Tại bước 2:** Nếu thông số nằm ngoài ngưỡng, hệ thống cảnh báo đỏ và yêu cầu QC xử lý trước khi tiếp tục.

### 8. Đặc tả Use-case: Thực thi công đoạn Cân (Weighing)
**Use case nghiệp vụ:** Cân nguyên liệu thực tế.
**Mô tả:** Công nhân cân từng thành phần nguyên liệu và hệ thống kiểm soát sai lệch thời gian thực.
**Các dòng cơ bản:**
1. **Nhận diện nguyên liệu:** Công nhân chọn nguyên liệu từ danh sách BOM trên App.
2. **Cân thực tế:** Nhập khối lượng cân được. Hệ thống tính toán % sai lệch so với định mức lý thuyết.
3. **Xác nhận đạt:** Nếu sai lệch ≤ 5%, viền hiển thị màu xanh. Công nhân ký PIN xác nhận.
4. **Ghi log:** Hệ thống lưu giá trị vào `BatchProcessLogs`.
**Các dòng thay thế:**
- **Tại bước 3:** Nếu sai lệch > 5%, hệ thống báo lỗi đỏ. Công nhân phải nhập lý do sai lệch và trạng thái lệnh sẽ chuyển sang `Hold`.

### 9. Đặc tả Use-case: Thực thi công đoạn Trộn (Mixing)
**Use case nghiệp vụ:** Vận hành trộn bột cao khô.
**Mô tả:** Ghi nhận quy trình vận hành máy trộn lập phương.
**Các dòng cơ bản:**
1. **Khởi động:** Nhập giờ bắt đầu và tốc độ máy cài đặt.
2. **Nạp liệu:** Xác nhận nạp liệu theo đúng thứ tự SOP.
3. **Kết thúc:** Nhập giờ kết thúc. Hệ thống tự động tính tổng thời gian trộn.
4. **Ký số:** Nhập PIN để hoàn tất công đoạn.
**Các dòng thay thế:**
- **Tại bước 3:** Nếu thời gian trộn thực tế sai lệch quá nhiều so với cài đặt, hệ thống yêu cầu nhập giải trình.

---

## NHÓM 5: KIỂM SOÁT & TRUY XUẤT

### 10. Đặc tả Use-case: Quản lý Sai lệch (Deviation)
**Use case nghiệp vụ:** Xử lý sự cố và chặn lỗi.
**Mô tả:** Tự động phát hiện và xử lý các hành động không tuân thủ quy chuẩn sản xuất.
**Các dòng cơ bản:**
1. **Kích hoạt sai lệch:** Hệ thống phát hiện dữ liệu nhập vào (nhiệt độ, khối lượng) không đạt chuẩn.
2. **Tạm dừng quy trình:** Chuyển trạng thái lệnh sang `Hold`, ngăn chặn các bước tiếp theo.
3. **Thông báo:** Gửi cảnh báo thời gian thực đến Dashboard của QC.
**Các dòng thay thế:**
- **Tại bước 2:** Lệnh chỉ được mở khóa sau khi QC thực hiện Use-case "Duyệt xử lý sai lệch".

### 11. Đặc tả Use-case: Truy xuất nguồn gốc (Traceability)
**Use case nghiệp vụ:** Tra cứu phả hệ lô sản phẩm.
**Mô tả:** Tìm kiếm thông tin ngược từ thành phẩm về nguyên liệu.
**Các dòng cơ bản:**
1. **Tìm kiếm:** Nhập mã số lô (Batch No) của thành phẩm.
2. **Hiển thị chuỗi:** Hệ thống liệt kê toàn bộ các mẻ sản xuất, các lô nguyên liệu đầu vào và phiếu kiểm nghiệm tương ứng.
3. **Xem Audit Trail:** Hiển thị chi tiết ai đã thao tác tại từng bước và chữ ký xác nhận của họ.
**Các dòng thay thế:**
- **Tại bước 1:** Nếu mã lô không hợp lệ, hệ thống báo không tìm thấy kết quả.

---

### 12. Đặc tả Use-case: Quản lý Thiết bị (Equipments)
**Use case nghiệp vụ:** Kiểm soát trạng thái máy móc sản xuất.
**Mô tả:** Quản lý danh mục thiết bị và ghi nhận lịch sử vệ sinh/hiệu chuẩn máy.
**Các dòng cơ bản:**
1. **Khai báo thiết bị:** Admin nhập mã máy, tên máy (ví dụ: Máy sấy TS-50) và loại thiết bị.
2. **Cập nhật trạng thái:** Ghi nhận máy đang Sẵn sàng, Đang sửa chữa hoặc Cần vệ sinh.
3. **Tra cứu:** Công nhân kiểm tra trạng thái máy trước khi đưa vào sản xuất.
**Các dòng thay thế:**
- **Tại bước 3:** Nếu máy đang ở trạng thái "Cần vệ sinh", hệ thống chặn không cho phép bắt đầu công đoạn sử dụng máy đó.

### 13. Đặc tả Use-case: Thực thi công đoạn Sấy (Drying)
**Use case nghiệp vụ:** Vận hành sấy tầng sôi cao khô.
**Mô tả:** Kiểm soát nhiệt độ và thời gian sấy để đảm bảo độ ẩm hạt đạt chuẩn.
**Các dòng cơ bản:**
1. **Thiết lập thông số:** Công nhân nhập nhiệt độ sấy cài đặt và thời gian sấy dự kiến.
2. **Theo dõi quá trình:** Ghi nhận nhiệt độ thực tế tại các thời điểm kiểm tra.
3. **Kiểm tra độ ẩm:** Sau khi kết thúc, nhập % độ ẩm hạt. Hệ thống kiểm tra nếu < 5% là đạt.
4. **Ký số:** Nhập mã PIN để hoàn tất.
**Các dòng thay thế:**
- **Tại bước 3:** Nếu độ ẩm > 5%, hệ thống yêu cầu sấy thêm và ghi nhận lý do vào nhật ký.

### 14. Đặc tả Use-case: Quản lý Phiếu kiểm nghiệm (Certificates)
**Use case nghiệp vụ:** Quản lý hồ sơ chất lượng vật tư.
**Mô tả:** Đính kèm các thông tin về chất lượng (CoA/Phòng thí nghiệm) cho từng lô nguyên liệu.
**Các dòng cơ bản:**
1. **Nhập thông tin phiếu:** Chọn lô nguyên liệu (Lot No) và nhập số phiếu kiểm nghiệm.
2. **Xác nhận kết quả:** Đánh giá Đạt/Không đạt dựa trên kết quả kiểm nghiệm thực tế.
3. **Lưu trữ:** Dữ liệu này sẽ được hiển thị khi QC duyệt cấp phát nguyên liệu.
**Các dòng thay thế:**
- **Tại bước 2:** Nếu kết quả là "Không đạt", lô nguyên liệu đó sẽ bị khóa trên toàn hệ thống và không thể xuất dùng cho sản xuất.
