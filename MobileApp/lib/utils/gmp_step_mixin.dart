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

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
