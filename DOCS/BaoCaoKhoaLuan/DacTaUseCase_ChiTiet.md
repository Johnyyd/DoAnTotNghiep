# ĐẶC TẢ CHI TIẾT CÁC HOẠT ĐỘNG NGHIỆP VỤ HỆ THỐNG (GMP-WHO)

1. Đặc tả Use-case: Đăng Nhập Hệ Thống
Use case nghiệp vụ: Đăng Nhập Hệ Thống
Use case này mô tả quy trình nhân viên truy cập vào hệ thống để bắt đầu làm việc. Mục tiêu của use case là xác thực danh tính và phân quyền hạn cho từng cá nhân dựa trên vị trí công tác.
Các dòng cơ bản:
1. Nhân viên thực hiện đăng nhập:
   o Nhân viên nhập tên đăng nhập và mật khẩu cá nhân vào các ô tương ứng trên màn hình khởi động.
   o Sau khi nhập, nhân viên nhấn nút đăng nhập để hệ thống xác nhận thông tin.
2. Hệ thống kiểm tra và điều hướng:
   o Hệ thống đối chiếu thông tin với danh sách nhân sự đã được cấp phép trong cơ sở dữ liệu.
   o Nếu thông tin chính xác, hệ thống cho phép nhân viên truy cập vào giao diện làm việc phù hợp với vai trò (Quản lý, Kiểm soát chất lượng hoặc Công nhân).
Các dòng thay thế:
• Tại bước 1: 
   o Nếu nhân viên nhập sai tên đăng nhập hoặc mật khẩu, hệ thống sẽ hiển thị thông báo lỗi và yêu cầu thực hiện lại quy trình đăng nhập.
   o Nếu tài khoản của nhân viên đang bị tạm khóa, hệ thống sẽ từ chối truy cập và yêu cầu liên hệ bộ phận kỹ thuật để được hỗ trợ.

2. Đặc tả Use-case: Quản Lý Hồ Sơ Nhân Viên Và Mã Xác Nhận
Use case nghiệp vụ: Quản Lý Hồ Sơ Nhân Viên Và Mã Xác Nhận
Use case mô tả hoạt động quản lý thông tin nhân sự và thiết lập chữ ký số cho nhân viên. Mục tiêu là đảm bảo mọi nhân viên đều có định danh rõ ràng và có thể thực hiện ký xác nhận các thao tác sản xuất.
Các dòng cơ bản:
1. Quản trị viên cập nhật thông tin nhân viên:
   o Quản trị viên chọn nhân viên từ danh sách và thực hiện cập nhật các thông tin như họ tên, chức vụ, bộ phận làm việc.
   o Quản trị viên thiết lập một mã số xác nhận cá nhân (mã PIN) gồm 6 chữ số cho nhân viên đó.
2. Ghi nhận và lưu trữ:
   o Hệ thống lưu lại toàn bộ lịch sử thay đổi và tự động ghi nhận tên người quản trị đã thực hiện việc cập nhật này.
Các dòng thay thế:
• Tại bước 1: Nếu mã số xác nhận cá nhân không đủ 6 chữ số hoặc chứa các ký tự không phải là số, hệ thống sẽ hiển thị cảnh báo và yêu cầu chỉnh sửa lại cho đúng quy chuẩn.

3. Đặc tả Use-case: Quản Lý Danh Mục Nguyên Liệu
Use case nghiệp vụ: Quản Lý Danh Mục Nguyên Liệu
Use case này mô tả việc khai báo và quản lý thông tin các loại vật tư dùng trong sản xuất. Mục tiêu là tạo ra một cơ sở dữ liệu nguyên liệu chính xác để phục vụ cho các công đoạn sản xuất thuốc.
Các dòng cơ bản:
1. Khai báo thông tin nguyên liệu:
   o Nhân viên văn phòng thực hiện nhập tên nguyên liệu mới, mã số định danh và chọn đơn vị tính tương ứng (ví dụ: kg, g, viên).
   o Nhân viên ghi nhận các tiêu chuẩn về nhiệt độ và độ ẩm cần thiết để bảo quản nguyên liệu theo đúng quy định dược điển.
