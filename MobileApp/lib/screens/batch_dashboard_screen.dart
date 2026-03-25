import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'batch_detail_screen.dart';

/// [BatchDashboardScreen] — Hiển thị danh sách mẻ sản xuất kéo từ API backend.
/// Operator chọn mẻ → vào màn hình chi tiết công đoạn.
class BatchDashboardScreen extends StatefulWidget {
  const BatchDashboardScreen({super.key});

  @override
  State<BatchDashboardScreen> createState() => _BatchDashboardScreenState();
}

class _BatchDashboardScreenState extends State<BatchDashboardScreen> {
  List<Map<String, dynamic>> _batches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await ApiService.getBatches();
    if (mounted) {
      setState(() {
        _batches = data;
        _isLoading = false;
        if (data.isEmpty) _error = 'Không có mẻ sản xuất nào.';
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade600;
      case 'In-Process':
        return Colors.blue.shade600;
      case 'On-Hold':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'Completed':
        return 'Hoàn thành';
      case 'In-Process':
        return 'Đang sản xuất';
      case 'On-Hold':
        return 'Tạm dừng';
      default:
        return status ?? 'Không rõ';
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'In-Process':
        return Icons.pending;
      case 'On-Hold':
        return Icons.pause_circle;
      default:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadBatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBatches,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DANH SÁCH MẺ SẢN XUẤT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${_batches.length} mẻ',
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._batches.map((batch) {
            final batchId = batch['batchId'] as int?;
            final batchNumber = batch['batchNumber'] as String? ?? '-';
            final status = batch['status'] as String?;
            final productName = batch['order']?['recipe']?['material']?['materialName']
                    as String? ??
                batch['order']?['productName'] as String? ??
                'Sản phẩm';
            final orderCode =
                batch['order']?['orderCode'] as String? ?? '#$batchId';

            final color = _statusColor(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: batchId == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BatchDetailScreen(
                              batchId: batchId,
                              batchNumber: batchNumber,
                            ),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_statusIcon(status), color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batchNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              productName,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Lệnh: $orderCode',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                              _statusLabel(status),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right,
                              size: 18, color: Colors.black26),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
