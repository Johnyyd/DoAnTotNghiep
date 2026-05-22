# ĐẶC TẢ CHI TIẾT USE CASE NGHIỆP VỤ VÀ HỆ THỐNG (GMP-WHO)

Tài liệu này phân tách rõ ràng giữa các Use Case Nghiệp vụ (BUC) mô tả quy trình thực tế tại nhà máy và các Use Case Hệ thống (SUC) mô tả các chức năng tương tác trên phần mềm, bám sát logic thực tế trong mã nguồn dự án và tiêu chuẩn GMP.

---

## PHẦN I: ĐẶC TẢ USE CASE NGHIỆP VỤ (BUC)
*Mô tả các quy trình hoạt động nghiệp vụ của nhà máy sản xuất cao khô.*

1. Đặc tả Use-case: Quản lý thông tin nhân viên
**Use case nghiệp vụ: Quản lý thông tin nhân viên**
Quy trình này mô tả việc quản lý hồ sơ nhân sự, thiết lập vai trò trách nhiệm và cung cấp định danh bảo mật cho nhân viên tham gia vào chuỗi sản xuất dược phẩm.
**Các dòng cơ bản:**
1. Khởi tạo hồ sơ: Quản lý thực hiện nhập thông tin cá nhân và vị trí công việc của nhân viên mới vào danh mục quản lý.
2. Phân quyền trách nhiệm: Hệ thống hóa các quyền hạn truy cập tương ứng với vai trò (Công nhân, QC hoặc Quản lý) để đảm bảo tuân thủ quy trình.
3. Thiết lập chữ ký điện tử: Cấp mã số xác nhận cá nhân (PIN) để nhân viên sử dụng làm bằng chứng pháp lý trong các bản ghi nhật ký mẻ.
**Các dòng thay thế:**
• Nếu nhân viên nghỉ việc hoặc thay đổi bộ phận, quản lý thực hiện cập nhật trạng thái hoặc quyền hạn ngay lập tức để bảo vệ an toàn dữ liệu.

2. Đặc tả Use-case: Kiểm Tra Thiết Bị Sử Dụng
**Use case nghiệp vụ: Kiểm Tra Thiết Bị Sử Dụng**
Đảm bảo các máy móc và dụng cụ (Cân, Máy trộn, Máy sấy) luôn đạt chuẩn kỹ thuật và vệ sinh trước khi vận hành mẻ sản xuất mới.
**Các dòng cơ bản:**
1. Kiểm tra kỹ thuật thiết bị: Nhân viên bảo trì thực hiện xác minh tình trạng hoạt động của các bộ phận cơ khí và cảm biến máy.
2. Xác nhận trạng thái vệ sinh: Công nhân thực hiện kiểm tra và ghi nhận máy đã được vệ sinh sạch sẽ sau lần sử dụng trước đó (đạt/không đạt).
3. Ghi nhận nhật ký máy: Mọi thông tin về trạng thái máy được lưu lại để phục vụ công tác giám sát và tra soát sau này.
**Các dòng thay thế:**
• Nếu máy đang ở trạng thái bảo trì hoặc chưa vệ sinh, công nhân không được phép khởi tạo quy trình chế biến trên thiết bị đó.

3. Đặc tả Use-case: Quản lý Nguyên liệu (Materials)
**Use case nghiệp vụ: Quản lý Nguyên liệu**
Quy trình kiểm soát danh mục nguyên liệu đầu vào, tá dược và bao bì phục vụ cho sản xuất cao khô đạt tiêu chuẩn chất lượng.
**Các dòng cơ bản:**
1. Khai báo danh mục vật tư: Nhập thông tin về tên, mã định danh, đơn vị tính và tiêu chuẩn kỹ thuật của nguyên liệu.
2. Thiết lập điều kiện bảo quản: Quy định các yêu cầu về nhiệt độ, độ ẩm môi trường cho từng loại nguyên liệu cụ thể.
3. Giám sát số lượng tồn kho: Theo dõi biến động số lượng để lập kế hoạch mua hàng kịp thời, tránh gián đoạn sản xuất.
**Các dòng thay thế:**
• Nếu nguyên liệu đã hết hạn sử dụng hoặc có kết quả kiểm nghiệm "Không đạt", hệ thống tự động khóa trạng thái và không cho phép xuất dùng cho sản xuất.

