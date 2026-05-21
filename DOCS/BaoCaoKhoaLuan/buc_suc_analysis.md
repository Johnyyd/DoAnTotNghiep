# Phân tích BUC và SUC - Hệ thống Quản lý Sản xuất GMP

## 2.2. Mô hình hóa quy trình nghiệp vụ (Business Use Cases - BUC)

### BUC 1: Lập lệnh sản xuất
**Use case nghiệp vụ:** Lập lệnh sản xuất
**Use case bắt đầu khi:** Quản lý tiến hành thiết lập thông tin và khởi tạo một lệnh sản xuất mới dựa trên công thức có sẵn. Mục tiêu của use case là ban hành lệnh sản xuất với đầy đủ thông số và định mức nguyên vật liệu để triển khai xuống xưởng.
**Các bước cơ bản:**
1. Quản lý đăng nhập vào hệ thống quản trị.
2. Quản lý truy cập chức năng lập lệnh sản xuất.
3. Quản lý chọn công thức sản phẩm, nhập ngày bắt đầu dự kiến và số lượng mẻ cần sản xuất.
4. Quản lý lưu thông tin để hệ thống tạo lệnh.
5. Hệ thống tính toán định mức nguyên vật liệu cần thiết và chuyển thông tin lệnh sản xuất sang bộ phận kho để chuẩn bị.
**Các dòng thay thế:**
Tại bước 4: Nếu có sai sót hoặc thiếu thông tin khi lập lệnh, hệ thống sẽ cảnh báo để quản lý kiểm tra lại và chỉnh sửa cho phù hợp.

### BUC 2: Quản lý và cấp phát nguyên vật liệu
**Use case nghiệp vụ:** Quản lý và cấp phát nguyên vật liệu
**Use case bắt đầu khi:** Nhân viên kho tiến hành xuất kho nguyên vật liệu theo yêu cầu của lệnh sản xuất. Mục tiêu của use case là đảm bảo cấp phát đúng và đủ vật tư theo định mức để bắt đầu sản xuất.
**Các bước cơ bản:**
1. Nhân viên kho đăng nhập vào hệ thống.
2. Nhân viên kho xem danh sách lệnh sản xuất đang chờ cấp phát và định mức vật tư yêu cầu.
3. Nhân viên kho chọn lô vật tư trong kho và nhập khối lượng cấp phát thực tế.
4. Nhân viên kho xác nhận cấp phát, hệ thống ghi nhận số lượng và trừ tồn kho.
5. Khi cấp phát đủ vật tư, hệ thống chuyển trạng thái lệnh sản xuất để xưởng bắt đầu vận hành.
**Các dòng thay thế:**
Tại bước 3: Nếu khối lượng vật tư trong kho không đủ, nhân viên kho sẽ tạm ngưng cấp phát và chờ nhập thêm vật tư để hoàn tất.

### BUC 3: Vận hành sản xuất thực tế
**Use case nghiệp vụ:** Vận hành sản xuất thực tế
**Use case bắt đầu khi:** Người thực hiện tiến hành các công đoạn sản xuất như cân, trộn, sấy theo lệnh đã được cấp vật tư. Mục tiêu của use case là ghi nhận thông số vận hành thực tế một cách chính xác vào hồ sơ lô.
**Các bước cơ bản:**
1. Người thực hiện đăng nhập vào hệ thống.
2. Người thực hiện chọn mẻ sản xuất và công đoạn cần làm.
3. Người thực hiện kiểm tra điều kiện vệ sinh, thiết bị và xác nhận trên hệ thống.
4. Người thực hiện thao tác máy móc và nhập các thông số thực tế (khối lượng, độ ẩm, nhiệt độ...) vào hệ thống.
5. Người thực hiện ký xác nhận điện tử hoàn thành công đoạn.
6. Hệ thống lưu thông tin và thông báo đến người kiểm tra chất lượng.
**Các dòng thay thế:**
Tại bước 5: Nếu chữ ký điện tử hoặc mã xác thực không đúng, người thực hiện sẽ phải nhập lại mã để hoàn tất.