2. Lưu trữ danh mục:
   o Hệ thống lưu thông tin vào danh mục dùng chung để làm căn cứ thiết lập công thức và lệnh sản xuất sau này.
Các dòng thay thế:
• Tại bước 1: Nếu tên hoặc mã số nguyên liệu đã tồn tại trong hệ thống, máy sẽ đưa ra cảnh báo để tránh việc nhập trùng lặp dữ liệu.

4. Đặc tả Use-case: Thiết Lập Định Mức Và Quy Trình Sản Xuất
Use case nghiệp vụ: Thiết Lập Định Mức Và Quy Trình Sản Xuất
Use case mô tả quy trình xây dựng công thức sản xuất thuốc gốc. Mục tiêu là xác định chính xác số lượng nguyên liệu và trình tự các bước thực hiện để đảm bảo mẻ thuốc luôn đạt chất lượng đồng nhất.
Các dòng cơ bản:
1. Xây dựng công thức gốc:
   o Người quản lý nhập tên loại thuốc cần sản xuất và quy mô lô hàng tiêu chuẩn cho công thức này.
   o Người quản lý lập danh sách các nguyên liệu cần thiết và khối lượng chính xác cho từng thành phần theo quy định.
2. Thiết lập trình tự công đoạn:
   o Người quản lý xác định thứ tự thực hiện các bước dưới xưởng như công đoạn cân, trộn, sấy và đóng gói.
3. Phê duyệt và khóa dữ liệu:
   o Sau khi kiểm tra, người quản lý xác nhận duyệt công thức. Hệ thống thực hiện khóa dữ liệu để không ai có thể tự ý thay đổi trong quá trình sản xuất.
Các dòng thay thế:
• Tại bước 1: Nếu công thức bị thiếu các thành phần quan trọng hoặc sai lệch khối lượng định mức, hệ thống sẽ ngăn chặn việc phê duyệt để đảm bảo an toàn sản xuất.

5. Đặc tả Use-case: Quản Lý Máy Móc Và Thiết Bị Sản Xuất
Use case nghiệp vụ: Quản Lý Máy Móc Và Thiết Bị Sản Xuất
Use case mô tả việc theo dõi danh sách và trạng thái hoạt động của các thiết bị trong nhà máy. Mục tiêu là đảm bảo máy móc luôn sạch và ở trạng thái tốt nhất trước khi đưa vào sản xuất.
Các dòng cơ bản:
1. Cập nhật danh sách máy móc:
   o Quản trị viên nhập thông tin chi tiết về máy như tên máy (máy sấy, máy trộn), mã máy và vị trí lắp đặt cụ thể trong xưởng.
2. Theo dõi trạng thái thiết bị:
   o Nhân viên cập nhật tình trạng hoạt động hàng ngày của máy: máy đang sẵn sàng, máy đang hỏng hoặc máy đang chờ vệ sinh sau khi làm việc.
3. Kiểm tra trước khi sử dụng:
   o Công nhân thực hiện kiểm tra trạng thái máy trên ứng dụng trước khi bắt đầu công việc để đảm bảo máy đủ điều kiện vận hành.
Các dòng thay thế:
• Tại bước 3: Nếu thiết bị đang ở trạng thái "Chờ vệ sinh" hoặc "Đang hỏng", hệ thống sẽ chặn không cho phép công nhân thực hiện công việc trên máy đó.

