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
    final batches = await ApiService.getBatchesForDispensing();
    setState(() {
      _orders = batches;
      _isLoading = false;
    });
  }

  Future<void> _handleDispense(int bomId, String materialName, String quantityStr) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận cấp phát'),
        content: Text('Bạn có chắc chắn muốn cấp phát $quantityStr $materialName cho mẻ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.dispenseBomItem(bomId, AuthService.currentUser?['userId'] ?? 0);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận cấp phát nguyên liệu')),
        );
      }
      _loadOrders();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi cấp phát nguyên liệu')),
        );
      }
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
                    final batch = _orders[index];
                    return _buildBatchCard(batch);
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
            'Không có mẻ cần cấp phát',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Các mẻ đang chờ sẽ hiển thị ở đây'),
        ],
      ),
    );
  }

  Widget _buildBatchCard(dynamic batch) {
    final boms = batch['productionOrderBoms'] ?? batch['ProductionOrderBoms'] ?? [];
    final recipeName = batch['recipeName'] ?? batch['RecipeName'] ?? 'Sản phẩm';
    final batchNumber = batch['batchNumber'] ?? batch['BatchNumber'] ?? 'N/A';
    final orderCode = batch['orderCode'] ?? batch['OrderCode'] ?? 'N/A';
    final status = batch['status'] ?? batch['Status'] ?? '';
    
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
                        '$orderCode - $batchNumber',
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
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (status == 'In-Process' || status == 'InProcess') ? 'Đang sản xuất' : 'Chờ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
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
                final selectedLotNumber = bom['selectedLotNumber'] ?? bom['SelectedLotNumber'] ?? 'Chưa chỉ định';
                
                final isDispensed = dispensingStatus == 'Dispensed';
                
                return ListTile(
                  leading: Icon(
                    isDispensed ? Icons.check_circle : Icons.pending_actions,
                    color: isDispensed ? Colors.green : Colors.orange,
                  ),
                  title: Text(materialName),
                  subtitle: Text('$requiredQuantity $uomName\nLô: $selectedLotNumber'),
                  isThreeLine: true,
                  trailing: isDispensed
                      ? const Text('Đã xong', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : ElevatedButton(
                          onPressed: () => _handleDispense(orderBomId, materialName, '$requiredQuantity $uomName'),
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
