# Multi-Agent Workflow: DoAnTotNghiep (GMP System)

Tài liệu này định nghĩa quy trình làm việc đa tác vụ (multi-agent workflow) sử dụng bộ kỹ năng **Cavecrew** (đã cài đặt qua `skills-lock.json`) để xử lý các tác vụ phức tạp, đặc biệt là sửa các lỗi logic và dữ liệu trong thư mục `MobileApp` và API backend.

## 1. Tổ chức Đội hình (Agent Roles)

Hệ thống sử dụng 4 vai trò chính dựa trên Cavecrew nhằm tối ưu hóa token (dùng caveman mode) và tránh cạn kiệt context:

1. **Main Thread (Orchestrator)**: Đóng vai trò là Kiến trúc sư và Quản lý. Nhận yêu cầu từ người dùng, lập kế hoạch, gọi các sub-agent và tổng hợp kết quả. Không trực tiếp viết code nếu tác vụ ảnh hưởng nhiều file.
2. **`cavecrew-investigator` (Trinh sát)**: Chuyên rà soát mã nguồn. Dùng để tìm kiếm vị trí file, dòng code (ví dụ: tìm tất cả các chỗ dùng `double.tryParse` hoặc truy xuất luồng `parametersData`).
3. **`cavecrew-builder` (Thợ xây)**: Chuyên thực thi sửa đổi cục bộ (1-2 file). Chỉnh sửa mã nguồn dựa trên định vị từ Investigator.
4. **`cavecrew-reviewer` (Kiểm duyệt QC)**: Đọc diff sau khi Builder sửa xong. Đánh giá tác động đến logic nghiệp vụ GMP (phân tích blast radius).

## 2. Quy trình Thực thi Chuẩn (Locate → Fix → Verify)

Áp dụng quy trình 3 bước này cho các đợt fix bug (ví dụ: chuỗi bug đã phát hiện trong `MobileApp`):

### Bước 1: Điều tra (Locate)
Main Thread gọi Investigator để tìm chính xác tọa độ lỗi.
> **Prompt mẫu**: *"Spawn cavecrew-investigator: Tìm tất cả các đoạn mã gọi `double.tryParse` trong thư mục `MobileApp/lib/screens/`. Trả về định dạng nén caveman."*

### Bước 2: Sửa chữa (Fix)
Main Thread phân tích kết quả của Investigator, sau đó giao việc cho Builder kèm theo nguyên tắc của dự án (Project Context).
> **Prompt mẫu**: *"Spawn cavecrew-builder: Sửa file `weighing_step_screen.dart` và `mixing_step_screen.dart`. Thay thế `double.tryParse(x)` bằng `double.tryParse(x.replaceAll(',', '.'))` để sửa lỗi dấu phẩy thập phân ở Việt Nam. Giữ lại logic validation của GMP."*

### Bước 3: Kiểm duyệt (Verify)
Main Thread gọi Reviewer để kiểm tra chéo, đảm bảo không có tác dụng phụ (side-effects).
> **Prompt mẫu**: *"Spawn cavecrew-reviewer: Review diff của các file vừa sửa trong `MobileApp`. Đảm bảo luồng tính toán BMR Yield không bị ảnh hưởng và tuân thủ null-safety."*

## 3. Project-Specific Context (Nguyên tắc tiêm vào Sub-agent)

Khi Main Thread gọi (spawn) bất kỳ sub-agent nào trong dự án **DoAnTotNghiep**, bắt buộc phải kèm theo các context sau để sub-agent không làm hỏng logic nghiệp vụ:

- **Dữ liệu số (Localization)**: Dấu phẩy `,` phải được xử lý thành dấu chấm `.` trước khi parse sang `double`.
- **API Payload Cấu trúc**: Cần chú ý sự khác biệt giữa các bước. Sấy (`Drying`) bọc data trong `rawInputs`, trong khi Cân (`Weighing`) và Trộn (`Mixing`) để data ở root của `parametersData`.
- **GMP Phase Sequence**: Trạng thái mẻ phải tuân thủ nghiêm ngặt: `Precheck -> Input -> PendingQC -> Execution -> Completed`. Bất kỳ thay đổi code nào liên quan đến `_nextPhase()` đều phải kiểm tra hàm `_isFormValid()`.
- **Lưu ý GitNexus**: Trước khi Builder sửa đổi một hàm cốt lõi (ví dụ: `_submit` hoặc `validateInput`), Reviewer hoặc Main Thread phải sử dụng `gitnexus_impact` để kiểm tra tầm ảnh hưởng.

## 4. Tối ưu Token (Caveman Compress)

- Yêu cầu các sub-agent **luôn luôn trả về kết quả ở dạng nén (compressed agent output)**.
- Khi cần tạo commit message, sử dụng tự động `caveman-commit` để giữ lịch sử Git gọn gàng.
- Nếu documentation của dự án quá dài, sử dụng `/caveman-compress` để nén các file `.md` hướng dẫn.
