import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../components/sticky_batch_header.dart';
import 'batch_dashboard_screen.dart';
import 'login_screen.dart';

/// [MainNavigationScreen] — Bộ khung (Scaffold) chính sau khi đăng nhập.
/// Điều hướng giữa Tiến độ mẻ, Sấy, Cân, Trộn qua BottomNavigationBar.
class MainNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const MainNavigationScreen({super.key, required this.orderData});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  double _batchProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  Future<void> _calculateProgress() async {
    final batches =
        await ApiService.getBatches(orderId: widget.orderData['orderId']);
    if (batches.isNotEmpty) {
      int completed = batches.where((b) => b['status'] == 'Completed').length;
      if (mounted) {
        setState(() {
          _batchProgress = completed / batches.length;
        });
      }
    }
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
    final role = user?['role'] as String? ?? '';

    final Widget dashboard = BatchDashboardScreen(orderId: widget.orderData['orderId']);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('eBMR', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // User info chip
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
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('($role)',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ],
              ),
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        child: const Text('Đồng ý')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          StickyBatchHeader(
            title: widget.orderData['productName'] ?? 'Sản phẩm',
            batchNo: widget.orderData['orderCode'] ?? '-',
            sdk: widget.orderData['sdk'] ?? '-',
            batchSize: widget.orderData['batchSize'] ?? '-',
            sizing: widget.orderData['sizing'] ?? '-',
            startDate: widget.orderData['startDate'] ?? '-',
            endDate: widget.orderData['endDate'] ?? '-',
            progress: _batchProgress,
          ),
          Expanded(
            child: dashboard,
          ),
        ],
      ),
    );
  }
}
