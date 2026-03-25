import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../components/sticky_batch_header.dart';
import 'batch_dashboard_screen.dart';
import 'drying_step_screen.dart';
import 'weighing_step_screen.dart';
import 'mixing_step_screen.dart';
import 'login_screen.dart';

/// [MainNavigationScreen] — Bộ khung (Scaffold) chính sau khi đăng nhập.
/// Điều hướng giữa Tiến độ mẻ, Sấy, Cân, Trộn qua BottomNavigationBar.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

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

    final List<Widget> pages = [
      const BatchDashboardScreen(),
      const DryingStepScreen(stepName: 'SẤY NLC 3 / TD 8'),
      const WeighingStepScreen(),
      const MixingStepScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('eBMR', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('($role)',
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
          const StickyBatchHeader(
            title: 'VIÊN NANG NLC 3',
            batchNo: 'BATCH-NLC3-001',
            sdk: 'VD-12345-21',
            batchSize: '100 kg',
            sizing: 'Thùng/ 80 chai/ 40 viên',
            startDate: '18/03/2026',
            endDate: '25/03/2026',
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Tiến độ'),
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined), label: 'Sấy'),
          NavigationDestination(
              icon: Icon(Icons.scale_outlined), label: 'Cân'),
          NavigationDestination(icon: Icon(Icons.cyclone), label: 'Trộn'),
        ],
      ),
    );
  }
}
