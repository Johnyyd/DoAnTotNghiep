# PRODUCT REQUIREMENT DOCUMENT & UI/UX SPECIFICATION

**Project:** Electronic Batch Manufacturing Record (eBMR) - Mobile App
**Target Device:** Mobile (iOS/Android)
**Primary User:** Factory Operator (Nhân viên vận hành nhà máy dược phẩm).

## 1. GLOBAL APP SETTINGS & USER FLOW

- **Color Palette:** Clean, medical/industrial theme (Primary: Blue/Teal, Background: Light Gray/White, Success: Green, Error: Red).
- **Typography:** highly legible sans-serif (Inter, Roboto).
- **User Flow:** 1. User selects an active Batch (Lô sản xuất). 2. User views the "Batch Dashboard" listing all steps. 3. User clicks on a pending step (e.g., Sấy -> Cân -> Trộn). 4. User fills out the form. Data auto-saves. 5. User signs (E-signature) and submits. The app unlocks the next step.

---

## 2. COMMON COMPONENT: STICKY BATCH HEADER

_Must be pinned to the top of the screen during all data-entry steps._

- [cite_start]**Title:** VIÊN NANG... [cite: 2] (Bold, Large)
- **Số lô (Batch No):** `<Text ReadOnly>`
- [cite_start]**SĐK & Cỡ lô:** `<Text ReadOnly>` [cite: 2]
- [cite_start]**Quy cách:** Thùng/ 80 chai/ 40 viên [cite: 2]
- [cite_start]**Timeline:** Ngày bắt đầu `[Date]` - Ngày kết thúc `[Date]` [cite: 2, 4]
- **UI Hint:** Create a collapsible accordion. Show only "Tên SP" and "Số lô" when collapsed to save mobile screen space.

---

## 3. SCREEN 1: BATCH DASHBOARD (DANH SÁCH CÔNG ĐOẠN)

_A list of manufacturing steps for the selected batch. Shows progress._

- [cite_start]**Step 1:** Xử lý nguyên liệu - Sấy TD 8 `[Status Badge: Completed/Pending]` [cite: 65]
- [cite_start]**Step 2:** Xử lý nguyên liệu - Sấy NLC 3 `[Status Badge: Pending]` [cite: 79]
- [cite_start]**Step 3:** Pha chế - Cân nguyên liệu `[Status Badge: Locked]` [cite: 120]
- [cite_start]**Step 4:** Pha chế - Trộn khô `[Status Badge: Locked]` [cite: 127]

---

## 4. SCREEN 2: CÔNG ĐOẠN SẤY (SẤY TD 8 / NLC 3)

_Reusable form template for any drying step._

### Section 4.1: Thông tin chung

- [cite_start]**Phòng thực hiện:** `<Dropdown>` (Mặc định: Pha chế) [cite: 67]
- **Ngày:** `<DatePicker>`
- [cite_start]**Người thực hiện & Người kiểm tra:** `<UserSelect>` [cite: 67]

### Section 4.2: Kiểm tra vệ sinh (Checklist)

_UI Hint: Use Segmented Controls or Switch Toggles._

- [cite_start]**Phòng pha chế:** `[Sạch] / [Không sạch]` [cite: 67]
- [cite_start]**Máy sấy tầng sôi KBC-TS-50:** `[Sạch] / [Không sạch]` [cite: 67]
- [cite_start]**Dụng cụ sấy:** `[Sạch] / [Không sạch]` [cite: 67]

### Section 4.3: Điều kiện môi trường

_UI Hint: Render as a 2-column grid. Show standard requirements as small placeholder text below the input._

- [cite_start]**Thời gian kiểm tra:** `<TimePicker>` [cite: 67]
- [cite_start]**Nhiệt độ đọc (°C):** `<NumberInput>` _(Standard: 21°C - 25°C)_ [cite: 67]
- [cite_start]**Độ ẩm đọc (%):** `<NumberInput>` _(Standard: 45% - 70%)_ [cite: 67]
- [cite_start]**Áp lực phòng đọc (Pa):** `<NumberInput>` _(Standard: >= 10 Pa)_ [cite: 67]

### Section 4.4: Thông số sấy & Kết quả

