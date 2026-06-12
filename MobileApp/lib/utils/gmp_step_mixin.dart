import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// [GmpStepMixin] — Chứa các logic dùng chung cho các màn hình công đoạn GMP.
/// Giảm thiểu trùng lặp code cho Polling, Dialog PIN và các tiện ích UI.
mixin GmpStepMixin<T extends StatefulWidget> on State<T> {
  Timer? pollTimer;
  bool isSaving = false;

  /// Bắt đầu Polling tự động để cập nhật trạng thái từ QC
  void startPolling(Future<void> Function() fetchData) {
    if (pollTimer != null && pollTimer!.isActive) return;
    debugPrint("--- START AUTO-POLLING ---");
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
  }

  /// Dừng Polling
  void stopPolling() {
    if (pollTimer != null) {
      debugPrint("--- STOP AUTO-POLLING ---");
      pollTimer!.cancel();
      pollTimer = null;
    }
  }

  /// Hiển thị Dialog nhập mã PIN chữ ký điện tử
  Future<String?> showPinDialog({String title = 'CHỮ KÝ ĐIỆN TỬ GMP'}) {
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
            hintText: 'Nhập mã PIN của bạn',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final pin = ctrl.text;
              if (AuthService.verifyPin(pin)) {
                Navigator.pop(c, pin);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Mã PIN không đúng!'))
                );
              }
            }, 
            child: const Text('Ký xác nhận')
          ),
        ],
      )
    );
  }

  /// Chuẩn hóa trạng thái từ DB để so sánh logic
  String normalizeStatus(dynamic status) {
    return (status ?? '').toString().replaceAll(' ', '').toUpperCase();
  }

  /// Trạng thái của các ô nhập liệu (none, error, warning)
  final Map<String, String> inputStatuses = {};

  /// Cập nhật trạng thái ô nhập liệu dựa trên Min-Max từ DB
  void validateInput(String fieldKey, String value, List<dynamic> standardParams, {String? matchName}) {
    final lookupName = (matchName ?? fieldKey).toLowerCase();
    final val = double.tryParse(value.replaceAll(',', '.')); // Handle comma as decimal separator
    
    if (val == null) {
      if (mounted) setState(() => inputStatuses[fieldKey] = 'none');
      return;
    }

    // 1. Tìm parameter khớp nhất trong DB
    final sp = (standardParams.isNotEmpty) ? standardParams.firstWhere(
      (p) {
        final pName = (p['parameterName'] as String? ?? '').toLowerCase();
        return pName.contains(lookupName) || lookupName.contains(pName);
      },
      orElse: () => null,
    ) : null;

    String status = 'none';

    if (sp != null) {
      final min = sp['minValue'] != null ? (sp['minValue'] as num).toDouble() : null;
      final max = sp['maxValue'] != null ? (sp['maxValue'] as num).toDouble() : null;

      if (min != null && val < min) status = 'error';
      if (max != null && val > max) status = 'error';
    } else {
      // 2. Logic dự phòng: Nếu không có tham số trong DB, áp dụng quy tắc mặc định (Giống Sấy TD 8)
      // Chỉ áp dụng cho thông số PHÒNG/MÔI TRƯỜNG, không áp dụng cho NGUYÊN LIỆU (sau sấy, thực tế...)
      final isRoom = lookupName.contains('phòng') || lookupName.contains('room') || lookupName.contains('môi trường');
      final isMaterial = lookupName.contains('sau sấy') || lookupName.contains('thực tế') || lookupName.contains('nguyên liệu') || lookupName.contains('thành phẩm');

      if (isRoom && !isMaterial) {
        if (lookupName.contains('áp lực') || lookupName.contains('pressure')) {
          if (val < 10) status = 'error';
          else status = 'valid';
        } else if (lookupName.contains('nhiệt độ') || lookupName.contains('temperature')) {
          if (val < 21 || val > 25) status = 'error';
          else status = 'valid';
        } else if (lookupName.contains('độ ẩm') || lookupName.contains('humidity')) {
          if (val < 45 || val > 70) status = 'error';
          else status = 'valid';
        }
      } else if (lookupName.contains('áp lực') || lookupName.contains('pressure')) {
        // Áp lực phòng đọc (kể cả không ghi chữ phòng) vẫn mặc định >= 10 Pa
        if (val < 10) status = 'error';
        else status = 'valid';
      }
    }
    
    debugPrint("Validation [$fieldKey]: val=$val, status=$status (Matched: ${sp?['parameterName'] ?? 'Default'})");
    if (mounted) setState(() => inputStatuses[fieldKey] = status);
  }

  /// Lấy chuỗi hiển thị tiêu chuẩn (VD: "Chuẩn: 21 - 25 °C")
  /// Tự động áp dụng giá trị mặc định cho Nhiệt độ, Độ ẩm, Áp suất nếu không có trong DB.
  String? getStandardText(String paramName, List<dynamic> standardParams) {
    final lookupName = paramName.toLowerCase();
    
    // 1. Tìm trong DB trước
    final sp = (standardParams.isNotEmpty) ? standardParams.firstWhere(
      (p) {
        final pName = (p['parameterName'] as String? ?? '').toLowerCase();
        return pName.contains(lookupName) || lookupName.contains(pName);
      },
      orElse: () => null,
    ) : null;

    if (sp != null) {
      if (sp['standardValue'] != null) return "Chuẩn: ${sp['standardValue']}";
      
      final min = sp['minValue'];
      final max = sp['maxValue'];
      final unit = sp['unit'] ?? '';
      
      if (min != null && max != null) {
        if (min == max) return "Chuẩn: ${min.toString().replaceAll('.0', '')} $unit";
        return "Chuẩn: ${min.toString().replaceAll('.0', '')} - ${max.toString().replaceAll('.0', '')} $unit";
      } else if (min != null) {
        return "Chuẩn: >= ${min.toString().replaceAll('.0', '')} $unit";
      } else if (max != null) {
        return "Chuẩn: <= ${max.toString().replaceAll('.0', '')} $unit";
      }
    }

    // 2. Nếu không có trong DB, áp dụng giá trị mặc định cho thông số PHÒNG
    final isRoom = lookupName.contains('phòng') || lookupName.contains('room') || lookupName.contains('môi trường');
    final isMaterial = lookupName.contains('sau sấy') || lookupName.contains('thực tế') || lookupName.contains('nguyên liệu') || lookupName.contains('thành phẩm');

    if (isRoom && !isMaterial) {
      if (lookupName.contains('nhiệt độ') || lookupName.contains('temperature')) {
        return "Chuẩn: 21 - 25 °C";
      }
      if (lookupName.contains('độ ẩm') || lookupName.contains('humidity')) {
        return "Chuẩn: 45 - 70 %";
      }
      if (lookupName.contains('áp lực') || lookupName.contains('pressure')) {
        return "Chuẩn: >= 10 Pa";
      }
    } else if (lookupName.contains('áp lực') || lookupName.contains('pressure')) {
      // Áp lực phòng (mặc định cho mọi bước)
      return "Chuẩn: >= 10 Pa";
    }

    return null;
  }


  Timer? _realtimeTimer;
  final List<TextEditingController> _autoTimeControllers = [];

  /// Bắt đầu cập nhật thời gian thực cho danh sách các controllers.
  /// Các controller này sẽ được cập nhật mỗi phút.
  void startTimeUpdates(List<TextEditingController> controllers) {
    if (_realtimeTimer != null) return;
    _autoTimeControllers.addAll(controllers);
    
    // Cập nhật ngay lập tức lần đầu
    _updateTimeFields();

    // Thiết lập timer chạy mỗi 30 giây để đảm bảo không lỡ phút mới
    _realtimeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTimeFields());
  }

  void _updateTimeFields() {
    if (!mounted) return;
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    bool changed = false;
    for (var ctrl in _autoTimeControllers) {
      if (ctrl.text != timeStr) {
        ctrl.text = timeStr;
        changed = true;
      }
    }
    
    if (changed && mounted) {
      // Trigger rebuild if needed, though TextEditingController updates UI automatically
      // but some screens might use the value for calculations.
      setState(() {}); 
    }
  }

  /// Dừng cập nhật thời gian thực
  void stopTimeUpdates() {
    _realtimeTimer?.cancel();
    _realtimeTimer = null;
    _autoTimeControllers.clear();
  }

  @override
  void dispose() {
    stopPolling();
    stopTimeUpdates();
    super.dispose();
  }
}
