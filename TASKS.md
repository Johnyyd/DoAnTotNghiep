# Theo Dõi Các Task Sửa Lỗi Mobile App

## 1. UI Overflow / Padding Issues
- [x] **Lỗi tràn viền 7.9 pixels ở giao diện Batch Dashboard**: Đã thêm `Flexible` cho khối Text chứa label trạng thái mẻ. (File: `batch_dashboard_screen.dart`)
- [x] **Lỗi nút bấm đè lên Form nhập liệu**: Đã tăng khoảng đệm (bottom padding) của ListView từ 100 lên 150 để nút FAB (Floating Action Button) không che khuất phần nhập liệu. (Files: `mixing_step_screen.dart`, `drying_step_screen.dart`, `weighing_step_screen.dart`)

## 2. Logic Progress Bar
- [x] **Lỗi hiển thị 0% trong màn hình eBMR**: Thay vì tự tính bằng `completedBatches / totalBatches`, giao diện `main_navigation.dart` đã được cập nhật để ưu tiên đọc trường `progress` trực tiếp từ dữ liệu backend (để phản ánh cả % của mẻ đang sản xuất).
- [x] **Lỗi mẻ "Hoàn thành" nhưng hiển thị 0/1 (Home Screen)**: Thêm logic tự động cưỡng ép thanh tiến trình thành 100% (`progress = 1.0`) và `completedBatches = totalBatches` khi trạng thái lô là `Completed`. (File: `home_screen.dart`)
