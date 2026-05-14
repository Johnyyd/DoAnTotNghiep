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

2. Đặc tả Use-case: Quản lý Tài khoản và Thông tin nhân viên
Use case nghiệp vụ: Quản lý thông tin nhân viên
Use case bắt đầu khi quản lý nhân sự thực hiện việc quản lý và cập nhật dữ liệu liên quan đến nhân viên trong hệ thống. Mục tiêu của use case là đảm bảo thông tin nhân viên luôn được cập nhật chính xác và đầy đủ.
Các dòng cơ bản:
1. Quản lý nhân sự cập nhật hồ sơ:
   o Quản lý nhân sự nhập và cập nhật thông tin nhân viên vào hệ thống quản lý nhân sự.
   o Thiết lập mã số xác nhận cá nhân (mã PIN) gồm 6 chữ số để nhân viên dùng làm chữ ký điện tử.
2. Theo dõi và kiểm tra:
   o Quản lý nhân sự theo dõi và kiểm tra thông tin nhân viên để đảm bảo dữ liệu không có sai sót.
   o Hệ thống lưu trữ các thông tin cập nhật và tự động ghi lại người đã thực hiện thao tác quản trị này.
Các dòng thay thế:
• Tại bước 2: Nếu thông tin nhân viên bị thiếu hoặc không chính xác, quản lý nhân sự sẽ yêu cầu nhân viên bổ sung và chỉnh sửa.

3. Đặc tả Use-case: Cấu hình Khu vực sản xuất
Use case nghiệp vụ: Cấu hình Khu vực sản xuất
Use case này mô tả việc thiết lập các phòng chức năng và khu vực làm việc trong nhà máy phục vụ cho quá trình sản xuất dược phẩm.
Các dòng cơ bản:
1. Thiết lập khu vực:
   o Nhân viên văn phòng nhập tên phòng, mã định danh phòng và loại khu vực sạch tương ứng.
   o Thực hiện gán danh sách các máy móc thiết bị cố định vào từng phòng làm việc cụ thể.
Các dòng thay thế:
• Tại bước 1: Nếu mã số phòng đã được sử dụng cho một khu vực khác, hệ thống sẽ yêu cầu người dùng thay đổi mã phòng mới.

4. Đặc tả Use-case: Quản lý nguyên liệu
Use case nghiệp vụ: Quản lý nguyên liệu
Use case bắt đầu khi quản lý kho theo dõi lượng nguyên liệu trong kho và thực hiện đặt hàng khi cần thiết. Mục tiêu của use case là đảm bảo nguồn nguyên liệu luôn đủ đáp ứng cho quá trình sản xuất.
Các dòng cơ bản:
1. Kiểm tra tồn kho:
   o Quản lý kho kiểm tra số lượng nguyên liệu hiện tại trong kho so với số nguyên liệu cần dùng cho các lệnh sản xuất sắp tới.
2. Cập nhật và đặt hàng:
   o Quản lý kho cập nhật lượng nguyên liệu đã sử dụng và thực hiện lập yêu cầu đặt hàng bổ sung nếu cần thiết.
   o Ghi nhận các yêu cầu bảo quản đặc biệt về nhiệt độ và độ ẩm cho từng loại nguyên liệu.
Các dòng thay thế:
• Tại bước 1: Nếu nguyên liệu sắp hết hoặc không đủ cho cỡ lô dự kiến, quản lý kho sẽ lập đơn đặt hàng để bổ sung nguyên liệu kịp thời.

5. Đặc tả Use-case: Quản lý Thiết bị và Kiểm Tra Thiết Bị Sử Dụng
Use case nghiệp vụ: Quản lý Thiết bị và Kiểm Tra Thiết Bị Sử Dụng
Use case mô tả việc theo dõi danh sách máy móc và kiểm soát trạng thái vệ sinh của thiết bị trước khi bắt đầu mỗi mẻ sản xuất.
Các dòng cơ bản:
1. Quản lý thông tin thiết bị:
   o Nhập tên máy, mã số máy và vị trí lắp đặt máy trong phân xưởng sản xuất.
   o Cập nhật trạng thái hiện tại của máy: Đang sẵn sàng làm việc, Đang chờ vệ sinh hoặc Đang sửa chữa.
2. Kiểm tra trước khi sử dụng:
   o Công nhân thực hiện tra cứu trạng thái máy trên ứng dụng di động để đảm bảo máy đủ điều kiện vận hành và đã được vệ sinh sạch sẽ.
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