6. Đặc tả Use-case: Lập Lệnh Sản Xuất Mới
Use case nghiệp vụ: Lập Lệnh Sản Xuất Mới
Use case bắt đầu khi người quản lý tạo ra một yêu cầu sản xuất cụ thể cho mẻ hàng. Mục tiêu là chuyển đổi từ kế hoạch sản xuất sang một lệnh thực thi thực tế với quy mô lô hàng cụ thể.
Các dòng cơ bản:
1. Khởi tạo yêu cầu sản xuất:
   o Người quản lý chọn loại thuốc cần sản xuất từ danh sách các công thức đã được duyệt trước đó.
   o Người quản lý nhập số lượng thuốc thực tế cần làm. Hệ thống tự động tính toán tổng khối lượng tất cả nguyên liệu cần chuẩn bị cho mẻ này.
2. Ghi nhận lệnh sản xuất:
   o Hệ thống lưu yêu cầu ở trạng thái chờ duyệt và hiển thị trên bảng theo dõi kế hoạch chung của nhà máy.
Các dòng thay thế:
• Tại bước 1: Nếu số lượng thuốc yêu cầu vượt quá khả năng đáp ứng của máy móc, hệ thống sẽ đưa ra cảnh báo để người quản lý điều chỉnh lại quy mô lô hàng cho phù hợp.

7. Đặc tả Use-case: Kiểm Duyệt Lệnh Sản Xuất
Use case nghiệp vụ: Kiểm Duyệt Lệnh Sản Xuất
Use case mô tả quy trình nhân viên kiểm soát chất lượng thẩm định lệnh sản xuất. Mục tiêu là đảm bảo lệnh sản xuất hoàn toàn chính xác trước khi cho phép công nhân thực hiện.
Các dòng cơ bản:
1. QC thực hiện thẩm định:
   o Nhân viên kiểm soát chất lượng xem xét kỹ lưỡng danh sách nguyên liệu và khối lượng đã được hệ thống tính toán trong lệnh sản xuất.
2. Phê duyệt và ký xác nhận:
   o Sau khi xác nhận đúng chuẩn, nhân viên QC nhấn duyệt và thực hiện nhập mã số cá nhân để ký tên xác nhận cho lệnh này.
3. Kích hoạt sản xuất:
   o Hệ thống chính thức cấp phép sản xuất mẻ hàng và thực hiện khóa cứng các thông số định mức để đảm bảo công nhân thực hiện đúng kế hoạch.
Các dòng thay thế:
• Tại bước 2: Nếu nhập sai mã số xác nhận cá nhân, hệ thống sẽ từ chối việc duyệt lệnh để đảm bảo tính an toàn và minh bạch của quy trình.

8. Đặc tả Use-case: Kiểm Tra Vệ Sinh Và Môi Trường
Use case nghiệp vụ: Kiểm Tra Vệ Sinh Và Môi Trường
Use case này mô tả quy trình kiểm tra vệ sinh và điều kiện môi trường trước khi thực hiện các bước sản xuất cao khô. Mục tiêu của use case là đảm bảo môi trường sản xuất đáp ứng đầy đủ các tiêu chuẩn vệ sinh và kỹ thuật.
Các dòng cơ bản:
1. Kiểm tra vệ sinh phòng cân:
   o Nhân viên kiểm tra vệ sinh phòng cân, đảm bảo không có bụi bẩn, rác thải hoặc các yếu tố không đạt chuẩn.
   o Ghi nhận trạng thái vệ sinh của phòng cân (sạch hoặc không sạch).
2. Kiểm tra các chỉ số môi trường, máy móc:
   o Nhiệt độ: Đo và ghi nhận nhiệt độ trong phòng cân. Yêu cầu phải nằm trong phạm vi 21°C – 25°C.
   o Độ ẩm: Đo và ghi nhận độ ẩm, đảm bảo từ 45% – 70%.
   o Áp lực phòng: Kiểm tra và ghi nhận áp lực phòng, yêu cầu ≥ 10 Pa.
   o Máy móc: Kiểm tra trạng thái máy móc và dụng cụ (sạch hoặc không sạch).
3. Ghi nhận kết quả kiểm tra:
   o Nhân viên ghi nhận toàn bộ kết quả kiểm tra vệ sinh và môi trường.
   o Nếu đạt chuẩn, xác nhận và chuyển sang bước tiếp theo trong quy trình sản xuất.
