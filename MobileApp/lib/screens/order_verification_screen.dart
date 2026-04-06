import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../components/step_form_inputs.dart'; // Mượn component UI cho ESignature

class OrderVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderVerificationScreen({super.key, required this.orderData});

  @override
  State<OrderVerificationScreen> createState() => _OrderVerificationScreenState();
}

class _OrderVerificationScreenState extends State<OrderVerificationScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _workerData;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);
    try {
      // Chờ 500ms để CSDL kịp commit (Race Condition Prevention)
      await Future.delayed(const Duration(milliseconds: 500));

      // Lấy TẤT CẢ các mẻ của lệnh này
      final batches = await ApiService.getBatches(orderId: widget.orderData['orderId']);
      
      Map<String, dynamic>? foundLog;
      
      for (var b in batches) {
        final bId = b['batchId'] ?? b['id'] as int?;
        if (bId == null) continue;
        
        final logs = await ApiService.getProcessLogs(bId);
        // Dò tìm log "Đang chờ QC" (Không phân biệt hoa thường/khoảng trắng)
        final log = logs.firstWhere(
          (l) {
            final st = l['resultStatus']?.toString().replaceAll(' ', '').toUpperCase() ?? '';
            return st == 'PENDINGQC' || st == 'PENDING_QC';
          },
          orElse: () => {},
        );
        
        if (log.isNotEmpty) {
          foundLog = log;
          break; // Tìm thấy rồi thì thôi
        }
      }

      if (foundLog != null) {
        final paramsStr = foundLog['parametersData'] as String?;
        if (paramsStr != null) {
          final Map<String, dynamic> params = jsonDecode(paramsStr);
          setState(() {
            _workerData = params['rawInputs'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading worker data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _qcSign() async {
    final pin = await _showPinDialog('Chữ ký QC');
    if (pin != null && pin.isNotEmpty) {
      if (pin != 'admin123' && pin != '123456') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Chữ ký không hợp lệ!')));
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        // 1. Lấy danh sách mẻ của lệnh này
        final batches = await ApiService.getBatches(orderId: widget.orderData['orderId']);
        if (batches.isNotEmpty) {
          // 2. Lấy log công đoạn của mẻ
          for (var batch in batches) {
            final bId = batch['batchId'] ?? batch['id'] as int?;
            if (bId == null) continue;

            final logs = await ApiService.getProcessLogs(bId);
            
            for (var log in logs) {
              final st = log['resultStatus']?.toString().replaceAll(' ', '').toUpperCase() ?? '';
              final lId = log['logId'] ?? log['id'] as int?;
              final sId = log['stepId'] ?? log['id'] as int?; // RoutingId phục vụ Create mới

              if (st == 'PENDINGQC' || st == 'PENDING_QC') {
                if (lId != null) {
                  debugPrint("--- QC AUTO-APPROVING LOG ID: $lId ---");
                  await ApiService.verifyStepData(
                    logId: lId, 
                    verifierId: AuthService.currentUser?['userId'] ?? 1, 
                    status: 'Approved'
                  );
                }
              } else if (st == 'NONE' || st == '') {
                // Nếu bước đầu tiên chưa được công nhân khởi tạo (null log)
                // ta sẽ tự động tạo log 'Approved' để thông luồng
                if (sId != null) {
                  debugPrint("--- QC AUTO-STARTING/APPROVING STEP ID: $sId ---");
                  await ApiService.submitStepData(
                    batchId: bId,
                    stepId: sId,
                    resultStatus: 'Approved',
                    notes: 'Auto-approved during Order Pre-check'
                  );
                }
              }
            }
          }
        }

        // 4. Cập nhật trạng thái lệnh sang Đang sản xuất
        final success = await ApiService.updateOrderStatus(widget.orderData['orderId'], 'In-Process');
        
        if (mounted) {
          // Thêm delay nhỏ để DB kịp commit trước khi refresh ở Dashboard
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✔ Đã DUYỆT CẤP QUYỀN: Lệnh đã chuyển sang tab Đang sản xuất!')));
            Navigator.pop(context, true); // Trở về Dashboard và báo refesh
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi DB: Không thể xác nhận lệnh.')));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi hệ thống: $e')));
        }
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
            child: const Text('Xác nhận & Cấp quyền')
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadWorkerData(),
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
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
          
          const Text('THÔNG SỐ THỰC TẾ TỪ CÔNG NHÂN (READ-ONLY)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 12),
          
          
          _buildReadOnlyParam('Nhiệt độ đọc được:', '${_workerData?['nhietDo'] ?? '--'} °C'),
          _buildReadOnlyParam('Độ ẩm đọc được:', '${_workerData?['doAm'] ?? '--'} %'),
          _buildReadOnlyParam('Áp lực phòng:', '${_workerData?['apLuc'] ?? '--'} Pa'),
          _buildReadOnlyParam('Thời gian kiểm tra:', '${_workerData?['thoiGianCheck'] ?? '--'}'),
          
          const SizedBox(height: 20),
          const Text('KIỂM TRA VỆ SINH & ĐIỀU KIỆN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _buildReadOnlyParam('Phòng pha chế:', _workerData?['checkPhong'] ?? '--'),
          _buildReadOnlyParam('Máy sấy tầng sôi:', _workerData?['checkMay'] ?? '--'),
          _buildReadOnlyParam('Dụng cụ sấy:', _workerData?['checkDungCu'] ?? '--'),
          _buildReadOnlyParam('Tình trạng không tải:', _workerData?['checkKhongTai'] ?? '--'),
          
          const SizedBox(height: 20),
          const Text('QUY TRÌNH THAO TÁC (CHECKLIST)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _buildCheckItem('Kiểm tra túi lọc (số 4, 5):', _workerData?['checkTuiLoc'] == true),
          _buildCheckItem('Lắp ráp máy theo SOP:', _workerData?['checkLapRap'] == true),
          _buildCheckItem('Rải nhẹ nhàng mẫu vào thùng:', _workerData?['checkRaiNhe'] == true),
          _buildCheckItem('Khỏa bằng mặt mẫu:', _workerData?['checkKhoaBang'] == true),
          _buildCheckItem('Đẩy thùng sấy vào máy:', _workerData?['checkDayThung'] == true),
          
          const SizedBox(height: 20),
          const Text('SẢN LƯỢNG ĐẦU VÀO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _buildReadOnlyParam('Khối lượng nguyên liệu sấy:', '${_workerData?['slTruocSay'] ?? '--'} kg'),
          
          const SizedBox(height: 32),
          const FormSectionHeader('XÁC NHẬN CỦA QC'),
          const SizedBox(height: 16),
          ESignatureButton(title: 'QC KIỂM TRA TỔNG QUAN & DUYỆT (START)', onPressed: _qcSign),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? Colors.green : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(isChecked ? 'ĐÃ CHECK' : 'CHƯA CHECK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isChecked ? Colors.green : Colors.grey)),
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
