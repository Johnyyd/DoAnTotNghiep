# ĐẶC TẢ CHI TIẾT CÁC HOẠT ĐỘNG NGHIỆP VỤ HỆ THỐNG (GMP-WHO)

1. Đặc tả Use-case: Đăng nhập/Đăng xuất
Use case nghiệp vụ: Đăng nhập/Đăng xuất
Use case này mô tả quy trình nhân viên truy cập và thoát khỏi hệ thống để đảm bảo an toàn thông tin và phân quyền hạn làm việc dựa trên vai trò cá nhân.
Các dòng cơ bản:
1. Nhân viên thực hiện đăng nhập:
   o Nhân viên nhập tên đăng nhập và mật khẩu cá nhân vào màn hình khởi động của hệ thống.
   o Hệ thống thực hiện xác thực thông tin và cấp quyền truy cập tương ứng với vị trí công tác (Quản lý, QC hoặc Công nhân).
2. Nhân viên thực hiện đăng xuất:
   o Nhân viên chọn chức năng đăng xuất sau khi hoàn thành phiên làm việc để đảm bảo tính bảo mật.
Các dòng thay thế:
• Tại bước 1: Nếu nhân viên nhập sai thông tin đăng nhập, hệ thống sẽ đưa ra thông báo lỗi và yêu cầu thực hiện nhập lại.

2. Đặc tả Use-case: Quản lý Tài khoản người dùng
Use case nghiệp vụ: Quản lý Tài khoản người dùng
Use case mô tả hoạt động khởi tạo, cập nhật thông tin và phân quyền hạn cho nhân sự trong nhà máy. Mục tiêu là thiết lập danh tính và mã số xác nhận cá nhân cho từng người dùng.
Các dòng cơ bản:
1. Quản trị viên cập nhật hồ sơ nhân viên:
   o Quản trị viên chọn nhân viên từ danh sách và thiết lập các quyền hạn truy cập phù hợp với nhiệm vụ được giao.
   o Quản trị viên cài đặt mã số xác nhận cá nhân (mã PIN) gồm 6 chữ số để nhân viên dùng làm chữ ký điện tử.
2. Ghi nhận thay đổi:
   o Hệ thống lưu trữ các thông tin cập nhật và tự động ghi lại người đã thực hiện thao tác quản trị này.
Các dòng thay thế:
• Tại bước 1: Nếu mã số xác nhận không đúng định dạng quy định, hệ thống sẽ yêu cầu quản trị viên điều chỉnh lại cho chính xác.

3. Đặc tả Use-case: Cấu hình Khu vực sản xuất
Use case nghiệp vụ: Cấu hình Khu vực sản xuất
Use case này mô tả việc thiết lập các phòng chức năng và khu vực làm việc trong nhà máy phục vụ cho quá trình sản xuất dược phẩm.
Các dòng cơ bản:
1. Thiết lập khu vực:
   o Nhân viên văn phòng nhập tên phòng, mã định danh phòng và loại khu vực sạch tương ứng.
   o Thực hiện gán danh sách các máy móc thiết bị cố định vào từng phòng làm việc cụ thể.
Các dòng thay thế:
• Tại bước 1: Nếu mã số phòng đã được sử dụng cho một khu vực khác, hệ thống sẽ yêu cầu người dùng thay đổi mã phòng mới.

4. Đặc tả Use-case: Quản lý Nguyên liệu (Materials)
Use case nghiệp vụ: Quản lý Nguyên liệu (Materials)
Use case mô tả việc khai báo và quản lý danh mục tất cả các loại nguyên vật liệu, tá dược dùng trong quá trình chế biến thuốc.
Các dòng cơ bản:
1. Khai báo danh mục:
   o Nhân viên nhập tên nguyên liệu, mã số quản lý và lựa chọn đơn vị tính phù hợp (ví dụ: kg, g).
   o Ghi nhận các yêu cầu bảo quản đặc biệt về nhiệt độ và độ ẩm cho từng loại nguyên liệu.
Các dòng thay thế:
• Tại bước 1: Nếu nguyên liệu đã tồn tại trong danh sách, hệ thống sẽ cảnh báo để tránh việc tạo ra dữ liệu trùng lặp.