Các dòng thay thế:
• Tại bước 1:
   o Nếu phòng cân không đạt yêu cầu vệ sinh (ví dụ: có bụi bẩn, rác thải), nhân viên kiểm tra dừng quy trình và thông báo cho bộ phận phụ trách để xử lý.
   o Sau khi xử lý, nhân viên thực hiện kiểm tra lại.
• Tại bước 2:
   o Nếu một hoặc nhiều chỉ số môi trường không nằm trong giới hạn tiêu chuẩn:
     ▪ Nhân viên kiểm tra: Ghi nhận các chỉ số không đạt và báo cáo cho bộ phận kỹ thuật để điều chỉnh môi trường.
     ▪ Người giám sát: Phê duyệt việc tạm ngừng quy trình để đảm bảo điều kiện môi trường đạt yêu cầu.
   o Sau khi điều chỉnh, thực hiện đo lại các chỉ số và ghi nhận kết quả mới.

9. Đặc tả Use-case: Cân Nguyên Liệu Sản Xuất Cao Khô
Use case nghiệp vụ: Cân Nguyên Liệu Sản Xuất Cao Khô
Use case bắt đầu khi nhân viên cân và người kiểm tra thực hiện việc cân nguyên liệu để sản xuất cao khô. Mục tiêu của use case là cung cấp quy trình hiện cân nguyên liệu theo tiêu chuẩn.
Các dòng cơ bản:
1. Nhân viên cân thực hiện cân nguyên liệu:
   o Nhân viên cân thực hiện chọn loại nguyên liệu cần cân từ danh sách yêu cầu hiển thị trên ứng dụng.
   o Nhân viên thực hiện cân và ghi nhận khối lượng thực tế đã cân được vào hệ thống.
   o Hệ thống tự động so sánh khối lượng thực tế với yêu cầu, nếu sai lệch trong khoảng 5%, hệ thống báo hiệu đạt yêu cầu.
2. Nhân viên cân xác nhận và ghi nhận:
   o Nhân viên cân thực hiện nhập mã số cá nhân để ký tên xác nhận kết quả cân và lưu vào hồ sơ lô điện tử.
Các dòng thay thế:
• Tại bước 1: Nếu khối lượng nguyên liệu thực tế chênh lệch vượt quá 5% so với yêu cầu, hệ thống sẽ báo lỗi và yêu cầu nhân viên cân báo cáo lý do hoặc thực hiện cân lại cho đúng quy định.

10. Đặc tả Use-case: Vận Hành Trộn Và Sấy Cao Khô
Use case nghiệp vụ: Vận Hành Trộn Và Sấy Cao Khô
Use case mô tả quy trình ghi nhận các bước chế biến thuốc thực tế dưới xưởng. Mục tiêu là lưu lại toàn bộ diễn biến quá trình trộn và sấy để đảm bảo tính minh bạch của nhật ký sản xuất.
Các dòng cơ bản:
1. Khởi động và vận hành:
   o Công nhân thực hiện nhập các thông số khởi động như giờ bắt đầu, tốc độ máy và nhiệt độ sấy cài đặt.
   o Công nhân xác nhận đã thực hiện nạp nguyên liệu vào máy theo đúng trình tự hướng dẫn.
2. Ghi nhận kết thúc:
   o Sau khi quy trình hoàn tất, công nhân nhập giờ kết thúc và ghi nhận kết quả kiểm tra (ví dụ: độ ẩm hạt sau khi sấy phải dưới 5%).
3. Ký xác nhận:
   o Công nhân thực hiện nhập mã số cá nhân để ký tên xác nhận hoàn tất công đoạn và lưu dữ liệu.
Các dòng thay thế:
• Tại bước 2: Nếu kết quả kiểm tra độ ẩm sau sấy không đạt (trên 5%), hệ thống sẽ yêu cầu thực hiện sấy thêm và ghi nhận lại kết quả mới cho đến khi đạt chuẩn.

