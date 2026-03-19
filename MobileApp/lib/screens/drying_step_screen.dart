import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';

/// Màn hình [DryingStepScreen] quản lý công đoạn sấy nguyên liệu.
/// Bao gồm biểu mẫu kiểm tra phòng, kiểm tra vệ sinh máy móc,
/// ghi nhận thông số môi trường và số lượng kiểm tra kết quả sấy.
class DryingStepScreen extends StatelessWidget {
  final String stepName; // Tên bước công đoạn hiện tại (vd: Sấy NLC 3)
  
  const DryingStepScreen({super.key, required this.stepName});

  @override
  Widget build(BuildContext context) {
    // Sử dụng ListView để đảm bảo người dùng có thể cuộn form xuống 
    // mượt mà khi bàn phím áo (virtual keyboard) xuất hiện.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tiêu đề của màn hình được truyền vào từ Router/Navigation
        Text(stepName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
        // --- Bắt đầu Khối 4.1 ---
        // Sử dụng FormSectionHeader tự custom để chia nhỏ các phần của biểu mẫu giúp dễ nhìn
        const FormSectionHeader('4.1 THÔNG TIN CHUNG'),
        const StandardInputField(label: 'Phòng thực hiện', hint: 'Pha chế'),
        const StandardInputField(label: 'Ngày', hint: '18/03/2026', suffixIcon: Icon(Icons.calendar_today)),
        const StandardInputField(label: 'Người thực hiện & Người kiểm tra', hint: 'Chọn nhân viên', suffixIcon: Icon(Icons.person_add)),

        // --- Bắt đầu Khối 4.2 ---
        const FormSectionHeader('4.2 KIỂM TRA VỆ SINH'),
        // SegmentedToggle được dùng thay cho Checkbox giúp thao tác chạm dễ dàng hơn
        const SegmentedToggle(label: 'Phòng pha chế', optionA: 'Sạch', optionB: 'Không sạch'),
        const SegmentedToggle(label: 'Máy sấy tầng sôi KBC-TS-50', optionA: 'Sạch', optionB: 'Không sạch'),
        const SegmentedToggle(label: 'Dụng cụ sấy', optionA: 'Sạch', optionB: 'Không sạch'),

        // --- Bắt đầu Khối 4.3 ---
        const FormSectionHeader('4.3 ĐIỀU KIỆN MÔI TRƯỜNG'),
        // Đặt nội dung trong Row -> Expanded để chia đôi chiều ngang màn hình (2 cột)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', hint: '23.0', standardText: 'Standard: 21 - 25', keyboardType: TextInputType.number)),
            SizedBox(width: 16), // Khoảng cách giữa 2 cột
            Expanded(child: StandardInputField(label: 'Độ ẩm (%)', hint: '60.0', standardText: 'Standard: 45 - 70', keyboardType: TextInputType.number)),
          ],
        ),
        const StandardInputField(label: 'Thời gian kiểm tra', hint: '08:00 AM', suffixIcon: Icon(Icons.access_time)),
        const StandardInputField(label: 'Áp lực phòng đọc (Pa)', hint: '15', standardText: 'Standard: >= 10', keyboardType: TextInputType.number),

        const FormSectionHeader('4.4 THÔNG SỐ SẤY & KẾT QUẢ'),
        const SegmentedToggle(label: 'Tình trạng máy chạy không tải', optionA: 'Ổn định', optionB: 'Không ổn định'),
        const Row(
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí vào (°C)', hint: '50', keyboardType: TextInputType.number)),
            SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí ra (°C)', hint: '45', keyboardType: TextInputType.number)),
          ],
        ),
        const Row(
          children: [
            Expanded(child: StandardInputField(label: 'Bắt đầu sấy', hint: '08:30 AM', suffixIcon: Icon(Icons.access_time))),
            SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Kết thúc sấy', hint: '10:30 AM', suffixIcon: Icon(Icons.access_time))),
          ],
        ),
        const StandardInputField(label: 'Độ ẩm sau khi sấy (%)', hint: '1.5', keyboardType: TextInputType.number),
        
        const ReadOnlyField(label: 'Lấy mẫu kiểm tra', value: '10 g/túi x 5 túi = 50 g'),
        const SizedBox(height: 16),
        
        const Row(
          children: [
            Expanded(child: StandardInputField(label: 'SL trước sấy (kg)', hint: '100', keyboardType: TextInputType.number)),
            SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'SL sau sấy (kg)', hint: '95', keyboardType: TextInputType.number)),
          ],
        ),
        
        const SizedBox(height: 24),
        ESignatureButton(title: 'KÝ & LƯU CÔNG ĐOẠN', onPressed: () {}),
        const SizedBox(height: 32),
      ],
    );
  }
}