5. Đặc tả Use-case: Quản lý Thiết bị (Equipments)
Use case nghiệp vụ: Quản lý Thiết bị (Equipments)
Use case mô tả việc theo dõi danh sách máy móc và kiểm soát trạng thái vệ sinh của thiết bị trước khi bắt đầu mỗi mẻ sản xuất.
Các dòng cơ bản:
1. Quản lý thông tin thiết bị:
   o Nhập tên máy, mã số máy và vị trí lắp đặt máy trong phân xưởng sản xuất.
   o Cập nhật trạng thái hiện tại của máy: Đang sẵn sàng làm việc, Đang chờ vệ sinh hoặc Đang sửa chữa.
2. Kiểm tra trạng thái:
   o Công nhân thực hiện tra cứu trạng thái máy trên ứng dụng di động để đảm bảo máy đủ điều kiện vận hành.
Các dòng thay thế:
• Nếu thiết bị đang ở trạng thái "Chờ vệ sinh", hệ thống sẽ ngăn chặn việc khởi tạo công đoạn sản xuất trên máy đó.

6. Đặc tả Use-case: Thiết lập Công thức (Recipe Management)
Use case nghiệp vụ: Thiết lập Công thức (Recipe Management)
Use case mô tả việc xây dựng bộ khung định mức nguyên liệu và các bước thực hiện chuẩn để sản xuất một sản phẩm thuốc.
Các dòng cơ bản:
1. Lập công thức chuẩn:
   o Người quản lý nhập tên sản phẩm, quy mô lô hàng tiêu chuẩn và danh sách các nguyên liệu cần thiết theo định mức.
   o Thiết lập trình tự các bước công đoạn sản xuất (ví dụ: Cân, Trộn, Sấy).
2. Thẩm định và duyệt:
   o Quản lý thực hiện duyệt công thức gốc để làm căn cứ tính toán cho các lệnh sản xuất thực tế.
Các dòng thay thế:
• Nếu công thức thiếu thông tin về các thành phần nguyên liệu chính, hệ thống sẽ chặn việc phê duyệt để đảm bảo an toàn.

7. Đặc tả Use-case: Lập Lệnh sản xuất (Production Order)
Use case nghiệp vụ: Lập Lệnh sản xuất (Production Order)
Use case mô tả việc khởi tạo một yêu cầu sản xuất cụ thể dựa trên quy trình gốc và quy mô mẻ hàng thực tế.
Các dòng cơ bản:
1. Tạo lệnh mới:
   o Người lập kế hoạch chọn công thức thuốc đã duyệt và nhập số lượng thành phẩm cần làm.
   o Hệ thống tự động tính toán ra tổng khối lượng tất cả nguyên liệu cần chuẩn bị cho lệnh này.
2. Lưu trữ kế hoạch:
   o Lệnh sản xuất được lưu ở trạng thái chờ phê duyệt trên hệ thống quản lý chung.
Các dòng thay thế:
• Tại bước 1: Nếu số lượng sản xuất vượt quá năng lực của thiết bị hiện có, hệ thống sẽ hiển thị cảnh báo cho người dùng.

8. Đặc tả Use-case: Duyệt Lệnh sản xuất
Use case nghiệp vụ: Duyệt Lệnh sản xuất
Use case mô tả quy trình thẩm định lệnh sản xuất của nhân viên kiểm soát chất lượng (QC) để đảm bảo tính hợp lệ trước khi thực hiện.
Các dòng cơ bản:
1. Kiểm tra và phê duyệt:
   o Nhân viên QC xem xét các thông số trong lệnh sản xuất và định mức nguyên liệu đã tính toán.
   o Nhân viên QC thực hiện ký xác nhận bằng mã số cá nhân để phê duyệt cho phép sản xuất.
2. Cấp phép thực thi:
   o Sau khi duyệt, lệnh sản xuất được chuyển trạng thái sẵn sàng để công nhân dưới xưởng có thể bắt đầu làm việc.
Các dòng thay thế:
• Tại bước 1: Nếu nhập sai mã số cá nhân xác thực, hệ thống sẽ không thực hiện lệnh duyệt để bảo vệ an toàn quy trình.

9. Đặc tả Use-case: Quản lý Mẻ sản xuất (Batch Management)
Use case nghiệp vụ: Quản lý Mẻ sản xuất (Batch Management)
Use case mô tả việc theo dõi và quản lý các mẻ thuốc thực tế trong quá trình thực thi lệnh sản xuất.
Các dòng cơ bản:
1. Khởi tạo mẻ:
   o Hệ thống tự động chia mẻ dựa trên quy mô lô hàng đã được duyệt.
   o Mỗi mẻ sản xuất được cấp một mã số định danh duy nhất để theo dõi nhật ký thực hiện.
Các dòng thay thế:
• Nếu lệnh sản xuất chưa được cấp phép (Approved), hệ thống sẽ không cho phép bắt đầu bất kỳ mẻ sản xuất nào.

