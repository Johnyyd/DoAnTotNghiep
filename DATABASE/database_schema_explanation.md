# Hướng dẫn tìm hiểu Cơ sở dữ liệu Hệ thống Dược phẩm (GMP-WHO)

Chào bạn, tài liệu này sẽ giúp bạn dễ dàng hình dung kiến trúc phân lớp dữ liệu của hệ thống **PharmaceuticalProcessingManagementSystem**. Thay vì liệt kê những thuật ngữ khô khan (như bảng này có khóa chính, khóa ngoại nào), mình sẽ giải thích cách các bảng (tables) móc nối với nhau theo dòng chảy thực tế của một nhà máy sản xuất thuốc nhé!

---

## 1. Quản lý nhân sự và phân quyền (Module User Management)

Để hệ thống hoạt động, điều đầu tiên chúng ta cần biết là "Ai đang làm gì?". Đó là nhiệm vụ của bảng **`AppUsers`**.
Bảng này lưu trữ toàn bộ hồ sơ nhân viên trong nhà máy, từ tên tài khoản đăng nhập (`Username`), họ tên người dùng (`FullName`) cho đến vai trò của họ (`Role` - ví dụ như Admin, chuyên viên kiểm tra chất lượng QC, hay công nhân vận hành xưởng).

- Mỗi nhân viên sẽ có một mã định danh riêng (`UserId` - đóng vai trò là khóa chính).
- Khi có nhân viên nghỉ việc, thay vì xóa dữ liệu (điều tối kỵ trong chuẩn GMP vì cần truy vết lịch sử), mình sẽ chỉ đổi trạng thái `IsActive` về 0 (ngưng hoạt động).

---

## 2. Dữ liệu gốc của hệ thống (Module Master Data)

Đây là những dữ liệu lõi, được đóng vai trò như bộ từ điển để các quy trình phía sau có thể lôi ra sử dụng.

***Bảng Đơn vị tính (`UnitOfMeasure`)**:

Quản lý danh mục các đơn vị đo lường như kg, gram, lít, viên nén, vỉ, hộp... Mỗi đơn vị có một ID nội bộ (`UomId`).

***Bảng Danh mục Vật tư (`Materials`)**: Chứa tất cả những thứ hữu hình trong nhà máy bao gồm: nguyên liệu thô, bao bì, bán thành phẩm và thành phẩm.

- Mỗi loại vật tư sẽ gắn liền với một đơn vị lưu kho mặc định bằng cách trỏ về bảng Đơn vị tính (`BaseUomId`).

- Để phân loại dễ dàng, cột `Type` quy định chặt chẽ vật tư này là nguyên liệu (RawMaterial) hay bao bì (Packaging)...

***Bảng Thiết bị máy móc (`Equipments`)**: Chứa danh sách các máy móc (ví dụ: máy sấy tầng sôi, cân phân tích, máy ép vỉ...). Theo chuẩn mực ngành dược, mọi thao tác người dùng đều phải ghi rõ làm trên bằng cái máy nào, nên mỗi máy ở đây đều có một mã định danh duy nhất (`EquipmentCode`).

---

## 3. Quản lý Quy trình và Công thức nấu (Module Process Definition)

Trước khi sản xuất ra một loại thuốc bất kỳ, bộ phận Nghiên cứu (R&D) và Quản lý chất lượng (QA) phải định hình ra một Công thức chuẩn chỉnh trước đã.

***Bảng Công thức chính (`Recipes`)**: Đây là công thức cha, quy định xem để làm ra sản phẩm X (liên kết với `MaterialId`) thì cần một mẻ chuẩn mất bao nhiêu lượng (`BatchSize`). Mỗi công thức này bắt buộc phải có "chữ ký phê duyệt" của người cầm trịch (`ApprovedBy` - chính là tài khoản của nhân sự QA lấy từ bảng người dùng).
***Bảng Lượng định mức nguyên liệu - BOM (`RecipeBom`)**: Giải thích chi tiết "Bên trong công thức đó cần pha trộn tỉ lệ nguyên vật liệu ra sao?". Nó sẽ trỏ ngược về bảng Công thức mẹ (`RecipeId`) và đính kèm các loạt vật tư thành phần (`MaterialId`), với lượng yêu cầu chi tiết từng món (`Quantity`), cùng tỷ lệ hao hụt cho phép khi gia công (`WastePercentage`).
***Bảng Các bước vận hành (`RecipeRouting`)**: Vẽ ra cho công nhân từng bước phải thực hiện. Ví dụ: Bước 1 là đem nguyên liệu đi cân, Bước 2 mang vào lò sấy, Bước 3 đi dập viên nén. Tại mỗi bước, hệ thống có thể chủ động gợi ý sẵn máy móc nào sẽ được sử dụng (`DefaultEquipmentId`).

---

