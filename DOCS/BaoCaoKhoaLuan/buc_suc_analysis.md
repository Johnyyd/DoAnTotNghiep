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

### BUC 2: Cấp phát nguyên vật liệu
**Use case nghiệp vụ:** Cấp phát nguyên vật liệu
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

### BUC 5: Thiết lập và quản lý BOM, Recipe, Routing
**Use case nghiệp vụ:** Thiết lập và quản lý danh sách vật tư (BOM), công thức (Recipe) và quy trình sản xuất (Routing)
**Use case bắt đầu khi:** Quản lý tiến hành nhập thông tin vào hệ thống để chuẩn bị làm ra một sản phẩm mới. Mục tiêu của use case là lưu lại công thức, số lượng nguyên liệu cần dùng và thứ tự các công đoạn sản xuất để làm chuẩn cho xưởng làm theo.
**Các bước cơ bản:**
1. Quản lý đăng nhập vào hệ thống và chọn chức năng tạo công thức sản phẩm mới.
2. Quản lý nhập tên sản phẩm và các thông tin cơ bản của công thức (Recipe).
3. Quản lý thêm danh sách các nguyên vật liệu cần dùng và số lượng chuẩn cho mỗi loại (định mức - BOM).
4. Quản lý thiết lập thứ tự các công đoạn sản xuất như cân, trộn, sấy (quy trình - Routing).
5. Quản lý nhập thêm giới hạn cho phép (như giới hạn thời gian, nhiệt độ, độ ẩm) cho từng công đoạn.
6. Quản lý lưu tất cả thông tin lại để hệ thống ghi nhận.
**Các dòng thay thế:**
Tại bước 3 và 4: Nếu quản lý nhập thiếu số lượng nguyên liệu hoặc chọn sai thông tin, hệ thống sẽ báo lỗi và yêu cầu quản lý kiểm tra, sửa lại trước khi lưu.

### BUC 6: Theo dõi tiến độ và thống kê
**Use case nghiệp vụ:** Theo dõi tiến độ sản xuất và thống kê sản phẩm
**Use case bắt đầu khi:** Quản lý muốn kiểm tra tình hình sản xuất ở xưởng hoặc thống kê sản lượng. Mục tiêu của use case là giúp quản lý nắm rõ các lệnh nào đang chạy, lệnh nào đã xong, và xem lại lịch sử chi tiết của từng mẻ sản phẩm.
**Các bước cơ bản:**
1. Quản lý đăng nhập vào hệ thống và chọn màn hình báo cáo.
2. Quản lý xem biểu đồ tiến độ để biết số lượng các lệnh sản xuất đang thực hiện, đang bị tạm dừng hoặc đã hoàn thành.
3. Quản lý xem phần thống kê thành phẩm để biết tổng số mẻ và số sản phẩm đã làm xong.
4. Quản lý chuyển sang chức năng truy xuất nguồn gốc khi cần kiểm tra lịch sử của một mẻ sản phẩm cụ thể.
5. Quản lý nhập mã của mẻ sản phẩm đó vào ô tìm kiếm.
6. Hệ thống hiển thị toàn bộ thông tin lịch sử của mẻ, từ lúc xuất kho vật tư cho đến lúc hoàn thành các công đoạn sản xuất.
**Các dòng thay thế:**
Tại bước 5 và 6: Nếu quản lý nhập sai mã mẻ sản phẩm, hệ thống sẽ báo không tìm thấy dữ liệu và yêu cầu quản lý kiểm tra lại mã.

---

## 2.3. Đặc tả Use Case hệ thống (SUC)

### Các SUC Chính và Bổ trợ

**1. Quản lý Recipe**
**Tên use case** Quản lý Recipe
**Tóm tắt** Nhân viên quản lý thiết lập Recipe, định mức BOM và Routing làm tiêu chuẩn cho sản xuất.
**Tác nhân** Nhân viên quản lý
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Lập lệnh sản xuất
**Dòng sự kiện chính** Nhân viên quản lý đăng nhập vào hệ thống.
Truy cập chức năng quản lý công thức.
Khai báo mới công thức, nhập định mức vật tư và thiết lập thông số các công đoạn.
Lưu thông tin cấu hình vào hệ thống.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu thiếu thông tin định mức hoặc công đoạn chưa được thiết lập.
**Điều kiện tiên quyết** Danh mục vật tư và thiết bị đã được khai báo trên hệ thống.
**Hậu điều kiện** Thông tin công thức sản xuất được lưu làm cơ sở dữ liệu gốc để tạo lệnh.