4. Đặc tả Use-case: Thiết lập Định mức Quy trình (Recipe)
**Use case nghiệp vụ: Thiết lập Định mức Quy trình**
Mô tả quy trình xây dựng công thức gốc (Recipe) – là bộ tài liệu chuẩn hướng dẫn cách thức sản xuất một loại thuốc cụ thể.
**Các dòng cơ bản:**
1. Xây dựng định mức nguyên liệu (BOM): Xác định chính xác khối lượng từng thành phần cần thiết cho một mẻ sản xuất tiêu chuẩn.
2. Quy định trình tự công đoạn: Thiết lập các bước thực hiện (Cân -> Trộn -> Sấy) và gán các thiết bị tương ứng cho từng bước.
3. Cài đặt thông số kiểm soát: Thiết lập các giá trị tiêu chuẩn (nhiệt độ, thời gian) và ngưỡng sai số cho phép để hệ thống tự động bẫy lỗi.
**Các dòng thay thế:**
• Trường hợp công thức bị người thẩm định từ chối phê duyệt, chuyên viên kỹ thuật phải thực hiện chỉnh sửa theo yêu cầu và trình duyệt lại.

5. Đặc tả Use-case: Lập Kế hoạch Sản xuất
**Use case nghiệp vụ: Lập Kế hoạch Sản xuất**
Quy trình chuyển đổi nhu cầu thị trường thành các lệnh sản xuất cụ thể trong nhà máy.
**Các dòng cơ bản:**
1. Khởi tạo lệnh sản xuất: Chọn công thức thuốc chuẩn và nhập quy mô mẻ hàng cần sản xuất.
2. Tính toán nguyên liệu dự kiến: Hệ thống tự động tính ra tổng khối lượng nguyên liệu cần cấp phát dựa trên cỡ lô.
3. Phê duyệt kế hoạch: Nhân viên QC thẩm định tính hợp lệ của lệnh sản xuất trước khi cho phép triển khai xuống phân xưởng.
**Các dòng thay thế:**
• Nếu số lượng thành phẩm dự kiến vượt quá năng lực vận hành của máy móc hiện có, người lập kế hoạch phải điều chỉnh lại lịch trình sản xuất.

6. Đặc tả Use-case: Kiểm Tra điều kiện môi trường
**Use case nghiệp vụ: Kiểm Tra điều kiện môi trường**
Quy trình đảm bảo phòng sạch và khu vực sản xuất đáp ứng đầy đủ các tiêu chuẩn vệ sinh, nhiệt độ, độ ẩm theo quy định GMP-WHO.
**Các dòng cơ bản:**
1. Kiểm tra vệ sinh khu vực: Nhân viên xác nhận phòng làm việc sạch sẽ, không có bụi bẩn hay vật lạ ảnh hưởng đến thuốc.
2. Ghi nhận chỉ số môi trường: Đo và lưu lại giá trị nhiệt độ (21-25°C), độ ẩm (45-70%) và áp suất phòng thực tế.
3. Xác nhận đạt chuẩn: Chỉ khi các chỉ số nằm trong ngưỡng an toàn, quy trình sản xuất mới được phép bắt đầu.
**Các dòng thay thế:**
• Nếu các chỉ số môi trường nằm ngoài ngưỡng an toàn, nhân viên phải báo cáo bộ phận kỹ thuật điều chỉnh và thực hiện đo lại sau khi môi trường ổn định.

7. Đặc tả Use-case: Cân Chuẩn bị Nguyên Liệu
**Use case nghiệp vụ: Cân Chuẩn bị Nguyên Liệu**
Quy trình chuẩn bị và cân chính xác từng loại nguyên liệu theo định mức đã duyệt để đảm bảo chất lượng thuốc đồng nhất.
**Các dòng cơ bản:**
1. Nhận diện lô nguyên liệu: Kiểm tra nhãn và trạng thái kiểm nghiệm của nguyên liệu trước khi cân.
2. Thực hiện cân định mức: Công nhân thực hiện cân đúng số lượng yêu cầu và ghi nhận khối lượng thực tế vào hồ sơ.
3. Đối soát sai lệch: Người giám sát kiểm tra lại khối lượng cân để đảm bảo nằm trong sai số cho phép (±5%).
**Các dòng thay thế:**
• Tại bước 3: Nếu khối lượng thực tế sai lệch vượt mức cho phép, công nhân bắt buộc phải điều chỉnh khối lượng hoặc khởi tạo biên bản giải trình lý do.

8. Đặc tả Use-case: Chế Biến Viên Nang
**Use case nghiệp vụ: Chế Biến Sản Phẩm**
Mô tả quy trình phối trộn bột và làm khô sản phẩm theo các thông số kỹ thuật nghiêm ngặt.
**Các dòng cơ bản:**
1. Vận hành máy trộn: Thực hiện trộn các loại nguyên liệu theo tốc độ và thời gian quy định để đạt độ đồng nhất.
2. Giám sát quá trình sấy: Theo dõi nhiệt độ buồng sấy và kiểm tra độ ẩm của hạt sau khi kết thúc quy trình đạt dưới 5%.
3. Ký xác nhận công đoạn: Nhân viên vận hành ký tên điện tử sau khi hoàn thành mỗi bước công việc.
**Các dòng thay thế:**
• Nếu thiết bị gặp sự cố trong lúc vận hành, công nhân phải dừng máy ngay lập tức và ghi nhận thời gian gián đoạn vào nhật ký mẻ.