## 4. Thực thi Sản xuất tại Xưởng (Module Production Execution)

Công thức đã duyệt xong, giấy tờ sẵn sàng, giờ là lúc mang xuống xưởng để sản xuất thực tế!

***Bảng Lệnh sản xuất (`ProductionOrders`)**: Quản đốc sẽ tạo một tờ "Lệnh sản xuất" tổng thể dựa trên cuốn bí kíp công thức chuẩn (`RecipeId`). Họ sẽ định lượng rõ mình cần sản xuất bao nhiêu hàng kỳ này (`PlannedQuantity`) vào ngày nào.
***Bảng Mẻ / Lô sản xuất (`ProductionBatches`)**: Do máy móc nhà máy có năng suất giới hạn, một tờ Lệnh to tướng thường sẽ phải chẻ nhỏ ra thành nhiều Mẻ/Lô (Batch). Mỗi Mẻ sẽ được gắn một Số Batch duy nhất (`BatchNumber`). Nhờ bảng này, quản đốc biết mẻ thuốc đang ở trạng thái nào (mới lên lịch, đang chạy ở xưởng, hay đã làm xong chờ kiểm định).
***Bảng Nhật ký vận hành mẻ (`BatchProcessLogs`)**: Trong ngành dược, quyển số ghi chép này mang tính sống còn (Electronic Batch Record - EBR). Bảng này chịu trách nhiệm ghi lại mọi "cử động" nhỏ nhất diễn ra trong từng công đoạn: Ông công nhân nào vừa thực hiện thao tác (`OperatorId`), thực hiện trên cái máy số mấy (`EquipmentId`), bắt đầu chạy lúc mấy giờ, làm xong mấy giờ. Tính minh bạch là cao nhất.

---

## 5. Quản lý Kho bãi và Truy xuất vết khi sự cố (Module Inventory & Traceability)

Theo chuẩn Thực hành Sản xuất Tốt (GMP), lỡ có rủi ro người dùng uống thuốc bị dị ứng, mình phải ngay lập tức "truy vết" xem lô thuốc này dùng bột hóa chất nào, nhập ngày nào để chặn thu hồi ngay tập lập tức.

***Bảng Lô kho hàng tồn (`InventoryLots`)**: Khi thủ kho nhận xe chở nguyên liệu về, hàng hóa sẽ không đổ chung vào một xó mà được quản lý chẻ nhỏ theo từng Lô (`LotNumber`). Bảng này có trọng trách lớn là giữ chặt ngày hết hạn của dược liệu (`ExpiryDate`), nếu thuốc hết đát là hệ thống sẽ chặn không cho nhặt vào máy.
***Bảng Ghi nhận xuất kho vật tư (`MaterialUsage`)**: Mỗi khi công nhân tới kho xin xuất hóa chất để trộn ra một mẻ thuốc, thủ kho sẽ lập bản ghi vào đây. Bảng này móc nối và có thể trả lời trơn tru câu hỏi thót tim nhất: *"Mẻ thuốc này (`BatchId`) đã vung tay xài những lô nguyên liệu nào (`InventoryLotId`) nằm sâu trong góc kho, xài bao nhiêu kg lượng hóa chất (`QuantityUsed`) và cuối cùng, ai là người cấp phát mang ra (`DispensedBy`)?"*

---

## 6. Kiểm soát Hệ thống và Chất lượng (Module QC & Audit)

Khâu cuối cùng là đảm bảo rằng nguyên liệu đi vào hay thuốc làm ra đều không nhiễm bẩn.

***Bảng Kết quả Kiểm nghiệm (`QualityTests`)**: Máy móc hay nguyên liệu đều phải chịu ánh mắt khắt khe của đội QC. Lô hóa chất mới nhập, QC sẽ vào lấy mẫu. Nếu kết quả "Đạt" (`PassStatus = 1`), cái Lô đó mới được mở khóa để mang đi xào nấu.

***Bảng Nhật ký thầm lặng (`SystemAuditLog`)**: Đây là "chiếc hộp đen" kiêm Camera giám sát của toàn bộ hệ cơ sở dữ liệu (Audit Trail). Nếu một ai đó "lỡ tay" đổi một dòng dữ liệu định mức hay xóa hạn sử dụng lô thuốc, bảng này sẽ vạch trần bằng cách âm thầm chép lại y nguyên giá trị lúc trước (`OldValue`) và giá trị cắc cớ mới sửa (`NewValue`) cùng với tên thủ phạm gây án (`ChangedBy`).

---

*Với cách diễn đạt này, hy vọng bạn có thể nhìn nhận sơ đồ cơ sở dữ liệu GMP-WHO một cách sinh động mang tính quy trình nghiệp vụ thay vì những hàng code logic khô cứng. Chúc bạn vận hành hệ thống trơn tru!*
