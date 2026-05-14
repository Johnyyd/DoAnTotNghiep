# ĐẶC TẢ CHI TIẾT USE CASE NGHIỆP VỤ VÀ HỆ THỐNG (GMP-WHO)

Tài liệu này trình bày chi tiết các Use Case Nghiệp vụ (BUC) mô tả quy trình kinh doanh thực tế và các Use Case Hệ thống (SUC) mô tả các chức năng kỹ thuật tương tác trên phần mềm, bám sát logic thực tế trong mã nguồn dự án.

---

## PHẦN I: ĐẶC TẢ USE CASE NGHIỆP VỤ (BUC)
*Mô tả các quy trình hoạt động thực tế tại nhà máy sản xuất cao khô.*

1. Đặc tả Use-case: Kiểm Tra Môi Trường
**Use case nghiệp vụ: Kiểm Tra điều kiện môi trường**
Use case này mô tả quy trình kiểm tra vệ sinh và điều kiện môi trường trước khi thực hiện các bước sản xuất. Mục tiêu của use case là đảm bảo môi trường sản xuất đáp ứng đầy đủ các tiêu chuẩn vệ sinh và kỹ thuật của GMP-WHO.
**Các dòng cơ bản:**
1. Kiểm tra vệ sinh khu vực làm việc:
   o Nhân viên kiểm tra vệ sinh phòng cân, phòng pha chế, đảm bảo không có bụi bẩn, vật lạ hoặc các yếu tố không đạt chuẩn.
   o Ghi nhận trạng thái vệ sinh của khu vực (đạt hoặc không đạt).
2. Kiểm tra các chỉ số kỹ thuật môi trường:
   o Nhiệt độ: Ghi nhận nhiệt độ trong phòng, yêu cầu phải nằm trong phạm vi 21°C – 25°C.
   o Độ ẩm: Đo và ghi nhận độ ẩm, yêu cầu duy trì từ 45% – 70%.
3. Xác nhận đủ điều kiện sản xuất:
   o Nhân viên xác nhận môi trường đã đạt các tiêu chuẩn kỹ thuật để bắt đầu quy trình chế biến.
**Các dòng thay thế:**
• Tại bước 1: Nếu khu vực làm việc không sạch, nhân viên tạm dừng quy trình và thực hiện vệ sinh lại cho đến khi đạt yêu cầu.
• Tại bước 2: Nếu nhiệt độ hoặc độ ẩm vượt ngưỡng, nhân viên báo cáo bộ phận kỹ thuật điều chỉnh và đo lại sau 15 phút.

2. Đặc tả Use-case: Cân Nguyên Liệu Sản Xuất Cao Khô
**Use case nghiệp vụ: Cân Nguyên Liệu Sản Xuất Cao Khô**
Use case bắt đầu khi nhân viên cân thực hiện việc chuẩn bị nguyên liệu thô cho mẻ sản xuất cao khô. Mục tiêu là cung cấp lượng nguyên liệu chính xác tuyệt đối theo tiêu chuẩn định mức.
**Các dòng cơ bản:**
1. Thực hiện cân nguyên liệu:
   o Nhân viên thực hiện cân từng loại nguyên liệu theo yêu cầu định mức trong hồ sơ lô sản xuất.
   o Nhân viên ghi nhận khối lượng thực tế đã cân được vào báo cáo nhật ký mẻ.
2. Kiểm tra xác nhận khối lượng:
   o Người kiểm tra thực hiện đối soát khối lượng cân thực tế với số liệu yêu cầu để đảm bảo tính chính xác và ký xác nhận.
**Các dòng thay thế:**
• Tại bước 1: Nếu khối lượng cân thực tế sai lệch quá mức cho phép (±5%), nhân viên phải thực hiện điều chỉnh hoặc báo cáo sai lệch.

