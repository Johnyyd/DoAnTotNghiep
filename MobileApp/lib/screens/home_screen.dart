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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allOrdersRaw = [];
  List<Map<String, dynamic>> _inProcessOrders = [];
  List<Map<String, dynamic>> _pendingWorkerOrders = [];
  List<Map<String, dynamic>> _pendingQCOrders = [];
  List<Map<String, dynamic>> _errorOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  List<String> _categories = ['Tất cả'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProductionOrders();
    if (mounted) {
      _allOrdersRaw = data;
      _categories = _extractCategories(data);
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Tất cả';
      }
      _filterAndGroupOrders();
    }
  }

  List<String> _extractCategories(List<dynamic> allOrders) {
    final Set<String> cats = {'Tất cả'};
    for (var o in allOrders) {
      final name = o['productName']?.toString() ?? '';
      cats.add(_getCategoryFromName(name));
    }
    return cats.toList();
  }

  String _getCategoryFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('viên nang')) return 'Viên nang';
    if (lower.contains('viên nén')) return 'Viên nén';
    if (lower.contains('thuốc ống') || lower.contains('ống')) {
      return 'Thuốc ống';
    }
    if (lower.contains('cốm')) return 'Cốm';

    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return name.isNotEmpty ? name : 'Khác';
  }

  void _filterAndGroupOrders() {
    final filtered = _allOrdersRaw.where((o) {
      if (_selectedCategory == 'Tất cả') return true;
      final cat = _getCategoryFromName(o['productName']?.toString() ?? '');
      return cat == _selectedCategory;
    }).toList();

    setState(() {
      _inProcessOrders = filtered
          .where((o) => _getOrderDisplayStatus(o) == 'In-Process')
          .toList();
      _pendingWorkerOrders = filtered
          .where((o) => _getOrderDisplayStatus(o) == 'Pending Worker')
          .toList();
      _pendingQCOrders = filtered
          .where((o) => _getOrderDisplayStatus(o) == 'Pending QC')
          .toList();
      _errorOrders = filtered
          .where((o) => _getOrderDisplayStatus(o) == 'On-Hold')
          .toList();
      _completedOrders = filtered
          .where((o) => _getOrderDisplayStatus(o) == 'Completed')
          .toList();
      _isLoading = false;
    });
  }

  String _getOrderDisplayStatus(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    if (status == 'Completed') return 'Completed';
    if (status == 'On-Hold' || status == 'Hold' || status == 'Error') {
      return 'On-Hold';
    }

    final batches = order['productionBatches'] as List<dynamic>? ?? [];
    if (batches.isEmpty) return 'Pending Worker';

    bool hasPendingQC = false;
    bool hasPendingWorker = false;
    bool hasInProcess = false;
    bool hasFailed = false;

    for (var b in batches) {
      if (b['status'] == 'Completed') continue;
      
      final logStatusRaw = b['latestLogStatus']?.toString() ?? '';
      final logStatus = logStatusRaw.replaceAll(' ', '').toUpperCase();

      if (logStatus == 'PENDINGQC' || logStatus == 'PENDING_QC') {
        hasPendingQC = true;
      } else if (logStatus == 'APPROVED') {
        hasInProcess = true;
      } else if (logStatus == 'RUNNING' || logStatus == 'PASSED' || logStatus == '') {
        // RUNNING: Công nhân đang nhập liệu (Phase 2)
        // PASSED: Vừa xong công đoạn trước, chưa bắt đầu công đoạn sau (Phase 1)
        // '': Chưa có log nào (Phase 1)
        hasPendingWorker = true;
      } else if (logStatus == 'FAILED' || logStatus == 'REJECTED') {
        hasFailed = true;
      }
    }

    // Thứ tự ưu tiên hiển thị: On-Hold > Pending QC > Pending Worker > In-Process
    if (hasFailed) return 'On-Hold';
    if (hasPendingQC) return 'Pending QC';
    if (hasPendingWorker) return 'Pending Worker';
    if (hasInProcess) return 'In-Process';

    // Fallback based on order status
    if (status == 'Draft') return 'Pending Worker';
    if (status == 'In-Process' || status == 'InProcess' || status == 'Running') {
      return 'In-Process';
    }

    return 'Pending Worker';
  }

  void _logout() async {
    await AuthService.clearSession();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade600;
      case 'In-Process':
        return Colors.blue.shade600;
      case 'Pending Worker':
        return Colors.orange.shade600;
      case 'Pending QC':
        return Colors.purple.shade600;
      case 'On-Hold':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, bool isPendingTab,
      {bool isQC = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không có lệnh sản xuất nào',
                style: TextStyle(color: Colors.grey.shade500)),
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
          final displayStatus = _getOrderDisplayStatus(order);
          final color = _statusColor(displayStatus);
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
                  if (!isQC) {
                    // Mở màn hình dành riêng cho Công nhân (có tab bar Cân, Sấy, Trộn)
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MainNavigationScreen(orderData: order),
                          ),
                        )
                        .then(
                            (_) => _loadOrders()); // Luôn load lại khi quay về
                  } else {
                    // Mở màn hình QC duyệt tổng quát
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderVerificationScreen(orderData: order),
                      ),
                    )
                        .then((result) {
                      _loadOrders(); // Tải lại
                      if (result == true) {
                        _tabController.animateTo(
                            0); // Tự động nhảy sang tab "Đang sản xuất"
                      }
                    });
                  }
                } else {
                  // Mở màn hình thao tác sản xuất bình thường
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MainNavigationScreen(orderData: order),
                        ),
                      )
                      .then((_) => _loadOrders()); // Luôn load lại khi quay về
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: color.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            (displayStatus == 'In-Process')
                                ? 'Đang sản xuất'
                                : (displayStatus == 'Completed')
                                    ? 'Đã hoàn tất'
                                    : (displayStatus == 'On-Hold')
                                        ? 'Đang tạm dừng'
                                        : (displayStatus == 'Pending QC')
                                            ? 'Chờ QC xét duyệt'
                                            : 'Chờ công nhân xử lý',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lệnh: ${order['orderCode']} - Cỡ lô: ${order['batchSize']}',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
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
                                  progress >= 1.0
                                      ? Colors.green
                                      : Theme.of(context).primaryColor,
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
                              color: progress >= 1.0
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã hoàn thành: ${order['completedBatches']} / ${order['totalBatches']} mẻ',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.engineering,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            isQC
                                ? 'Chờ QC kiểm tra hồ sơ mẻ...'
                                : 'Nhấn để bắt đầu các mẻ (batch) sản xuất...',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
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

  Widget _buildCompletedList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có lệnh nào hoàn thành',
                style: TextStyle(color: Colors.grey.shade500)),
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
          final progress = (order['progress'] ?? 0.0) as double;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade200, width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MainNavigationScreen(orderData: order),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order['productName'] ?? 'Sản phẩm',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Hoàn thành',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lệnh: ${order['orderCode']} · Cỡ lô: ${order['batchSize']}',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (order['endDate'] != null &&
                        order['endDate'] != '-') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.green.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Kết thúc: ${order['endDate']}',
                            style: TextStyle(
                                color: Colors.green.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đã hoàn thành: ${order['completedBatches']} / ${order['totalBatches']} mẻ  ·  ${(progress * 100).toInt()}%',
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _selectedCategory = cat;
                  _filterAndGroupOrders();
                }
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100), // Height for chips + tabs
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryChips(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Đang sản xuất'),
                  Tab(text: 'Chờ Công nhân'),
                  Tab(text: 'Chờ QC xét duyệt'),
                  Tab(text: 'Đang tạm dừng'),
                  Tab(text: 'Đã hoàn tất'),
                ],
              ),
            ],
          ),
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
                      child: const Text('Đồng ý'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_inProcessOrders, false),
                _buildOrderList(_pendingWorkerOrders, true, isQC: false),
                _buildOrderList(_pendingQCOrders, true, isQC: true),
                _buildOrderList(_errorOrders, false),
                _buildCompletedList(_completedOrders),
              ],
            ),
    );
  }
}
