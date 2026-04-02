import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../components/step_form_inputs.dart'; // Mượn component UI cho ESignature
import 'main_navigation.dart';

class OrderVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  static Set<int> mockWorkerSignedOrders = {}; // Global mock state

  const OrderVerificationScreen({super.key, required this.orderData});

  @override
  State<OrderVerificationScreen> createState() => _OrderVerificationScreenState();
}

class _OrderVerificationScreenState extends State<OrderVerificationScreen> {
  bool _isQCSigned = false;
  bool _isLoading = false;

  void _qcSign() async {
    final pin = await _showPinDialog('Chữ ký QC');
    if (pin != null && pin.isNotEmpty) {
      if (pin != 'admin123' && pin != '123456') { // Mock logic
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Chữ ký QC không hợp lệ!')));
        return;
      }
      setState(() => _isLoading = true);
      
      // MOCK BACKEND CALL: Chuyển Order sang InProcess
      await Future.delayed(const Duration(seconds: 1)); // giả lập delay
      // Thực tế cần gọi ApiService.updateOrderStatus(orderId, 'In-Process')
      
      setState(() {
        _isQCSigned = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ QC chứng nhận. Lệnh chính thức bắt đầu (In-Process).')),
        );
        Navigator.pop(context, true); // Pop out when done
      }
    }
  }

  Future<String?> _showPinDialog(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Mã PIN cá nhân',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, ctrl.text), 
            child: const Text('Ký xác nhận')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra ban đầu (Pre-check)', style: TextStyle(fontSize: 16)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lệnh: ${widget.orderData['orderCode']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                const SizedBox(height: 8),
                Text('Sản phẩm: ${widget.orderData['productName']}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Cỡ lô chỉ định: ${widget.orderData['batchSize']}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('THÔNG SỐ & THIẾT BỊ TỪ DB (READ-ONLY)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          
          // Dữ liệu fix cứng từ DB
          _buildReadOnlyParam('Nhiệt độ phòng (yêu cầu)', '21 - 25 °C'),
          _buildReadOnlyParam('Độ ẩm (yêu cầu)', '45 - 70 %'),
          _buildReadOnlyParam('Thiết bị sử dụng', 'Máy sấy TS KBC-50, Máy đánh chảo chữ V'),
          _buildReadOnlyParam('Loại nguyên liệu', 'NLC 3 / TD 8, Bột Talc, Tinh bột mì'),
          
          const SizedBox(height: 24),
          const FormSectionHeader('CHECKLIST XÁC NHẬN TẠI XƯỞNG'),
          SegmentedToggle(label: 'Tình trạng vệ sinh xưởng:', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v){}),
          SegmentedToggle(label: 'Vệ sinh dụng cụ chứa:', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v){}),
          SegmentedToggle(label: 'Tình trạng thiết bị điện:', optionA: 'Sẵn sàng', optionB: 'Báo lỗi', onChanged: (v){}),
          
          const SizedBox(height: 32),
          // Flow chữ ký (chỉ hiển thị QC vì công nhân đã ký ở tab riêng)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Công nhân đã khai báo trên toàn bộ công đoạn và ký xác nhận', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          ESignatureButton(title: 'QC KIỂM TRA TỔNG QUAN & DUYỆT (START)', onPressed: _qcSign),
        ],
      ),
    );
  }

  Widget _buildReadOnlyParam(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6)
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          )
        ],
      ),
    );
  }
}