3. Đặc tả Use-case: Chế Biến Và Đóng Gói Cao Khô
**Use case nghiệp vụ: Chế Biến Và Đóng Gói Cao Khô**
Quy trình mô tả việc phối trộn, sấy và đóng gói thành phẩm cao khô để đưa vào kho bảo quản.
**Các dòng cơ bản:**
1. Thực hiện trộn và sấy:
   o Nhân viên nạp nguyên liệu vào máy trộn và cài đặt thông số vận hành.
   o Chuyển bột sang máy sấy và theo dõi nhiệt độ, thời gian sấy để đạt độ ẩm yêu cầu (< 5%).
2. Đóng gói và dán nhãn:
   o Sản phẩm sau sấy đạt chuẩn được đóng vào túi PE 2 lớp và dán nhãn biệt trữ.
**Các dòng thay thế:**
• Tại bước 1: Nếu độ ẩm sau sấy chưa đạt chuẩn, nhân viên thực hiện sấy bổ sung và kiểm tra lại mẫu.

---

## PHẦN II: ĐẶC TẢ USE CASE HỆ THỐNG (SUC)
*Mô tả các chức năng kỹ thuật tương tác trên phần mềm hỗ trợ nghiệp vụ.*

1. Đăng nhập hệ thống
**Tên use case:** Đăng nhập hệ thống
**Tóm tắt:** Người dùng truy cập vào phần mềm bằng tài khoản cá nhân để thực hiện các chức năng theo quyền hạn được phân bổ trong hệ thống.
**Tác nhân:** Quản lý sản xuất, Nhân viên QC, Công nhân vận hành
**Use case liên quan:** Thiết lập mã PIN chữ ký điện tử
**Dòng sự kiện chính:** 
- Người dùng nhập tên tài khoản (Username) và mật khẩu (Password) trên giao diện đăng nhập.
- Hệ thống đối chiếu thông tin với dữ liệu người dùng trong bảng AppUsers.
- Hệ thống xác định vai trò (Role) và cấp quyền truy cập các module tương ứng.
- Hệ thống hiển thị Dashboard làm việc chính cho người dùng.
**Dòng sự kiện phụ:** Hệ thống hiển thị thông báo lỗi nếu thông tin mật khẩu không đúng hoặc tài khoản đang bị vô hiệu hóa.
**Điều kiện tiên quyết:** Người dùng đã được quản trị viên cấp tài khoản truy cập hợp lệ.
**Hậu điều kiện:** Người dùng đăng nhập thành công và có thể thao tác trên các chức năng được phân quyền.

2. Cân nguyên liệu sản xuất cao khô
**Tên use case:** Cân nguyên liệu sản xuất cao khô
**Tóm tắt:** Người thực hiện cân nguyên liệu thô để sản xuất cao khô, nhập khối lượng vào hệ thống và chuyển dữ liệu cân cho các tác nhân liên quan để kiểm tra và xác nhận.
**Tác nhân:** Người thực hiện (Công nhân)
**Use case liên quan:** Kiểm tra điều kiện môi trường, Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Người thực hiện đăng nhập vào ứng dụng trên thiết bị di động (Tablet).
- Chọn lệnh sản xuất và danh sách các nguyên liệu cần cân từ hệ thống.
- Tiến hành cân thực tế và nhập giá trị khối lượng vào ô dữ liệu trên phần mềm.
- Hệ thống lưu trữ thông tin khối lượng và gửi thông báo yêu cầu phê duyệt đến nhân viên QC.
**Dòng sự kiện phụ:** Hệ thống tự động kiểm tra và đưa ra cảnh báo nếu khối lượng nhập vào không nằm trong giới hạn sai số (±5%) đã thiết lập trong công thức.
**Điều kiện tiên quyết:** Nguyên liệu đã được chuẩn bị và sẵn sàng; người thực hiện đã hoàn tất bước kiểm tra môi trường.
**Hậu điều kiện:** Thông tin khối lượng nguyên liệu thực tế được lưu vào nhật ký mẻ điện tử và chuyển trạng thái công đoạn.

