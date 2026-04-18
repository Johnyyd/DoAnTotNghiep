# 📖 Hướng Dẫn Cài Đặt Cơ Sở Dữ Liệu (GMP-WHO DB)

Tài liệu này hướng dẫn cách thiết lập cơ sở dữ liệu cho dự án **Pharmaceutical Processing Management System** theo tiêu chuẩn GMP-WHO.

## 📌 Yêu cầu chuẩn bị
- **SQL Server**: Phiên bản 2019 trở lên (hoặc chạy qua Docker).
- **Phần mềm quản lý**: SQL Server Management Studio (SSMS) hoặc Azure Data Studio.

---

## 🚀 Các bước cài đặt

### Bước 1: Tạo cơ sở dữ liệu mới
Mở SSMS, kết nối tới Server và chạy lệnh sau để tạo DB:
```sql
CREATE DATABASE [PharmaceuticalProcessingManagementSystem];
GO
```

### Bước 2: Khởi tạo cấu trúc (Schema)
Hệ thống sử dụng cấu trúc modular (chia nhỏ từng phần) để dễ quản lý. Bạn có hai cách thực hiện:

- **Cách A (Khuyên dùng)**: Chạy file `init.sql`. File này sẽ tự động gọi các file module khác theo đúng thứ tự (cần dùng chế độ **SQLCMD Mode** trong SSMS).
- **Cách B (Thủ công)**: Chạy lần lượt các file trong thư mục `DATABASE/` theo thứ tự:
  1. `UserManagement.sql` (Người dùng)
  2. `UomConversion.sql` (Quy đổi đơn vị)
  3. `ProcessDefinition.sql` (Công thức, Đơn pha chế)
  4. `ProductionExecution.sql` (Lệnh sản xuất, Lô sản xuất)
  5. `InventoryTraceability.sql` (Tồn kho, Truy xuất)
  6. `SystemAudit.sql` & `AuditTrail.sql` (Nhật ký hệ thống)
  7. `AdvancedLogic.sql` & `Immutability.sql` (Logic nâng cao & Bảo mật dữ liệu)

### Bước 3: Nạp dữ liệu mẫu (Seeding)
Sau khi đã có cấu trúc, chạy file sau để nạp dữ liệu mẫu ban đầu:
- **`full_seed.sql`**: Chứa dữ liệu mẫu về Hoạt chất NLC 3, công thức sản xuất nang và các tài khoản quản trị/vận hành.

---

## ⚙️ Cấu hình Connection String
Trong file `appsettings.json` của Backend, hãy đảm bảo thông tin khớp với DB vừa tạo:

```json
"ConnectionStrings": {
  "DefaultConnection": "Server=localhost;Database=PharmaceuticalProcessingManagementSystem;User Id=sa;Password=YourPassword;TrustServerCertificate=true"
}
```

## ⚠️ Lưu ý quan trọng
- **Tên Database**: Phải là `PharmaceuticalProcessingManagementSystem` để đồng bộ với code Backend.
- **Ràng buộc khóa ngoại**: Nếu cập nhật thủ công, hãy chú ý thứ tự xóa/tạo bảng để tránh lỗi ràng buộc (Foreign Key). Các file module đã được sắp xếp để hạn chế tối đa vấn đề này.

||docker-compose up -d --build gmp-sqlserver gmp-api gmp-frontend||