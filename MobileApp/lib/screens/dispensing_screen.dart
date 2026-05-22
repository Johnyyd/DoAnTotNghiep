import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DispensingScreen extends StatefulWidget {
  const DispensingScreen({super.key});

  @override
  State<DispensingScreen> createState() => _DispensingScreenState();
}

class _DispensingScreenState extends State<DispensingScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await ApiService.getProductionOrders();
    // Lọc các lệnh đã duyệt hoặc đang sản xuất VÀ chưa cấp phát xong
    setState(() {
      _orders = orders.where((o) => 
        (o['status'] == 'Approved' || o['status'] == 'InProcess' || o['status'] == 'In-Process' || o['status'] == 'Scheduled') && 
        o['isFullyDispensed'] != true
      ).toList();
      _isLoading = false;
    });
  }

  Future<void> _handleDispense(int bomId) async {
    final success = await ApiService.dispenseBomItem(bomId, AuthService.currentUser?['userId'] ?? 0);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận cấp phát nguyên liệu')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi cấp phát nguyên liệu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấp Phát Nguyên Liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có lệnh cần cấp phát',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Các lệnh sau khi được duyệt sẽ hiển thị ở đây'),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    // Xử lý linh hoạt cả camelCase và PascalCase từ Backend
    final boms = order['productionOrderBoms'] ?? order['ProductionOrderBoms'] ?? [];
    final recipeName = order['recipe']?['recipeName'] ?? order['Recipe']?['RecipeName'] ?? order['recipeName'] ?? 'Sản phẩm';
    final orderCode = order['orderCode'] ?? order['OrderCode'] ?? 'N/A';
    final status = order['status'] ?? order['Status'] ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                      Text(
                        recipeName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (status == 'Approved' || status == 'InProcess' || status == 'In-Process') ? Colors.blue[100] : Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (status == 'Approved') ? 'Đã duyệt' : 'Đang sản xuất',
                    style: TextStyle(
                      fontSize: 12,
                      color: (status == 'Approved') ? Colors.blue[800] : Colors.purple[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (boms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Không có dữ liệu nguyên liệu cho lệnh này.', style: TextStyle(color: Colors.red)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: boms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final bom = boms[index];
                // Hỗ trợ cả PascalCase và camelCase cho các field bên trong
                final dispensingStatus = bom['dispensingStatus'] ?? bom['DispensingStatus'];
                final materialName = bom['materialName'] ?? bom['MaterialName'] ?? 'Nguyên liệu';
                final requiredQuantity = bom['requiredQuantity'] ?? bom['RequiredQuantity'] ?? 0;
                final uomName = bom['uomName'] ?? bom['UomName'] ?? 'kg';
                final orderBomId = bom['orderBomId'] ?? bom['OrderBomId'] ?? 0;
                
                final isDispensed = dispensingStatus == 'Dispensed';
                
                return ListTile(
                  leading: Icon(
                    isDispensed ? Icons.check_circle : Icons.pending_actions,
                    color: isDispensed ? Colors.green : Colors.orange,
                  ),
                  title: Text(materialName),
                  subtitle: Text('$requiredQuantity $uomName'),
                  trailing: isDispensed
                      ? const Text('Đã xong', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : ElevatedButton(
                          onPressed: () => _handleDispense(orderBomId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Cấp phát'),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