9. Đặc tả Use-case: Đóng Gói Và Biệt Trữ
**Use case nghiệp vụ: Đóng Gói Và Biệt Trữ**
Quy trình bảo quản thành phẩm sau sản xuất, dán nhãn định danh và đưa vào khu vực chờ kiểm nghiệm cuối cùng.
**Các dòng cơ bản:**
1. Thực hiện đóng gói: Cho sản phẩm vào túi PE 2 lớp, cột chặt miệng túi để tránh hút ẩm.
2. Dán nhãn định danh: Ghi đầy đủ thông tin tên thuốc, số lô, ngày sản xuất lên bao bì.
3. Bàn giao kho: Di chuyển thành phẩm vào khu vực biệt trữ và ghi chép số lượng thực tế bàn giao.
**Các dòng thay thế:**
• Nếu bao bì túi PE bị thủng hoặc rách trong quá trình đóng gói, nhân viên phải thực hiện thay bao bì mới và kiểm tra lại tình trạng sản phẩm.

10. Đặc tả Use-case: Kiểm soát và Xử lý Sai lệch (Deviation)
**Use case nghiệp vụ: Kiểm soát và Xử lý Sai lệch**
Quy trình quản lý các tình huống phát sinh ngoài ý muốn hoặc dữ liệu sản xuất vượt ngưỡng an toàn trong quá trình thực hiện mẻ hàng.
**Các dòng cơ bản:**
1. Nhận diện sự cố: Tự động phát hiện các hành động hoặc dữ liệu sai lệch (ví dụ: cân sai, nhiệt độ sấy quá cao).
2. Tạm dừng quy trình: Khóa mẻ hàng để ngăn chặn các sai hỏng lan truyền sang công đoạn tiếp theo.
3. Điều tra và ra quyết định: Nhân viên QC thẩm định nguyên nhân và quyết định cho phép tiếp tục sản xuất hoặc hủy bỏ lô hàng.
**Các dòng thay thế:**
• Nếu nhân viên QC quyết định hủy bỏ lô hàng, hệ thống sẽ thực hiện đánh dấu mẻ sản phẩm là "Hủy" và ngăn chặn mọi hoạt động nhập kho tiếp theo.

11. Đặc tả Use-case: Đối chiếu và Hoàn tất mẻ hàng
**Use case nghiệp vụ: Đối chiếu và Hoàn tất mẻ hàng**
Quy trình so sánh dữ liệu thực tế đầu ra với lý thuyết đầu vào để tính toán hiệu suất sản xuất và đánh giá chất lượng mẻ hàng.
**Các dòng cơ bản:**
1. Tổng hợp dữ liệu mẻ: Thu thập toàn bộ khối lượng nguyên liệu đã dùng và thành phẩm thu được.
2. Tính toán hiệu suất (Yield): Đối chiếu tỷ lệ thu hồi thực tế với định mức lý thuyết (thông thường từ 95-105%).
3. Phê duyệt hoàn tất: Người quản lý xem xét báo cáo đối chiếu và ký duyệt kết thúc lệnh sản xuất.
**Các dòng thay thế:**
• Nếu hiệu suất tính toán nằm ngoài ngưỡng cho phép (Yield < 95% hoặc > 105%), hệ thống yêu cầu khởi tạo biên bản điều tra sai lệch hiệu suất.

12. Đặc tả Use-case: Truy xuất nguồn gốc Sản phẩm
**Use case nghiệp vụ: Truy xuất nguồn gốc Sản phẩm**
Quy trình cho phép tra cứu toàn bộ lịch sử của một lô sản phẩm từ lúc còn là nguyên liệu thô đến khi thành phẩm cuối cùng.
**Các dòng cơ bản:**
1. Tra cứu số lô: Nhập mã định danh lô hàng cần kiểm tra vào hệ thống tra cứu.
2. Hiển thị phả hệ sản xuất: Xem chi tiết các nguyên liệu đã dùng, thiết bị đã vận hành và những nhân sự đã tham gia ký xác nhận.
**Các dòng thay thế:**
• Nếu mã số lô nhập vào không chính xác hoặc không tồn tại trong hệ thống, người dùng sẽ nhận được thông báo lỗi tra cứu dữ liệu.

---

## PHẦN II: ĐẶC TẢ USE CASE HỆ THỐNG (SUC)
*Mô tả các chức năng kỹ thuật tương tác trên phần mềm hỗ trợ nghiệp vụ.*