**3. Vận hành công đoạn cân**
**Tên use case** Vận hành công đoạn cân
**Tóm tắt** Nhân viên sản xuất tiến hành cân nguyên liệu thô theo định mức, nhập khối lượng vào hệ thống và chuyển dữ liệu cho người kiểm tra xác nhận.
**Tác nhân** Nhân viên sản xuất
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **<<extend>>**: (Được mở rộng bởi) Quản lý cảnh báo và sai lệch
- **Liên kết**: Ghi nhận xuất kho vật tư, Phê duyệt công đoạn
**Dòng sự kiện chính** Nhân viên sản xuất đăng nhập vào hệ thống.
Chọn mẻ sản xuất và bước cân nguyên liệu.
Xác nhận điều kiện vệ sinh phòng và thiết bị.
Tiến hành cân nguyên liệu, nhập khối lượng vào hệ thống.
Ký xác nhận điện tử.
Hệ thống lưu thông tin cân và thông báo đến Người kiểm tra.
**Dòng sự kiện phụ** Hệ thống kiểm tra và cảnh báo nếu khối lượng nhập không nằm trong giới hạn cho phép.
**Điều kiện tiên quyết** Nguyên liệu đã được chuẩn bị và cấp phát đầy đủ. Người thực hiện có quyền thao tác sản xuất.
**Hậu điều kiện** Thông tin về khối lượng nguyên liệu được lưu và chuyển tiếp đến người kiểm tra.

**4. Vận hành công đoạn trộn**
**Tên use case** Vận hành công đoạn trộn
**Tóm tắt** Nhân viên sản xuất thao tác máy trộn, nhập khối lượng bán thành phẩm thu được và chuyển dữ liệu cho người kiểm tra.
**Tác nhân** Nhân viên sản xuất
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **<<extend>>**: (Được mở rộng bởi) Quản lý cảnh báo và sai lệch
- **Liên kết**: Vận hành công đoạn cân, Phê duyệt công đoạn
**Dòng sự kiện chính** Nhân viên sản xuất đăng nhập vào hệ thống.
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
**Tóm tắt** Nhân viên sản xuất vận hành tủ sấy, nhập thông số độ ẩm, khối lượng và chuyển dữ liệu cho người kiểm tra đánh giá.
**Tác nhân** Nhân viên sản xuất
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **<<extend>>**: (Được mở rộng bởi) Quản lý cảnh báo và sai lệch
- **Liên kết**: Vận hành công đoạn trộn, Phê duyệt công đoạn
**Dòng sự kiện chính** Nhân viên sản xuất đăng nhập vào hệ thống.
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
**Tóm tắt** Nhân viên QC xem xét dữ liệu từ các công đoạn sản xuất, đối chiếu tiêu chuẩn và xác nhận cho phép mẻ sản xuất đi tiếp.
**Tác nhân** Nhân viên QC
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Vận hành công đoạn cân, Vận hành công đoạn trộn, Vận hành công đoạn sấy
**Dòng sự kiện chính** Nhân viên QC đăng nhập vào hệ thống.
Chọn dữ liệu công đoạn đang chờ duyệt từ danh sách.
Đối chiếu các thông số vận hành thực tế với tiêu chuẩn.
Ký xác nhận điện tử để phê duyệt.
Hệ thống lưu kết quả kiểm tra và cập nhật trạng thái mẻ sản xuất.
**Dòng sự kiện phụ** Hệ thống ghi nhận trạng thái từ chối nếu người kiểm tra không phê duyệt, và yêu cầu người thực hiện xử lý lại.
**Điều kiện tiên quyết** Có dữ liệu công đoạn đã được người thực hiện hoàn tất và gửi lên.
**Hậu điều kiện** Kết quả phê duyệt được lưu, mẻ sản xuất chuyển sang bước tiếp theo hoặc hoàn thành.