### BUC 4: Kiểm soát và phê duyệt chất lượng
**Use case nghiệp vụ:** Kiểm soát và phê duyệt chất lượng
**Use case bắt đầu khi:** Người kiểm tra tiến hành đánh giá dữ liệu vận hành của các công đoạn sản xuất. Mục tiêu của use case là đảm bảo chất lượng bán thành phẩm đạt chuẩn trước khi thực hiện bước tiếp theo.
**Các bước cơ bản:**
1. Người kiểm tra đăng nhập vào hệ thống.
2. Người kiểm tra xem danh sách các công đoạn đang chờ phê duyệt.
3. Người kiểm tra đối chiếu các thông số thực tế do người thực hiện nhập với tiêu chuẩn quy định.
4. Người kiểm tra ký xác nhận phê duyệt dữ liệu.
5. Hệ thống lưu kết quả phê duyệt và cho phép thực hiện công đoạn tiếp theo hoặc hoàn thành mẻ.
**Các dòng thay thế:**
Tại bước 4: Nếu thông số không đạt chuẩn, người kiểm tra sẽ từ chối phê duyệt và yêu cầu người thực hiện kiểm tra lại hoặc xử lý lại mẻ sản xuất.

### BUC 5: Thiết lập và quản lý dữ liệu gốc
**Use case nghiệp vụ:** Thiết lập và quản lý dữ liệu gốc
**Use case bắt đầu khi:** Quản trị viên tiến hành khai báo các dữ liệu nền tảng cho hệ thống. Mục tiêu của use case là tạo lập cơ sở dữ liệu chuẩn (danh mục vật tư, thiết bị, người dùng) để hệ thống hoạt động đồng bộ.
**Các bước cơ bản:**
1. Quản trị viên đăng nhập vào hệ thống quản trị.
2. Quản trị viên truy cập các chức năng quản lý danh mục.
3. Quản trị viên thêm mới, cập nhật thông tin về người dùng, thiết bị, công thức và nguyên vật liệu.
4. Quản trị viên lưu dữ liệu vào hệ thống.
**Các dòng thay thế:**
Tại bước 4: Nếu thông tin bị trùng lặp hoặc không hợp lệ, hệ thống sẽ cảnh báo để quản trị viên kiểm tra lại và chỉnh sửa cho phù hợp.

### BUC 6: Theo dõi tiến độ và thống kê
**Use case nghiệp vụ:** Theo dõi tiến độ và thống kê
**Use case bắt đầu khi:** Quản lý tiến hành tổng hợp và xem xét tình trạng của các lệnh sản xuất. Mục tiêu của use case là cung cấp cái nhìn tổng quan về tiến độ và sản lượng thành phẩm để đánh giá hiệu quả sản xuất.
**Các bước cơ bản:**
1. Quản lý đăng nhập vào hệ thống.
2. Quản lý truy cập màn hình báo cáo tiến độ và thống kê.
3. Quản lý xem biểu đồ thống kê các lệnh đang sản xuất và các lệnh đã hoàn thành.
4. Quản lý tra cứu lịch sử chi tiết của một mẻ sản xuất bất kỳ để truy xuất nguồn gốc.
**Các dòng thay thế:**
Tại bước 4: Nếu mã tra cứu không tồn tại, hệ thống sẽ thông báo không tìm thấy dữ liệu để quản lý kiểm tra lại mã mẻ.

---

## 2.3. Đặc tả Use Case hệ thống (SUC)

### 6 SUC Chính

