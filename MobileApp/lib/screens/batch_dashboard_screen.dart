import 'package:flutter/material.dart';

/// Màn hình [BatchDashboardScreen] hiển thị danh sách các công đoạn
/// của một lô sản xuất. Hỗ trợ hiển thị trạng thái hoàn thành, đang chờ (Pending) hoặc bị khóa.
class BatchDashboardScreen extends StatelessWidget {
  const BatchDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng ListView để hiển thị danh sách các thẻ trạng thái công đoạn có thể cuộn dọc
    // Padding 16 pixels giúp cách đều lề màn hình để giao diện thoáng hơn
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tiêu đề của danh sách
        const Text(
          'DANH SÁCH CÔNG ĐOẠN',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 16), // Tạo khoảng trống 16px giữa Tiêu đề và Danh sách
        
        // Render tĩnh các bước thông qua hàm xây dựng widget cục bộ _buildStepItem
        _buildStepItem(context, 'Step 1: Xử lý nguyên liệu - Sấy TD 8', 'Completed'),
        _buildStepItem(context, 'Step 2: Xử lý nguyên liệu - Sấy NLC 3', 'Pending'),
        _buildStepItem(context, 'Step 3: Pha chế - Cân nguyên liệu', 'Locked'),
        _buildStepItem(context, 'Step 4: Pha chế - Trộn khô', 'Locked'),
      ],
    );
  }

  /// Hàm xây dựng giao diện cho từng bước công đoạn (Card)
  /// Nhận vào [title] là tên bước và [status] là trạng thái để render icon và màu sắc tương ứng.
  Widget _buildStepItem(BuildContext context, String title, String status) {
    // Khai báo các biến lưu trữ style giao diện tùy theo trạng thái (status)
    Color statusColor;
    IconData statusIcon;
    String statusText;

    // Phân tích tham số status để ánh xạ màu sắc, biểu tượng và nhãn Text tiếng Việt
    switch (status) {
      case 'Completed':
        statusColor = Theme.of(context).primaryColor; // Màu chủ đạo (Xanh đậm) cho trạng thái hoàn thành
        statusIcon = Icons.check_circle;
        statusText = 'Hoàn thành';
        break;
      case 'Pending':
        statusColor = Colors.orange.shade700; // Màu cam làm nổi bật trạng thái đang chờ xử lý
        statusIcon = Icons.pending;
        statusText = 'Đang chờ';
        break;
      case 'Locked':
      default:
        statusColor = Colors.grey; // Màu xám chìm biểu thị trạng thái chưa mở khóa (Locked)
        statusIcon = Icons.lock;
        statusText = 'Khóa';
        break;
    }

    // Wrap bằng Card để tạo khối có Material Design (đổ bóng, viền bo)
    // - Khối Card này đóng vai trò bao bọc ListTile, tách biệt thẻ công đoạn hiện tại khỏi nền trắng (ListView)
    return Card(
      // margin: EdgeInsets.only(bottom: 12) tạo khoảng cách 12 pixels ở mép dưới
      // Giúp các Card xếp hàng dọc không bị dính sát vào nhau.
      margin: const EdgeInsets.only(bottom: 12),
      // child: Khai báo thành phần cấu trúc bên trong. ListTile sinh ra để làm UI cho 1 hàng mục lục chuẩn, bao gồm Trái-Giữa-Phải.
      child: ListTile(
        // leading: Thuộc tính của ListTile dành riêng để đặt Widget nằm sát viền trái. Gắn Icon trạng thái vào đây.
        leading: Icon(statusIcon, color: statusColor),
        // title: Hiển thị đoạn chữ chính giữa của hàng (Tên công đoạn)
        title: Text(
          title, // Biến title lấy từ tham số truyền vào hàm
          // style: Khai báo TextStyle để tuỳ chỉnh phông chữ, cỡ, độ đậm, màu sắc...
          style: TextStyle(
            fontSize: 14, // Kích thước chữ 14, đạt chuẩn dễ đọc cho Mobile.
            // fontWeight: Dùng toán tử 3 ngôi (condition ? result_if_true : result_if_false).
            // Nếu trạng thái là Khóa -> chữ mảnh hơn (normal). Nếu đang mở -> in đậm (bold) để nhấn mạnh.
            fontWeight: status == 'Locked' ? FontWeight.normal : FontWeight.bold,
            // color: Làm mờ màu (black54) thành xám nhạt nếu khóa. Nếu mở khóa thì dùng đen đậm rõ ràng (black87).
            color: status == 'Locked' ? Colors.black54 : Colors.black87,
          ),
        ),
        // trailing: Góc phải của ListTile, thường dùng để chứa label trạng thái, badge hoặc icon điều hướng.
        trailing: Container(
          // Kéo giãn mép trong (padding) sang 2 bên là 10px, trên dưới 4px để không bị ép chữ
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            // Pha 10% (alpha: 0.1) màu sắc gốc để làm mờ nền thành màu pastel dịu nhẹ (ví dụ Xanh nhạt, Cam nhạt)
            color: statusColor.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(12), // Bo các mép cong của Container để tạo hình Capsule (thuốc con nhộng)
            // Kẻ 1 viền mỏng bao quanh với màu lấy 50% độ đậm nguyên bản
            border: Border.all(color: statusColor.withValues(alpha: 0.5)), 
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12, // Badge nhỏ gọn nên chữ hẹp lại còn 12px
              fontWeight: FontWeight.bold,
              color: statusColor, // Chữ hiển thị phải sử dụng màu cực đậm (nguyên bản) mới ăn khớp với nền nhạt
            ),
          ),
        ),
        // onTap: Bắt sự kiện người dùng bấm vào dòng này. 
        // Nếu dòng bị 'Locked', thuộc tính gán là null => Vô hiệu hóa tính năng bấm (ListTile không phát sáng khi click).
        // Ngược lại, truyền một hàm rỗng `() {}` để tạo ra hiệu ứng sóng nhấn (ripple API).
        onTap: status == 'Locked' ? null : () {},
      ),
    );
  }
}
