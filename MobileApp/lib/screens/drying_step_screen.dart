import 'dart:convert';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';

/// Màn hình [DryingStepScreen] quản lý công đoạn sấy nguyên liệu.
class DryingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;
  final String stepName;
  final bool isPrecheck;
  final bool isViewer;

  const DryingStepScreen({
    super.key, 
    this.batchId,
    this.stepId,
    required this.stepName,
    this.isPrecheck = false,
    this.isViewer = false,
  });

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
  String _mauKiemTra = '0'; 
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isViewer && widget.batchId != null) {
      _loadDataFromDB();
    }
  }

  Future<void> _loadDataFromDB() async {
    try {
      final logs = await ApiService.getProcessLogs(widget.batchId!);
      final log = logs.firstWhere((l) => l['stepId'] == widget.stepId, orElse: () => <String, dynamic>{});
      if (log.isNotEmpty) {
        final rawParams = log['parametersData'];
        Map<String, dynamic> params = {};
        if (rawParams is Map<String, dynamic>) {
          params = rawParams;
        } else if (rawParams is String && rawParams.isNotEmpty) {
          try {
            params = Map<String, dynamic>.from(jsonDecode(rawParams) ?? {});
          } catch (_) {}
        }
        
        if (mounted) {
          setState(() {
            _ngayCtrl.text = params['ngay'] ?? '';
            _nguoiCtrl.text = params['nguoiThucHien'] ?? '';
            if (params['veSinhPhong'] != null) _phongSach = params['veSinhPhong'];
            if (params['veSinhMay'] != null) _maySay = params['veSinhMay'];
            if (params['veSinhDungCu'] != null) _dungCuSay = params['veSinhDungCu'];
            _tempCtrl.text = params['nhietDo'] ?? '';
            _humidCtrl.text = params['doAm'] ?? '';
            _timeCtrl.text = params['thoiGianKiemTra'] ?? '';
            _pressCtrl.text = params['apLuc'] ?? '';
            if (params['mayKhongTai'] != null) _mayKhongTai = params['mayKhongTai'];
            _tempInCtrl.text = params['nhietDoKhiVao'] ?? '';
            _tempOutCtrl.text = params['nhietDoKhiRa'] ?? '';
            _timeStartCtrl.text = params['batDauSay'] ?? '';
            _timeEndCtrl.text = params['ketThucSay'] ?? '';
            _humidAfterCtrl.text = params['doAmSauSay'] ?? '';
            _slTruocCtrl.text = params['slTruocSay'] ?? '';
            _slSauCtrl.text = params['slSauSay'] ?? '';
            _mauKiemTra = params['layMauKiemTraGams'] ?? '0';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _verifyAndSubmit() async {
    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return;

    if (pin != '123456') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN không đúng!')));
      return;
    }

    await _submit('Passed', null);
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
    
    if (widget.batchId == null || widget.stepId == null) {
      setState(() => _isSaving = false);
      return;
    }

    bool success = await ApiService.submitStepData(
      batchId: widget.batchId!,
      stepId: widget.stepId!,
      resultStatus: resultStatus,
      parametersData: params,
      notes: devNotes,
    );
    setState(() => _isSaving = false);
    
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn sấy thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.isPrecheck) 
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('ĐIỀN CHECKLIST KIỂM TRA MÔI TRƯỜNG & THIẾT BỊ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        else
          Text(widget.stepName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
        if (widget.isViewer)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('CHẾ ĐỘ HỒ SƠ LƯU (READ-ONLY)\nDữ liệu thông số đã được xác nhận.', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
        
        const FormSectionHeader('4.1 THÔNG TIN CHUNG'),
          StandardInputField(label: 'Phòng thực hiện', hint: 'Pha chế', readOnly: widget.isViewer),
          StandardInputField(label: 'Ngày', controller: _ngayCtrl, suffixIcon: const Icon(Icons.calendar_today), readOnly: widget.isViewer),
          StandardInputField(label: 'Người thực hiện & Người kiểm tra', controller: _nguoiCtrl, hint: 'Chọn nhân viên', suffixIcon: const Icon(Icons.person_add), readOnly: widget.isViewer),
  
          const FormSectionHeader('4.2 KIỂM TRA VỆ SINH'),
          SegmentedToggle(label: 'Phòng pha chế', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _phongSach = v, disabled: widget.isViewer),
          SegmentedToggle(label: 'Máy sấy tầng sôi KBC-TS-50', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _maySay = v, disabled: widget.isViewer),
          SegmentedToggle(label: 'Dụng cụ sấy', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCuSay = v, disabled: widget.isViewer),
  
          const FormSectionHeader('4.3 ĐIỀU KIỆN MÔI TRƯỜNG'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', controller: _tempCtrl, hint: '23.0', standardText: 'Standard: 21 - 25', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
              const SizedBox(width: 16),
              Expanded(child: StandardInputField(label: 'Độ ẩm (%)', controller: _humidCtrl, hint: '60.0', standardText: 'Standard: 45 - 70', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
            ],
          ),
          StandardInputField(label: 'Thời gian kiểm tra', controller: _timeCtrl, hint: '08:00 AM', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer),
          StandardInputField(label: 'Áp lực phòng đọc (Pa)', controller: _pressCtrl, hint: '15', standardText: 'Standard: >= 10', keyboardType: TextInputType.number, readOnly: widget.isViewer),
  
        if (!widget.isPrecheck) ...[
          const FormSectionHeader('4.4 THÔNG SỐ SẤY & KẾT QUẢ'),
          SegmentedToggle(label: 'Tình trạng máy chạy không tải', optionA: 'Ổn định', optionB: 'Không ổn định', onChanged: (v) => _mayKhongTai = v, disabled: widget.isViewer),
          Row(
            children: [
              Expanded(child: StandardInputField(label: 'Nhiệt độ khí vào (°C)', controller: _tempInCtrl, hint: '50', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
              const SizedBox(width: 16),
              Expanded(child: StandardInputField(label: 'Nhiệt độ khí ra (°C)', controller: _tempOutCtrl, hint: '45', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
            ],
          ),
          Row(
            children: [
              Expanded(child: StandardInputField(label: 'Bắt đầu sấy', controller: _timeStartCtrl, hint: '08:30 AM', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer)),
              const SizedBox(width: 16),
              Expanded(child: StandardInputField(label: 'Kết thúc sấy', controller: _timeEndCtrl, hint: '10:30 AM', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer)),
            ],
          ),
          StandardInputField(label: 'Độ ẩm sau khi sấy (%)', controller: _humidAfterCtrl, hint: '1.5', keyboardType: TextInputType.number, readOnly: widget.isViewer),
          
          DryingSampleField(onResultChanged: (v) => _mauKiemTra = v, readOnly: widget.isViewer),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: StandardInputField(label: 'SL trước sấy (kg)', controller: _slTruocCtrl, hint: '100', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
              const SizedBox(width: 16),
              Expanded(child: StandardInputField(label: 'SL sau sấy (kg)', controller: _slSauCtrl, hint: '95', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
            ],
          ),
        ],
        
        if (!widget.isPrecheck && !widget.isViewer) ...[
          const SizedBox(height: 24),
          _isSaving
           ? const Center(child: CircularProgressIndicator())
           : ESignatureButton(title: 'KÝ & LƯU CÔNG ĐOẠN', onPressed: _verifyAndSubmit),
          const SizedBox(height: 32),
        ]
      ],
    );

    if (widget.isPrecheck) return content;
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.stepName)),
      body: content,
    );
  }
}
