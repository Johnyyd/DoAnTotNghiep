import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../components/material_card.dart';
import '../services/api_service.dart';

/// Màn hình [WeighingStepScreen] hiển thị giao diện cho công đoạn cân nguyên liệu.
class WeighingStepScreen extends StatefulWidget {
  final int batchId;
  final int stepId;

  const WeighingStepScreen({
    super.key,
    required this.batchId,
    required this.stepId,
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
    setState(() => _isLoading = true);
    final batch = await ApiService.getBatchById(widget.batchId);
    if (mounted) {
      setState(() {
        _bom = batch['order']?['recipe']?['recipeBoms'] ?? [];
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

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final params = {
      "temperature": _tempCtrl.text,
      "humidity": _humidCtrl.text,
      "pressure": _pressCtrl.text,
      "canIW2": _canIW2,
      "canPMA": _canPMA,
      "dungCuCan": _dungCuCan,
      "materials": _materialsData,
      "notes": _noteCtrl.text,
    };
    
    bool success = await ApiService.submitStepData(
      batchId: widget.batchId,
      stepId: widget.stepId,
      resultStatus: 'Passed',
      parametersData: params,
    );
    setState(() => _isSaving = false);
    
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn cân thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
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
            : ESignatureButton(title: 'KÝ XÁC NHẬN SỐ', onPressed: _submit),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