1. Đăng nhập hệ thống
**Tên use case:** Đăng nhập hệ thống
**Tóm tắt:** Người dùng truy cập vào phần mềm bằng tài khoản cá nhân để thực hiện các chức năng theo quyền hạn được phân bổ.
**Tác nhân:** Quản lý sản xuất, Nhân viên QC, Công nhân vận hành
**Use case liên quan:** Thiết lập mã PIN chữ ký điện tử
**Dòng sự kiện chính:** 
- Người dùng nhập tên tài khoản và mật khẩu trên giao diện đăng nhập.
- Hệ thống đối chiếu thông tin với dữ liệu trong bảng AppUsers.
- Hệ thống xác định vai trò (Role) và hiển thị Dashboard làm việc tương ứng.
**Dòng sự kiện phụ:** Hệ thống hiển thị thông báo lỗi nếu thông tin tài khoản không chính xác hoặc đang bị khóa.
**Điều kiện tiên quyết:** Người dùng đã có tài khoản truy cập hợp lệ.
**Hậu điều kiện:** Người dùng truy cập thành công vào các chức năng được phân quyền.

2. Cân nguyên liệu sản xuất cao khô
**Tên use case:** Cân nguyên liệu sản xuất cao khô
**Tóm tắt:** Người thực hiện cân nguyên liệu thô, nhập khối lượng vào hệ thống và chuyển dữ liệu cân cho các tác nhân liên quan để kiểm tra và xác nhận.
**Tác nhân:** Người thực hiện (Công nhân)
**Use case liên quan:** Kiểm tra điều kiện môi trường, Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Người thực hiện đăng nhập vào ứng dụng trên máy tính bảng (Tablet).
- Chọn lệnh sản xuất và danh sách các nguyên liệu cần cân từ hệ thống.
- Tiến hành cân nguyên liệu thực tế và nhập giá trị khối lượng vào ô dữ liệu trên phần mềm.
- Hệ thống lưu trữ thông tin khối lượng và gửi thông báo yêu cầu phê duyệt đến nhân viên QC.
**Dòng sự kiện phụ:** Hệ thống tự động kiểm tra và đưa ra cảnh báo đỏ nếu khối lượng nhập vào không nằm trong giới hạn sai số (±5%) của công thức.
**Điều kiện tiên quyết:** Nguyên liệu đã sẵn sàng; bước kiểm tra môi trường đã hoàn thành.
**Hậu điều kiện:** Khối lượng cân thực tế được ghi nhận vào hồ sơ mẻ điện tử và chuyển trạng thái công đoạn.

3. Quản Lý Quy Trình Chế Biến Cao Khô
**Tên use case:** Quản Lý Quy Trình Chế Biến Cao Khô
**Tóm tắt:** Người thực hiện thực hiện quản lý và điều phối các bước trong quy trình chế biến, đảm bảo từng giai đoạn được thực hiện đúng tiêu chuẩn và ghi nhận dữ liệu vào hệ thống.
**Tác nhân:** Người thực hiện (Công nhân)
**Use case liên quan:** Cân nguyên liệu sản xuất cao khô, Đối chiếu
**Dòng sự kiện chính:** 
- Người thực hiện đăng nhập hệ thống và chọn quy trình sản xuất mẻ hàng đang xử lý.
- Theo dõi tiến độ của từng bước công việc (Trộn bột, Sấy hạt) hiển thị trên màn hình.
- Cập nhật thời gian bắt đầu, kết thúc và các thông số vận hành (Nhiệt độ, Tốc độ) cho từng bước.
- Hệ thống tự động ghi nhận dữ liệu và cập nhật trạng thái tiến độ mẻ hàng.
**Dòng sự kiện phụ:** Hệ thống tự động kiểm tra tính hợp lệ của các thông số trước khi lưu trữ; gửi cảnh báo ngay lập tức nếu phát hiện bất thường về thông số kỹ thuật.
**Điều kiện tiên quyết:** Lệnh sản xuất đã được phê duyệt và bước cân nguyên liệu đã hoàn thành.
**Hậu điều kiện:** Nhật ký điện tử của quy trình chế biến được cập nhật đầy đủ và minh bạch.

4. Đối chiếu
**Tên use case:** Đối chiếu
**Tóm tắt:** Người phê duyệt và Giám sát thực hiện đối chiếu dữ liệu thực tế và dữ liệu hệ thống, đảm bảo tính xác thực của hiệu suất trước khi hoàn tất lệnh.
**Tác nhân:** Người phê duyệt (Quản lý), Giám sát bộ phận QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Truy xuất nguồn gốc
**Dòng sự kiện chính:** 
- Người kiểm tra chọn lô sản xuất thành phẩm cần thực hiện đối chiếu trên hệ thống.
- Hệ thống hiển thị bảng so sánh giữa khối lượng nguyên liệu đầu vào và sản lượng đầu ra.
- Hệ thống tự động tính toán hiệu suất (Yield) và mức độ hao hụt thực tế.
- Người phê duyệt thực hiện ký xác nhận kết quả đối chiếu bằng mã PIN để đóng lệnh.
**Dòng sự kiện phụ:** Hệ thống cung cấp báo cáo so sánh chi tiết và gửi cảnh báo đỏ nếu phát hiện sai lệch hiệu suất vượt ngưỡng an toàn.
**Điều kiện tiên quyết:** Tất cả các công đoạn thực thi của mẻ hàng đã kết thúc hoàn toàn.
**Hậu điều kiện:** Kết quả đối chiếu được lưu vào hồ sơ lô và mẻ hàng chuyển trạng thái Hoàn thành.

