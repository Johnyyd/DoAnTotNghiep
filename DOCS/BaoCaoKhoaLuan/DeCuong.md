
# 2. TÀI LIỆU DỰ ÁN CNTT: ĐỀ CƯƠNG CHI TIẾT KHÓA LUẬN (Từ file `DeCuong.pdf`)

Đây là tài liệu mô tả yêu cầu xây dựng phần mềm để tin học hóa quy trình sản xuất dược phẩm đã mô tả ở trên.

## 2.1. Thông tin chung về Khóa luận
*   **Tên đề tài:** **XÂY DỰNG HỆ THỐNG QUẢN LÝ QUY TRÌNH CHẾ BIẾN THUỐC THEO TIÊU CHUẨN GMP-WHO** [23].
*   **Đơn vị quản lý:** Khoa Công nghệ Thông tin, Trường Đại học Công Thương TP.HCM (HUIT), năm học 2025 - 2026 [23].
*   **Số lượng sinh viên:** Tối đa 3 sinh viên/nhóm [24].
*   **Thời gian thực hiện:** 12 tuần [25].

## 2.2. Mục tiêu dự án
*   Khảo sát quy trình nghiệp vụ sản xuất thực tế tại đơn vị [26].
*   Phân tích, mô hình hóa nghiệp vụ, thiết kế hệ thống (sơ đồ Use-case, sơ đồ lớp, thiết kế dữ liệu) [26].
*   Xây dựng một ứng dụng hoàn chỉnh đáp ứng nhu cầu quản lý trên **02 nền tảng: Web và Mobile** [23, 26].
*   Xây dựng các biểu mẫu báo cáo thống kê, có chức năng phân quyền, có giao diện thân thiện, dễ sử dụng [26, 27].

## 2.3. Công nghệ và Môi trường phát triển
*   **Hệ quản trị CSDL:** SQL Server [25].
*   **Ngôn ngữ lập trình:** ASP.NET (cho Web/API) và React Native (cho Mobile) [25].
*   **Nền tảng:** .NET Framework [25].

## 2.4. Các module chức năng hệ thống yêu cầu
Hệ thống phần mềm bắt buộc phải có các chức năng sau để quản lý đúng quy trình ở tài liệu nghiệp vụ:
*   **Chức năng cơ bản (Hệ thống):** Đăng nhập, đăng xuất, phân quyền người dùng, Backup & Restore [28].
*   **Chức năng trên ứng dụng Web [28, 29]:**
    *   Quản lý **BOM** (Định mức nguyên liệu), **Recipe** (Công thức pha chế), **Routing** (Quy trình công đoạn). *(Nơi lưu trữ công thức và tính toán tỷ lệ nguyên liệu NLC 3 và TD 8)* [28].
    *   Quản lý lập lệnh sản xuất [29].
    *   Quản lý lô thành phẩm [29].
    *   Báo cáo tiến độ sản xuất và thống kê thành phẩm [29].
*   **Chức năng trên ứng dụng Mobile (Dành cho nền tảng di động) [29]:**
    *   Tra cứu lệnh sản xuất và mẻ sản xuất [29].
    *   Theo dõi và cập nhật tiến độ theo từng công đoạn sản xuất (Sấy, cân, trộn...) [29].
    *   Xác nhận quá trình cấp phát nguyên vật liệu theo từng mẻ [29].
    *   Cập nhật các trạng thái của lệnh sản xuất: **In-Process** (Đang sản xuất), **Hold** (Tạm dừng), hoặc **Completed** (Hoàn thành) [29].

## 2.5. Kế hoạch triển khai (Roadmap 12 tuần)
*   **Tuần 1 - 2:** Lập kế hoạch, phân công công việc, khảo sát tổng quan hệ thống và thu thập biểu mẫu [30].
*   **Tuần 3 - 4:** Phân tích dữ liệu, thiết lập sơ đồ Use-case nghiệp vụ/hệ thống, sơ đồ hoạt động (Activity diagram), sơ đồ lớp, thiết kế cơ sở dữ liệu [31].
*   **Tuần 5 - 6:** Thiết kế giao diện hệ thống và xây dựng chức năng quản trị người dùng [31].
*   **Tuần 7 - 10:** Xây dựng chức năng quản lý danh mục, chức năng nghiệp vụ và thống kê báo cáo [32].
*   **Tuần 11 - 12:** Hoàn chỉnh toàn bộ ứng dụng, viết báo cáo tổng kết, thiết kế slide thuyết trình trên PowerPoint và nộp báo cáo [32].