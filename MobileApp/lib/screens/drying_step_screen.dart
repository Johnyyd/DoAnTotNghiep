import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';

/// Màn hình [DryingStepScreen] quản lý công đoạn sấy nguyên liệu.
class DryingStepScreen extends StatefulWidget {
  final String stepName;
  const DryingStepScreen({super.key, required this.stepName});

  @override
  State<DryingStepScreen> createState() => _DryingStepScreenState();
}

class _DryingStepScreenState extends State<DryingStepScreen> {
  final _ngayCtrl = TextEditingController(text: '18/03/2026');
  final _nguoiCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _humidCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _pressCtrl = TextEditingController();
  final _tempInCtrl = TextEditingController();
  final _tempOutCtrl = TextEditingController();
  final _timeStartCtrl = TextEditingController();
  final _timeEndCtrl = TextEditingController();
  final _humidAfterCtrl = TextEditingController();
  final _slTruocCtrl = TextEditingController();
  final _slSauCtrl = TextEditingController();

  String _phongSach = 'Sạch';
  String _maySay = 'Sạch';
  String _dungCuSay = 'Sạch';
  String _mayKhongTai = 'Ổn định';
  String _mauKiemTra = '0'; // Lưu kết quả DryingSampleField
  
  bool _isSaving = false;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final params = {
      "ngay": _ngayCtrl.text,
      "nguoiThucHien": _nguoiCtrl.text,
      "veSinhPhong": _phongSach,
      "veSinhMay": _maySay,
      "veSinhDungCu": _dungCuSay,
      "nhietDo": _tempCtrl.text,
      "doAm": _humidCtrl.text,
      "thoiGianKiemTra": _timeCtrl.text,
      "apLuc": _pressCtrl.text,
      "mayKhongTai": _mayKhongTai,
      "nhietDoKhiVao": _tempInCtrl.text,
      "nhietDoKhiRa": _tempOutCtrl.text,
      "batDauSay": _timeStartCtrl.text,
      "ketThucSay": _timeEndCtrl.text,
      "doAmSauSay": _humidAfterCtrl.text,
      "layMauKiemTraGams": _mauKiemTra,
      "slTruocSay": _slTruocCtrl.text,
      "slSauSay": _slSauCtrl.text,
    };
    
    // Ghi nhận: Lô mặc định BatchId=1, Bước Sấy StepId=2
    bool success = await ApiService.submitStepData(
      batchId: 1,
      stepId: 2,
      resultStatus: 'Passed',
      parametersData: params,
    );
    setState(() => _isSaving = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn sấy thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.stepName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
        const FormSectionHeader('4.1 THÔNG TIN CHUNG'),
        const StandardInputField(label: 'Phòng thực hiện', hint: 'Pha chế'),
        StandardInputField(label: 'Ngày', controller: _ngayCtrl, suffixIcon: const Icon(Icons.calendar_today)),
        StandardInputField(label: 'Người thực hiện & Người kiểm tra', controller: _nguoiCtrl, hint: 'Chọn nhân viên', suffixIcon: const Icon(Icons.person_add)),

        const FormSectionHeader('4.2 KIỂM TRA VỆ SINH'),
        SegmentedToggle(label: 'Phòng pha chế', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _phongSach = v),
        SegmentedToggle(label: 'Máy sấy tầng sôi KBC-TS-50', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _maySay = v),
        SegmentedToggle(label: 'Dụng cụ sấy', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCuSay = v),

        const FormSectionHeader('4.3 ĐIỀU KIỆN MÔI TRƯỜNG'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', controller: _tempCtrl, hint: '23.0', standardText: 'Standard: 21 - 25', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Độ ẩm (%)', controller: _humidCtrl, hint: '60.0', standardText: 'Standard: 45 - 70', keyboardType: TextInputType.number)),
          ],
        ),
        StandardInputField(label: 'Thời gian kiểm tra', controller: _timeCtrl, hint: '08:00 AM', suffixIcon: const Icon(Icons.access_time)),
        StandardInputField(label: 'Áp lực phòng đọc (Pa)', controller: _pressCtrl, hint: '15', standardText: 'Standard: >= 10', keyboardType: TextInputType.number),

        const FormSectionHeader('4.4 THÔNG SỐ SẤY & KẾT QUẢ'),
        SegmentedToggle(label: 'Tình trạng máy chạy không tải', optionA: 'Ổn định', optionB: 'Không ổn định', onChanged: (v) => _mayKhongTai = v),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí vào (°C)', controller: _tempInCtrl, hint: '50', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí ra (°C)', controller: _tempOutCtrl, hint: '45', keyboardType: TextInputType.number)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Bắt đầu sấy', controller: _timeStartCtrl, hint: '08:30 AM', suffixIcon: const Icon(Icons.access_time))),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Kết thúc sấy', controller: _timeEndCtrl, hint: '10:30 AM', suffixIcon: const Icon(Icons.access_time))),
          ],
        ),
        StandardInputField(label: 'Độ ẩm sau khi sấy (%)', controller: _humidAfterCtrl, hint: '1.5', keyboardType: TextInputType.number),
        
        DryingSampleField(onResultChanged: (v) => _mauKiemTra = v),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'SL trước sấy (kg)', controller: _slTruocCtrl, hint: '100', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'SL sau sấy (kg)', controller: _slSauCtrl, hint: '95', keyboardType: TextInputType.number)),
          ],
        ),
        
        const SizedBox(height: 24),
        _isSaving
         ? const Center(child: CircularProgressIndicator())
         : ESignatureButton(title: 'KÝ & LƯU CÔNG ĐOẠN', onPressed: _submit),
        const SizedBox(height: 32),
      ],
    );
  }
}