**1. Quản lý công thức và lệnh sản xuất**
**Tên use case** Quản lý công thức và lệnh sản xuất
**Tóm tắt** Quản lý thiết lập công thức sản xuất, định mức vật tư và tạo lệnh sản xuất mới, chuyển thông tin đến kho để chuẩn bị.
**Tác nhân** Quản lý
**Use case liên quan** Cấp phát nguyên vật liệu
**Dòng sự kiện chính** Quản lý đăng nhập vào hệ thống.
Truy cập chức năng tạo lệnh sản xuất.
Chọn công thức và nhập số lượng mẻ cần sản xuất.
Lưu thông tin tạo lệnh.
Hệ thống tính toán định mức vật tư, lưu lệnh sản xuất và thông báo đến nhân viên kho.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu thông tin lệnh sản xuất nhập vào bị thiếu hoặc không hợp lệ.
**Điều kiện tiên quyết** Danh mục công thức và vật tư đã được khai báo trên hệ thống.
**Hậu điều kiện** Thông tin lệnh sản xuất được lưu và chuyển tiếp đến tác nhân kho.

**2. Cấp phát nguyên vật liệu**
**Tên use case** Cấp phát nguyên vật liệu
**Tóm tắt** Nhân viên kho kiểm tra yêu cầu từ lệnh sản xuất, thực hiện xuất vật tư và ghi nhận khối lượng vào hệ thống.
**Tác nhân** Nhân viên kho
**Use case liên quan** Quản lý công thức và lệnh sản xuất, Vận hành công đoạn cân
**Dòng sự kiện chính** Nhân viên kho đăng nhập vào hệ thống.
Chọn lệnh sản xuất đang chờ cấp phát từ danh sách.
Chọn lô vật tư và nhập khối lượng cấp phát thực tế.
Xác nhận cấp phát vật tư.
Hệ thống lưu thông tin, trừ tồn kho và cập nhật trạng thái lệnh sản xuất khi đủ vật tư.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu khối lượng cấp phát vượt quá số lượng tồn kho hiện tại.
**Điều kiện tiên quyết** Lệnh sản xuất đã được tạo và vật tư có sẵn trong kho.
**Hậu điều kiện** Thông tin cấp phát được lưu và lệnh sản xuất sẵn sàng để vận hành.

**3. Vận hành công đoạn cân**
**Tên use case** Vận hành công đoạn cân
**Tóm tắt** Người thực hiện tiến hành cân nguyên liệu thô theo định mức, nhập khối lượng vào hệ thống và chuyển dữ liệu cho người kiểm tra xác nhận.
**Tác nhân** Người thực hiện
**Use case liên quan** Cấp phát nguyên vật liệu, Phê duyệt công đoạn
**Dòng sự kiện chính** Người thực hiện đăng nhập vào hệ thống.
Chọn mẻ sản xuất và bước cân nguyên liệu.
Xác nhận điều kiện vệ sinh phòng và thiết bị.
Tiến hành cân nguyên liệu, nhập khối lượng vào hệ thống.
Ký xác nhận điện tử.
Hệ thống lưu thông tin cân và thông báo đến Người kiểm tra.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu khối lượng nhập không nằm trong giới hạn cho phép.
**Điều kiện tiên quyết** Nguyên liệu đã được chuẩn bị và cấp phát đầy đủ.
Người thực hiện có quyền thao tác sản xuất.
**Hậu điều kiện** Thông tin về khối lượng nguyên liệu được lưu và chuyển tiếp đến người kiểm tra.

**4. Vận hành công đoạn trộn**
**Tên use case** Vận hành công đoạn trộn
**Tóm tắt** Người thực hiện thao tác máy trộn, nhập khối lượng bán thành phẩm thu được và chuyển dữ liệu cho người kiểm tra.
**Tác nhân** Người thực hiện
**Use case liên quan** Vận hành công đoạn cân, Phê duyệt công đoạn
**Dòng sự kiện chính** Người thực hiện đăng nhập vào hệ thống.
Chọn mẻ sản xuất và bước trộn.
Xác nhận điều kiện vệ sinh thiết bị và nhấn bắt đầu.
Sau khi trộn xong, nhập khối lượng đầu ra vào hệ thống.
Ký xác nhận điện tử.
Hệ thống tính toán hao hụt, lưu thông tin và thông báo đến Người kiểm tra.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu tỷ lệ hao hụt vượt quá mức sai số quy định.
**Điều kiện tiên quyết** Công đoạn cân trước đó đã được hoàn tất và phê duyệt.
**Hậu điều kiện** Thông tin về quá trình trộn được lưu và chuyển tiếp đến người kiểm tra.