5. Quản lý sai lệch (Deviation)
**Tên use case:** Quản lý sai lệch
**Tóm tắt:** Hệ thống tự động nhận diện các hành động nhập dữ liệu sai tiêu chuẩn và ghi nhận biên bản sai lệch để chờ QC xử lý.
**Tác nhân:** Hệ thống (System), Nhân viên QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:**
- Hệ thống thu thập dữ liệu nhập vào từ màn hình thao tác của công nhân.
- Hệ thống đối chiếu dữ liệu với bảng tham số tiêu chuẩn trong công thức (Recipe).
- Hệ thống phát hiện dữ liệu vượt ngưỡng an toàn (ví dụ: nhiệt độ sấy quá cao).
- Hệ thống tự động chuyển trạng thái mẻ hàng sang "Hold" và thông báo cho bộ phận QC.
**Dòng sự kiện phụ:** Gửi thông báo đẩy tức thời đến ứng dụng di động của nhân viên quản lý chất lượng.
**Điều kiện tiên quyết:** Định mức sai số đã được cài đặt trong bước cấu hình Master Data.
**Hậu điều kiện:** Mẻ hàng bị khóa cho đến khi QC thẩm định và phê duyệt cho phép tiếp tục hoặc hủy bỏ.

6. Truy xuất nguồn gốc
**Tên use case:** Truy xuất nguồn gốc
**Tóm tắt:** Cho phép tra cứu phả hệ lô sản phẩm từ mã số lô thành phẩm để xác định chính xác nguồn gốc nguyên liệu và các nhân sự liên quan.
**Tác nhân:** Quản lý sản xuất, Nhân viên QC
**Use case liên quan:** Đối chiếu
**Dòng sự kiện chính:**
- Người dùng nhập mã số định danh lô sản xuất (Batch No) vào thanh tìm kiếm truy xuất.
- Hệ thống truy vấn toàn bộ dữ liệu lịch sử mẻ từ bảng nhật ký điện tử (eBMR).
- Hệ thống hiển thị sơ đồ phả hệ (Genealogy) chi tiết từ nguyên liệu đến thành phẩm.
- Người dùng xuất báo cáo truy xuất dưới định dạng PDF.
**Dòng sự kiện phụ:** Hệ thống thông báo lỗi nếu mã số lô không tồn tại trong cơ sở dữ liệu.
**Điều kiện tiên quyết:** Dữ liệu lô hàng đã được phê duyệt và lưu trữ chính thức.
**Hậu điều kiện:** Thông tin nguồn gốc sản phẩm được hiển thị minh bạch và rõ ràng.

7. Thiết lập công thức (Recipe Management)
**Tên use case:** Thiết lập công thức
**Tóm tắt:** Chuyên viên kỹ thuật thiết lập định mức nguyên liệu và trình tự các bước thực hiện cho từng loại thuốc.
**Tác nhân:** Chuyên viên kỹ thuật, Quản lý sản xuất
**Use case liên quan:** Lập kế hoạch sản xuất
**Dòng sự kiện chính:** 
- Người dùng nhập thông tin sản phẩm và quy mô lô hàng chuẩn.
- Thêm danh sách nguyên liệu và khối lượng định mức vào bảng BOM.
- Thiết lập trình tự Routing và các tham số kiểm soát (Nhiệt độ, Thời gian).
- Hệ thống lưu công thức ở trạng thái Draft.
**Dòng sự kiện phụ:** Cảnh báo nếu tỷ lệ hao hụt dự kiến quá cao so với tiêu chuẩn chung.
**Điều kiện tiên quyết:** Danh mục nguyên liệu đã có sẵn trong hệ thống.
**Hậu điều kiện:** Công thức thuốc sẵn sàng chờ phê duyệt.

8. Thiết lập mã PIN chữ ký điện tử
**Tên use case:** Thiết lập mã PIN chữ ký điện tử
**Tóm tắt:** Người dùng cài đặt mã số cá nhân bảo mật để thực hiện ký tên điện tử vào hồ sơ sản xuất.
**Tác nhân:** Toàn bộ nhân viên
**Use case liên quan:** Đăng nhập hệ thống, Duyệt lệnh sản xuất
**Dòng sự kiện chính:** 
- Người dùng truy cập module Thông tin cá nhân.
- Nhập mã PIN mới gồm 6 chữ số và xác nhận lại.
- Hệ thống mã hóa và lưu trữ mã PIN vào bảng AppUsers.
**Dòng sự kiện phụ:** Yêu cầu nhập lại nếu hai lần nhập không trùng khớp hoặc sai định dạng số.
**Điều kiện tiên quyết:** Người dùng đã đăng nhập thành công.
**Hậu điều kiện:** Chức năng ký số được kích hoạt cho tài khoản.

