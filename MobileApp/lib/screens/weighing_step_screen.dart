import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../components/material_card.dart';
import '../services/api_service.dart';

/// Màn hình [WeighingStepScreen] hiển thị giao diện cho công đoạn cân nguyên liệu.
class WeighingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;

  const WeighingStepScreen({
    super.key,
    this.batchId,
    this.stepId,
  });

  @override
  State<WeighingStepScreen> createState() => _WeighingStepScreenState();
}

class _WeighingStepScreenState extends State<WeighingStepScreen> {
  final _tempCtrl = TextEditingController();
  final _humidCtrl = TextEditingController();
  final _pressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _canIW2 = 'Tốt';
  String _canPMA = 'Tốt';
  String _dungCuCan = 'Sạch';

  final Map<String, Map<String, String>> _materialsData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _bom = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.batchId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final batch = await ApiService.getBatchById(widget.batchId!);
    if (mounted) {
      setState(() {
        _bom = batch?['order']?['recipe']?['recipeBoms'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _updateMaterial(String name, String field, String value) {
    if (!_materialsData.containsKey(name)) {
      _materialsData[name] = {};
    }
    _materialsData[name]![field] = value;
  }

  Future<void> _verifyAndSubmit() async {
    // 1. Validate Deviation
    bool hasDeviation = false;
    String deviationMsg = '';

    for (var item in _bom) {
      final name = item['material']?['materialName'] ?? 'N/A';
      final requiredQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final actualStr = _materialsData[name]?['actual'] ?? '0';
      final actualQty = double.tryParse(actualStr) ?? 0.0;
      
      if (requiredQty > 0) {
        final double diffPercent = ((actualQty - requiredQty).abs() / requiredQty) * 100;
        if (diffPercent > 5.0) {
          hasDeviation = true;
          deviationMsg += '- $name: Y/c ${requiredQty}kg, Cân ${actualQty}kg (Lệch ${diffPercent.toStringAsFixed(1)}%)\n';
        }
      }
    }

    if (hasDeviation) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('CẢNH BÁO DEVIATION (>5%)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('Phát hiện sai số khối lượng quá mức cho phép:\n\n$deviationMsg\nBạn có chắc chắn muốn tiếp tục và ghi nhận sự cố (Failed)?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy & Cân lại')),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xác nhận Lỗi', style: TextStyle(color: Colors.white))
            ),
          ],
        )
      );
      if (proceed != true) return;
    }

    // 2. E-Signature
    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return; 

    // Mock verify PIN
    if (pin != '123456') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN không đúng!')));
      return;
    }

    await _submit(hasDeviation ? 'Failed' : 'Passed', hasDeviation ? deviationMsg : null);
  }

  Future<String?> _showPinDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('CHỮ KÝ ĐIỆN TỬ GMP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Mã PIN cá nhân',
            hintText: 'Nhập 123456 để test',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, ctrl.text), 
            child: const Text('Ký xác nhận')
          ),
        ],
      )
    );
  }

  Future<void> _submit(String resultStatus, String? devNotes) async {
    setState(() => _isSaving = true);
    final params = {
      "temperature": _tempCtrl.text,
      "humidity": _humidCtrl.text,
      "pressure": _pressCtrl.text,
      "canIW2": _canIW2,
      "canPMA": _canPMA,
      "dungCuCan": _dungCuCan,
      "materials": _materialsData,
    };
    
    final finalNotes = devNotes != null 
      ? 'DEVIATION REPORT:\n$devNotes\nGhi chú người dùng: ${_noteCtrl.text}'
      : _noteCtrl.text;

    if (widget.batchId == null || widget.stepId == null) {
      setState(() => _isSaving = false);
      return;
    }

    bool success = await ApiService.submitStepData(
      batchId: widget.batchId!,
      stepId: widget.stepId!,
      resultStatus: resultStatus,
      parametersData: params,
      notes: finalNotes.isNotEmpty ? finalNotes : null,
    );
    setState(() => _isSaving = false);
    
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('CÔNG ĐOẠN CÂN')),
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          const Text('CÔNG ĐOẠN CÂN NGUYÊN LIỆU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          
          const FormSectionHeader('5.1 MÔI TRƯỜNG & THIẾT BỊ'),
          const ReadOnlyField(label: 'Phòng thực hiện', value: 'Phòng cân'),
          const SizedBox(height: 16), 
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', hint: '23.0', controller: _tempCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 16), 
              Expanded(child: StandardInputField(label: 'Độ ẩm (%)', hint: '60.0', controller: _humidCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          StandardInputField(label: 'Áp lực (Pa)', hint: '15', controller: _pressCtrl, keyboardType: TextInputType.number),
          
          SegmentedToggle(label: 'Cân IW2-60', optionA: 'Tốt', optionB: 'Không ổn định', onChanged: (v) => _canIW2 = v),
          SegmentedToggle(label: 'Cân PMA-5000', optionA: 'Tốt', optionB: 'Không ổn định', onChanged: (v) => _canPMA = v),
          SegmentedToggle(label: 'Dụng cụ cân', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCuCan = v),
  
          const FormSectionHeader('5.2 DANH SÁCH NGUYÊN LIỆU QUY ĐỊNH'),
          const Text('Nhập đúng khối lượng yêu cầu để xác nhận hoàn thành từng nguyên liệu.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          
          if (_bom.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Không có dữ liệu BOM cho mẻ này.', style: TextStyle(color: Colors.red)),
            )
          else
            ..._bom.map((item) {
              final materialName = item['material']?['materialName'] ?? 'N/A';
              final requiredQty = item['quantity']?.toString() ?? '0.00';
              return MaterialCard(
                materialName: materialName, 
                requiredWeightKg: requiredQty, 
                onWeightChanged: (v) => _updateMaterial(materialName, 'actual', v), 
                onPhieuKNChanged: (v) => _updateMaterial(materialName, 'phieuKN', v)
              );
            }),
          
          const FormSectionHeader('5.3 NHẬN XÉT'),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Nhập ghi chú hoặc nhận xét...'),
          ),
          const SizedBox(height: 24),
          
          _isSaving 
            ? const Center(child: CircularProgressIndicator()) 
            : ESignatureButton(title: 'KÝ XÁC NHẬN SỐ', onPressed: _verifyAndSubmit),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
