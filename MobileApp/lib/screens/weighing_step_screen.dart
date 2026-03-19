import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../components/material_card.dart';

/// Màn hình [WeighingStepScreen] hiển thị giao diện cho công đoạn cân nguyên liệu.
/// Bao gồm kiểm tra điều kiện phòng cân, các loại cân sử dụng và 
/// danh sách các nguyên liệu cần cân (hiển thị danh sách động qua `MaterialCard`).
class WeighingStepScreen extends StatelessWidget {
  const WeighingStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Khung ListView bao bọc toàn bộ component để có cơ chế trượt cuộn trơn tru,
    // Tránh bị lỗi Overflow Render Pixel khi bàn phím ảo (Virtual Keyboard) ở dưới bật ngang che khuất UI 
    return ListView(
      padding: const EdgeInsets.all(16), // Kéo toàn bộ ruột thụt vào 16px để tạo vùng an toàn (Safe Area) với mí viền điện thoại
      children: [
        // Text Header tĩnh khai báo tiêu đề
        const Text('CÔNG ĐOẠN CÂN NGUYÊN LIỆU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
        // --- Phần 5.1: Môi trường ---
        // Gọi Component tự thiết kế (từ step_form_inputs.dart) chuyên đóng hộp Label tiêu đề Form
        const FormSectionHeader('5.1 MÔI TRƯỜNG & THIẾT BỊ'),
        // ReadOnlyField là một TextBox giả tĩnh nhưng đổ nền xám mô phỏng giao diện không khả dụng chỉnh sửa (Read-only)
        const ReadOnlyField(label: 'Phòng thực hiện', value: 'Phòng cân'),
        const SizedBox(height: 16), // Một cục nhựa cách điện khoảng không trong suốt 16px giong Row
        
        // Row lồng nhiều Widget con nằm trên 1 trục hoành (hàng ngang)
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded bành widget TextField ra cướp lấy 50% chỗ trống
            Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', hint: '23.0', keyboardType: TextInputType.number)),
            SizedBox(width: 16), // Tạo đới đệm chiều rộng 16px hệt vách tường giữa 2 khung TextField
            // Widget còn lại cân đối lấy 50% chỗ
            Expanded(child: StandardInputField(label: 'Độ ẩm (%)', hint: '60.0', keyboardType: TextInputType.number)),
          ],
        ),
        // TextInputType.number ra lệnh cho hệ điều hành kích hoạt Numeric Keypad mặc định khi click (chỉ phím số)
        const StandardInputField(label: 'Áp lực (Pa)', hint: '15', keyboardType: TextInputType.number),
        // Widget chuyên biệt thiết kế Toggle chuyển trạng thái thay vì dùng ô vuông check box cực kì nhỏ xíu và khó click trúng trên Mobile
        const SegmentedToggle(label: 'Cân IW2-60', optionA: 'Tốt', optionB: 'Không ổn định'),
        const SegmentedToggle(label: 'Cân PMA-5000', optionA: 'Tốt', optionB: 'Không ổn định'),

        // --- Phần 5.2: Danh sách nguyên liệu ---
        const FormSectionHeader('5.2 DANH SÁCH NGUYÊN LIỆU QUY ĐỊNH'),
        const Text('Nhập đúng khối lượng yêu cầu để xác nhận hoàn thành từng nguyên liệu.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        
        // --- Gọi các Component MaterialCard ---
        // MaterialCard đóng gói logic tự động bắt lỗi và báo thành công khi số lượng khớp
        const MaterialCard(materialName: 'NLC 3', requiredWeightKg: '50.00'),
        const MaterialCard(materialName: 'TD 1', requiredWeightKg: '10.00'),
        const MaterialCard(materialName: 'TD 3', requiredWeightKg: '5.00'),
        const MaterialCard(materialName: 'TD 4', requiredWeightKg: '15.00'),
        const MaterialCard(materialName: 'TD 5', requiredWeightKg: '2.50'),
        const MaterialCard(materialName: 'TD 8', requiredWeightKg: '1.50'),
        
        const FormSectionHeader('5.3 NHẬN XÉT'),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(hintText: 'Nhập ghi chú hoặc nhận xét...'),
        ),
        const SizedBox(height: 24),
        ESignatureButton(title: 'KÝ XÁC NHẬN SỐ', onPressed: () {}),
        const SizedBox(height: 32),
      ],
    );
  }
}