9. Theo dõi tiến độ thời gian thực (Dashboard)
**Tên use case:** Theo dõi tiến độ thời gian thực
**Tóm tắt:** Cung cấp bảng điều khiển trung tâm để giám sát toàn bộ hoạt động sản xuất dưới xưởng.
**Tác nhân:** Quản lý sản xuất, QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Quản lý truy cập màn hình Dashboard chính.
- Hệ thống tổng hợp trạng thái thực tế của các lệnh và mẻ đang chạy (In-Process, Hold).
- Hiển thị tỷ lệ hoàn thành theo thời gian thực và các cảnh báo khẩn cấp.
**Dòng sự kiện phụ:** Cho phép nhấn vào từng mẻ để xem chi tiết thông số sấy/trộn đang vận hành.
**Điều kiện tiên quyết:** Đã có mẻ sản xuất được khởi tạo.
**Hậu điều kiện:** Người quản lý nắm bắt chính xác hiện trạng nhà máy để ra quyết định điều phối.

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
**Tóm tắt:** Hệ thống thực hiện việc chia nhỏ lệnh sản xuất chính thành các mẻ thực thi cụ thể trên thiết bị di động.
**Tác nhân:** Quản lý sản xuất, Hệ thống
**Use case liên quan:** Duyệt lệnh sản xuất, Quản Lý Quy Trình Chế Biến Cao Khô
**Dòng sự kiện chính:** 
- Hệ thống quét các lệnh sản xuất đã ở trạng thái "Approved".
- Tự động khởi tạo mã số mẻ (Batch Number) duy nhất cho từng lô hàng.
- Phân bổ định mức nguyên liệu và thiết bị tương ứng cho từng mẻ.
- Hiển thị danh sách mẻ hàng trên ứng dụng di động tại xưởng sản xuất.
**Dòng sự kiện phụ:** Cho phép quản lý điều chỉnh kích thước mẻ thủ công nếu cần thiết trước khi bắt đầu.
**Điều kiện tiên quyết:** Lệnh sản xuất cha đã được phê duyệt chính thức trên hệ thống.
**Hậu điều kiện:** Mẻ sản xuất sẵn sàng để công nhân bắt đầu thực hiện các công đoạn thực thi.

13. Kiểm tra điều kiện môi trường (Pre-check)
**Tên use case:** Kiểm tra điều kiện môi trường
**Tóm tắt:** Công nhân thực hiện ghi nhận và xác minh các chỉ số vệ sinh, nhiệt độ, độ ẩm tại khu vực sản xuất trước khi bắt đầu mẻ hàng.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Quản lý sai lệch
**Dòng sự kiện chính:** 
- Công nhân chọn mẻ sản xuất cần thực hiện trên ứng dụng Tablet.
- Nhập các giá trị đo thực tế: Nhiệt độ (21-25°C), Độ ẩm (45-70%) và Áp suất phòng.
- Hệ thống đối chiếu tự động với ngưỡng tiêu chuẩn đã cài đặt cho khu vực đó.
- Hệ thống ghi nhận kết quả và mở khóa cho bước sản xuất tiếp theo nếu đạt chuẩn.
**Dòng sự kiện phụ:** Hệ thống hiển thị cảnh báo đỏ và ngăn chặn việc sản xuất nếu các chỉ số vượt ngoài ngưỡng an toàn.
**Điều kiện tiên quyết:** Công nhân đã đăng nhập và mẻ hàng đang ở trạng thái chuẩn bị.
**Hậu điều kiện:** Trạng thái môi trường được lưu vào hồ sơ mẻ điện tử và cho phép thao tác chính.

14. Thực thi công đoạn Trộn (Mixing)
**Tên use case:** Thực thi công đoạn Trộn
**Tóm tắt:** Công nhân ghi nhận các thông số vận hành máy trộn và kiểm soát việc đóng gói sơ bộ thành phẩm bột sau trộn.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Đối chiếu
**Dòng sự kiện chính:** 
- Công nhân truy cập vào bước Trộn trong quy trình mẻ hàng đang thực thi.
- Nhập Tốc độ quay của máy và Thời gian trộn thực tế theo quy trình gốc.
- Xác nhận tình trạng vệ sinh túi PE 2 lớp và thùng chứa Inox.
- Nhập khối lượng đóng gói bột thực tế và ký xác nhận hoàn tất bằng mã PIN.
**Dòng sự kiện phụ:** Hệ thống cảnh báo nếu thời gian trộn thực tế không đạt yêu cầu tối thiểu của quy trình chuẩn.
**Điều kiện tiên quyết:** Công đoạn cân nguyên liệu và kiểm tra môi trường đã hoàn thành.
**Hậu điều kiện:** Dữ liệu trộn được ghi nhận vào nhật ký mẻ điện tử.

