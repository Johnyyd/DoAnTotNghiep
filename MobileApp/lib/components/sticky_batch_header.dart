import 'package:flutter/material.dart';

/// Component [StickyBatchHeader] hiển thị thông tin tổng quan của Lô Sản Xuất.
/// Nó có thể được thu gọn/mở rộng (collapsible) để tiết kiệm không gian màn hình,
/// được ghim trên cùng của mọi màn hình công đoạn nhập liệu.
class StickyBatchHeader extends StatefulWidget {
  final String title;
  final String batchNo;
  final String sdk;
  final String batchSize;
  final String sizing;
  final String startDate;
  final String endDate;

  const StickyBatchHeader({
    super.key,
    required this.title,
    required this.batchNo,
    required this.sdk,
    required this.batchSize,
    required this.sizing,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<StickyBatchHeader> createState() => _StickyBatchHeaderState();
}

class _StickyBatchHeaderState extends State<StickyBatchHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lô: ${widget.batchNo}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                )
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 24),
            _buildDetailRow('SĐK & Cỡ lô:', '${widget.sdk} - ${widget.batchSize}'),
            const SizedBox(height: 8),
            _buildDetailRow('Quy cách:', widget.sizing),
            const SizedBox(height: 8),
            _buildDetailRow('Timeline:', 'Từ ${widget.startDate} - Đến ${widget.endDate}'),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
