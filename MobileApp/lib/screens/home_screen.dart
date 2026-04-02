import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import 'order_verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _inProcessOrders = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _errorOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProductionOrders();
    if (mounted) {
      setState(() {
        _inProcessOrders = data.where((o) => o['status'] == 'In-Process' || o['status'] == 'InProcess' || o['status'] == 'Completed').toList();
        _pendingOrders = data.where((o) => o['status'] == 'Approved' || o['status'] == 'Draft').toList();
        _errorOrders = data.where((o) => o['status'] == 'On-Hold' || o['status'] == 'Hold' || o['status'] == 'Error').toList();
        _isLoading = false;
      });
    }
  }

  void _logout() {
    AuthService.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade600;
      case 'In-Process':
      case 'InProcess':
        return Colors.blue.shade600;
      case 'Draft':
      case 'Approved':
        return Colors.orange.shade600;
      case 'On-Hold':
      case 'Hold':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, bool isPendingTab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không có lệnh sản xuất nào', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final color = _statusColor(order['status']);
          final progress = (order['progress'] ?? 0.0) as double;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (isPendingTab) {
                  // Mở màn hình xác nhận kép
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderVerificationScreen(orderData: order),
                    ),
                  );
                  if (result == true) {
                    _loadOrders(); // Tải lại danh sách nếu chứng nhận thành công
                  }
                } else {
                  // Mở màn hình thao tác sản xuất bình thường
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MainNavigationScreen(orderData: order),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order['productName'] ?? 'Sản phẩm',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            (order['status'] == 'In-Process' || order['status'] == 'InProcess') ? 'Đang sản xuất' : 
                            order['status'] == 'Completed' ? 'Hoàn thành' : 
                            (order['status'] == 'On-Hold' || order['status'] == 'Hold') ? 'Đang tạm dừng' : 'Chờ xác nhận',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lệnh: ${order['orderCode']} - Cỡ lô: ${order['batchSize']}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    if (!isPendingTab) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã hoàn thành: ${order['completedBatches']} / ${order['totalBatches']} mẻ',
                        style: const TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Cần xác nhận chuẩn bị trước khi sản xuất',
                            style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final username = user?['username'] as String? ?? 'Operator';
    final role = user?['role'] as String? ?? '';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang Chủ', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Đang sản xuất'),
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Gặp lỗi / Dừng'),
            ],
          ),
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
                    if (role.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text('($role)',
                          style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ),
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
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        child: const Text('Đồng ý'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOrderList(_inProcessOrders, false), // Đang sản xuất
                  _buildOrderList(_pendingOrders, true),    // Chờ xác nhận
                  _buildOrderList(_errorOrders, false),     // Lỗi / Dừng
                ],
              ),
      ),
    );
  }
}
