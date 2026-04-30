**ĐỒ ÁN TỐT NGHIỆP**
*Quản lý quy trình sản xuất nguyên liệu dược phẩm Cao Khô*

---

## LỜI CẢM ƠN
Chúng tôi xin gửi lời cảm ơn sâu sắc tới:

- **Ths. Trần Thị Vân Anh** – giảng viên hướng dẫn, đã chỉ bảo và hỗ trợ nhiệt tình trong suốt quá trình thực hiện đề tài.
- **Các thầy cô trong Khoa Công nghệ Thông tin, Trường Đại học Công thương** – cung cấp kiến thức nền tảng và môi trường học tập tốt.
- **Gia đình và bạn bè** – luôn động viên, tạo điều kiện để chúng tôi hoàn thành đồ án.

---

## MỤC LỤC

| STT | Nội dung | Trang |
|-----|----------|-------|
| 1 | **CHƯƠNG 1: TỔNG QUAN** | 2 |
| 2 | **CHƯƠNG 2: PHÂN TÍCH HỆ THỐNG** | 3 |
| 3 | **CHƯƠNG 3: THIẾT KẾ HỆ THỐNG** | 5 |
| 4 | **CHƯƠNG 4: KẾT LUẬN** | 7 |

---

## CHƯƠNG 1: TỔNG QUAN

### 1.1. Giới thiệu
Hệ thống quản lý sản xuất cao khô là một chuỗi các công đoạn từ **cân nguyên liệu**, **trộn ướt**, **xát hạt ướt**, **sấy hạt ướt**, **sửa hạt khô** đến **đóng gói**. Quy trình này được thiết kế để đáp ứng tiêu chuẩn **GMP‑WHO**, tối ưu hiệu suất, giảm lãng phí và tăng khả năng truy xuất nguồn gốc.

### 1.2. Mục tiêu và phạm vi đề tài
- **Khảo sát** quy trình sản xuất hiện tại và các vấn đề tồn tại.
- **Mô hình hoá** nghiệp vụ sản xuất và đề xuất kiến trúc phần mềm quản lý.
- **Xây dựng** ứng dụng đa nền tảng (Web + Mobile) hỗ trợ:
  - Quản lý vật tư, thiết bị, công thức (BOM).
  - Theo dõi tiến độ, cảnh báo sai lệch.
  - Ghi nhận lịch sử (Audit Trail) để tuân thủ GMP‑WHO.

### 1.3. Khảo sát hệ thống (Quy trình nghiệp vụ)
1. **Cân nguyên liệu** – cân chính xác NLC 2 và TD 1.
2. **Trộn ướt** – máy MTU‑1, 20 phút.
3. **Xát hạt ướt** – lưới 2 mm, máy KBC‑SHU‑100.
4. **Sấy hạt ướt** – máy KBC‑TS‑50 (60 °C/30 phút → 50 °C/20 phút).
5. **Sửa hạt khô** – máy KBC‑XB‑300 (lưới 2 mm & 1 mm).
6. **Đóng gói** – thùng inox, túi PE, dán nhãn biệt trữ.

---

## CHƯƠNG 2: PHÂN TÍCH HỆ THỐNG

### 2.1. Phân tích nghiệp vụ
#### Use‑case chính
| STT | Use‑case | Mô tả ngắn |
|-----|----------|------------|
| 1 | Kiểm tra môi trường | Nhiệt độ 21‑25 °C, độ ẩm 45‑70 %, áp lực ≥10 Pa. |
| 2 | Kiểm tra thiết bị | Nhân viên bảo trì kiểm tra cân, máy trộn, máy xát, … |
| 3 | Quản lý nguyên liệu | Cập nhật nhập/ xuất, cảnh báo thiếu hụt. |
| 4 | Chế biến cao khô | Kiểm soát từng bước, nhập PIN để xác nhận. |
| 5 | Đóng gói & giao kho | Cân lại, lấy mẫu, phát hành phiếu. |

### 2.2. Đặc tả hệ thống (State Machine)
Lệnh sản xuất di chuyển qua các trạng thái:

```
Draft → Approved → InProcess → Hold → Completed
```  

Mọi thay đổi được ghi lại **Audit Trail** để đáp ứng yêu cầu truy xuất nguồn gốc.

---

## CHƯƠNG 3: THIẾT KẾ HỆ THỐNG

### 3.1. Kiến trúc tổng thể
- **Backend:** .NET 8 (API) – triển khai trên Docker, kết nối SQL Server 2022.
- **Frontend (Web):** React – dashboard quản lý, báo cáo, phê duyệt.
- **Frontend (Mobile):** Flutter – hỗ trợ công nhân thực hiện các bước trên sàn nhà máy.

### 3.2. Cơ sở dữ liệu (Entity Model)
| Table | Mô tả |
|-------|------|
| Users | Thông tin tài khoản, quyền (UserRole). |
| Materials | Danh sách nguyên liệu, tồn kho. |
| Equipments | Thông tin thiết bị, trạng thái bảo trì. |
| Recipes | BOM, công thức sản xuất. |
| ProductionOrders | Lệnh sản xuất, trạng thái, lịch sử. |
| AuditLogs | Ghi nhận mọi thay đổi (INSERT/UPDATE/DELETE). |

### 3.3. Giao diện người dùng
- **Web Admin:** Dashboard thống kê, tạo lệnh sản xuất, quản lý vật tư, báo cáo audit.
- **Mobile Operate:** Màn hình tiến độ từng bước, cảnh báo lỗi (màu đỏ) khi sai lệch >5 %, nhập PIN/ký số để xác nhận.

---

## CHƯƠNG 4: KẾT LUẬN

### 4.1. Kết quả đạt được
- **Tăng năng suất** và **độ chính xác** trong quản lý sản xuất.
- **Giảm lỗi** nhờ cảnh báo tự động khi sai lệch BOM.
- **Audit Trail** minh bạch, đáp ứng chuẩn GMP‑WHO.
- **Hai nền tảng** (Web + Mobile) đáp ứng nhu cầu của quản lý và công nhân.

### 4.2. Hạn chế
- Chưa hỗ trợ **offline sync** sâu cho Mobile trong vùng mạng yếu.
- Chưa tích hợp **PLC/SCADA** để thu thập dữ liệu tự động từ thiết bị.

### 4.3. Hướng phát triển trong tương lai
1. **IoT integration** – thu thập nhiệt độ, độ ẩm, khối lượng cân tự động.
2. **AI dự đoán** – phân tích dữ liệu lịch sử để cảnh báo chất lượng trước khi xảy ra.
3. **Offline Sync** nâng cao cho Mobile bằng SQLite.
4. **Mở rộng** tính năng báo cáo thống kê và xuất PDF tự động cho quản lý.

---

*Được biên soạn dựa trên cấu trúc của file **QuanLyCaoKho_Nhom Cuong.pdf**, kết hợp nội dung chi tiết từ các tài liệu review codebase và các file nguồn trong thư mục `.../BaoCaoKhoaLuan` (trừ file PDF gốc).*
