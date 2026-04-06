import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'weighing_step_screen.dart';
import 'mixing_step_screen.dart';
import 'drying_step_screen.dart';

/// [BatchDetailScreen] — Màn hình chi tiết một mẻ sản xuất.
/// Hiển thị danh sách các bước công đoạn (process logs) từ API,
/// cho phép operator ghi nhận kết quả từng bước.
class BatchDetailScreen extends StatefulWidget {
  final int batchId;
  final String batchNumber;
  final int? orderId;

  const BatchDetailScreen({
    super.key,
    required this.batchId,
    required this.batchNumber,
    this.orderId,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  Map<String, dynamic>? _batch;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getBatchById(widget.batchId),
      ApiService.getProcessLogs(widget.batchId),
    ]);
    if (mounted) {
      setState(() {
        _batch = results[0] as Map<String, dynamic>?;
        _logs = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  Future<void> _finishBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text('Đóng mẻ ${widget.batchNumber}? Không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.finishBatch(widget.batchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã hoàn thành mẻ!' : 'Không thể hoàn thành mẻ.'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Color _logStatusColor(String? status) {
    switch (status) {
      case 'Passed':
        return Colors.green.shade600;
      case 'Failed':
        return Colors.red.shade600;
      case 'PendingQC':
        return Colors.orange.shade600;
      case 'Approved':
      case 'Running':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  String _logStatusLabel(String? status) {
    switch (status) {
      case 'Passed':
        return 'Đạt';
      case 'Failed':
        return 'Sự cố (Failed)';
      case 'PendingQC':
        return 'Đợi QC Duyệt';
      case 'Approved':
        return 'Đang sản xuất';
      case 'Running':
        return 'Đang thực hiện';
      default:
        return 'Chưa thực hiện';
    }
  }

  void _onStepTap(int index, Map<String, dynamic> log) {
    final status = log['resultStatus'] as String?;
    
    // GMP Sequential Check
    bool isBlocked = false;
    if (index > 0) {
      final prevStatus = _logs[index - 1]['resultStatus'];
      if (prevStatus != 'Passed') {
        isBlocked = true;
      }
    }

    if (isBlocked) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('⚠ Bạn phải hoàn thành và được QC Duyệt bước trước đó mới có thể thực hiện bước này!'), backgroundColor: Colors.orange),
       );
       return;
    }

    Widget? nextScreen;
    final stepType = log['step']?['stepName']?.toString().toLowerCase() ?? '';
    // isViewer is true if the step is already finalized (Passed/Failed)
    final bool isViewer = status == 'Passed' || status == 'Failed'; 

    if (stepType.contains('cân') || stepType.contains('weigh')) {
      nextScreen = WeighingStepScreen(
        batchId: widget.batchId, 
        stepId: log['stepId'], 
        orderId: widget.orderId,
        isViewer: isViewer
      );
    } else if (stepType.contains('trộn') || stepType.contains('mix')) {
      nextScreen = MixingStepScreen(
        batchId: widget.batchId, 
        stepId: log['stepId'], 
        orderId: widget.orderId,
        isViewer: isViewer
      );
    } else if (stepType.contains('sấy') || stepType.contains('dry')) {
      nextScreen = DryingStepScreen(
        batchId: widget.batchId, 
        stepId: log['stepId'], 
        orderId: widget.orderId,
        stepName: log['step']?['stepName'] ?? 'SẤY', 
        isViewer: isViewer
      );
    }

    if (nextScreen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => nextScreen!)).then((_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchStatus = _batch?['status'] as String?;
    final productName = _batch?['order']?['recipe']?['material']?['materialName']
        as String? ?? 'Sản phẩm';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchNumber),
        actions: [
          if (batchStatus == 'In-Process')
            TextButton.icon(
              onPressed: _finishBatch,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Đóng mẻ', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Batch info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoChip('Mẻ', widget.batchNumber),
                              const SizedBox(width: 8),
                              if (_batch?['order']?['orderCode'] != null)
                                _infoChip(
                                    'Lệnh', _batch!['order']['orderCode']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Process steps header
                  const Text(
                    'TIẾN ĐỘ CÔNG ĐOẠN (GMP SEQUENTIAL)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Process logs
                  if (_logs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa có nhật ký công đoạn nào.\nBắt đầu ghi nhận từ các tab bên dưới.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._logs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final log = entry.value;
                      final status = log['resultStatus'] as String?;
                      final color = _logStatusColor(status);
                      final stepName = log['step']?['stepName'] as String? ??
                          'Công đoạn ${i + 1}';
                      final endTime = log['endTime'] as String?;
                      
                      bool isClickable = true;
                      if (i > 0) {
                        final prevStatus = _logs[i - 1]['resultStatus'];
                        if (prevStatus != 'Passed') isClickable = false;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: isClickable ? 1 : 0,
                        color: isClickable ? Colors.white : Colors.grey.shade100,
                        child: ListTile(
                          onTap: () => _onStepTap(i, log),
                          enabled: isClickable || (status != null), 
                          leading: CircleAvatar(
                            backgroundColor: isClickable ? color.withValues(alpha: 0.15) : Colors.grey.shade200,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                  color: isClickable ? color : Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(stepName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isClickable ? Colors.black87 : Colors.grey
                              )),
                          subtitle: endTime != null
                              ? Text(
                                  'Hoàn thành: ${_formatDate(endTime)}',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : (isClickable ? const Text('Sẵn sàng thực hiện', style: TextStyle(fontSize: 12, color: Colors.blue)) : null),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: color.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _logStatusLabel(status),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
                text: value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}