- [cite_start]**Tình trạng máy chạy không tải:** `[Ổn định] / [Không ổn định]` [cite: 67]
- [cite_start]**Nhiệt độ khí vào (°C):** `<NumberInput>` [cite: 67]
- [cite_start]**Nhiệt độ khí ra (°C):** `<NumberInput>` [cite: 67]
- [cite_start]**Thời gian sấy:** Bắt đầu `<TimePicker>` - Kết thúc `<TimePicker>` [cite: 67]
- [cite_start]**Độ ẩm sau khi sấy (%):** `<NumberInput>` [cite: 67]
- [cite_start]**Lấy mẫu kiểm tra:** `<NumberInput: g/túi>` x `<NumberInput: số túi>` = `<Text: Tính tự động tổng g>` [cite: 67]
- [cite_start]**Số lượng trước khi sấy (kg):** `<NumberInput>` [cite: 67]
- [cite_start]**Số lượng sau khi sấy (kg):** `<NumberInput>` [cite: 67]
- **Action:** `<Button: Ký & Lưu công đoạn>`

---

## 5. SCREEN 3: CÔNG ĐOẠN CÂN NGUYÊN LIỆU

### Section 5.1: Môi trường & Thiết bị

- [cite_start]**Phòng thực hiện:** Phòng cân [cite: 121]
- [cite_start]**Nhiệt độ, Độ ẩm, Áp lực:** _(Giống Section 4.3)_ [cite: 121]
- [cite_start]**Cân IW2-60:** `[Tốt] / [Không ổn định]` [cite: 121]
- [cite_start]**Cân PMA-5000:** `[Tốt] / [Không ổn định]` [cite: 121]

### Section 5.2: Danh sách nguyên liệu cần cân

_UI Hint: Do NOT use a wide table. Use a vertically scrollable list of "Material Cards"._
**Material Card Structure:**

- [cite_start]**Tên nguyên liệu:** `<Text>` (Loop through: NLC 3, TD 1, TD 3, TD 4, TD 5, TD 8) [cite: 122]
- [cite_start]**Số phiếu KN:** `<TextInput>` [cite: 122]
- [cite_start]**Khối lượng yêu cầu (kg):** `<NumberInput: ReadOnly/Pre-filled>` [cite: 122]
- [cite_start]**Khối lượng cân (kg):** `<NumberInput>` _(UI Logic: Text turns green if matches "Khối lượng yêu cầu")_ [cite: 122]
- [cite_start]**Người cân / Người kiểm soát:** `<SignaturePad>` [cite: 122]

### Section 5.3: Nhận xét

- [cite_start]**Nhận xét:** `<TextArea>` [cite: 123]

---

## 6. SCREEN 4: CÔNG ĐOẠN TRỘN KHÔ

### Section 6.1: Môi trường & Thiết bị

- [cite_start]**Phòng thực hiện:** Trộn khô [cite: 128]
- [cite_start]**Nhiệt độ, Độ ẩm, Áp lực:** _(Giống Section 4.3)_ [cite: 128]
- [cite_start]**Máy trộn lập phương AD-LP-200:** `[Sạch] / [Không sạch]` [cite: 128]

### Section 6.2: Thông số vận hành

- [cite_start]**Thời gian trộn:** Từ `<TimePicker>` - Đến `<TimePicker>` [cite: 132]
- [cite_start]**Thời gian trộn thực tế (phút):** `<NumberInput>` _(Standard: 15 phút)_ [cite: 128]
- [cite_start]**Tốc độ quay thực tế (vòng/phút):** `<NumberInput>` _(Standard: 15 vòng/phút)_ [cite: 128]

### Section 6.3: Đối chiếu nguyên liệu

_UI Hint: 2-column layout (Lý thuyết vs Thực sử dụng)._

- [cite_start]**NLC 3 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**TD 1 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**TD 3 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**TD 4 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**TD 5 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**TD 8 (kg):** `<ReadOnly: X>` vs `<Input: Y>` [cite: 132]
- [cite_start]**Dư phẩm lô số:** `<TextInput>` [cite: 132]
- [cite_start]**Xác nhận đưa vào máy:** `<SignaturePad>` [cite: 132]

### Section 6.4: Kết quả hạt khô

- [cite_start]**Tỷ trọng gõ:** `<NumberInput>` [cite: 132]
- [cite_start]**Số lượng đóng gói:** `<NumberInput: Số túi>` x `<NumberInput: kg/túi>` = `<Calculated: Tổng kg>` [cite: 132]
- [cite_start]**Nhận xét:** `<TextArea>` [cite: 132]
- **Action:** `<Button: Hoàn thành Công đoạn Trộn>`
