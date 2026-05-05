import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MaterialCard extends StatefulWidget {
  final String materialName;
  final String requiredWeightKg;
  final String unitLabel;
  final Function(String) onWeightChanged;
  final Function(String) onPhieuKNChanged;
  final String initialActualWeight;
  final String initialPhieuKN;
  final bool readOnly;

  const MaterialCard({
    super.key,
    required this.materialName,
    required this.requiredWeightKg,
    this.unitLabel = 'kg',
    required this.onWeightChanged,
    required this.onPhieuKNChanged,
    this.initialActualWeight = '',
    this.initialPhieuKN = '',
    this.readOnly = false,
  });

  @override
  State<MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<MaterialCard> {
  late TextEditingController _controller;
  late TextEditingController _phieuKNController;
  bool _isMatched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialActualWeight);
    _phieuKNController = TextEditingController(text: widget.initialPhieuKN);
    _checkMatch();
  }

  @override
  void didUpdateWidget(MaterialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialActualWeight != _controller.text && !widget.readOnly) {
      _controller.text = widget.initialActualWeight;
    }
    if (widget.initialPhieuKN != _phieuKNController.text && !widget.readOnly) {
      _phieuKNController.text = widget.initialPhieuKN;
    }
    _checkMatch();
  }

  void _checkMatch() {
    final cur = double.tryParse(_controller.text) ?? -1;
    final req = double.tryParse(widget.requiredWeightKg) ?? 0;
    setState(() {
      // Use higher precision for matching: 0.0001 instead of 0.001
      _isMatched = (cur - req).abs() < 0.0001;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isMatched ? AppTheme.success : Colors.grey.shade300,
          width: _isMatched ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Material Name & Match Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.materialName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                if (_isMatched)
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              ],
            ),
            const Divider(height: 24),

            // Vertical Layout for Fields
            // 1. Số phiếu kiểm nghiệm
            const Text(
              'Số phiếu KN:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phieuKNController,
              readOnly: widget.readOnly,
              onChanged: widget.onPhieuKNChanged,
              decoration: InputDecoration(
                hintText: 'Nhập số phiếu KN',
                filled: true,
                fillColor: widget.readOnly ? Colors.grey.shade100 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: const OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),

            // 2. Khối lượng và Thực cân
            Row(
              children: [
                // Required Weight
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu (${widget.unitLabel}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.requiredWeightKg,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Actual Weight
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thực cân (${widget.unitLabel}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        readOnly: widget.readOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          _checkMatch();
                          widget.onWeightChanged(v);
                        },
                        decoration: InputDecoration(
                          hintText: '0.00',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _isMatched ? AppTheme.success : Colors.grey.shade400,
                              width: _isMatched ? 2 : 1,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isMatched ? AppTheme.success : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
