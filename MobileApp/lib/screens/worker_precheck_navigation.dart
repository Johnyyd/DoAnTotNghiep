import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart'; // Nơi chứa ESignatureButton

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

import 'drying_step_screen.dart';
import 'weighing_step_screen.dart';
import 'mixing_step_screen.dart';

class WorkerPrecheckNavigation extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const WorkerPrecheckNavigation({super.key, required this.orderData});

  @override
  State<WorkerPrecheckNavigation> createState() => _WorkerPrecheckNavigationState();
}

class _WorkerPrecheckNavigationState extends State<WorkerPrecheckNavigation> {
  int _selectedIndex = 0;
  bool _isSubmitting = false;

  void _workerSign() async {
    final pin = await _showPinDialog('Chữ ký Công nhân');
    if (pin != null && pin.isNotEmpty) {
      setState(() => _isSubmitting = true);
      final success = await ApiService.updateOrderStatus(widget.orderData['orderId'], 'Pending QC');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✔ Hồ sơ đã gửi cho QC chờ duyệt!')));
          Navigator.pop(context); // Quay về Home
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi DB: Không thể cập nhật trạng thái.')));
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
            child: const Text('Ký xác nhận')
          ),
        ],
      )
    );
  }

  void _logout() {
    AuthService.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final username = user?['username'] as String? ?? 'Operator';

    final pages = [
      _buildOverviewTab(),
      const DryingStepScreen(stepName: 'SẤY NLC 3 / TD 8', isPrecheck: true),
      const WeighingStepScreen(isPrecheck: true),
      const MixingStepScreen(isPrecheck: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập liệu & Kiểm tra', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                   const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined), label: 'Sấy'),
          NavigationDestination(icon: Icon(Icons.scale_outlined), label: 'Cân'),
          NavigationDestination(icon: Icon(Icons.cyclone), label: 'Trộn'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200)
          ),
          child: const Column(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
              SizedBox(height: 12),
              Text(
                'Yêu cầu: Điều hướng qua các bộ phận Cân, Sấy, Trộn bên dưới để khai báo đầy đủ các thông số ban đầu.\n\nSau khi rà soát tất cả công đoạn bên dưới, hãy ký tên điện tử tại trang Tổng quan này.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
            ],
          )
        ),
        const SizedBox(height: 32),
        ESignatureButton(title: 'KÝ CHỐT VÀ CHUYỂN QC', onPressed: _workerSign),
      ],
    );
  }
}