**7. Đăng nhập**
**Tên use case** Đăng nhập
**Tóm tắt** Người dùng xác thực thông tin tài khoản để truy cập vào hệ thống.
**Tác nhân** Tất cả người dùng (Nhân viên quản lý, Nhân viên kho, Nhân viên sản xuất, Nhân viên QC)
**Use case liên quan**
- **Liên kết**: Phân quyền
**Dòng sự kiện chính** Người dùng mở ứng dụng trên thiết bị.
Nhập tên đăng nhập và mật khẩu.
Nhấn nút Đăng nhập.
Hệ thống xác thực và chuyển hướng đến màn hình làm việc tương ứng với quyền hạn.
**Dòng sự kiện phụ** Nếu nhập sai thông tin tài khoản, hệ thống báo lỗi và yêu cầu nhập lại.
**Điều kiện tiên quyết** Tài khoản đã được cấp và kích hoạt trên hệ thống.
**Hậu điều kiện** Người dùng bắt đầu một phiên làm việc hợp lệ.

**8. Phân quyền**
**Tên use case** Phân quyền
**Tóm tắt** Người quản trị thiết lập quyền truy cập chức năng cho từng nhóm tài khoản người dùng.
**Tác nhân** Quản trị viên (hoặc Nhân viên quản lý cấp cao)
**Use case liên quan**
- **<<include>>**: Đăng nhập
**Dòng sự kiện chính** Quản trị viên đăng nhập và vào mục Quản lý người dùng.
Chọn một tài khoản hoặc nhóm người dùng cần phân quyền.
Tích chọn các quyền hạn tương ứng (ví dụ: Quyền thao tác kho, thao tác vận hành cân/trộn/sấy, duyệt QC).
Lưu cấu hình phân quyền.
**Dòng sự kiện phụ** Hệ thống cảnh báo nếu thao tác phân quyền mâu thuẫn.
**Điều kiện tiên quyết** Quản trị viên có đặc quyền hệ thống.
**Hậu điều kiện** Tài khoản được cập nhật quyền mới ngay lập tức.

**9. Quản lý danh mục**
**Tên use case** Quản lý danh mục
**Tóm tắt** Quản lý các dữ liệu cơ sở của hệ thống như danh sách thiết bị, phòng ban, nguyên vật liệu.
**Tác nhân** Nhân viên quản lý
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Quản lý Recipe
**Dòng sự kiện chính** Nhân viên quản lý truy cập chức năng Quản lý danh mục.
Chọn loại danh mục cần thao tác (ví dụ: Nguyên vật liệu, Thiết bị).
Thực hiện thêm mới, cập nhật thông tin hoặc vô hiệu hóa một mục.
Hệ thống lưu lại dữ liệu.
**Dòng sự kiện phụ** Hệ thống cảnh báo nếu mã danh mục thêm mới bị trùng lặp với mã đang có.
**Điều kiện tiên quyết** Người dùng có quyền thêm/sửa/xóa danh mục.
**Hậu điều kiện** Dữ liệu danh mục được đồng bộ trên toàn bộ hệ thống để sử dụng cho các luồng khác.

**10. Truy xuất nguồn gốc lô**
**Tên use case** Truy xuất nguồn gốc lô
**Tóm tắt** Người dùng tra cứu lại toàn bộ thông tin lịch sử của một mẻ sản xuất đã hoàn thành, bao gồm nguyên liệu, thao tác và kết quả kiểm tra.
**Tác nhân** Nhân viên quản lý, Nhân viên QC
**Use case liên quan**
- **<<include>>**: Đăng nhập
**Dòng sự kiện chính** Người dùng truy cập chức năng Truy xuất nguồn gốc.
Nhập mã lệnh sản xuất hoặc quét mã vạch của mẻ/lô thành phẩm.
Hệ thống truy vấn cơ sở dữ liệu và hiển thị báo cáo chi tiết.
Người dùng có thể xuất báo cáo ra file PDF.
**Dòng sự kiện phụ** Nếu mã mẻ/lệnh không tồn tại, hệ thống báo lỗi không tìm thấy dữ liệu.
**Điều kiện tiên quyết** Mẻ/lệnh sản xuất đã có dữ liệu được lưu trữ.
**Hậu điều kiện** Người dùng xem hoặc tải về được thông tin báo cáo đầy đủ.

