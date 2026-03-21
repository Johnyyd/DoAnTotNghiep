import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../components/material_card.dart';
import '../services/api_service.dart';

/// Màn hình [WeighingStepScreen] hiển thị giao diện cho công đoạn cân nguyên liệu.
class WeighingStepScreen extends StatefulWidget {
  const WeighingStepScreen({super.key});

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
  bool _isSaving = false;

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
    
    // Ghi nhận: Lô mặc định BatchId=1, Bước Cân StepId=1
    bool success = await ApiService.submitStepData(
      batchId: 1,
      stepId: 1,
      resultStatus: 'Passed',
      parametersData: params,
    );
    setState(() => _isSaving = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn cân thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        
        MaterialCard(materialName: 'NLC 3', requiredWeightKg: '50.00', onWeightChanged: (v) => _updateMaterial('NLC3', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('NLC3', 'phieuKN', v)),
        MaterialCard(materialName: 'TD 1', requiredWeightKg: '10.00', onWeightChanged: (v) => _updateMaterial('TD1', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('TD1', 'phieuKN', v)),
        MaterialCard(materialName: 'TD 3', requiredWeightKg: '5.00', onWeightChanged: (v) => _updateMaterial('TD3', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('TD3', 'phieuKN', v)),
        MaterialCard(materialName: 'TD 4', requiredWeightKg: '15.00', onWeightChanged: (v) => _updateMaterial('TD4', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('TD4', 'phieuKN', v)),
        MaterialCard(materialName: 'TD 5', requiredWeightKg: '2.50', onWeightChanged: (v) => _updateMaterial('TD5', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('TD5', 'phieuKN', v)),
        MaterialCard(materialName: 'TD 8', requiredWeightKg: '1.50', onWeightChanged: (v) => _updateMaterial('TD8', 'actual', v), onPhieuKNChanged: (v) => _updateMaterial('TD8', 'phieuKN', v)),
        
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
    );
  }
}
