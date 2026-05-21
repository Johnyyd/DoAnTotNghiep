# Phân tích BUC và SUC - Hệ thống Quản lý Sản xuất GMP

Dựa trên việc rà soát toàn bộ Codebase (Backend C# .NET Core & Frontend React Web / Flutter Mobile), dưới đây là bản phân tích chi tiết về **BUC (Business Use Case)** và **SUC (System Use Case)** được đối chiếu chính xác 100% với logic code hiện có:

---

## 2.2. Mô hình hóa quy trình nghiệp vụ (Business Use Cases - BUC)

### BUC 1: Lập Lệnh Sản Xuất
**1. Đặc tả Use-case: Lập Lệnh Sản Xuất**
**Use case nghiệp vụ:** Lập Lệnh Sản Xuất
**Use case bắt đầu khi:** Quản đốc hoặc nhân viên lên kế hoạch cần khởi tạo một Lệnh sản xuất mới dựa trên Công thức (Recipe) để triển khai thực tế xuống xưởng.
**Các dòng cơ bản:**
1.	Quản đốc đăng nhập vào hệ thống Web Admin.
2.	Truy cập module "Production Orders" và chọn chức năng thêm mới Lệnh sản xuất.
3.	Quản đốc chọn Công thức (Recipe) đã được thiết lập sẵn quy trình từ danh sách.
4.	Quản đốc nhập các thông tin cấu hình lệnh: Ngày bắt đầu dự kiến và Số lượng mẻ (Number of Batches).
5.	Quản đốc nhấn nút Lưu để tạo Lệnh.
6.	Hệ thống Backend tự động tính toán tổng định mức nguyên vật liệu (BOM) cần thiết và sinh ra các Mẻ sản xuất (Batches) tương ứng dựa trên Số lượng mẻ.
7.	Hệ thống lưu trữ Lệnh sản xuất với trạng thái ban đầu là "PendingDispensing" (Chờ cấp phát), tự động chuyển thông tin sang phân hệ của bộ phận Kho.
**Các dòng thay thế:**
•	Tại bước 4 và 5: Nếu thông tin nhập vào không hợp lệ (ví dụ: để trống trường bắt buộc, hoặc số mẻ bằng 0), giao diện Web hiển thị lỗi cảnh báo (validation) và từ chối gọi API tạo lệnh.

### BUC 2: Quản lý và Cấp phát Nguyên Vật Liệu
**2. Đặc tả Use-case: Quản lý và Cấp phát Nguyên Vật Liệu**
**Use case nghiệp vụ:** Cấp phát vật tư cho lệnh sản xuất
**Use case bắt đầu khi:** Lệnh sản xuất có trạng thái "PendingDispensing". Nhân viên kho tiến hành cấp phát vật tư từ kho ra xưởng trên Mobile App.
**Các dòng cơ bản:**
1.	Nhân viên Kho (Warehouse Staff) đăng nhập vào Mobile App.
2.	Vào màn hình Cấp phát (Dispensing), chọn một Lệnh sản xuất đang chờ.
3.	Hệ thống hiển thị danh sách nguyên vật liệu cần cấp phát (Order BOM).
4.	Nhân viên Kho chọn lô tồn kho (Inventory Lot) và nhập khối lượng thực tế xuất kho.
5.	Nhân viên Kho nhấn xác nhận, hệ thống gọi API trừ lùi số lượng trong lô tồn kho và cộng dồn vào `DispensedQuantity` của BOM.
6.	Khi tất cả vật tư trong BOM đều đạt 100% định mức, Backend tự động chuyển trạng thái Lệnh sang "InProcess" và các mẻ sang trạng thái "Pending".
**Các dòng thay thế:**
•	Tại bước 4: Nếu khối lượng xuất kho lớn hơn tồn kho hiện tại của lô, Backend trả về lỗi "Insufficient inventory" và từ chối giao dịch.
•	Tại bước 6: Nếu cấp phát chưa đủ 100%, trạng thái Lệnh vẫn giữ là "PendingDispensing".

### BUC 3: Vận hành Sản Xuất Thực Tế (EBR)
**3. Đặc tả Use-case: Vận hành Sản Xuất Thực Tế**
**Use case nghiệp vụ:** Thực hiện các công đoạn sản xuất (Cân, Trộn, Sấy...)
**Use case bắt đầu khi:** Mẻ sản xuất ở trạng thái "Pending" hoặc "Running". Công nhân thao tác trên Mobile App để ghi nhận thông số thực tế theo thời gian thực (Hồ sơ lô điện tử).
**Các dòng cơ bản:**
1.	Công nhân (Operator) đăng nhập vào Mobile App.
2.	Hệ thống hiển thị danh sách Lệnh đang "InProcess". Công nhân chọn mẻ cần làm.
3.	Công nhân thực hiện bước kiểm tra thiết bị/vệ sinh (Pre-check) bằng cách tick chọn xác nhận "Clean/Checked".
4.	Tiến hành vận hành máy và nhập thông số thực tế tại giao diện công đoạn (Cân: khối lượng; Trộn: khối lượng đầu ra; Sấy: bấm đồng hồ đếm lùi mô phỏng, nhập độ ẩm và khối lượng).
5.	Hệ thống so sánh thông số nhập vào với định mức giới hạn (Min/Max). Nếu vi phạm, tự động đánh cờ `IsDeviation = true`.
6.	Công nhân nhập mã PIN để ký điện tử (E-Signature).
7.	Hệ thống gọi API xác thực PIN, lưu log công đoạn và chuyển trạng thái công đoạn sang "Pending QC" (Chờ QC duyệt).
**Các dòng thay thế:**
•	Tại bước 6: Nếu mã PIN sai, API `/api/Auth/verify-pin` trả về false, App hiển thị lỗi yêu cầu nhập lại PIN.

### BUC 4: Kiểm soát và Phê duyệt Chất Lượng (In-process QC)
**4. Đặc tả Use-case: Kiểm soát và Phê duyệt Chất Lượng**
**Use case nghiệp vụ:** Phê duyệt kết quả công đoạn (In-process QC)
**Use case bắt đầu khi:** Công nhân gửi dữ liệu yêu cầu QC phê duyệt (Pending QC).
**Các dòng cơ bản:**
1.	Nhân viên QA/QC đăng nhập vào Mobile App.
2.	Vào tab danh sách các mẻ đang "Pending QC".
3.	Xem chi tiết báo cáo công đoạn (Log Viewer), chú ý các trường bị đánh cờ Deviation (Sai lệch).
4.	QA/QC nhấn "Approve" (Phê duyệt) và nhập mã PIN để ký số.
5.	Hệ thống ghi nhận chữ ký QC, mở khóa (Unlock) công đoạn tiếp theo cho mẻ.
6.	Nếu đây là công đoạn cuối cùng của mẻ, Backend tự động đánh dấu mẻ là "Completed".
**Các dòng thay thế:**
•	Tại bước 4: QA/QC có thể nhấn "Reject" (Từ chối). Trạng thái công đoạn sẽ lùi về lại cho Công nhân thao tác lại, hoặc QC có thể chọn đình chỉ toàn bộ mẻ (Hold).

### BUC 5: Thiết lập và Quản lý Dữ liệu gốc
**5. Đặc tả Use-case: Thiết lập và Quản lý Dữ liệu gốc**
**Use case nghiệp vụ:** Quản lý danh mục và phân quyền hệ thống
**Use case bắt đầu khi:** Admin thiết lập hệ thống Web để khai báo dữ liệu chuẩn (Master Data).
**Các dòng cơ bản:**
1.	Admin đăng nhập vào hệ thống Web.
2.	Truy cập các module danh mục: App Users, Equipments, Materials, Recipes.
3.	Thêm mới hoặc chỉnh sửa dữ liệu.
4.	Nhấn Lưu, Frontend gửi payload qua API.
5.	Backend xác thực tính toàn vẹn (ví dụ: Không trùng username) và lưu vào cơ sở dữ liệu SQL.
**Các dòng thay thế:**
•	Tại bước 5: Nếu dữ liệu vi phạm ràng buộc (Duplicate key, missing fields), Backend trả về HTTP 400 Bad Request, Frontend hiển thị toast thông báo lỗi.

### BUC 6: Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc
**6. Đặc tả Use-case: Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc**
**Use case nghiệp vụ:** Báo cáo và thống kê sản lượng
**Use case bắt đầu khi:** Quản đốc hoặc Cơ quan Thanh tra cần theo dõi tiến độ sản xuất hiện tại hoặc truy xuất hồ sơ điện tử của một lô cụ thể.
**Các dòng cơ bản:**
1.	Manager/Admin đăng nhập vào hệ thống Web.
2.	Vào module "Dashboard" để xem thống kê tổng quan trạng thái Lệnh (Pending, InProcess, Completed) qua biểu đồ.
3.	Vào module "Finished Goods Stats" để xem thống kê sản lượng mẻ hoàn thành.
4.	Vào module "Traceability", nhập mã mẻ (Batch Number) để truy xuất toàn bộ lịch sử (Audit Trail) của mẻ đó.
5.	Hệ thống query các bảng liên kết (Order, Batch, Logs, Material Usages) và render timeline điện tử.
**Các dòng thay thế:**
•	Tại bước 4: Nếu nhập sai mã mẻ, bảng Traceability sẽ trả về kết quả rỗng (No data).

---

## 2.3. Đặc tả Use Case hệ thống (SUC)

Dưới đây là đặc tả chi tiết của **6 SUC cốt lõi** đại diện cho vòng đời khép kín của sản phẩm trên phần mềm:

### 6 SUC Chính (Được mô tả chi tiết)

**1. Quản lý Công thức và Lệnh sản xuất (Web)**
**Tên use case:** Quản lý Công thức và Lệnh sản xuất
**Tóm tắt:** Manager thiết lập Recipe (Gồm BOM và Routing), sau đó tạo Lệnh sản xuất dựa trên Recipe này.
**Tác nhân:** Manager, Admin
**Use case liên quan:** Lập Kế hoạch và Ban hành Lệnh Sản Xuất (BUC 1)
**Dòng sự kiện chính:** 
- Manager đăng nhập Web, mở giao diện "Recipes".
- Tạo Recipe mới: Thêm danh sách nguyên liệu (BOM) và cấu hình các bước công đoạn (Routing như Weighing, Mixing, Drying kèm thông số Min/Max).
- Chuyển sang "Production Orders", bấm "Tạo mới". Chọn Recipe vừa tạo, nhập Số lượng mẻ.
- Bấm "Save". Hệ thống gọi API `POST /api/ProductionOrders`.
- Backend tự động clone BOM và Routing từ Recipe sang Order. Trạng thái Order là `PendingDispensing`.
**Dòng sự kiện phụ:** Nếu Recipe chưa có công đoạn nào (Routing rỗng), hệ thống báo lỗi không cho phép tạo Order.
**Điều kiện tiên quyết:** Đã có tài khoản Manager và danh mục Vật tư đã được khai báo.
**Hậu điều kiện:** Lệnh sản xuất được ghi vào Database, hiển thị sang Mobile App ở tab Cấp phát.

**2. Cấp phát Nguyên vật liệu (Mobile)**
**Tên use case:** Cấp phát Nguyên vật liệu
**Tóm tắt:** Nhân viên kho thực hiện quét/chọn lô vật tư và trừ tồn kho.
**Tác nhân:** Warehouse Staff
**Use case liên quan:** Quản lý và Cấp phát Nguyên Vật Liệu (BUC 2)
**Dòng sự kiện chính:** 
- Nhân viên kho mở Mobile App, vào tab Cấp phát.
- Chọn Lệnh đang chờ. Giao diện tải danh sách định mức cần cấp (`OrderBOMs`).
- Bấm vào một vật tư, chọn Lô trong kho và nhập khối lượng cấp.
- Bấm xác nhận, API `POST /api/MaterialUsages/issue` được gọi.
- Hệ thống trừ tồn kho, cập nhật `% Cấp phát`. Nếu đạt 100%, Lệnh tự động đổi sang `InProcess`.
**Dòng sự kiện phụ:** Nếu nhập lố số lượng tồn trong Lô, API trả lỗi 400.
**Điều kiện tiên quyết:** Kho có tồn lô nguyên liệu hợp lệ.
**Hậu điều kiện:** Số lượng tồn kho vật lý bị trừ trên hệ thống, Lệnh sản xuất sẵn sàng cho công nhân.

**3. Vận hành Công đoạn Cân (Mobile)**
**Tên use case:** Vận hành Công đoạn Cân
**Tóm tắt:** Công nhân thực hiện cân chia nguyên liệu, hệ thống đối chiếu sai số.
**Tác nhân:** Operator
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
- Operator mở Mobile App, chọn Mẻ sản xuất, chọn bước Cân.
- Check "Clean/Checked" cho phòng và cân điện tử.
- Nhập khối lượng thực tế của từng nguyên liệu.
- Ký tên điện tử bằng mã PIN (API `/verify-pin`).
- Hệ thống tạo `BatchProcessLog`. Nếu khối lượng sai lệch vượt Min/Max của công thức, Log bị đánh dấu `IsDeviation = true`. Trạng thái chuyển `Pending QC`.
**Dòng sự kiện phụ:** Mã PIN sai, hệ thống báo "Invalid PIN".
**Điều kiện tiên quyết:** Lệnh đã cấp đủ vật tư, Mẻ đang ở trạng thái Pending/Running.
**Hậu điều kiện:** Log được lưu, công đoạn Cân chờ QC xác nhận.

**4. Vận hành Công đoạn Trộn (Mobile)**
**Tên use case:** Vận hành Công đoạn Trộn
**Tóm tắt:** Công nhân ghi nhận kết quả quá trình trộn vật liệu.
**Tác nhân:** Operator
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
- Operator mở bước Trộn trên Mobile App.
- Xác nhận vệ sinh máy trộn. Bấm nút Bắt đầu (hệ thống lấy Timestamp bắt đầu).
- Kết thúc trộn, nhập Khối lượng đầu ra (Output Quantity).
- Ký mã PIN xác nhận hoàn thành. API tự tính tỷ lệ hao hụt (Yield).
- Hệ thống đẩy Log sang cho QC phê duyệt.
**Dòng sự kiện phụ:** Khối lượng hao hụt quá lớn, hệ thống tự cắm cờ Deviation.
**Điều kiện tiên quyết:** Bước Cân đã được QC duyệt (Approved).
**Hậu điều kiện:** Dữ liệu Trộn được đóng băng chờ QC.

**5. Vận hành Công đoạn Sấy (Mobile)**
**Tên use case:** Vận hành Công đoạn Sấy
**Tóm tắt:** Công nhân ghi nhận nhiệt độ, độ ẩm sau quá trình sấy tủ.
**Tác nhân:** Operator
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
- Operator mở bước Sấy. Xác nhận vệ sinh tủ sấy.
- Bấm bắt đầu sấy. Giao diện chạy bộ đếm thời gian lùi (Timer mô phỏng quá trình sấy).
- Sau khi Timer chạy hết, màn hình mở khóa ô nhập liệu.
- Operator nhập: Độ ẩm thực tế, Khối lượng đầu ra.
- Ký PIN và hoàn tất.
**Dòng sự kiện phụ:** Nếu đóng App khi Timer đang chạy và mở lại, App vẫn duy trì bộ đếm hoặc mở khóa nếu đã hết giờ.
**Điều kiện tiên quyết:** Bước Trộn đã được QC duyệt.
**Hậu điều kiện:** Log công đoạn Sấy được tạo, chờ QC kiểm tra độ ẩm.

**6. Phê duyệt Công đoạn (Mobile)**
**Tên use case:** Phê duyệt Công đoạn (In-process QC)
**Tóm tắt:** Nhân viên QC đối chiếu số liệu và phê duyệt chữ ký số.
**Tác nhân:** QA_QC
**Use case liên quan:** Kiểm soát và Phê duyệt Chất Lượng (BUC 4)
**Dòng sự kiện chính:** 
- QA/QC đăng nhập Mobile App, vào tab "Pending QC".
- Chọn log công đoạn do Operator vừa gửi.
- Rà soát các chỉ số (hiển thị màu đỏ nếu có Deviation).
- Nhấn "Approve" (hoặc "Reject") -> Nhập mã PIN.
- API cập nhật Log. Nếu Approve, bước tiếp theo được Unlock. Nếu là bước cuối cùng, Mẻ cập nhật thành `Completed`.
**Dòng sự kiện phụ:** Nếu QC chọn Reject, công đoạn bị trả lại trạng thái cho Operator xử lý.
**Điều kiện tiên quyết:** Có log công đoạn đang chờ duyệt.
**Hậu điều kiện:** Công đoạn được xác nhận hợp lệ theo chuẩn GMP hoặc bị từ chối.

---

### Danh sách các SUC Phụ (Để vẽ Sơ đồ Use Case tổng thể)
Các SUC này tồn tại độc lập hoặc hỗ trợ cho 6 SUC cốt lõi trên, phục vụ hoàn thiện hệ thống nhưng không đi sâu vào chi tiết vận hành sản xuất:
1. **SUC Đăng nhập & Xác thực** (Web/Mobile - Gọi API cấp JWT Token).
2. **SUC Quản lý Người dùng và Phân quyền** (Web - Role mapping: Admin, Manager, QA_QC, Operator, Warehouse).
3. **SUC Quản lý Danh mục Thiết bị & Khu vực** (Web - CRUD Equipments, Production Areas).
4. **SUC Quản lý Danh mục Nguyên vật liệu** (Web - CRUD Materials, UOM, quy đổi UOM).
5. **SUC Quản lý Tồn kho** (Web - CRUD Inventory Lots nhập kho).
6. **SUC Xem Báo cáo Tiến độ Lệnh sản xuất** (Web - Dashboard In-Process/Hold).
7. **SUC Thống kê Sản lượng Thành phẩm** (Web - Finished Goods Stats).
8. **SUC Truy xuất Nguồn gốc Lô** (Web - Traceability Audit Trail).
9. **SUC Tra cứu Lệnh/Mẻ sản xuất** (Mobile - Search, View details).
10. **SUC Quản lý Cảnh báo & Sai lệch** (Web - Theo dõi các cờ Deviation sinh ra trong hệ thống).
