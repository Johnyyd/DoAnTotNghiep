import 'package:flutter/material.dart';
import '../components/sticky_batch_header.dart';
import 'batch_dashboard_screen.dart';
import 'drying_step_screen.dart';
import 'weighing_step_screen.dart';
import 'mixing_step_screen.dart';

/// Màn hình [MainNavigationScreen] đóng vai trò bộ khung (Scaffold) chính của ứng dụng.
/// Điều hướng qua các công đoạn bằng `BottomNavigationBar` (Sấy, Cân, Trộn...).
/// Khung hiển thị bao gồm `StickyBatchHeader` neo trên cùng và các màn hình thay đổi.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20)),
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tiến độ'),
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Sấy'),
          NavigationDestination(icon: Icon(Icons.scale_outlined), label: 'Cân'),
          NavigationDestination(icon: Icon(Icons.cyclone), label: 'Trộn'),
        ],
      ),
    );
  }
}