3. Quản Lý Quy Trình Chế Biến Cao Khô
**Tên use case:** Quản Lý Quy Trình Chế Biến Cao Khô
**Tóm tắt:** Người thực hiện thực hiện quản lý và điều phối các bước trong quy trình chế biến cao khô, đảm bảo từng giai đoạn được thực hiện đúng tiêu chuẩn và ghi nhận dữ liệu vào hệ thống.
**Tác nhân:** Người thực hiện (Công nhân)
**Use case liên quan:** Cân nguyên liệu sản xuất cao khô, Đối chiếu
**Dòng sự kiện chính:** 
- Người thực hiện đăng nhập hệ thống và chọn quy trình sản xuất của mẻ hàng đang xử lý.
- Theo dõi tiến độ của từng bước công việc (Trộn khô, Sấy hạt) hiển thị trên màn hình.
- Cập nhật thời gian bắt đầu, thời gian kết thúc và các thông số kỹ thuật vận hành cho từng giai đoạn.
- Hệ thống tự động ghi nhận dữ liệu và cập nhật trạng thái tiến độ mẻ hàng.
**Dòng sự kiện phụ:** Hệ thống tự động kiểm tra tính hợp lệ của các thông số trước khi lưu trữ; gửi cảnh báo ngay lập tức nếu phát hiện bất thường về thông số sấy/trộn.
**Điều kiện tiên quyết:** Lệnh sản xuất đã được phê duyệt và bước cân nguyên liệu đã hoàn thành.
**Hậu điều kiện:** Nhật ký điện tử của quy trình chế biến được cập nhật đầy đủ và minh bạch thông tin.

4. Đối chiếu dữ liệu thực tế
**Tên use case:** Đối chiếu
**Tóm tắt:** Người phê duyệt và Giám sát bộ phận bào chế thực hiện đối chiếu dữ liệu thực tế và dữ liệu hệ thống, đảm bảo tính chính xác của thông tin trước khi chuyển tiếp để phê duyệt hoàn tất mẻ.
**Tác nhân:** Người phê duyệt (Quản lý), Giám sát bộ phận QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Truy xuất nguồn gốc
**Dòng sự kiện chính:** 
- Người kiểm tra đăng nhập vào hệ thống và chọn lô sản xuất thành phẩm cần thực hiện đối chiếu.
- Hệ thống hiển thị bảng so sánh giữa khối lượng nguyên liệu đầu vào và sản lượng thành phẩm đầu ra.
- Hệ thống tự động tính toán tỷ lệ hiệu suất (Yield) và mức độ hao hụt thực tế.
- Người phê duyệt thực hiện ký xác nhận kết quả đối chiếu để hoàn tất mẻ hàng.
**Dòng sự kiện phụ:** Hệ thống cung cấp báo cáo so sánh chi tiết và gửi cảnh báo đỏ nếu phát hiện sai lệch hiệu suất vượt ngưỡng an toàn cho phép (ngoài 95% - 105%).
**Điều kiện tiên quyết:** Tất cả các công đoạn thực thi từ Cân đến Đóng gói của mẻ hàng đã kết thúc.
**Hậu điều kiện:** Kết quả đối chiếu được ghi nhận vào hồ sơ lô và mẻ hàng chuyển trạng thái hoàn thành.

5. Quản lý sai lệch dữ liệu (Deviation)
**Tên use case:** Quản lý sai lệch
**Tóm tắt:** Hệ thống tự động phát hiện và ghi nhận các hành động nhập dữ liệu sai tiêu chuẩn (Min/Max), sau đó chuyển trạng thái mẻ hàng sang tạm dừng để chờ xử lý.
**Tác nhân:** Hệ thống (System), Nhân viên QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:**
- Hệ thống thu thập dữ liệu thực tế từ các màn hình thao tác của công nhân.
- Hệ thống đối chiếu dữ liệu này với bảng tham số tiêu chuẩn đã cài đặt trong công thức (Recipe).
- Hệ thống nhận diện dữ liệu vượt ngưỡng an toàn.
- Hệ thống tự động chuyển mẻ hàng sang trạng thái "Hold" và thông báo cho bộ phận chất lượng.
**Dòng sự kiện phụ:** Gửi thông báo thông báo cho nhân viên QC thông qua ứng dụng di động để thực hiện xử lý khẩn cấp.
**Điều kiện tiên quyết:** Các giới hạn tham số kỹ thuật đã được thiết lập đầy đủ trong module Master Data.
**Hậu điều kiện:** Mẻ hàng bị tạm dừng cho đến khi nhân viên QC thực hiện thẩm định và phê duyệt cho phép tiếp tục.