8. Đặc tả Use-case: Kiểm Duyệt Lệnh Sản Xuất
Use case nghiệp vụ: Kiểm Duyệt Lệnh Sản Xuất
Use case mô tả quy trình nhân viên kiểm soát chất lượng (QC) thẩm định lệnh sản xuất để đảm bảo tính hợp lệ trước khi thực hiện.
Các dòng cơ bản:
1. Kiểm tra và phê duyệt:
   o Nhân viên QC xem xét các thông số trong lệnh sản xuất và định mức nguyên liệu đã tính toán.
   o Nhân viên QC thực hiện ký xác nhận bằng mã số cá nhân để phê duyệt cho phép sản xuất.
2. Cấp phép thực thi:
   o Sau khi duyệt, lệnh sản xuất được chuyển trạng thái sẵn sàng để công nhân dưới xưởng có thể bắt đầu làm việc.
Các dòng thay thế:
• Tại bước 1: Nếu nhập sai mã số cá nhân xác thực, hệ thống sẽ không thực hiện lệnh duyệt để bảo vệ an toàn quy trình.

9. Đặc tả Use-case: Quản lý Mẻ sản xuất và Thống kê sản phẩm
Use case nghiệp vụ: Thống kê sản phẩm
Use case bắt đầu khi quản lý tiến hành tổng hợp và thống kê số lượng sản phẩm đã sản xuất. Mục tiêu của use case là tạo ra báo cáo chi tiết và chính xác về số lượng và chất lượng sản phẩm.
Các dòng cơ bản:
1. Thu thập và tổng hợp:
   o Quản lý thu thập dữ liệu sản phẩm từ các công đoạn sản xuất thực tế (Cân, Trộn, Đóng gói).
   o Hệ thống tự động chia mẻ và gán mã số định danh duy nhất (Batch No) cho từng mẻ hàng.
2. Lập báo cáo:
   o Quản lý tổng hợp và lập báo cáo thống kê, bao gồm số lượng thực tế, chất lượng (đạt/không đạt), và tiến độ sản xuất.
Các dòng thay thế:
• Tại bước 2: Nếu có sai sót trong dữ liệu thống kê, quản lý sẽ kiểm tra lại nhật ký mẻ và chỉnh sửa báo cáo cho phù hợp.

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
   o Nhân viên cân ghi nhận các thông tin liên quan đến quá trình cân và nhập mã số cá nhân để thực hiện ký tên điện tử.
Các dòng thay thế:
• Tại bước 1: Nếu khối lượng thực tế sai lệch vượt mức cho phép, nhân viên phải thực hiện cân lại hoặc giải trình lý do để điều chỉnh khối lượng theo yêu cầu.

13. Đặc tả Use-case: Thực thi công đoạn Trộn (Mixing)
Use case nghiệp vụ: Thực thi công đoạn Trộn (Mixing)
Use case mô tả quy trình trộn bột nguyên liệu, ghi nhận các thông số vận hành máy và kiểm soát quy cách đóng gói sơ bộ sau khi trộn.
Các dòng cơ bản:
1. Vận hành máy trộn:
   o Nhân viên thực hiện nhập giờ bắt đầu, tốc độ quay của máy và thời gian trộn dự kiến theo quy định.
   o Xác nhận việc nạp liệu đã thực hiện đúng trình tự hướng dẫn để đảm bảo độ đồng nhất.
2. Kiểm tra đóng gói bột:
   o Nhân viên xác nhận tình trạng vệ sinh của thùng chứa và việc sử dụng túi PE 2 lớp để chứa bột sau khi trộn.
   o Ghi nhận khối lượng bột đóng gói thực tế sau khi hoàn tất công đoạn.
3. Ký xác nhận:
   o Nhân viên nhập mã số cá nhân (PIN) để thực hiện ký tên điện tử hoàn tất công đoạn.
Các dòng thay thế:
• Tại bước 1: Nếu thời gian hoặc tốc độ trộn thực tế sai lệch so với quy trình, hệ thống sẽ đưa ra cảnh báo để nhân viên điều chỉnh.

14. Đặc tả Use-case: Thực thi công đoạn Sấy (Drying)
Use case nghiệp vụ: Thực thi công đoạn Sấy (Drying)
Use case mô tả việc theo dõi quá trình sấy, kiểm soát nhiệt độ và kiểm tra chất lượng sản phẩm thông qua chỉ số độ ẩm sau khi sấy.
Các dòng cơ bản:
1. Giám sát quá trình sấy:
   o Nhân viên ghi nhận nhiệt độ sấy cài đặt và theo dõi biến động nhiệt độ thực tế của thiết bị trong suốt quá trình vận hành.