15. Thực thi công đoạn Sấy (Drying)
**Tên use case:** Thực thi công đoạn Sấy
**Tóm tắt:** Công nhân theo dõi nhiệt độ buồng sấy và ghi nhận kết quả kiểm tra độ ẩm bán thành phẩm sau sấy.
**Tác nhân:** Công nhân vận hành (Operator)
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Quản lý sai lệch
**Dòng sự kiện chính:** 
- Công nhân chọn công đoạn Sấy trên ứng dụng di động.
- Ghi nhận diễn biến nhiệt độ buồng sấy thực tế tại các mốc thời gian quy định.
- Thực hiện đo và nhập chỉ số độ ẩm sản phẩm sau khi kết thúc sấy (Tiêu chuẩn < 5%).
- Nhập mã PIN cá nhân để ký xác nhận hoàn thành công đoạn.
**Dòng sự kiện phụ:** Nếu độ ẩm thực tế đo được lớn hơn 5%, hệ thống yêu cầu thực hiện sấy bổ sung.
**Điều kiện tiên quyết:** Công đoạn phối trộn bột trước đó đã kết thúc thành công.
**Hậu điều kiện:** Thông số sấy được lưu trữ phục vụ cho việc thẩm định chất lượng lô hàng.

16. Phê duyệt xử lý sai lệch
**Tên use case:** Phê duyệt xử lý sai lệch
**Tóm tắt:** Nhân viên QC thực hiện thẩm định các biên bản lỗi tự động và ra quyết định giải phóng mẻ hàng bị tạm dừng.
**Tác nhân:** Nhân viên QC
**Use case liên quan:** Quản lý sai lệch (Deviation)
**Dòng sự kiện chính:** 
- Nhân viên QC đăng nhập vào danh sách các sai lệch chưa được xử lý trên hệ thống.
- Xem xét nguyên nhân và mức độ nghiêm trọng của dữ liệu vượt ngưỡng (Hold).
- Nhập hướng xử lý khắc phục và giải trình chi tiết biên bản.
- Ký duyệt điện tử để chuyển trạng thái mẻ hàng sang Tiếp tục hoặc Hủy bỏ.
**Dòng sự kiện phụ:** Hệ thống yêu cầu QC nhập lý do giải trình bắt buộc nếu quyết định cho phép mẻ hàng lỗi tiếp tục sản xuất.
**Điều kiện tiên quyết:** Hệ thống đã tự động bẫy lỗi và chuyển mẻ hàng sang trạng thái "Hold".
**Hậu điều kiện:** Mẻ hàng được giải phóng trạng thái để tiếp tục quy trình.

17. Quản lý Phiếu kiểm nghiệm (Certificates)
**Tên use case:** Quản lý Phiếu kiểm nghiệm
**Tóm tắt:** Nhân viên QC cập nhật kết quả kiểm nghiệm nguyên vật liệu và thành phẩm lên hệ thống để làm căn cứ phê duyệt sử dụng.
**Tác nhân:** Nhân viên QC
**Use case liên quan:** Quản lý danh mục nguyên liệu, Đối chiếu
**Dòng sự kiện chính:** 
- Người dùng chọn lô hàng nguyên liệu hoặc mẻ thành phẩm cần cập nhật kết quả.
- Nhập mã số phiếu kiểm nghiệm và kết luận đánh giá chất lượng (Đạt/Không đạt).
- Tải lên bản quét kết quả kiểm nghiệm và thực hiện ký xác nhận điện tử.
- Hệ thống cập nhật trạng thái "Approved for Production" hoặc "Released" cho lô hàng.
**Dòng sự kiện phụ:** Hệ thống tự động khóa không cho phép lập lệnh sản xuất nếu các lô nguyên liệu chính chưa có phiếu kiểm nghiệm đạt chuẩn.
**Điều kiện tiên quyết:** Lô nguyên liệu đã được nhập kho hoặc thành phẩm đã hoàn tất đóng gói.
**Hậu điều kiện:** Lô hàng đủ điều kiện pháp lý để lưu thông hoặc đưa vào dây chuyền sản xuất.