**11. Quản lý cảnh báo và sai lệch**
**Tên use case** Quản lý cảnh báo và sai lệch
**Tóm tắt** Hệ thống tự động ghi nhận và yêu cầu người có thẩm quyền xử lý khi có thông số vượt tiêu chuẩn hoặc sự cố trong sản xuất.
**Tác nhân** Nhân viên QC, Nhân viên quản lý
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **<<extend>>**: Mở rộng cho: Vận hành công đoạn cân, trộn, sấy
**Dòng sự kiện chính** Hệ thống tự động nhận diện thông số (nhiệt độ, độ ẩm, khối lượng) vượt ngưỡng và tạo một bản ghi sai lệch (Deviation).
Hệ thống tạm khóa công đoạn và gửi cảnh báo đến Nhân viên QC.
Nhân viên QC mở chi tiết cảnh báo, kiểm tra nguyên nhân.
Ghi chú biện pháp xử lý và ký xác nhận điện tử để cho phép tiếp tục hoặc hủy mẻ.
**Dòng sự kiện phụ** Hệ thống lưu lại lịch sử cảnh báo dù sai lệch có được chấp nhận hay không.
**Điều kiện tiên quyết** Chức năng giám sát các thông số luôn được bật trong quá trình sản xuất.
**Hậu điều kiện** Sai lệch được xử lý thành công, mẻ sản xuất được tiếp tục hoặc bị hủy theo quyết định.

---

**13. Quản lý tồn kho nguyên vật liệu**
**Tên use case** Quản lý tồn kho nguyên vật liệu
**Tóm tắt** Nhân viên kho theo dõi biến động số lượng nguyên vật liệu, kiểm soát các lô nhập mới và nhận cảnh báo khi vật tư dưới mức tồn kho tối thiểu (MinStock).
**Tác nhân** Nhân viên kho
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **<<extend>>**: (Mở rộng cho) Ghi nhận xuất kho vật tư
**Dòng sự kiện chính** Nhân viên kho truy cập chức năng Quản lý tồn kho.
Hệ thống hiển thị danh sách toàn bộ vật tư kèm số lượng tồn và trạng thái lô (Pending, Passed, Failed).
Người dùng tra cứu thông tin vật tư cụ thể và xuất báo cáo tồn kho.
**Dòng sự kiện phụ** Hệ thống tự động bôi đỏ và hiển thị cảnh báo đối với các lô vật tư sắp hết hạn (ExpiryDate) hoặc sắp cạn kiệt.
**Điều kiện tiên quyết** Đăng nhập với quyền của bộ phận kho.
**Hậu điều kiện** Dữ liệu tồn kho được cập nhật chính xác để phục vụ cho các lệnh sản xuất.

**14. Theo dõi và thống kê tiến độ sản xuất**
**Tên use case** Theo dõi và thống kê tiến độ sản xuất
**Tóm tắt** Nhân viên quản lý xem Dashboard tổng quan để theo dõi trạng thái các lệnh sản xuất (In-Process, Hold, Completed) và thống kê sản lượng thành phẩm thực tế so với kế hoạch.
**Tác nhân** Nhân viên quản lý
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Lập lệnh sản xuất
**Dòng sự kiện chính** Nhân viên quản lý truy cập màn hình Dashboard tiến độ.
Hệ thống truy vấn cơ sở dữ liệu và hiển thị các biểu đồ (tiến độ theo thời gian thực, tỷ lệ hoàn thành, sản lượng, hao hụt).
Người dùng có thể lọc báo cáo theo khoảng thời gian hoặc theo từng loại sản phẩm.
**Dòng sự kiện phụ** Nếu dữ liệu quá lớn, hệ thống sẽ yêu cầu người dùng thu hẹp khoảng thời gian lọc.
**Điều kiện tiên quyết** Có các lệnh sản xuất đang chạy hoặc đã hoàn thành trong hệ thống.
**Hậu điều kiện** Nhân viên quản lý có cái nhìn tổng quan để ra quyết định điều hành kịp thời.

**15. Xem nhật ký kiểm toán (Audit Trail)**
**Tên use case** Xem nhật ký kiểm toán (Audit Trail)
**Tóm tắt** Quản trị viên hoặc Thanh tra QC tra cứu lại toàn bộ lịch sử thao tác của người dùng trên hệ thống nhằm đảm bảo tính toàn vẹn dữ liệu chuẩn GMP (ai đã làm gì, vào lúc nào, giá trị cũ/mới là gì).
**Tác nhân** Quản trị viên, Nhân viên QC
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Phân quyền, Quản lý trạng thái lệnh/mẻ sản xuất
**Dòng sự kiện chính** Quản trị viên hoặc QC truy cập chức năng Audit Log.
Nhập bộ lọc (theo tên người dùng, khoảng thời gian hoặc hành động).
Hệ thống hiển thị danh sách các thay đổi chi tiết, từ việc sửa đổi công thức, chuyển trạng thái lệnh, đến việc cập nhật kết quả QC.
**Dòng sự kiện phụ** Hệ thống chặn hoàn toàn mọi quyền xóa hoặc chỉnh sửa nội dung bên trong bảng ghi lịch sử (Read-only).
**Điều kiện tiên quyết** Hệ thống đã tự động ghi nhận các log thông qua Audit Middleware.
**Hậu điều kiện** Đảm bảo truy xuất được vết kiểm toán phục vụ cho các đợt thanh tra chuẩn GMP-WHO.

