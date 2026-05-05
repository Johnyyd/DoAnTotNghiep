# 1. TÀI LIỆU NGHIỆP VỤ: QUY TRÌNH SẢN XUẤT VIÊN NANG (Từ file `CamScanner.pdf`)

Đây là tài liệu đặc tả nghiệp vụ, cung cấp các biểu mẫu, công thức, quy chuẩn kỹ thuật và các bước thao tác thực tế mà phần mềm cần phải số hóa và quản lý.

## 1.1. Thông tin chung về Lô sản xuất
*   **Doanh nghiệp:** Công ty ABC [1].
*   **Loại tài liệu:** Hồ sơ chế biến lô - Quy trình sản xuất viên nang [1].
*   **Dạng phân liều:** Viên nang số "0" [1].
*   **Quy cách đóng gói:** Đóng chai, mỗi thùng 80 chai, mỗi chai 40 viên [1].
*   **Quản lý tiến độ:** Được ghi nhận bằng ngày bắt đầu (ngày pha chế mẻ đầu tiên) và ngày kết thúc (ngày kết thúc đóng gói cấp 2) [1].

## 1.2. Thành phần và Công thức (Dữ liệu cho quản lý BOM - Bill of Materials)
Công thức chuẩn cho 1 viên nang (Khối lượng lý thuyết 540,0 mg) [2]:
*   **NLC 3 (Cao khô Trinh nữ Crila):** 250,00 mg (46,30%) [2].
*   **TD 1 (Aerosil USP 30):** 1,62 mg (0,30%) [2].
*   **TD 3 (Sodium starch glycolate USP 30):** 29,70 mg (5,50%) [2].
*   **TD 4 (Talc DĐVN V):** 4,05 mg (0,75%) [2].
*   **TD 5 (Magnesi stearat DĐVN V):** 4,05 mg (0,75%) [2].
*   **TD 8 (Tinh bột DĐVN V):** 250,58 mg (46,40%) [2].
*   **NLP 6:** Vỏ nang cứng DĐVN V (1 viên) [2].

**Lưu ý nghiệp vụ quan trọng (Nghiệp vụ tính toán Recipe):** 
Số liệu NLC 3 có thể biến động. Tỷ lệ tá dược TD 8 sẽ được điều chỉnh tăng giảm bù trừ để đảm bảo khối lượng viên chuẩn và hàm lượng alcaloid toàn phần tính theo lycorin trong mỗi viên đạt đúng mức **1,250 mg/viên** [2, 3]. Các công thức tính toán lượng NLC 3 (gọi là Y), tổng khối lượng Alcaloid (X), và số viên nang sản xuất được (Q) cần được tích hợp vào hệ thống [3, 4].

## 1.3. Tiêu chuẩn kỹ thuật (Quality Control - QC)
*   **Đặc điểm:** Viên nang số "0", bột thuốc trong nang màu vàng nhạt đến nâu đậm, mùi thơm đặc trưng, vị đặc biệt [5].
*   **Thông số kỹ thuật:** Mất khối lượng do làm khô $\le 9,0\%$, rã không quá 30 phút, đồng đều khối lượng $\pm 7,5\%$ [5].
*   **Định lượng:** Hàm lượng alcaloid toàn phần tính theo lycorin đạt 1,125 - 1,375 mg/viên [6].
*   **Giới hạn vi sinh:** Tổng số vi khuẩn hiếu khí $\le 10^4$ cfu/g, nấm men/mốc $\le 10^2$ cfu/g [6]. Không được có E.coli, Pseudomonas aeruginosa, Staphylococcus aureus, và Salmonella [6].

## 1.4. Quản lý Thiết bị (Equipment/Routing)
Hệ thống cần quản lý các thiết bị sau tham gia vào quy trình sản xuất [7, 8]:
*   **Cân nguyên liệu/tá dược:** Cân điện tử IW2-60 (60kg), PMA-5000 (5kg), TE-212 (210g) [7].
*   **Trộn hạt:** Máy trộn lập phương AD-LP-200 (200 kg/mẻ) [7].
*   **Đóng nang:** Máy đóng nang tự động NJP-1200 D (72.000 viên/giờ) [7].
*   **Đóng gói:** Máy lau nang IPJ, máy đóng chai KW-102, tủ sấy chai CNTB-TSC, máy in số lô VIDEOJET-1220, máy dán nhãn tự động ABL-M, máy gấp toa F-262 [7, 8].

## 1.5. Các công đoạn sản xuất (Quy trình thao tác chuẩn - SOP)
**Điều kiện môi trường bắt buộc đối với phòng sản xuất:** Nhiệt độ 21°C – 25°C, độ ẩm 45% – 70%, áp lực phòng $\ge 10$ Pa [9-12].

*   **Công đoạn 1: Sấy nguyên liệu (TD 8 và NLC 3)**
    *   Thực hiện trên máy sấy tầng sôi KBC-TS-50 [10, 13].
    *   Mỗi mẻ tối đa 50 kg, nhiệt độ cài đặt 75°C, thời gian 180 phút, vị trí cửa gió số 4 [13, 14]. 
    *   Bảo quản trong kho cốm với túi PE 2 lớp [15, 16].
*   **Công đoạn 2: Cân nguyên liệu**
    *   Sử dụng các cân điện tử đã kiểm tra, nhân viên ghi chép đầy đủ số phiếu kiểm nghiệm, khối lượng yêu cầu và khối lượng cân thực tế (Có người cân và người kiểm soát) [17, 18].
*   **Công đoạn 3: Trộn khô**
    *   Trộn trên máy trộn lập phương AD-LP-200 trong 15 phút, tốc độ 15 vòng/phút [19, 20].
    *   Thứ tự nạp liệu: Từng lớp NLC 3 xen kẽ với lớp (TD 8 + TD 3), sau đó rắc hỗn hợp (TD 1 + TD 4 + TD 5) [12].
    *   Bảo quản: Hạt khô được chứa trong túi PE, xếp trong thùng inox, chèn 5 viên silicagel giữa 2 lớp túi [21, 22].

