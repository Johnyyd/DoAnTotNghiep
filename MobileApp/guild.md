# YÊU CẦU THIẾT KẾ GIAO DIỆN MOBILE APP: HỒ SƠ CHẾ BIẾN LÔ ĐIỆN TỬ (eBMR)

**Mô tả chung:** Ứng dụng di động dành cho nhân viên vận hành tại nhà máy sản xuất Dược phẩm. App giúp số hóa quá trình ghi chép "Hồ sơ chế biến lô" thay cho bản giấy. Giao diện cần trực quan, dễ thao tác trên màn hình điện thoại, các trường dữ liệu cần được phân cụm rõ ràng.

---

## 1. COMPONENT DÙNG CHUNG: STICKY HEADER (THÔNG TIN LÔ)

_Component này luôn ghim ở đầu màn hình trong mọi công đoạn để nhân viên biết họ đang thao tác trên lô nào._

- [cite_start]**Tên sản phẩm:** Viên nang... (Hiển thị nổi bật) [cite: 2]
- [cite_start]**Số lô (Batch No):** Text read-only [cite: 2]
- [cite_start]**Cỡ lô:** Text read-only [cite: 2]
- [cite_start]**Quy cách:** Thùng/ 80 chai/ 40 viên [cite: 2]
- [cite_start]**Ngày bắt đầu / Ngày kết thúc:** Date format [cite: 2, 4]
- [cite_start]_UI Hint:_ Thiết kế dạng Card nhỏ gọn, có nút "Mở rộng" (Caret down) để xem thêm các thông tin như: SĐK, Hạn dùng, Dạng phân liều, Người soạn, Người kiểm tra[cite: 2].

---

## 2. MÀN HÌNH 1: CÔNG ĐOẠN SẤY NGUYÊN LIỆU (SẤY TD 8 / NLC 3)

[cite_start]_Giao diện áp dụng cho cả việc sấy tá dược và hoạt chất[cite: 65, 79]._

### 2.1. Cụm: Thông tin chung

- [cite_start]**Phòng thực hiện:** Dropdown (Mặc định: Pha chế) [cite: 67]
- [cite_start]**Ngày thực hiện:** Date picker (Mặc định: Hôm nay) [cite: 67]
- [cite_start]**Người thực hiện / Người kiểm tra:** Text input (hoặc User Select) kèm nút bấm "Ký tên" (E-signature)[cite: 67].

### 2.2. Cụm: Kiểm tra điều kiện sản xuất

_UI Hint: Sử dụng Toggle Switch hoặc Segmented Control (Sạch / Không sạch)._

- [cite_start]**Vệ sinh phòng pha chế:** Toggle [Sạch] / [Không sạch] [cite: 67]
- [cite_start]**Máy sấy tầng sôi KBC-TS-50:** Toggle [Sạch] / [Không sạch] [cite: 67]
- [cite_start]**Dụng cụ sấy:** Toggle [Sạch] / [Không sạch] [cite: 67]

### 2.3. Cụm: Môi trường sản xuất (Thời điểm kiểm tra)

_UI Hint: Nhập liệu dạng Card, có hiển thị sẵn thông số tiêu chuẩn mờ (placeholder) bên dưới ô nhập._

- [cite_start]**Thời gian kiểm tra:** Time picker (Giờ : Phút) [cite: 67]
- **Nhiệt độ đọc:** Number input (Đơn vị: °C). [cite_start]_Note: Tiêu chuẩn 21°C - 25°C_[cite: 67].
- **Độ ẩm đọc:** Number input (Đơn vị: %). [cite_start]_Note: Tiêu chuẩn 45% - 70%_[cite: 67].
- **Áp lực phòng đọc:** Number input (Đơn vị: Pa). [cite_start]_Note: Tiêu chuẩn >= 10 Pa_[cite: 67].

### 2.4. Cụm: Thông số vận hành & Kết quả

- [cite_start]**Tình trạng chạy không tải:** Toggle [Ổn định] / [Không ổn định] [cite: 67]
- [cite_start]**Nhiệt độ khí vào ổn định:** Number input (°C) [cite: 67]
- [cite_start]**Nhiệt độ khí ra kết thúc:** Number input (°C) [cite: 67]
- [cite_start]**Thời gian sấy:** \* Bắt đầu từ: Time picker [cite: 67]
  - [cite_start]Kết thúc: Time picker [cite: 67]
