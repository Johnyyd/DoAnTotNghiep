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
    if (standardParams.isEmpty) {
      debugPrint("Validation: standardParams is empty for $fieldKey");
      return;
    }

    final val = double.tryParse(value.replaceAll(',', '.')); // Handle comma as decimal separator
    if (val == null) {
      if (mounted) setState(() => inputStatuses[fieldKey] = 'none');
      return;
    }

    final lookupName = (matchName ?? fieldKey).toLowerCase();
    
    // Tìm parameter khớp nhất
    final sp = standardParams.firstWhere(
      (p) {
        final pName = (p['parameterName'] as String? ?? '').toLowerCase();
        return pName.contains(lookupName) || lookupName.contains(pName);
      },
      orElse: () => null,
    );

    if (sp != null) {
      final min = sp['minValue'] != null ? (sp['minValue'] as num).toDouble() : null;
      final max = sp['maxValue'] != null ? (sp['maxValue'] as num).toDouble() : null;

      String status = 'none';
      if (min != null && val < min) status = 'error';
      if (max != null && val > max) status = 'error';
      
      debugPrint("Validation [$fieldKey]: val=$val, min=$min, max=$max => status=$status");

      if (mounted) setState(() => inputStatuses[fieldKey] = status);
    } else {
      debugPrint("Validation: Could not find parameter matching '$lookupName'");
    }
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