6. Truy xuất nguồn gốc phả hệ
**Tên use case:** Truy xuất nguồn gốc
**Tóm tắt:** Cho phép người dùng tra cứu phả hệ lô sản phẩm từ mã số lô thành phẩm để xác định chính xác nguồn gốc nguyên liệu và các cá nhân tham gia sản xuất.
**Tác nhân:** Quản lý sản xuất, Nhân viên QC
**Use case liên quan:** Đối chiếu
**Dòng sự kiện chính:**
- Người dùng nhập mã số định danh lô sản xuất (Batch No) vào thanh tìm kiếm truy xuất.
- Hệ thống truy vấn toàn bộ dữ liệu lịch sử mẻ, kết nối thông tin từ bảng hồ sơ điện tử (eBMR).
- Hệ thống hiển thị sơ đồ phả hệ (Genealogy) chi tiết bao gồm nguyên liệu, thiết bị và các chữ ký xác nhận.
- Người dùng xuất báo cáo truy xuất nguồn gốc dạng PDF để lưu trữ.
**Dòng sự kiện phụ:** Hệ thống thông báo lỗi nếu mã số lô sản xuất không tồn tại trong cơ sở dữ liệu.
**Điều kiện tiên quyết:** Dữ liệu của lô hàng đã được phê duyệt và lưu trữ chính thức trên hệ thống.
**Hậu điều kiện:** Toàn bộ thông tin nguồn gốc sản phẩm được hiển thị minh bạch và rõ ràng.

7. Quản lý Tài khoản người dùng
**Tên use case:** Quản lý Tài khoản người dùng
**Tóm tắt:** Quản trị viên thực hiện khởi tạo, cập nhật thông tin và quản lý trạng thái hoạt động của các tài khoản trong hệ thống.
**Tác nhân:** Quản trị viên (Admin)
**Use case liên quan:** Đăng nhập hệ thống
**Dòng sự kiện chính:** 
- Quản trị viên đăng nhập vào module quản trị nhân sự.
- Nhập các thông tin bắt buộc: Username, Full Name, Role.
- Hệ thống tự động mã hóa mật khẩu khởi tạo.
- Hệ thống lưu thông tin vào bảng AppUsers và hiển thị thông báo thành công.
**Dòng sự kiện phụ:** Hệ thống báo lỗi nếu Username đã tồn tại trong hệ thống.
**Điều kiện tiên quyết:** Quản trị viên có quyền truy cập module quản trị.
**Hậu điều kiện:** Tài khoản mới sẵn sàng để đăng nhập và sử dụng.

8. Thiết lập mã PIN chữ ký điện tử
**Tên use case:** Thiết lập mã PIN chữ ký điện tử
**Tóm tắt:** Người dùng thực hiện cài đặt hoặc thay đổi mã PIN 6 chữ số để sử dụng cho việc ký xác nhận điện tử trong quy trình sản xuất.
**Tác nhân:** Quản lý, QC, Công nhân
**Use case liên quan:** Đăng nhập hệ thống, Cân nguyên liệu sản xuất cao khô
**Dòng sự kiện chính:** 
- Người dùng truy cập vào trang thông tin cá nhân.
- Nhập mã PIN mới (6 chữ số) và xác nhận lại mã PIN.
- Hệ thống kiểm tra tính hợp lệ của mã PIN.
- Hệ thống lưu trữ mã PIN đã mã hóa vào cơ sở dữ liệu.
**Dòng sự kiện phụ:** Hệ thống yêu cầu nhập lại nếu mã PIN mới và mã PIN xác nhận không trùng khớp.
**Điều kiện tiên quyết:** Người dùng đã đăng nhập thành công vào hệ thống.
**Hậu điều kiện:** Mã PIN được kích hoạt để sử dụng cho chức năng ký số.

