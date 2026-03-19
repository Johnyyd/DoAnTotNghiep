import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';

/// Màn hình [MixingStepScreen] dành cho công đoạn trộn khô nguyên liệu.
/// Hỗ trợ kiểm tra máy trộn, thông số thời gian quay, và 
/// bảng phân tích đối chiếu khối lượng lý thuyết so với thực tế nhập vào.
class MixingStepScreen extends StatelessWidget {
  const MixingStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng ListView để tránh lỗi tràn màn hình (Overflow) trên các thiết bị có kích thước nhỏ
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tên màn hình
        const Text('CÔNG ĐOẠN TRỘN KHÔ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
        // --- Phần Môi trường ---
        const FormSectionHeader('6.1 MÔI TRƯỜNG & THIẾT BỊ'),
        // ReadOnlyField hiển thị tĩnh phòng thực hiện
        const ReadOnlyField(label: 'Phòng thực hiện', value: 'Trộn khô'),
        const SegmentedToggle(label: 'Máy trộn lập phương AD-LP-200', optionA: 'Sạch', optionB: 'Không sạch'),

        const FormSectionHeader('6.2 THÔNG SỐ VẬN HÀNH'),
        const Row(
          children: [
            Expanded(child: StandardInputField(label: 'Từ', hint: '09:00', suffixIcon: Icon(Icons.access_time))),
            SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Đến', hint: '09:15', suffixIcon: Icon(Icons.access_time))),
          ],
        ),
        const StandardInputField(label: 'Thời gian trộn thực tế (phút)', hint: '15', standardText: 'Standard: 15 phút', keyboardType: TextInputType.number),
        const StandardInputField(label: 'Tốc độ quay (vòng/phút)', hint: '15', standardText: 'Standard: 15 vòng/phút', keyboardType: TextInputType.number),

        const FormSectionHeader('6.3 ĐỐI CHIẾU NGUYÊN LIỆU'),
        const Text('Lý thuyết vs Thực sử dụng', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
        const SizedBox(height: 8),
        _buildComparisonRow('NLC 3 (kg)', '50.00'),
        _buildComparisonRow('TD 1 (kg)', '10.00'),
        _buildComparisonRow('TD 3 (kg)', '5.00'),
        _buildComparisonRow('TD 4 (kg)', '15.00'),
        _buildComparisonRow('TD 5 (kg)', '2.50'),
        _buildComparisonRow('TD 8 (kg)', '1.50'),
        const SizedBox(height: 12),
        const StandardInputField(label: 'Dư phẩm lô số', hint: 'Nhập số lô dư phẩm'),

        const FormSectionHeader('6.4 KẾT QUẢ HẠT KHÔ'),
        const StandardInputField(label: 'Tỷ trọng gõ', hint: '0.8', keyboardType: TextInputType.number),
        const ReadOnlyField(label: 'Số lượng đóng gói', value: '10 túi x 8 kg/túi = 80 kg'),
        const SizedBox(height: 12),
        const Text('Nhận xét', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Nhập ghi chú hoặc nhận xét...'),
        ),
        
        const SizedBox(height: 24),
        ESignatureButton(title: 'HOÀN THÀNH CÔNG ĐOẠN TRỘN', onPressed: () {}),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Hàm hỗ trợ hiển thị 1 dòng so sánh dữ liệu đối chiếu nguyên liệu
  /// Hiển thị tên nguyên liệu [label], khối lượng lý thuyết [expected] và input điền thực tế.
  Widget _buildComparisonRow(String label, String expected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: ReadOnlyField(label: '', value: expected)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(color: Colors.grey))),
          const Expanded(child: StandardInputField(label: '', hint: 'Thực tế')),
        ],
      ),
    );
  }
}