10. Đặc tả Use-case: Theo dõi tiến độ thời gian thực
Use case nghiệp vụ: Theo dõi tiến độ thời gian thực
Use case này mô tả việc giám sát diễn biến của quá trình sản xuất trên bảng điều khiển trung tâm (Dashboard).
Các dòng cơ bản:
1. Giám sát quá trình:
   o Hệ thống tự động cập nhật tiến độ thực hiện từ ứng dụng di động của công nhân về màn hình quản trị.
   o Hiển thị các thông báo tức thời nếu có mẻ sản xuất bị tạm dừng hoặc có sai sót phát sinh.

11. Đặc tả Use-case: Kiểm tra môi trường (Pre-check)
Use case nghiệp vụ: Kiểm tra điều kiện môi trường
Use case này mô tả quy trình kiểm tra vệ sinh và điều kiện môi trường trước khi thực hiện các bước sản xuất. Mục tiêu của use case là đảm bảo môi trường sản xuất đáp ứng đầy đủ các tiêu chuẩn vệ sinh và kỹ thuật.
Các dòng cơ bản:
1. Kiểm tra vệ sinh:
   o Nhân viên kiểm tra vệ sinh phòng sạch, đảm bảo không có bụi bẩn hay rác thải ảnh hưởng đến thuốc.
   o Ghi nhận trạng thái vệ sinh của khu vực (sạch hoặc không sạch).
2. Kiểm tra chỉ số môi trường:
   o Ghi nhận nhiệt độ thực tế (yêu cầu từ 21°C – 25°C).
   o Ghi nhận độ ẩm thực tế (yêu cầu từ 45% – 70%).
   o Kiểm tra áp lực phòng (yêu cầu ≥ 10 Pa).
3. Xác nhận đạt chuẩn:
   o Nếu các thông số đều đạt, hệ thống cho phép công nhân chuyển sang công đoạn sản xuất tiếp theo.
Các dòng thay thế:
• Tại bước 2: Nếu có chỉ số không nằm trong giới hạn cho phép, hệ thống sẽ yêu cầu dừng lại để điều chỉnh môi trường đạt chuẩn.

12. Đặc tả Use-case: Thực thi công đoạn Cân (Weighing)
Use case nghiệp vụ: Cân Nguyên Liệu Sản Xuất Cao Khô
Use case bắt đầu khi nhân viên cân thực hiện việc cân nguyên liệu để sản xuất. Mục tiêu của use case là cung cấp quy trình hiện cân nguyên liệu theo tiêu chuẩn.
Các dòng cơ bản:
1. Nhân viên cân thực hiện cân nguyên liệu:
   o Công nhân thực hiện cân lượng nguyên liệu theo yêu cầu định mức hiển thị trên ứng dụng máy tính bảng.
   o Nhập khối lượng thực tế đã cân được vào hệ thống và kiểm tra sai lệch (sai số cho phép trong khoảng ±5%).
2. Xác nhận và lưu kết quả:
   o Nhân viên cân nhập mã số cá nhân để thực hiện ký tên điện tử, xác nhận trách nhiệm cho khối lượng đã cân.
Các dòng thay thế:
• Tại bước 1: Nếu khối lượng thực tế sai lệch quá 5% so với yêu cầu, nhân viên phải thực hiện cân lại hoặc giải trình lý do theo quy định.

13. Đặc tả Use-case: Thực thi công đoạn Trộn (Mixing)
Use case nghiệp vụ: Thực thi công đoạn Trộn (Mixing)
Use case mô tả quy trình vận hành máy trộn nguyên liệu, ghi nhận thời gian và tốc độ quay của máy.
Các dòng cơ bản:
1. Vận hành máy trộn:
   o Nhập thời gian bắt đầu chạy máy và tốc độ quay thực tế của thiết bị.
   o Xác nhận đã thực hiện nạp các loại nguyên liệu vào máy theo đúng trình tự hướng dẫn.
2. Hoàn tất công đoạn:
   o Nhập thời gian dừng máy và thực hiện ký tên cá nhân để hoàn thành bước trộn.
Các dòng thay thế:
• Nếu thời gian trộn thực tế ít hơn thời gian quy định trong quy trình chuẩn, hệ thống sẽ đưa ra cảnh báo cho người vận hành.