18. Quản lý danh mục nguyên liệu
**Tên use case:** Quản lý danh mục nguyên liệu
**Tóm tắt:** Người dùng khai báo và quản lý thông tin các loại nguyên liệu, tá dược, bao bì vào hệ thống để phục vụ sản xuất.
**Tác nhân:** Nhân viên kho, Chuyên viên kỹ thuật
**Use case liên quan:** Thiết lập công thức, Quản lý Phiếu kiểm nghiệm
**Dòng sự kiện chính:** 
- Người dùng chọn chức năng thêm mới hoặc cập nhật nguyên liệu.
- Nhập các thông tin bắt buộc: Mã nguyên liệu, Tên khoa học, Đơn vị tính (kg, g, túi).
- Thiết lập các ngưỡng bảo quản an toàn (Nhiệt độ, Độ ẩm tối đa).
- Hệ thống lưu trữ thông tin và hiển thị danh mục vật tư hiện hành.
**Dòng sự kiện phụ:** Hệ thống thông báo lỗi nếu mã nguyên liệu bị trùng lặp hoặc đơn vị tính không hợp lệ.
**Điều kiện tiên quyết:** Người dùng có quyền quản trị danh mục vật tư.
**Hậu điều kiện:** Nguyên liệu sẵn sàng để được chọn trong module lập công thức (BOM).

19. Quản lý thiết bị sản xuất
**Tên use case:** Quản lý thiết bị sản xuất
**Tóm tắt:** Khai báo và theo dõi trạng thái vận hành, vệ sinh của các máy móc trong nhà máy.
**Tác nhân:** Quản lý sản xuất, Nhân viên bảo trì
**Use case liên quan:** Kiểm tra điều kiện môi trường
**Dòng sự kiện chính:** 
- Người dùng nhập thông tin thiết bị: Tên máy, Mã số định danh, Công suất thiết kế.
- Gán thiết bị vào một khu vực sản xuất (Phòng sạch) cụ thể.
- Cập nhật trạng thái máy: Sẵn sàng, Đang sửa chữa, Chờ vệ sinh.
- Hệ thống ghi lại nhật ký thay đổi trạng thái của thiết bị.
**Dòng sự kiện phụ:** Hệ thống tự động chuyển trạng thái máy sang "Chờ vệ sinh" ngay sau khi một mẻ sản xuất kết thúc.
**Điều kiện tiên quyết:** Danh mục khu vực sản xuất đã được thiết lập trước đó.
**Hậu điều kiện:** Thiết bị đủ điều kiện sẽ hiển thị trong danh sách lựa chọn khi thực thi mẻ hàng.

20. Cấu hình khu vực sản xuất
**Tên use case:** Cấu hình khu vực sản xuất
**Tóm tắt:** Thiết lập các thông số môi trường tiêu chuẩn và quản lý danh sách các phòng chức năng trong phân xưởng.
**Tác nhân:** Quản trị viên (Admin)
**Use case liên quan:** Kiểm tra điều kiện môi trường
**Dòng sự kiện chính:** 
- Người dùng khai báo mã phòng và tên phòng (Phòng cân, Phòng trộn...).
- Thiết lập các ngưỡng giới hạn môi trường tiêu chuẩn (Nhiệt độ: 21-25°C, Độ ẩm: 45-70%).
- Hệ thống lưu cấu hình làm căn cứ để bẫy lỗi tự động trong quy trình sản xuất.
**Dòng sự kiện phụ:** Hệ thống yêu cầu xác nhận khi thực hiện thay đổi các ngưỡng tiêu chuẩn đã vận hành.
**Điều kiện tiên quyết:** Người dùng có quyền cấu hình hệ thống cao cấp.
**Hậu điều kiện:** Các khu vực sản xuất được định nghĩa rõ ràng phục vụ việc quản lý mẻ hàng.

21. Theo dõi tiến độ thời gian thực (Dashboard)
**Tên use case:** Theo dõi tiến độ thời gian thực
**Tóm tắt:** Cung cấp bảng điều khiển trung tâm giúp nhà quản lý giám sát toàn bộ hoạt động sản xuất đang diễn ra dưới xưởng.
**Tác nhân:** Quản lý sản xuất, QC
**Use case liên quan:** Quản Lý Quy Trình Chế Biến Cao Khô, Quản lý sai lệch
**Dòng sự kiện chính:** 
- Người dùng truy cập vào màn hình Dashboard chính của hệ thống.
- Hệ thống tổng hợp và hiển thị trạng thái của tất cả các mẻ đang thực thi (In-Process), đang chờ (Hold) hoặc đã xong.
- Hiển thị biểu đồ tỷ lệ hoàn thành và danh sách các biên bản sai lệch chưa xử lý.
- Hệ thống tự động cập nhật dữ liệu mới sau mỗi chu kỳ (ví dụ 30 giây).
**Dòng sự kiện phụ:** Cho phép người dùng nhấn vào một mẻ cụ thể để xem chi tiết nhật ký sấy/trộn đang diễn ra.
**Điều kiện tiên quyết:** Đã có ít nhất một lệnh sản xuất đang ở trạng thái triển khai.
**Hậu điều kiện:** Người quản lý có dữ liệu chính xác để điều phối nguồn lực và xử lý sự cố kịp thời.

... (Tương tự cho các SUC còn lại: Quản lý thiết bị, Quản lý vật tư, Phiếu kiểm nghiệm, Cấu hình khu vực...) ...