**16. Thiết lập và quản lý cấu hình hệ thống**
**Tên use case** Thiết lập và quản lý cấu hình hệ thống
**Tóm tắt** Quản trị viên thiết lập các tham số toàn cục cho hệ thống như giới hạn thời gian (Timeout), tỷ lệ sai số mặc định (Tolerance Percent) và chính sách mật khẩu.
**Tác nhân** Quản trị viên
**Use case liên quan**
- **<<include>>**: Đăng nhập
**Dòng sự kiện chính** Quản trị viên truy cập màn hình Cấu hình hệ thống.
Tiến hành chỉnh sửa các tham số mặc định (ví dụ: Tỷ lệ sai số cho phép khi xuất kho là ±5%).
Nhấn Lưu để áp dụng.
**Dòng sự kiện phụ** N/A.
**Điều kiện tiên quyết** Đăng nhập bằng tài khoản Quản trị cấp cao (Admin).
**Hậu điều kiện** Cấu hình mới có hiệu lực ngay lập tức trên hệ thống.

**17. Quản lý trạng thái lệnh/mẻ sản xuất**
**Tên use case** Quản lý trạng thái lệnh/mẻ sản xuất
**Tóm tắt** Nhân viên quản lý trực tiếp thực hiện chuyển đổi trạng thái của Lệnh hoặc Mẻ (Draft -> Approved -> In-Process -> Hold -> Completed) theo tiến trình.
**Tác nhân** Nhân viên quản lý
**Use case liên quan**
- **<<include>>**: Đăng nhập
- **Liên kết**: Lập lệnh sản xuất
**Dòng sự kiện chính** Nhân viên quản lý chọn một lệnh sản xuất đang ở trạng thái Draft.
Tiến hành duyệt lệnh và chuyển trạng thái sang Approved (hệ thống yêu cầu xác thực chữ ký điện tử).
Khi xưởng bắt đầu chạy, chuyển trạng thái sang In-Process.
Sau khi các mẻ hoàn tất, đóng lệnh và chuyển sang Completed.
**Dòng sự kiện phụ** Nếu lệnh sản xuất đang bị gián đoạn do sự cố, quản lý chuyển trạng thái sang Hold.
**Điều kiện tiên quyết** Lệnh sản xuất đã được tạo và lưu trữ trên hệ thống.
**Hậu điều kiện** Trạng thái lệnh được cập nhật chính xác, hệ thống ngăn chặn việc chuyển trạng thái nhảy cóc.

**18. Đổi mật khẩu tài khoản**
**Tên use case** Đổi mật khẩu tài khoản
**Tóm tắt** Người dùng tự thay đổi mật khẩu đăng nhập định kỳ hoặc khi có yêu cầu bảo mật để bảo vệ tài khoản cá nhân.
**Tác nhân** Tất cả người dùng
**Use case liên quan**
- **<<include>>**: Đăng nhập
**Dòng sự kiện chính** Người dùng chọn mục Đổi mật khẩu trong hồ sơ cá nhân.
Hệ thống yêu cầu nhập mật khẩu cũ và mật khẩu mới.
Nhấn xác nhận đổi mật khẩu.
Hệ thống mã hóa (Hash) mật khẩu mới và lưu vào cơ sở dữ liệu.
**Dòng sự kiện phụ** Nếu mật khẩu mới không đạt chuẩn bảo mật (độ dài, ký tự đặc biệt) hoặc mật khẩu cũ sai, hệ thống từ chối và yêu cầu nhập lại.
**Điều kiện tiên quyết** Người dùng đã đăng nhập vào hệ thống.
**Hậu điều kiện** Mật khẩu được cập nhật thành công, hệ thống có thể yêu cầu đăng nhập lại.