14. Đặc tả Use-case: Thực thi công đoạn Sấy (Drying)
Use case nghiệp vụ: Thực thi công đoạn Sấy (Drying)
Use case mô tả việc giám sát nhiệt độ, thời gian và kiểm soát chất lượng sản phẩm thông qua chỉ số độ ẩm sau khi sấy.
Các dòng cơ bản:
1. Giám sát sấy:
   o Ghi nhận nhiệt độ sấy cài đặt và theo dõi nhiệt độ thực tế trong quá trình thiết bị vận hành.
2. Kiểm tra chất lượng:
   o Thực hiện đo và nhập chỉ số độ ẩm của sản phẩm sau khi kết thúc quá trình sấy (yêu cầu đạt chuẩn < 5%).
3. Ký xác nhận hoàn tất:
   o Nhân viên thực hiện nhập mã số cá nhân để ký tên điện tử và đóng công đoạn sấy.
Các dòng thay thế:
• Tại bước 2: Nếu độ ẩm sản phẩm vẫn cao hơn 5%, hệ thống yêu cầu công nhân thực hiện sấy bổ sung cho đến khi đạt yêu cầu.

15. Đặc tả Use-case: Ký xác nhận điện tử (Digital Signature)
Use case nghiệp vụ: Ký xác nhận điện tử (Digital Signature)
Use case mô tả cơ chế xác thực trách nhiệm của nhân sự sau mỗi bước công việc bằng mã số PIN định danh.
Các dòng cơ bản:
1. Thực hiện ký số:
   o Khi hệ thống yêu cầu, người dùng nhập mã số cá nhân gồm 6 chữ số.
   o Hệ thống xác thực danh tính và lưu vết tên người ký kèm thời điểm thực hiện chính xác vào nhật ký điện tử.

16. Đặc tả Use-case: Quản lý Sai lệch (Deviation)
Use case nghiệp vụ: Quản lý Sai lệch (Deviation)
Use case mô tả cơ chế tự động phát hiện và cảnh báo khi có dữ liệu sản xuất vượt ra ngoài ngưỡng an toàn.
Các dòng cơ bản:
1. Phát hiện sai sót:
   o Hệ thống tự động nhận diện các giá trị không đạt chuẩn (ví dụ: cân sai khối lượng, nhiệt độ phòng quá cao).
2. Tạm dừng mẻ hàng:
   o Hệ thống tự động chuyển trạng thái mẻ sản xuất sang "Hold" (Tạm dừng) và chặn không cho thực hiện các bước tiếp theo để chờ xử lý.

17. Đặc tả Use-case: Duyệt xử lý sai lệch
Use case nghiệp vụ: Duyệt xử lý sai lệch
Use case mô tả quy trình thẩm định và ra quyết định xử lý của nhân viên QC đối với các mẻ sản xuất đang bị tạm dừng do sai sót.
Các dòng cơ bản:
1. Thẩm định sự cố:
   o Nhân viên QC xem xét lý do phát sinh sai lệch và nhập hướng xử lý khắc phục lên hệ thống.
2. Ra quyết định:
   o QC chọn "Resume" để cho phép mẻ hàng tiếp tục sản xuất hoặc "Reject" nếu mẻ hàng không đảm bảo chất lượng.

18. Đặc tả Use-case: Truy xuất nguồn gốc (Traceability)
Use case nghiệp vụ: Truy xuất nguồn gốc (Traceability)
Use case mô tả hoạt động tra cứu phả hệ sản phẩm, cho phép tìm kiếm thông tin từ thành phẩm quay ngược về nguồn gốc nguyên liệu.
Các dòng cơ bản:
1. Thực hiện tra cứu:
   o Người dùng nhập mã số lô sản xuất (Batch No) cần kiểm tra.
   o Hệ thống hiển thị cây phả hệ bao gồm nguyên liệu đầu vào, các công đoạn đã thực hiện và danh sách nhân sự tham gia.

19. Đặc tả Use-case: Quản lý Phiếu kiểm nghiệm (Certificates)
Use case nghiệp vụ: Quản lý Phiếu kiểm nghiệm (Certificates)
Use case mô tả việc đính kèm và kiểm soát kết quả kiểm nghiệm chất lượng cho từng lô nguyên vật liệu.
Các dòng cơ bản:
1. Cập nhật kết quả:
   o Nhập mã số phiếu kiểm nghiệm và ghi nhận kết quả đánh giá (Đạt chuẩn hoặc Không đạt chuẩn).
2. Kiểm soát sử dụng:
   o Hệ thống chỉ cho phép xuất dùng những lô nguyên liệu đã được xác nhận kết quả "Đạt chuẩn" trên phiếu kiểm nghiệm.