9. Thiết lập công thức (Recipe Management)
**Tên use case:** Thiết lập công thức
**Tóm tắt:** Chuyên viên kỹ thuật thiết lập định mức nguyên liệu (BOM) và trình tự các bước sản xuất (Routing) cho sản phẩm thuốc.
**Tác nhân:** Chuyên viên kỹ thuật, Quản lý sản xuất
**Use case liên quan:** Lập lệnh sản xuất
**Dòng sự kiện chính:** 
- Người dùng nhập thông tin sản phẩm và quy mô lô hàng chuẩn.
- Thêm danh sách nguyên liệu và khối lượng định mức vào bảng BOM.
- Thiết lập các bước công đoạn (Routing) và các tham số kiểm soát (Min/Max).
- Hệ thống lưu công thức ở trạng thái "Draft" để chờ phê duyệt.
**Dòng sự kiện phụ:** Hệ thống cảnh báo nếu tổng tỷ lệ nguyên liệu không cân đối với quy mô lô.
**Điều kiện tiên quyết:** Danh mục nguyên liệu và thiết bị đã được khai báo trên hệ thống.
**Hậu điều kiện:** Công thức chuẩn được lưu trữ và sẵn sàng để lập lệnh sản xuất sau khi được duyệt.

10. Lập lệnh sản xuất (Production Order)
**Tên use case:** Lập lệnh sản xuất
**Tóm tắt:** Người lập kế hoạch khởi tạo yêu cầu sản xuất mới dựa trên công thức đã được duyệt và quy mô mẻ hàng thực tế.
**Tác nhân:** Nhân viên lập kế hoạch (Planner)
**Use case liên quan:** Thiết lập công thức, Duyệt lệnh sản xuất
**Dòng sự kiện chính:** 
- Người dùng chọn công thức sản phẩm cần sản xuất.
- Nhập số lượng thành phẩm dự kiến và ngày bắt đầu/kết thúc.
- Hệ thống tự động tính toán tổng nhu cầu nguyên liệu dựa trên cỡ lô.
- Hệ thống lưu lệnh sản xuất ở trạng thái "Draft".
**Dòng sự kiện phụ:** Hệ thống cảnh báo nếu số lượng sản xuất vượt quá năng lực thiết bị trong công thức.
**Điều kiện tiên quyết:** Công thức sản phẩm đã được phê duyệt ở trạng thái "Approved".
**Hậu điều kiện:** Lệnh sản xuất được tạo thành công và chờ phê duyệt từ QC.

11. Duyệt lệnh sản xuất
**Tên use case:** Duyệt lệnh sản xuất
**Tóm tắt:** Nhân viên QC hoặc Quản lý sản xuất thẩm định tính hợp lệ của lệnh sản xuất trước khi cho phép thực thi dưới xưởng.
**Tác nhân:** Nhân viên QC, Quản lý sản xuất
**Use case liên quan:** Lập lệnh sản xuất, Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Người phê duyệt xem xét chi tiết lệnh sản xuất và định mức nguyên liệu kèm theo.
- Nhập mã PIN cá nhân để thực hiện ký duyệt điện tử.
- Hệ thống chuyển trạng thái lệnh sang "Approved".
**Dòng sự kiện phụ:** Hệ thống chặn việc duyệt nếu người dùng không nhập đúng mã PIN xác nhận.
**Điều kiện tiên quyết:** Lệnh sản xuất đang ở trạng thái "Draft" hoặc "Pending".
**Hậu điều kiện:** Lệnh sản xuất sẵn sàng để khởi tạo các mẻ sản xuất thực tế.

