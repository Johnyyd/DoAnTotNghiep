import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DynamicLogViewerScreen extends StatefulWidget {
  final int batchId;
  final int stepId;
  final String stepName;

  const DynamicLogViewerScreen({
    super.key,
    required this.batchId,
    required this.stepId,
    required this.stepName,
  });

  @override
  State<DynamicLogViewerScreen> createState() => _DynamicLogViewerScreenState();
}

class _DynamicLogViewerScreenState extends State<DynamicLogViewerScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _logData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final logs = await ApiService.getProcessLogs(widget.batchId);
    
    Map<String, dynamic>? targetLog;
    for (var log in logs) {
      if (log['stepId'] == widget.stepId) {
        targetLog = log;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _logData = targetLog;
        _isLoading = false;
      });
    }
  }

  IconData _statusIcon(String? status) {
    if (status == 'Passed') return Icons.check_circle;
    if (status == 'Failed') return Icons.cancel;
    if (status == 'PendingQC') return Icons.pending;
    return Icons.lock_clock;
  }

  Color _statusColor(String? status) {
    if (status == 'Passed') return Colors.green.shade600;
    if (status == 'Failed') return Colors.red.shade600;
    if (status == 'PendingQC') return Colors.orange.shade600;
    return Colors.grey.shade600;
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'Passed':
        return 'Đạt tiêu chuẩn';
      case 'Failed':
        return 'Không đạt / Phát sinh lỗi';
      case 'PendingQC':
        return 'QC đang kiểm duyệt';
      default:
        return status ?? 'Chưa ghi nhận hoặc chưa có CSDL';
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Map<String, dynamic> _parseParams(dynamic rawData) {
    if (rawData == null) return {};
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawData);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (e) {
        return {'Dữ liệu thô': rawData};
      }
    }
    return {};
  }

  Widget _buildParamRow(String key, dynamic value) {
    String displayValue = value?.toString() ?? 'N/A';
    if (value is Map || value is List) {
      // If nested map, encode nicely
      displayValue = const JsonEncoder.withIndent('  ').convert(value);
    }
    
    // Capitalize key gracefully
    final displayKey = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayKey, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Text(
              displayValue, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _logData?['resultStatus'] as String?;
    final color = _statusColor(status);
    final endTime = _logData?['endTime'] as String?;
    final paramsData = _parseParams(_logData?['parametersData']);

    // Build lists of Key Value Pairs
    final List<Widget> paramWidgets = paramsData.entries
      .map((entry) => _buildParamRow(entry.key, entry.value))
      .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stepName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Icon(_statusIcon(status), color: color, size: 48),
                const SizedBox(height: 8),
                Text(
                  _statusLabel(status),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                if (endTime != null) ...[
                  const SizedBox(height: 8),
                  Text('Đã cập nhật lúc: ${_formatDate(endTime)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ]
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'THÔNG SỐ ĐÃ GHI NHẬN (QC ĐÃ DUYỆT)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),

          if (_logData == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Chưa có nhật ký hoạt động cho công đoạn này trên CSDL.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            )
          else if (paramWidgets.isEmpty)
             const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Không có dữ liệu ParametersData', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...paramWidgets,
        ],
      ),
    );
  }
}
