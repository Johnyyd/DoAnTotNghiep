# Phân tích BUC và SUC - Hệ thống Quản lý Sản xuất GMP

Dựa trên việc rà soát toàn bộ Codebase (Backend C# .NET Core & Frontend Flutter), dưới đây là bản phân tích chi tiết về **BUC (Business Use Case)** và **SUC (System Use Case)** được trình bày theo định dạng chuẩn đặc tả:

---

## 2.2. Mô hình hóa quy trình nghiệp vụ (Business Use Cases - BUC)

### BUC 1: Lập Kế hoạch và Ban hành Lệnh Sản Xuất
**1. Đặc tả Use-case: Lập Kế hoạch và Ban hành Lệnh Sản Xuất**
**Use case nghiệp vụ:** Lập Kế hoạch và Ban hành Lệnh Sản Xuất
**Use case bắt đầu khi:** Quản đốc tiếp nhận yêu cầu sản xuất và bắt đầu thiết lập thông tin để ban hành Lệnh sản xuất xuống xưởng. Mục tiêu nhằm đảm bảo số lượng, công thức, định mức vật tư và Quy trình công đoạn (Routing) sản xuất rõ ràng.
**Các dòng cơ bản:**
1.	Quản đốc đăng nhập vào hệ thống quản lý (Web/Admin).
2.	Hệ thống hiển thị danh sách công thức sản xuất hiện có.
3.	Quản đốc lựa chọn công thức, thiết lập cỡ lô và số lượng mẻ cần sản xuất.
4.	Hệ thống tự động tính toán dự trù nguyên vật liệu (BOM) cần thiết cho lệnh.
5.	Quản đốc xác nhận và ban hành Lệnh sản xuất theo đúng Quy trình công đoạn (Routing).
6.	Hệ thống lưu trạng thái lệnh và tự động chuyển thông báo đến bộ phận Kho.
**Các dòng thay thế:**
•	Tại bước 4: Nếu nguyên vật liệu trong kho không đủ theo dự trù, hệ thống cảnh báo "Thiếu vật tư" nhưng vẫn cho phép lưu nháp hoặc yêu cầu giảm cỡ lô tương ứng.

### BUC 2: Quản lý và Cấp phát Nguyên Vật Liệu
**2. Đặc tả Use-case: Quản lý và Cấp phát Nguyên Vật Liệu**
**Use case nghiệp vụ:** Cấp phát vật tư cho lệnh sản xuất
**Use case bắt đầu khi:** Lệnh sản xuất được ban hành và chuyển trạng thái sang "Chờ cấp phát". Mục tiêu nhằm đảm bảo số lượng nguyên vật liệu được cấp đúng và đủ theo định mức BOM.
**Các dòng cơ bản:**
1.	Nhân viên Kho đăng nhập hệ thống và xem danh sách lệnh đang "Chờ cấp phát".
2.	Hệ thống hiển thị chi tiết số lượng nguyên vật liệu cần xuất (Required Quantity) theo BOM.
3.	Nhân viên Kho tiến hành soạn hàng và xác nhận số lượng thực tế đã cấp phát.
4.	Hệ thống tự động trừ tồn kho tương ứng và cập nhật trạng thái cấp phát.
5.	Nếu nguyên vật liệu được cấp đủ 100%, hệ thống tự động chuyển trạng thái Lệnh sang "Chờ công nhân".
**Các dòng thay thế:**
•	Tại bước 3: Nếu nhân viên Kho cấp phát thiếu (chưa đủ 100%), hệ thống vẫn cho phép lưu tiến độ hiện tại, Lệnh sản xuất giữ nguyên trạng thái "Chờ cấp phát" cho đến khi xuất đủ vật tư.

### BUC 3: Vận hành Sản Xuất Thực Tế (EBR)
**3. Đặc tả Use-case: Vận hành Sản Xuất Thực Tế**
**Use case nghiệp vụ:** Thực hiện các công đoạn sản xuất (Cân, Trộn, Sấy...)
**Use case bắt đầu khi:** Nguyên vật liệu đã được cấp đủ và Công nhân bắt đầu thao tác trên dây chuyền theo các công đoạn chuẩn. Mục tiêu nhằm ghi nhận toàn bộ thông số theo thời gian thực để hình thành Hồ sơ lô điện tử (EBR).
**Các dòng cơ bản:**
1.	Công nhân vận hành đăng nhập vào ứng dụng Mobile.
2.	Hệ thống hiển thị danh sách Lệnh và Mẻ đang ở trạng thái "Chờ công nhân".
3.	Công nhân chọn một mẻ và bắt đầu công đoạn đầu tiên.
4.	Công nhân kiểm tra điều kiện vệ sinh, thiết bị và xác nhận trạng thái "Sạch".
5.	Công nhân tiến hành vận hành máy và nhập thông số thực tế (nhiệt độ, độ ẩm, khối lượng...).
6.	Công nhân nhập mã PIN để ký điện tử xác nhận hoàn thành công đoạn.
7.	Hệ thống lưu Hồ sơ lô an toàn và chuyển trạng thái mẻ sang "Chờ QC xét duyệt".
**Các dòng thay thế:**
•	Tại bước 4: Nếu kiểm tra vệ sinh không đạt, hệ thống yêu cầu xử lý lại và ghi chú lý do trước khi cho phép tiến hành vận hành.
•	Tại bước 6: Nếu mã PIN sai, hệ thống từ chối ghi nhận chữ ký và yêu cầu nhập lại.

### BUC 4: Kiểm soát và Phê duyệt Chất Lượng (In-process QC)
**4. Đặc tả Use-case: Kiểm soát và Phê duyệt Chất Lượng**
**Use case nghiệp vụ:** Phê duyệt kết quả công đoạn (In-process QC)
**Use case bắt đầu khi:** Công nhân hoàn thành một công đoạn và gửi dữ liệu yêu cầu QC phê duyệt. Mục tiêu nhằm đảm bảo chất lượng bán thành phẩm đạt chuẩn GMP trước khi qua bước tiếp theo.
**Các dòng cơ bản:**
1.	Nhân viên QA/QC đăng nhập vào ứng dụng Mobile.
2.	Hệ thống hiển thị danh sách các mẻ đang "Chờ QC xét duyệt".
3.	QA/QC xem chi tiết các thông số vận hành mà Công nhân đã nhập ở công đoạn trước.
4.	QA/QC tiến hành đối chiếu thông số thực tế với tiêu chuẩn GMP.
5.	QA/QC phê duyệt (Approve) và nhập mã PIN để ký điện tử.
6.	Hệ thống chốt dữ liệu công đoạn và mở khóa (unlock) cho phép công nhân làm công đoạn kế tiếp.
**Các dòng thay thế:**
•	Tại bước 4 và 5: Nếu thông số không đạt hoặc có sai lệch (Deviation), QA/QC chọn Từ chối (Reject) và ghi chú lý do. Hệ thống trả trạng thái mẻ về lại cho Công nhân để tiến hành xử lý/sửa chữa.

### BUC 5: Thiết lập và Quản lý Dữ liệu gốc
**5. Đặc tả Use-case: Thiết lập và Quản lý Dữ liệu gốc**
**Use case nghiệp vụ:** Quản lý danh mục và phân quyền hệ thống
**Use case bắt đầu khi:** Quản trị viên (Admin) thiết lập hệ thống để đưa vào sử dụng. Mục tiêu nhằm cung cấp nền tảng Master Data (dữ liệu tiêu chuẩn) phục vụ cho mọi hoạt động sản xuất nhất quán và có thể truy xuất.
**Các dòng cơ bản:**
1.	Admin đăng nhập vào hệ thống Quản trị.
2.	Hệ thống hiển thị các chức năng quản lý danh mục (Thiết bị, Khu vực, Đơn vị tính, Nguyên liệu, Người dùng).
3.	Admin nhập thông tin mới hoặc cập nhật dữ liệu gốc (ví dụ: Thêm nguyên liệu, Tạo tài khoản, Phân quyền Role).
4.	Hệ thống kiểm tra tính hợp lệ của dữ liệu đầu vào.
5.	Hệ thống lưu trữ dữ liệu gốc và cập nhật các liên kết tham chiếu trong toàn bộ hệ thống.
**Các dòng thay thế:**
•	Tại bước 4: Nếu dữ liệu bị thiếu hoặc trùng lặp (ví dụ: Trùng mã nguyên liệu, trùng tên đăng nhập), hệ thống báo lỗi đỏ và yêu cầu Admin sửa lại trước khi lưu.

### BUC 6: Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc
**6. Đặc tả Use-case: Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc**
**Use case nghiệp vụ:** Báo cáo tiến độ và Thống kê thành phẩm.
**Use case bắt đầu khi:** Quản đốc hoặc Cơ quan Thanh tra cần kiểm tra trạng thái sản xuất hiện tại, hoặc thống kê sản lượng thành phẩm cuối kỳ.
**Các dòng cơ bản:**
1.	Manager/Admin đăng nhập vào hệ thống Web.
2.	Hệ thống hiển thị Dashboard báo cáo tiến độ sản xuất theo thời gian thực (Lệnh nào đang In-Process, Hold, Completed).
3.	Manager truy cập module Thống kê thành phẩm để xem số lượng lô thuốc đã hoàn thiện.
4.	Trên ứng dụng Mobile, Operator/QC sử dụng chức năng Tra cứu để tìm kiếm nhanh thông tin Lệnh sản xuất và các mẻ đang vận hành.
5.	Hệ thống trích xuất Hồ sơ lô điện tử (EBR) để phục vụ việc truy xuất nguồn gốc khi có yêu cầu từ Auditor.
**Các dòng thay thế:**
•	Tại bước 4: Nếu thông tin tra cứu không tồn tại, hệ thống báo lỗi không tìm thấy Lệnh/Mẻ.

---

## 2.3. Đặc tả Use Case hệ thống (SUC)

Dưới đây là đặc tả chi tiết của một số SUC tiêu biểu đại diện cho các tính năng thực thi trong hệ thống phần mềm:

**1. Tạo Lệnh Sản Xuất**
**Tên use case:** Tạo Lệnh Sản Xuất
**Tóm tắt:** Quản đốc tạo Lệnh sản xuất mới dựa trên công thức, thiết lập định mức nguyên vật liệu (BOM) và xác định rõ quy trình công đoạn (Routing) để chuẩn bị kế hoạch sản xuất thực tế tại xưởng.
**Tác nhân:** Quản lý / Quản đốc (Manager)
**Use case liên quan:** Lập Kế hoạch và Ban hành Lệnh Sản Xuất (BUC 1)
**Dòng sự kiện chính:** 
-	Quản đốc đăng nhập hệ thống Web/Admin.
-	Chọn chức năng "Tạo Lệnh Sản Xuất" và chọn một công thức (Recipe) từ danh sách thả xuống, kèm theo Quy trình công đoạn (Routing) tương ứng.
-	Nhập số lượng lô (cỡ lô) mong muốn và số lượng mẻ.
-	Hệ thống tự động tính toán và hiển thị danh sách nguyên vật liệu cần thiết (Order BOM).
-	Quản đốc nhấn "Lưu và Ban hành".
-	Hệ thống lưu trữ Lệnh sản xuất và chuyển trạng thái sang "Chờ cấp phát".
**Dòng sự kiện phụ:** Nếu hệ thống tính toán thấy kho không còn đủ số lượng nguyên liệu, hệ thống đưa ra cảnh báo "Thiếu vật tư" nhưng vẫn cho phép lưu nháp để chờ nhập kho.
**Điều kiện tiên quyết:** Các dữ liệu gốc (Công thức, Nguyên liệu, Quy trình công đoạn) đã được thiết lập.
**Hậu điều kiện:** Lệnh sản xuất được tạo thành công, có đầy đủ BOM, Routing và xuất hiện ở phân hệ màn hình của nhân viên Kho.

**2. Cấp phát Nguyên vật liệu**
**Tên use case:** Cấp phát Nguyên vật liệu
**Tóm tắt:** Nhân viên Kho thực hiện quy trình trừ lùi tồn kho và xuất nguyên vật liệu cho một lệnh sản xuất cụ thể.
**Tác nhân:** Nhân viên Kho (Warehouse Staff)
**Use case liên quan:** Quản lý Lệnh Sản Xuất (BUC 2)
**Dòng sự kiện chính:** 
-	Nhân viên Kho đăng nhập hệ thống trên Mobile/Web.
-	Mở danh sách các Lệnh sản xuất "Chờ cấp phát".
-	Chọn một lệnh và xem danh sách định mức BOM yêu cầu.
-	Chọn từng nguyên liệu, nhập số lượng xuất kho thực tế từ các lô (Inventory Lot) đang khả dụng trong kho.
-	Nhấn "Xác nhận cấp phát".
-	Hệ thống trừ tồn kho tương ứng và lưu lịch sử cấp phát của lô đó.
**Dòng sự kiện phụ:** Hệ thống tự động tính tổng phần trăm cấp phát vật tư. Ngay khi đạt 100%, hệ thống tự động đổi trạng thái lệnh sang "Chờ công nhân".
**Điều kiện tiên quyết:** Có Lệnh sản xuất đang ở trạng thái "Chờ cấp phát" và trong kho có lô vật tư khả dụng.
**Hậu điều kiện:** Số lượng tồn kho giảm tương ứng và vật tư được ghi nhận cho Lệnh sản xuất đó.

**3. Vận hành Công đoạn Cân**
**Tên use case:** Vận hành Công đoạn Cân
**Tóm tắt:** Công nhân thực hiện quá trình cân chia nguyên liệu theo định mức, nhập các thông số khối lượng thực tế và ký tên điện tử hoàn tất.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
-	Công nhân đăng nhập vào ứng dụng Mobile.
-	Mở Lệnh sản xuất và chọn mẻ cần thao tác.
-	Thực hiện bước kiểm tra điều kiện vệ sinh phòng/cân (Pre-check) và nhấn "Tiếp tục".
-	Mở giao diện Cân nguyên liệu, hệ thống hiển thị danh sách các nguyên liệu cần cân từ BOM.
-	Tiến hành cân nguyên liệu thực tế và nhập giá trị khối lượng vào phần mềm.
-	Công nhân nhập mã PIN để ký điện tử xác nhận hoàn tất việc cân.
-	Hệ thống lưu trữ dữ liệu khối lượng và chuyển trạng thái công đoạn sang "Chờ QC xét duyệt".
**Dòng sự kiện phụ:** Nếu khối lượng nhập vào không nằm trong giới hạn sai số (±5%) của công thức, hệ thống tự động cảnh báo đỏ và ghi nhận sai lệch (Deviation).
**Điều kiện tiên quyết:** Nguyên vật liệu đã được cấp phát đầy đủ từ kho.
**Hậu điều kiện:** Công đoạn Cân hoàn thành, dữ liệu chờ QC đánh giá.

**4. Vận hành Công đoạn Trộn**
**Tên use case:** Vận hành Công đoạn Trộn
**Tóm tắt:** Công nhân thực hiện quá trình trộn nguyên liệu, nhập các thông số thực tế và ký tên điện tử hoàn tất.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
-	Công nhân đăng nhập vào ứng dụng Mobile.
-	Mở Lệnh sản xuất và chọn mẻ cần trộn.
-	Thực hiện bước kiểm tra phòng/máy móc (Pre-check) và nhấn "Tiếp tục".
-	Khởi động công đoạn Trộn, hệ thống ghi nhận chính xác thời gian bắt đầu (Timestamp).
-	Sau khi trộn xong theo thời gian quy định, công nhân nhập khối lượng đầu ra (Output) thực tế.
-	Hệ thống tự động tính toán Hiệu suất (Yield) tức thời.
-	Công nhân nhập mã PIN để ký điện tử xác nhận hoàn tất.
-	Hệ thống chốt dữ liệu, lưu trữ log công đoạn và chuyển trạng thái mẻ sang "Chờ QC xét duyệt".
**Dòng sự kiện phụ:** Nếu khối lượng hao hụt làm hiệu suất vượt quá mức sai số quy định của chuẩn GMP, hệ thống bôi đỏ chỉ số và tự động đánh dấu đây là một sự cố sai lệch (Deviation) khi đẩy thông báo cho QC.
**Điều kiện tiên quyết:** Công đoạn trước đó (Cân) đã hoàn tất và được QC phê duyệt đạt.
**Hậu điều kiện:** Hồ sơ công đoạn Trộn được ghi lại, giao diện chuyển trạng thái sang chờ đánh giá QC.

**5. Vận hành Công đoạn Sấy**
**Tên use case:** Vận hành Công đoạn Sấy
**Tóm tắt:** Công nhân thao tác đưa bán thành phẩm vào tủ sấy, ghi nhận thời gian và kết quả độ ẩm đạt được.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Vận hành Sản Xuất Thực Tế (BUC 3)
**Dòng sự kiện chính:** 
-	Công nhân mở công đoạn Sấy trên ứng dụng Mobile.
-	Hoàn thành bước kiểm tra điều kiện vệ sinh đầu vào của tủ sấy.
-	Bấm xác nhận bắt đầu sấy, hệ thống ghi nhận thời điểm bắt đầu.
-	Sau khi hoàn tất thời gian sấy quy định, công nhân dừng máy và tiến hành đo lường.
-	Công nhân nhập các thông số thực tế: Độ ẩm, Nhiệt độ sấy, Khối lượng đầu ra.
-	Nhập mã PIN xác thực và gửi yêu cầu cho QC.
**Dòng sự kiện phụ:** Nếu độ ẩm vượt quá mức cho phép của tiêu chuẩn, hệ thống cảnh báo và có thể yêu cầu sấy thêm.
**Điều kiện tiên quyết:** Công đoạn Trộn trước đó đã hoàn tất và được QC duyệt.
**Hậu điều kiện:** Công đoạn Sấy kết thúc, mẻ được chuyển trạng thái sang chờ QC đánh giá độ ẩm.

**6. Phê duyệt Công đoạn (In-process QC)**
**Tên use case:** Phê duyệt Công đoạn (In-process QC)
**Tóm tắt:** Nhân viên QC tiến hành thẩm định dữ liệu công nhân vừa nhập và quyết định cho phép mẻ làm tiếp hay bắt buộc phải xử lý lại.
**Tác nhân:** Nhân viên Đảm bảo chất lượng (QA_QC)
**Use case liên quan:** Kiểm soát và Phê duyệt Chất Lượng (BUC 4)
**Dòng sự kiện chính:** 
-	QA/QC đăng nhập vào ứng dụng Mobile và mở tab "Chờ QC xét duyệt".
-	Chọn một mẻ sản xuất và xem báo cáo điện tử chi tiết của công đoạn vừa hoàn thành.
-	Đánh giá và đối chiếu thông số (Ví dụ: Khối lượng đầu ra, Hiệu suất, Độ ẩm sau sấy) với khung quy chuẩn.
-	Nếu đạt, nhấn nút "QC KÝ XÁC NHẬN" (Approve).
-	Nhập mã PIN để đính kèm chữ ký điện tử.
-	Hệ thống chốt hồ sơ vĩnh viễn và mở khóa chức năng công đoạn tiếp theo cho Công nhân. Khi công đoạn cuối cùng của mẻ được QC duyệt đạt, hệ thống tự động cập nhật trạng thái lệnh thành Completed và sinh ra dữ liệu Lô thành phẩm. Nếu QC đình chỉ mẻ, trạng thái cập nhật thành Hold.
**Dòng sự kiện phụ:** Nếu các thông số vi phạm tiêu chuẩn (Deviation) hoặc phát hiện sai phạm, hệ thống làm nổi bật bằng cảnh báo đỏ. QC nhấn nút "Từ chối" (Reject) để trả lại trạng thái cho Công nhân tiến hành xử lý lại (vd: Sấy thêm thời gian).
**Điều kiện tiên quyết:** Có ít nhất một mẻ sản xuất do Công nhân gửi lên và đang ở trạng thái chờ xét duyệt.
**Hậu điều kiện:** Trạng thái công đoạn chuyển dứt điểm sang "Hoàn thành" hoặc "Bị từ chối làm lại". Lệnh có thể chuyển sang Completed hoặc Hold.

**7. Tra cứu Lệnh và Mẻ Sản xuất (Mobile)**
**Tên use case:** Tra cứu Lệnh và Mẻ Sản xuất (Mobile)
**Tóm tắt:** Người dùng sử dụng thanh tìm kiếm hoặc quét mã QR trên Mobile App để truy xuất nhanh thông tin, trạng thái của một lệnh hoặc mẻ cụ thể.
**Tác nhân:** Công nhân (Operator), Nhân viên QA/QC (QA_QC), Quản đốc (Manager)
**Use case liên quan:** Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc (BUC 6)
**Dòng sự kiện chính:** 
-	Người dùng nhập mã lệnh/mẻ hoặc quét mã QR trên Mobile App.
-	Hệ thống trả về thông tin chi tiết bao gồm: định mức (BOM), quy trình công đoạn (Routing) và trạng thái hiện tại.
**Dòng sự kiện phụ:** Nếu dữ liệu không hợp lệ hoặc không tồn tại, hiển thị thông báo "Không tìm thấy kết quả".
**Điều kiện tiên quyết:** Người dùng có tài khoản hợp lệ trên Mobile App.
**Hậu điều kiện:** Thông tin Lệnh/Mẻ được truy xuất và hiển thị chính xác.

**8. Xem Báo cáo Tiến độ Sản xuất (Web)**
**Tên use case:** Xem Báo cáo Tiến độ Sản xuất
**Tóm tắt:** Hiển thị biểu đồ và thông tin tổng quan về các Lệnh sản xuất đang trong quá trình thực thi, giúp nhà quản lý nắm bắt nhanh các điểm nghẽn.
**Tác nhân:** Quản lý / Quản đốc (Manager), Admin
**Use case liên quan:** Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc (BUC 6)
**Dòng sự kiện chính:** 
-	Manager hoặc Admin đăng nhập vào hệ thống Web.
-	Truy cập vào module Báo cáo tiến độ.
-	Hệ thống tải dữ liệu thời gian thực và hiển thị biểu đồ trạng thái của các Lệnh sản xuất.
-	Người dùng tập trung theo dõi các Lệnh đang ở trạng thái In-Process (Đang thực hiện) hoặc Hold (Bị đình chỉ).
**Dòng sự kiện phụ:** Người dùng có thể nhấp vào một vùng trên biểu đồ để xem chi tiết danh sách các Lệnh thuộc trạng thái đó.
**Điều kiện tiên quyết:** Có dữ liệu Lệnh sản xuất đang vận hành trong hệ thống.
**Hậu điều kiện:** Giao diện hiển thị trực quan tỷ lệ các Lệnh đang chạy hoặc đang bị gián đoạn.

**9. Thống kê Lô thành phẩm (Web)**
**Tên use case:** Thống kê Lô thành phẩm
**Tóm tắt:** Thống kê số lượng mẻ, lệnh đã hoàn tất và quy đổi thành sản lượng lô thành phẩm thực tế để đánh giá năng suất.
**Tác nhân:** Quản lý / Quản đốc (Manager), Admin
**Use case liên quan:** Theo dõi Tiến độ, Thống kê và Truy xuất nguồn gốc (BUC 6)
**Dòng sự kiện chính:** 
-	Manager hoặc Admin đăng nhập vào hệ thống Web.
-	Truy cập vào module Thống kê thành phẩm.
-	Hệ thống tải dữ liệu tổng hợp về các mẻ và Lệnh sản xuất đã đạt trạng thái Completed (Hoàn thành).
-	Người dùng xem tổng số lượng lô thuốc thành phẩm đã được sản xuất và nhập kho thành công.
**Dòng sự kiện phụ:** Có thể sử dụng các bộ lọc theo khoảng thời gian (ngày/tuần/tháng) hoặc theo từng sản phẩm cụ thể để thống kê chi tiết hơn.
**Điều kiện tiên quyết:** Có ít nhất một Lệnh sản xuất đã chuyển sang trạng thái Completed.
**Hậu điều kiện:** Hiển thị báo cáo và bảng số liệu thống kê sản lượng thành phẩm đầu ra chính xác.