12. Quản lý mẻ sản xuất (Batch Management)
**Tên use case:** Quản lý mẻ sản xuất
**Tóm tắt:** Hệ thống tự động chia lệnh sản xuất thành các mẻ nhỏ để công nhân thực hiện trên ứng dụng di động.
**Tác nhân:** Quản lý sản xuất, Hệ thống
**Use case liên quan:** Duyệt lệnh sản xuất, Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Hệ thống kiểm tra các lệnh sản xuất đã được duyệt (Approved).
- Tự động tạo mã số mẻ (Batch Number) duy nhất cho từng mẻ hàng.
- Phân bổ định mức nguyên liệu tương ứng cho từng mẻ.
- Hiển thị danh sách mẻ hàng trên ứng dụng Tablet tại xưởng.
**Dòng sự kiện phụ:** Cho phép quản lý điều chỉnh kích thước mẻ thủ công nếu cần thiết trước khi bắt đầu.
**Điều kiện tiên quyết:** Lệnh sản xuất cha đã được phê duyệt chính thức.
**Hậu điều kiện:** Mẻ sản xuất sẵn sàng để công nhân bắt đầu thực hiện bước kiểm tra môi trường.

13. Kiểm tra điều kiện môi trường (Pre-check)
**Tên use case:** Kiểm tra điều kiện môi trường
**Tóm tắt:** Công nhân ghi nhận các chỉ số nhiệt độ, độ ẩm và áp suất phòng trên ứng dụng di động để đảm bảo phòng sạch đủ tiêu chuẩn trước khi thao tác.
**Tác nhân:** Công nhân (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Công nhân đăng nhập vào mẻ sản xuất trên Tablet.
- Nhập giá trị Nhiệt độ, Độ ẩm và Áp suất phòng thực tế.
- Hệ thống đối chiếu với ngưỡng cho phép trong cấu hình khu vực.
- Hệ thống ghi nhận thời gian kiểm tra và chữ ký xác nhận của công nhân.
**Dòng sự kiện phụ:** Hệ thống hiển thị cảnh báo đỏ và chặn không cho phép thực hiện bước tiếp theo nếu các chỉ số vượt ngưỡng an toàn.
**Điều kiện tiên quyết:** Công nhân đã vào đúng khu vực sản xuất và mẻ hàng đang ở trạng thái sẵn sàng.
**Hậu điều kiện:** Trạng thái môi trường được lưu vào hồ sơ mẻ; hệ thống mở khóa cho các bước sản xuất chính.

14. Thực thi công đoạn Trộn (Mixing)
**Tên use case:** Thực thi công đoạn Trộn
**Tóm tắt:** Công nhân ghi nhận các thông số vận hành máy trộn (Tốc độ, Thời gian) và khối lượng sản phẩm sau trộn trên ứng dụng di động.
**Tác nhân:** Công nhân (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Đối chiếu
**Dòng sự kiện chính:** 
- Công nhân chọn công đoạn Trộn trong quy trình mẻ hàng.
- Nhập Tốc độ máy (vòng/phút) và Thời gian trộn thực tế.
- Ghi nhận việc sử dụng bao bì (Túi PE 2 lớp) và khối lượng đóng gói sau trộn.
- Ký xác nhận hoàn tất công đoạn bằng mã PIN.
**Dòng sự kiện phụ:** Hệ thống cảnh báo nếu thời gian trộn thực tế thấp hơn yêu cầu trong quy trình gốc.
**Điều kiện tiên quyết:** Bước cân nguyên liệu và kiểm tra môi trường đã hoàn tất thành công.
**Hậu điều kiện:** Dữ liệu trộn được ghi nhận vào eBMR và chuyển sang công đoạn kế tiếp.

15. Thực thi công đoạn Sấy (Drying)
**Tên use case:** Thực thi công đoạn Sấy
**Tóm tắt:** Công nhân theo dõi nhiệt độ sấy và ghi nhận kết quả kiểm tra độ ẩm của bán thành phẩm trên phần mềm.
**Tác nhân:** Công nhân (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Quản lý sai lệch
**Dòng sự kiện chính:** 
- Công nhân chọn công đoạn Sấy trên ứng dụng.
- Nhập nhiệt độ buồng sấy thực tế tại các thời điểm theo dõi.
- Nhập kết quả đo độ ẩm cuối công đoạn (Yêu cầu < 5%).
- Ký xác nhận hoàn tất bước sấy.
**Dòng sự kiện phụ:** Nếu độ ẩm > 5%, hệ thống yêu cầu nhân viên thực hiện thêm bước sấy bổ sung và đo lại.
**Điều kiện tiên quyết:** Công đoạn trước đó (Trộn/Tạo hạt) đã hoàn thành.
**Hậu điều kiện:** Dữ liệu nhiệt độ và độ ẩm được lưu trữ phục vụ truy xuất nguồn gốc.

16. Phê duyệt xử lý sai lệch
**Tên use case:** Phê duyệt xử lý sai lệch
**Tóm tắt:** Nhân viên QC xem xét biên bản sai lệch tự động và đưa ra quyết định cho phép mẻ hàng tiếp tục hoặc hủy bỏ.
**Tác nhân:** Nhân viên QC
**Use case liên quan:** Quản lý sai lệch (Deviation)
**Dòng sự kiện chính:** 
- Nhân viên QC đăng nhập vào danh sách mẻ hàng đang bị tạm dừng (Hold).
- Xem xét nguyên nhân và giá trị sai lệch do hệ thống ghi nhận.
- Nhập hướng xử lý (Tiếp tục/Hủy) và ký xác nhận bằng mã PIN.
- Hệ thống cập nhật trạng thái mẻ hàng dựa trên quyết định của QC.
**Dòng sự kiện phụ:** Hệ thống yêu cầu QC nhập lý do giải trình chi tiết nếu quyết định cho mẻ hàng tiếp tục sản xuất bất chấp sai lệch.
**Điều kiện tiên quyết:** Mẻ hàng đang bị hệ thống tự động khóa ở trạng thái "Hold".
**Hậu điều kiện:** Mẻ hàng được giải phóng để tiếp tục quy trình hoặc bị hủy bỏ hoàn toàn.

17. Quản lý phiếu kiểm nghiệm (Certificates)
**Tên use case:** Quản lý phiếu kiểm nghiệm
**Tóm tắt:** Nhân viên chất lượng cập nhật kết quả kiểm nghiệm nguyên liệu và thành phẩm lên hệ thống để làm căn cứ xuất dùng hoặc xuất xưởng.
**Tác nhân:** Nhân viên QC
**Use case liên quan:** Quản lý danh mục nguyên liệu, Đối chiếu
**Dòng sự kiện chính:** 
- Người dùng nhập mã số phiếu kiểm nghiệm và chọn lô nguyên liệu/thành phẩm tương ứng.
- Nhập kết quả đánh giá (Đạt/Không đạt).
- Đính kèm tệp tin kết quả (nếu có) và ký xác nhận.
- Hệ thống cập nhật trạng thái chất lượng của lô hàng.
**Dòng sự kiện phụ:** Hệ thống tự động khóa không cho phép lập lệnh sản xuất nếu nguyên liệu chính chưa có phiếu kiểm nghiệm đạt chuẩn.
**Điều kiện tiên quyết:** Lô nguyên liệu đã được nhập kho hoặc mẻ thành phẩm đã hoàn thành đối chiếu.
**Hậu điều kiện:** Trạng thái chất lượng được cập nhật, cho phép các bước tiếp theo trong chuỗi cung ứng.

18. Quản lý danh mục nguyên liệu
**Tên use case:** Quản lý danh mục nguyên liệu
**Tóm tắt:** Người dùng khai báo các loại nguyên liệu, tá dược và bao bì vào hệ thống để phục vụ việc lập công thức và quản lý kho.
**Tác nhân:** Nhân viên kho, Chuyên viên kỹ thuật
**Use case liên quan:** Thiết lập công thức
**Dòng sự kiện chính:** 
- Người dùng chọn chức năng thêm mới nguyên liệu.
- Nhập các thông tin: Mã nguyên liệu, Tên nguyên liệu, Đơn vị tính cơ bản (UoM).
- Thiết lập các yêu cầu bảo quản (Nhiệt độ, Độ ẩm tối đa).
- Hệ thống lưu trữ thông tin vào bảng Materials.
**Dòng sự kiện phụ:** Hệ thống ngăn chặn nếu mã nguyên liệu đã tồn tại hoặc đơn vị tính không có trong danh mục chuẩn.
**Điều kiện tiên quyết:** Các đơn vị tính (UoM) đã được định nghĩa trước đó.
**Hậu điều kiện:** Nguyên liệu mới sẵn sàng để đưa vào BOM của công thức.

19. Quản lý thiết bị sản xuất
**Tên use case:** Quản lý thiết bị sản xuất
**Tóm tắt:** Quản lý danh sách máy móc, thiết bị trong nhà máy và theo dõi trạng thái vệ sinh của chúng.
**Tác nhân:** Quản lý sản xuất, Công nhân
**Use case liên quan:** Kiểm tra điều kiện môi trường, Cấu hình khu vực sản xuất
**Dòng sự kiện chính:** 
- Người dùng nhập thông tin máy: Mã máy, Tên máy, Công suất.
- Gán máy vào một khu vực sản xuất (Area) cụ thể.
- Cập nhật trạng thái máy (Sẵn sàng/Chờ vệ sinh/Đang sửa chữa).
- Hệ thống ghi nhận lịch sử thay đổi trạng thái.
**Dòng sự kiện phụ:** Hệ thống tự động chuyển trạng thái máy sang "Chờ vệ sinh" sau khi mẻ sản xuất kết thúc.
**Điều kiện tiên quyết:** Khu vực sản xuất đã được thiết lập.
**Hậu điều kiện:** Thiết bị sẵn sàng để được chọn trong quy trình sản xuất.

20. Cấu hình khu vực sản xuất
**Tên use case:** Cấu hình khu vực sản xuất
**Tóm tắt:** Thiết lập các thông số môi trường tiêu chuẩn cho từng phòng sạch trong phân xưởng.
**Tác nhân:** Quản trị viên (Admin)
**Use case liên quan:** Kiểm tra điều kiện môi trường
**Dòng sự kiện chính:** 
- Người dùng khai báo tên phòng và mã phòng.
- Thiết lập các ngưỡng giới hạn môi trường (Nhiệt độ: 21-25°C, Độ ẩm: 45-70%).
- Hệ thống lưu cấu hình vào bảng ProductionAreas.
**Dòng sự kiện phụ:** Hệ thống yêu cầu xác nhận khi thay đổi các ngưỡng tiêu chuẩn đã thiết lập.
**Điều kiện tiên quyết:** Quản trị viên có quyền cấu hình hệ thống.
**Hậu điều kiện:** Các thông số này sẽ làm căn cứ để hệ thống bẫy lỗi (Deviation) trong bước Pre-check.

21. Theo dõi tiến độ thời gian thực (Dashboard)
**Tên use case:** Theo dõi tiến độ thời gian thực
**Tóm tắt:** Cung cấp cái nhìn tổng quát về trạng thái của tất cả các lệnh và mẻ sản xuất đang diễn ra trong nhà máy.
**Tác nhân:** Quản lý sản xuất, QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Người dùng truy cập vào màn hình Dashboard chính.
- Hệ thống tổng hợp dữ liệu từ các mẻ sản xuất đang ở trạng thái In-Process, Hold hoặc Completed.
- Hiển thị biểu đồ tiến độ và danh sách các cảnh báo sai lệch (nếu có).
- Hệ thống tự động làm mới dữ liệu sau mỗi 30 giây.
**Dòng sự kiện phụ:** Cho phép người dùng nhấn vào một mẻ cụ thể để xem chi tiết nhật ký điện tử (eBMR).
**Điều kiện tiên quyết:** Đã có mẻ sản xuất được khởi tạo.
**Hậu điều kiện:** Người quản lý nắm bắt được tình hình sản xuất thực tế để điều phối kịp thời.