**5. Vận hành công đoạn sấy**
**Tên use case** Vận hành công đoạn sấy
**Tóm tắt** Người thực hiện vận hành tủ sấy, nhập thông số độ ẩm, khối lượng và chuyển dữ liệu cho người kiểm tra đánh giá.
**Tác nhân** Người thực hiện
**Use case liên quan** Vận hành công đoạn trộn, Phê duyệt công đoạn
**Dòng sự kiện chính** Người thực hiện đăng nhập vào hệ thống.
Chọn mẻ sản xuất và bước sấy.
Xác nhận vệ sinh thiết bị và nhấn bắt đầu sấy.
Chờ hoàn thành thời gian sấy, nhập độ ẩm và khối lượng thu được vào hệ thống.
Ký xác nhận điện tử.
Hệ thống lưu thông tin sấy và thông báo đến Người kiểm tra.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu thông số độ ẩm hoặc khối lượng không đạt tiêu chuẩn.
**Điều kiện tiên quyết** Công đoạn trộn trước đó đã được hoàn tất và phê duyệt.
**Hậu điều kiện** Thông tin về quá trình sấy được lưu và chuyển tiếp đến người kiểm tra.

**6. Phê duyệt công đoạn**
**Tên use case** Phê duyệt công đoạn
**Tóm tắt** Người kiểm tra xem xét dữ liệu từ các công đoạn sản xuất, đối chiếu tiêu chuẩn và xác nhận cho phép mẻ sản xuất đi tiếp.
**Tác nhân** Người kiểm tra
**Use case liên quan** Vận hành công đoạn cân, Vận hành công đoạn trộn, Vận hành công đoạn sấy
**Dòng sự kiện chính** Người kiểm tra đăng nhập vào hệ thống.
Chọn dữ liệu công đoạn đang chờ duyệt từ danh sách.
Đối chiếu các thông số vận hành thực tế với tiêu chuẩn.
Ký xác nhận điện tử để phê duyệt.
Hệ thống lưu kết quả kiểm tra và cập nhật trạng thái mẻ sản xuất.
**Dòng sự kiện phụ** Hệ thống ghi nhận trạng thái từ chối nếu người kiểm tra không phê duyệt, và yêu cầu người thực hiện xử lý lại.
**Điều kiện tiên quyết** Có dữ liệu công đoạn đã được người thực hiện hoàn tất và gửi lên.
**Hậu điều kiện** Kết quả phê duyệt được lưu, mẻ sản xuất chuyển sang bước tiếp theo hoặc hoàn thành.

---

### Danh sách các SUC Phụ (Để vẽ Sơ đồ Use Case tổng thể)
1. **Tên use case:** Đăng nhập hệ thống
2. **Tên use case:** Quản lý người dùng và phân quyền
3. **Tên use case:** Quản lý danh mục thiết bị và khu vực
4. **Tên use case:** Quản lý danh mục nguyên vật liệu
5. **Tên use case:** Quản lý tồn kho
6. **Tên use case:** Xem báo cáo tiến độ lệnh sản xuất
7. **Tên use case:** Thống kê sản lượng thành phẩm
8. **Tên use case:** Truy xuất nguồn gốc lô
9. **Tên use case:** Tra cứu lệnh/mẻ sản xuất
10. **Tên use case:** Quản lý cảnh báo và sai lệch
