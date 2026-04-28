
# Phân tích kiến trúc dự án và review cụ thể các module (clusters) dành cho Mobile

## 1. Tổng Quan Cấu Trúc Đồ Án (Hệ sinh thái GMP-WHO)

Dự án được xây dựng theo một kiến trúc tổng thể chặt chẽ giúp kiểm soát chất lượng Dược phẩm theo chuẩn phân tách Microservices/Component-based:

    Backend (/GMP_System): Xây dựng bằng C# .NET 8 (Clean Architecture, DDD pattern) đóng vai trò điều phối nghiệp vụ lõi, xác thực tiến trình và theo dõi Audit Trails.

    Frontend (/PharmaceuticalProcessingManagementSystem): Giao diện React/TypeScript đảm nhận phận Web Admin quản lý toàn bộ Master Data, Danh mục định mức và Kế hoạch phân xưởng.

    Database (/DATABASE): SQL Server 2022 quản lý trạng thái máy và dữ liệu tập trung với kho lưu trữ cực kì chặt chẽ (Triggers bảo vệ dữ liệu gốc).
    
    Mobile App (/MobileApp): Ứng dụng eBMR (electronic Batch Manufacturing Record) xây dựng bằng Flutter, chạy môi trường Web dùng trên Tablet dành cho các Công nhân thao tác trực tiếp tại các buồng sản xuất.

## 2. Review Codebase các Module (Clusters) Chính trong Mobile App

Thông qua phân tích cấu trúc folder MobileApp/lib, codebase được phân nhóm thành các Module/Cluster cụ thể theo logic Presentation & Services. Dưới đây là chức năng và luồng đi của từng Cluster:

### 🎯 Cluster 1: Tầng Giao Diện Nghiệp Vụ (Screens Module)

Trong thư mục lib/screens, đây là trái tim của Mobile application tập trung vào mọi thao tác của người dùng.

    home_screen.dart & main_navigation.dart: Điều hướng chính của App. Luồng xuất phát nơi công nhân đăng nhập và nhìn thấy tổng quan nhà máy.

    batch_dashboard_screen.dart & batch_detail_screen.dart: Các màn hình Dashboard giúp tra cứu, hiển thị trạng thái của các Lệnh sản xuất (ProductionOrder & ProductionBatch).

    Cụm Thực thi Quy trình GMP (The Execution Flow):
        weighing_step_screen.dart: Giao diện đặc tả quy trình Cân Nguyên Liệu.
        mixing_step_screen.dart: Giao diện đặc tả quy trình Trộn.
        drying_step_screen.dart: Giao diện đặc tả quy trình Sấy NLC.
        
» Luồng Đi: Tương ứng với vòng đời (Pre-check Initial Inspection -> Execution -> Verification), dữ liệu thông số nhiệt độ/độ ẩm/khối lượng được công nhân nhập vào.
order_verification_screen.dart: Module thẩm định, phê duyệt cuối cùng để chuyển bước.
dynamic_log_viewer_screen.dart: Hiển thị Audit logs. Lịch sử ai làm gì, vào giờ nào, thiết bị nào.

### 🔌 Cluster 2: Tầng Giao Tiếp Dữ Liệu (Services Module)

Chứa ở lib/services, nhóm module này chịu trách nhiệm tách biệt logic gọi API ra khỏi giao diện tĩnh.

    api_service.dart: Cầu nối quan trọng nhất. Đứng ra tiếp nhận thông số từ máy ảo (Tablet) gửi thẳng gói JSON lên .NET API của Backend để ghi BatchProcessLog.
    auth_service.dart: Kiểm soát việc Login và duy trì token/session của vị Trưởng Ca hoặc Công Nhân đang giữ thiết bị.

### 🧩 Cluster 3: Tầng Thành Phần Tái Sử Dụng (Components Module)

Chứa tại lib/components, hệ thống sử dụng rất nhiều view động được chia nhỏ:

    step_form_inputs.dart: Form động chuyên biệt sinh ra dựa theo định mức (Recipe). Nếu bước sấy yêu cầu nhiệt độ, nó sẽ sinh rãnh nhập nhiệt độ có check min-max threshold.

    sticky_batch_header.dart & material_card.dart: Hiển thị vắn tắt trạng thái Mẻ, mã nguyên liệu - giúp công nhân không bao giờ quên họ đang thao tác trên lô hàng nào.

### 📦 Cluster 4: Mô Hình Dữ Liệu & UI State (Models & Theme Module)

    execution_phase.dart (trong models): Quản lý tính trạng máy trạng thái (Phase State Machine) xác định giai đoạn hiện tại (Đang chờ duyệt, Đang thực hiện, Tạm hoãn).
    theme: Thiết lập Color Palette và Layout chuẩn (sạch sẽ, độ tương phản cao, thao tác chạm to rõ để phục vụ găng tay y tế trên màn hình Tablet).

## 💡 Tóm tắt Luồng Hoạt Động (Flow) của Mobile App

    Authentication: Công nhân quẹt thẻ / Login qua login_screen. Hệ thống gọi auth_service để verify với .NET Core backend.

    Navigation: Khám phá các mẻ đang chờ phân công hoặc mẻ InProcess hiện tại thông qua batch_dashboard_screen.

    Process Tracking: Click vào 1 thiết bị/mẻ ở trong Line, điều hướng sang một trong các Flow cố định như weighing, mixing, drying.

    Logging & Approving: Người thao tác điền thông số vào step_form_inputs. api_service đẩu dữ liệu ngược về Database. Nếu Deviation (Thông số sai) quá định mức, bắt buộc chuyển qua order_verification_screen để người có thẩm quyền cao hơn ấn Approve.