2. Kiểm tra kết quả độ ẩm:
   o Thực hiện đo và nhập chỉ số độ ẩm của sản phẩm sau khi kết thúc quá trình sấy (Yêu cầu tiêu chuẩn đạt < 5%).
3. Ký xác nhận hoàn tất:
   o Nhân viên thực hiện nhập mã số cá nhân để ký tên điện tử và đóng công đoạn sấy.
Các dòng thay thế:
• Tại bước 2: Nếu chỉ số độ ẩm đo được vẫn cao hơn 5%, hệ thống yêu cầu nhân viên phải thực hiện sấy bổ sung cho đến khi đạt chuẩn.

15. Đặc tả Use-case: Ký xác nhận điện tử (Digital Signature)
Use case nghiệp vụ: Ký xác nhận điện tử (Digital Signature)
Use case mô tả cơ chế xác thực trách nhiệm của nhân sự sau mỗi bước công việc bằng mã số PIN định danh cá nhân.
Các dòng cơ bản:
1. Thực hiện ký số:
   o Khi hoàn thành một công đoạn, hệ thống yêu cầu nhân viên nhập mã số cá nhân gồm 6 chữ số.
   o Hệ thống kiểm tra mã PIN và lưu vết tên người thực hiện kèm thời điểm xác nhận chính xác vào nhật ký điện tử.
Các dòng thay thế:
• Tại bước 1: Nếu nhập sai mã số PIN, hệ thống sẽ thông báo lỗi và yêu cầu thực hiện lại.

16. Đặc tả Use-case: Quản lý Sai lệch (Deviation)
Use case nghiệp vụ: Quản lý Sai lệch (Deviation)
Use case mô tả cơ chế tự động phát hiện và cảnh báo khi các dữ liệu sản xuất thực tế vượt ra ngoài ngưỡng an toàn đã thiết lập.
Các dòng cơ bản:
1. Phát hiện sai lệch:
   o Hệ thống tự động so sánh giá trị nhập vào (khối lượng cân, độ ẩm, nhiệt độ) với định mức tiêu chuẩn.
   o Nếu giá trị vượt ngưỡng cho phép, hệ thống tự động hiển thị cảnh báo đỏ cho nhân viên.
2. Tạm dừng mẻ hàng:
   o Hệ thống tự động chuyển trạng thái mẻ sản xuất sang "Hold" và chặn không cho phép thực hiện các bước tiếp theo để chờ QC xử lý.

17. Đặc tả Use-case: Duyệt xử lý sai lệch
Use case nghiệp vụ: Duyệt xử lý sai lệch
Use case mô tả quy trình thẩm định và ra quyết định xử lý của nhân viên QC đối với các sai lệch phát sinh trong quá trình sản xuất.
Các dòng cơ bản:
1. Thẩm định sự cố:
   o Nhân viên QC xem xét lý do sai lệch được ghi nhận trên hệ thống và nhập hướng xử lý khắc phục.
2. Quyết định xử lý:
   o QC xác nhận bằng chữ ký số để chuyển trạng thái mẻ hàng từ "Hold" sang tiếp tục sản xuất hoặc hủy bỏ lô hàng.

18. Đặc tả Use-case: Truy xuất nguồn gốc (Traceability)
Use case nghiệp vụ: Truy xuất nguồn gốc (Traceability)
Use case mô tả hoạt động tra cứu phả hệ sản phẩm, cho phép tìm kiếm thông tin từ số lô thành phẩm quay ngược về toàn bộ chuỗi cung ứng và sản xuất.
Các dòng cơ bản:
1. Thực hiện tra cứu:
   o Người dùng nhập mã số lô sản xuất (Batch No) của thành phẩm vào hệ thống tra cứu.
   o Hệ thống hiển thị cây phả hệ bao gồm: nguồn gốc nguyên liệu đầu vào, các máy móc đã sử dụng và danh sách nhân sự đã tham gia thao tác.

19. Đặc tả Use-case: Quản lý Phiếu kiểm nghiệm (Certificates)
Use case nghiệp vụ: Quản lý Phiếu kiểm nghiệm (Certificates)
Use case mô tả việc đính kèm và kiểm soát kết quả kiểm nghiệm chất lượng cho từng lô nguyên vật liệu và thành phẩm.
Các dòng cơ bản:
1. Cập nhật kết quả:
   o Nhân viên nhập mã số phiếu kiểm nghiệm và ghi nhận kết quả đánh giá đạt chuẩn hoặc không đạt chuẩn.
2. Kiểm soát xuất dùng:
   o Hệ thống tự động kiểm tra trạng thái phiếu kiểm nghiệm; chỉ những lô nguyên liệu có kết quả đạt chuẩn mới được phép đưa vào sản xuất.