11. Đặc tả Use-case: Xử Lý Sự Cố Và Sai Sót
Use case nghiệp vụ: Xử Lý Sự Cố Và Sai Sót
Use case mô tả quy trình giải quyết các vấn đề bất thường phát sinh trong sản xuất. Mục tiêu là đảm bảo mọi sai lệch đều được nhân viên QC kiểm soát và đưa ra hướng xử lý an toàn.
Các dòng cơ bản:
1. Tạm dừng do sự cố:
   o Khi phát hiện sai sót (như cân sai, máy hỏng), hệ thống tự động tạm dừng lệnh sản xuất và thông báo cho nhân viên kiểm soát chất lượng.
2. QC điều tra và xử lý:
   o Nhân viên QC thực hiện kiểm tra hiện trường, tìm nguyên nhân và nhập hướng giải quyết vào hệ thống.
3. Khôi phục quy trình:
   o Sau khi sự cố đã được giải quyết an toàn, nhân viên QC thực hiện lệnh cho phép quy trình sản xuất được tiếp tục thực hiện.
Các dòng thay thế:
• Tại bước 2: Nếu sự cố nghiêm trọng ảnh hưởng đến chất lượng, nhân viên QC sẽ ra quyết định hủy bỏ mẻ hàng đó và ghi nhận lý do chi tiết vào hệ thống.

12. Đặc tả Use-case: Truy Xuất Nguồn Gốc Lô Sản Phẩm
Use case nghiệp vụ: Truy Xuất Nguồn Gốc Lô Sản Phẩm
Use case này mô tả hoạt động tra cứu phả hệ sản phẩm từ thành phẩm về nguyên liệu đầu vào. Mục tiêu là hỗ trợ việc điều tra chất lượng và thu hồi sản phẩm khi cần thiết.
Các dòng cơ bản:
1. Thực hiện tra cứu:
   o Nhân viên nhập mã số lô sản xuất của hộp thuốc vào hệ thống tra cứu.
2. Hiển thị thông tin phả hệ:
   o Hệ thống hiển thị chi tiết các mẻ hàng đã làm ra lô thuốc đó và danh sách toàn bộ các lô nguyên liệu đầu vào đã được sử dụng.
3. Xem chi tiết thao tác:
   o Nhân viên có thể xem lại từng người đã thực hiện cân, trộn, sấy, thời điểm thực hiện và các chữ ký xác nhận tương ứng.
Các dòng thay thế:
• Tại bước 1: Nếu mã số lô không tồn tại trong hệ thống, máy sẽ thông báo không tìm thấy dữ liệu và yêu cầu người dùng kiểm tra lại mã số.

13. Đặc tả Use-case: Lưu Nhật Ký Lịch Sử Hệ Thống
Use case nghiệp vụ: Lưu Nhật Ký Lịch Sử Hệ Thống
Use case mô tả cơ chế tự động ghi lại mọi biến động dữ liệu trên phần mềm. Mục tiêu là đảm bảo tính trung thực tuyệt đối của dữ liệu theo các tiêu chuẩn nghiêm ngặt của ngành dược.
Các dòng cơ bản:
1. Tự động ghi nhận thay đổi:
   o Mọi hành động thêm mới, sửa đổi hoặc xóa dữ liệu trên hệ thống đều được máy tự động theo dõi và ghi lại.
2. Lưu trữ vết dữ liệu:
   o Hệ thống ghi lại một bản chứng cứ đầy đủ bao gồm: giá trị dữ liệu cũ, giá trị mới sau khi sửa, người thực hiện và thời gian chính xác.
3. Bảo vệ dữ liệu nhật ký:
   o Các bản ghi nhật ký lịch sử này được hệ thống bảo vệ, không ai có quyền sửa đổi hoặc xóa bỏ chúng khỏi hệ thống.
Các dòng thay thế:
• Use case này là hoạt động tự động của hệ thống nên không có dòng thay thế do tác động của người dùng.