- **Kết quả:**
  - [cite_start]Độ ẩm sau khi sấy: Number input (%) [cite: 67]
  - [cite_start]Khối lượng trước khi sấy: Number input (kg) [cite: 67]
  - [cite_start]Khối lượng sau khi sấy: Number input (kg) [cite: 67]
  - [cite_start]Lấy mẫu kiểm tra: `[Input: g/túi]` x `[Input: số túi]` = `[Calculated Field: Tổng số g]`[cite: 67].

---

## 3. MÀN HÌNH 2: CÔNG ĐOẠN CÂN NGUYÊN LIỆU

[cite_start]_Quá trình lấy nguyên liệu và cân đo chuẩn bị pha chế[cite: 120]._

### 3.1. Cụm: Môi trường & Thiết bị (Tương tự công đoạn sấy)

- [cite_start]**Phòng thực hiện:** Phòng cân [cite: 121]
- [cite_start]**Môi trường:** Nhập Nhiệt độ (°C), Độ ẩm (%), Áp lực (Pa)[cite: 121].
- [cite_start]**Tình trạng cân (IW2-60 & PMA-5000):** Toggle [Tốt] / [Không ổn định][cite: 121].

### 3.2. Cụm: Danh sách nguyên liệu cần cân

_UI Hint: Không dùng Table truyền thống vì màn hình mobile hẹp. Thay vào đó, dùng dạng "List View" với các "Material Card". Mỗi Card đại diện cho 1 nguyên liệu._

**Cấu trúc 1 Material Card:**

- [cite_start]**Tên nguyên liệu:** Text (VD: NLC 3, TD 1, TD 3...) [cite: 122]
- [cite_start]**Số phiếu KN (Kiểm nghiệm):** Text input [cite: 122]
- [cite_start]**Khối lượng yêu cầu:** Number input (kg) [cite: 122]
- [cite_start]**Khối lượng thực cân:** Number input (kg) (Highlight màu xanh nếu khớp KL yêu cầu) [cite: 122]
- [cite_start]**Người cân / Người kiểm soát:** Select / Ký tên [cite: 122]
- _Action:_ Nút "Lưu/Hoàn thành" cho từng thẻ nguyên liệu.

### 3.3. Cụm: Nhận xét

- [cite_start]**Nhận xét quá trình cân:** Text area (nhiều dòng)[cite: 123].

---

## 4. MÀN HÌNH 3: CÔNG ĐOẠN TRỘN KHÔ

[cite_start]_Quá trình trộn hỗn hợp bột[cite: 127]._

### 4.1. Cụm: Môi trường & Thiết bị

- [cite_start]**Phòng thực hiện:** Trộn khô [cite: 128]
- [cite_start]**Thiết bị (Máy trộn AD-LP-200):** Toggle [Sạch] / [Không sạch] [cite: 128]
- [cite_start]**Nhập thông số môi trường:** Nhiệt độ, Độ ẩm, Áp lực[cite: 128].

### 4.2. Cụm: Thông số vận hành máy

- **Thời gian trộn thực tế:** Number input (Phút). [cite_start]_Note: Tiêu chuẩn 15 phút_[cite: 128].
- **Tốc độ quay thực tế:** Number input (Vòng/phút). [cite_start]_Note: Tiêu chuẩn 15 vòng/phút_[cite: 128].
- [cite_start]**Thời gian trộn:** Từ (Time picker) - Đến (Time picker)[cite: 132].

### 4.3. Cụm: Đối chiếu nguyên liệu đưa vào trộn

_UI Hint: Danh sách các ô nhập liệu dạng lưới 2 cột (Lý thuyết vs Thực tế)._

- **NLC 3:** Lưới nhập [Lý thuyết: ___ kg] | [cite_start][Thực sử dụng: ___ kg] [cite: 132]
- [cite_start]**TD 1, TD 3, TD 4, TD 5, TD 8:** (Tương tự như trên) [cite: 132]
- [cite_start]**Dư phẩm lô số:** Text input [cite: 132]
- [cite_start]**Xác nhận:** Nút bấm "Ký xác nhận sử dụng"[cite: 132].

### 4.4. Cụm: Kết quả trộn (Hạt khô)

- [cite_start]**Tỷ trọng gõ:** Number input [cite: 132]
- [cite_start]**Số lượng thành phẩm:** \* Bao bì: `[Input: Số túi]` x `[Input: kg/túi]` [cite: 132]
  - [cite_start]Số lẻ cộng thêm: `+ [Input: kg]` [cite: 132]
  - [cite_start]Tổng cộng: `[Calculated Field: Tổng số kg]` [cite: 132]
- [cite_start]**Nhận xét quá trình trộn:** Text area[cite: 132].
