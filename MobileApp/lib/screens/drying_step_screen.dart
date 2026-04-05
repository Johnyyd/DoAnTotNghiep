import 'dart:convert';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/execution_phase.dart';

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
  final _ngayCtrl = TextEditingController();
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
  final _cuaGioCtrl = TextEditingController(text: '4');
  
  // Expanded GMP Parameters
  final _tgSayCaiDatCtrl = TextEditingController();
  final _tocDoGioCtrl = TextEditingController();
  final _apSuatTuiLocCtrl = TextEditingController();
  final _tanSoSayCtrl = TextEditingController();

  // Map lưu trữ trạng thái hiển thị (none, warning, error) cho từng input
  final Map<String, String> _inputStatus = {};
  List<dynamic> _standardParams = [];
  Map<String, dynamic> _currentLog = {};
  ExecutionPhase _currentPhase = ExecutionPhase.precheck;

  String _phongSach = 'Sạch';
  String _maySay = 'Sạch';
  String _dungCuSay = 'Sạch';
  String _mayKhongTai = 'Ổn định';
  String _mauKiemTra = '0'; 
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Tự động khởi tạo ngày và người thực hiện nếu không phải mode xem lại
    if (!widget.isViewer) {
      final now = DateTime.now();
      _ngayCtrl.text = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      _nguoiCtrl.text = AuthService.currentUser?['fullName'] ?? '';
    }
    
    if (widget.batchId != null) {
      _loadDataFromDB();
    }
  }

  String? _getStandardText(String paramName) {
    if (_standardParams.isEmpty) return null;
    try {
      final sp = _standardParams.firstWhere(
        (p) => (p['parameterName'] as String).toLowerCase().contains(paramName.toLowerCase()),
        orElse: () => null,
      );
      if (sp != null) {
        final min = sp['minValue'];
        final max = sp['maxValue'];
        final unit = sp['unit'] ?? '';
        if (min != null && max != null) {
          if (min == max) return "Chuẩn: ${min.toString().replaceAll('.0', '')} $unit";
          return "Chuẩn: ${min.toString().replaceAll('.0', '')} - ${max.toString().replaceAll('.0', '')} $unit";
        } else if (min != null) {
          return "Chuẩn: >= ${min.toString().replaceAll('.0', '')} $unit";
        } else if (max != null) {
          return "Chuẩn: <= ${max.toString().replaceAll('.0', '')} $unit";
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadDataFromDB() async {
    try {
      final logs = await ApiService.getProcessLogs(widget.batchId!);
      final log = logs.firstWhere((l) => l['stepId'] == widget.stepId, orElse: () => <String, dynamic>{});
      
      if (log.isNotEmpty) {
        _currentLog = log;
        // Lấy parameters chuẩn từ routing (đã được ApiService map vào)
        _standardParams = log['routing']?['stepParameters'] ?? [];
        
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
            // Chỉ ghi đè nếu trong DB có dữ liệu, nếu không giữ giá trị mặc định đã init ở initState
            if (params['ngay'] != null && params['ngay'].toString().isNotEmpty) {
               _ngayCtrl.text = params['ngay'];
            }
            if (params['nguoiThucHien'] != null && params['nguoiThucHien'].toString().isNotEmpty) {
               _nguoiCtrl.text = params['nguoiThucHien'];
            }
            
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
            
            _tgSayCaiDatCtrl.text = params['tgSayCaiDat'] ?? '';
            _tocDoGioCtrl.text = params['tocDoGio'] ?? '';
            _apSuatTuiLocCtrl.text = params['apSuatTuiLoc'] ?? '';
            _tanSoSayCtrl.text = params['tanSoSay'] ?? '';
            _cuaGioCtrl.text = params['viTriCuaGio'] ?? '4';

            // Xác định phase hiện tại dựa trên dữ liệu từ DB
            final status = _currentLog['resultStatus'];
            if (status == 'PendingQC') {
              _currentPhase = ExecutionPhase.verification;
            } else if (status == 'Approved') {
              _currentPhase = ExecutionPhase.execution;
            } else if (status == 'Passed') {
              _currentPhase = ExecutionPhase.completed;
            } else if (rawParams != null) {
              _currentPhase = ExecutionPhase.input;
            }
          });
          _updateAllInputStatuses();
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _updateInputStatus(String fieldName, String value, {String? paramNameInStandard}) {
    if (_standardParams.isEmpty) return;
    
    final val = double.tryParse(value);
    if (val == null) {
      setState(() => _inputStatus[fieldName] = 'none');
      return;
    }

    final sp = _standardParams.firstWhere(
      (p) => (p['parameterName'] as String).toLowerCase().contains((paramNameInStandard ?? fieldName).toLowerCase()),
      orElse: () => null,
    );

    if (sp != null) {
      final min = sp['minValue'] != null ? (sp['minValue'] as num).toDouble() : null;
      final max = sp['maxValue'] != null ? (sp['maxValue'] as num).toDouble() : null;
      
      String status = 'none';
      if (min != null && val < min) status = 'error';
      if (max != null && val > max) status = 'error';
      
      setState(() => _inputStatus[fieldName] = status);
    }
  }

  void _updateAllInputStatuses() {
    _updateInputStatus('nhietDo', _tempCtrl.text, paramNameInStandard: 'Nhiệt độ phòng');
    _updateInputStatus('doAm', _humidCtrl.text, paramNameInStandard: 'Độ ẩm phòng');
    _updateInputStatus('apLuc', _pressCtrl.text, paramNameInStandard: 'Áp lực phòng');
    _updateInputStatus('nhietDoKhiVao', _tempInCtrl.text, paramNameInStandard: 'Nhiệt độ sấy');
    _updateInputStatus('tgSayCaiDat', _tgSayCaiDatCtrl.text, paramNameInStandard: 'Thời gian sấy');
    _updateInputStatus('doAmSauSay', _humidAfterCtrl.text, paramNameInStandard: 'Độ ẩm');
  }

  Future<void> _approveByQC(String status) async {
    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return;
    if (pin != '123456') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN xác nhận không đúng!')));
       return;
    }

    setState(() => _isSaving = true);
    final verifierId = AuthService.currentUser?['userId'] ?? 0;
    
    final success = await ApiService.verifyStepData(
      logId: _currentLog['logId'],
      verifierId: verifierId,
      status: status,
      notes: status == 'Failed' ? 'QC Rejected' : 'Approved via Mobile',
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      setState(() {
        _currentPhase = (status == 'Approved') ? ExecutionPhase.execution : _currentPhase;
      });
      if (status != 'Approved') Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✔ QC đã xác nhận: $status')));
    }
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

  Future<void> _nextPhase() async {
    if (_currentPhase == ExecutionPhase.precheck) {
      setState(() => _currentPhase = ExecutionPhase.input);
      await _submit('Running', null, isInternal: true);
    } else if (_currentPhase == ExecutionPhase.input) {
      await _verifyAndSubmit(); 
    } else if (_currentPhase == ExecutionPhase.execution) {
       await _submit('Passed', null);
    }
  }

  Future<void> _prevPhase() async {
    if (_currentPhase == ExecutionPhase.completed || _currentPhase == ExecutionPhase.precheck) return;
    
    // Logic lùi trạng thái dựa trên phase mới
    String newStatus = 'Running';
    final targetPhase = ExecutionPhase.values[_currentPhase.index - 1];
    
    if (targetPhase == ExecutionPhase.verification) {
      newStatus = 'PendingQC';
    } else if (targetPhase == ExecutionPhase.execution) {
      newStatus = 'Approved';
    } else if (targetPhase == ExecutionPhase.input || targetPhase == ExecutionPhase.precheck) {
      newStatus = 'Running';
    }

    setState(() {
      _currentPhase = targetPhase;
    });

    // Cập nhật trạng thái lên server để đồng bộ và khóa/mở khóa dữ liệu
    await _submit(newStatus, null, isInternal: true);
  }

  Future<void> _submit(String resultStatus, String? devNotes, {bool isInternal = false}) async {
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
      "mauKiemTraGams": _mauKiemTra,
      "slTruocSay": _slTruocCtrl.text,
      "slSauSay": _slSauCtrl.text,
      "tgSayCaiDat": _tgSayCaiDatCtrl.text,
      "tocDoGio": _tocDoGioCtrl.text,
      "apSuatTuiLoc": _apSuatTuiLocCtrl.text,
      "tanSoSay": _tanSoSayCtrl.text,
      "viTriCuaGio": _cuaGioCtrl.text,
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
      if (resultStatus == 'PendingQC') {
        setState(() => _currentPhase = ExecutionPhase.verification);
      } else if (resultStatus == 'Passed') {
        setState(() => _currentPhase = ExecutionPhase.completed);
        Navigator.pop(context);
      }
    }
    
    if (!isInternal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '✔ Cập nhật dữ liệu thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SẤY: ${_currentPhase.label}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _currentPhase.indexNumber / 5.0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_currentPhase == ExecutionPhase.precheck) _buildPhase1(),
                if (_currentPhase == ExecutionPhase.input) _buildPhase2(),
                if (_currentPhase == ExecutionPhase.verification) _buildPhase3(),
                if (_currentPhase == ExecutionPhase.execution) _buildPhase4(),
                if (_currentPhase == ExecutionPhase.completed) _buildPhase5(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildContextualFAB(),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Bước ${_currentPhase.indexNumber}/5', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          Text(_currentPhase.label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget? _buildContextualFAB() {
    if (widget.isViewer && _currentPhase != ExecutionPhase.verification) return null;
    
    if (_currentPhase == ExecutionPhase.verification) {
      if (AuthService.currentUser?['role'] == 'QA_QC') {
        return FloatingActionButton.extended(
          heroTag: 'btnApprove',
          onPressed: () => _approveByQC('Approved'),
          label: const Text('XÁC NHẬN QC'),
          icon: const Icon(Icons.verified_user),
          backgroundColor: Colors.green,
        );
      }
      // Khách (Worker) đang đợi QC: Cho phép quay lại Phase 2 để sửa
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton.extended(
          heroTag: 'btnBackWait',
          onPressed: _isSaving ? null : _prevPhase,
          label: const Text('QUAY LẠI SỬA'),
          icon: const Icon(Icons.arrow_back),
          backgroundColor: Colors.grey.shade700,
        ),
      );
    }

    if (_currentPhase == ExecutionPhase.completed) return null;

    String label = 'TIẾP TỤC';
    IconData icon = Icons.arrow_forward;
    if (_currentPhase == ExecutionPhase.input) label = 'GỬI DUYỆT QC';
    if (_currentPhase == ExecutionPhase.execution) {
      label = 'KẾT THÚC CÔNG ĐOẠN';
      icon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPhase != ExecutionPhase.precheck && _currentPhase != ExecutionPhase.completed) 
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FloatingActionButton.extended(
                heroTag: 'btnBack',
                onPressed: _isSaving ? null : _prevPhase,
                label: const Text('QUAY LẠI'),
                icon: const Icon(Icons.arrow_back),
                backgroundColor: Colors.grey.shade700,
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'btnNext',
            onPressed: _isSaving ? null : _nextPhase,
            label: Text(label),
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(icon),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase1() {
    return Column(
      key: const ValueKey('phase1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader('PHASE 1: KIỂM TRA MÔI TRƯỜNG & VỆ SINH'),
        const StandardInputField(label: 'Phòng thực hiện', hint: 'Phòng Pha chế', readOnly: true),
        StandardInputField(label: 'Ngày', controller: _ngayCtrl, suffixIcon: const Icon(Icons.calendar_today)),
        StandardInputField(label: 'Người thực hiện', controller: _nguoiCtrl, hint: 'Chọn nhân viên', suffixIcon: const Icon(Icons.person_add)),
        SegmentedToggle(label: 'Vệ sinh phòng pha chế', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _phongSach = v),
        SegmentedToggle(label: 'Vệ sinh máy sấy tầng sôi', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _maySay = v),
        SegmentedToggle(label: 'Vệ sinh dụng cụ sấy', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCuSay = v),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'Nhiệt độ (°C)', 
              controller: _tempCtrl, 
              keyboardType: TextInputType.number,
              status: _inputStatus['nhietDo'] ?? 'none',
              standardText: _getStandardText('Nhiệt độ phòng'),
              onChanged: (v) => _updateInputStatus('nhietDo', v, paramNameInStandard: 'Nhiệt độ phòng'),
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(
              label: 'Độ ẩm (%)', 
              controller: _humidCtrl, 
              keyboardType: TextInputType.number,
              status: _inputStatus['doAm'] ?? 'none',
              standardText: _getStandardText('Độ ẩm phòng'),
              onChanged: (v) => _updateInputStatus('doAm', v, paramNameInStandard: 'Độ ẩm phòng'),
            )),
          ],
        ),
        StandardInputField(
          label: 'Áp lực (Pa)', 
          controller: _pressCtrl, 
          keyboardType: TextInputType.number,
          status: _inputStatus['apLuc'] ?? 'none',
          standardText: _getStandardText('Áp lực phòng'),
          onChanged: (v) => _updateInputStatus('apLuc', v, paramNameInStandard: 'Áp lực phòng'),
        ),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionHeader('PHASE 2: THÔNG SỐ VÀ KẾT QUẢ SẤY'),
        SegmentedToggle(label: 'Tình trạng máy (Không tải)', optionA: 'Ổn định', optionB: 'Không ổn định', onChanged: (v) => _mayKhongTai = v),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí vào (°C)', controller: _tempInCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Nhiệt độ khí ra (°C)', controller: _tempOutCtrl, keyboardType: TextInputType.number)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Giờ bắt đầu', controller: _timeStartCtrl, suffixIcon: const Icon(Icons.access_time))),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Giờ kết thúc', controller: _timeEndCtrl, suffixIcon: const Icon(Icons.access_time))),
          ],
        ),
        StandardInputField(label: 'Độ ẩm sau sấy (%)', controller: _humidAfterCtrl, keyboardType: TextInputType.number),
        DryingSampleField(onResultChanged: (v) => _mauKiemTra = v),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'KL trước sấy (kg)', controller: _slTruocCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'KL sau sấy (kg)', controller: _slSauCtrl, keyboardType: TextInputType.number)),
          ],
        ),
        const FormSectionHeader('THÔNG SỐ VẬN HÀNH CHI TIẾT'),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'TG sấy cài đặt (phút)', 
              controller: _tgSayCaiDatCtrl, 
              keyboardType: TextInputType.number,
              status: _inputStatus['tgSayCaiDat'] ?? 'none',
              standardText: _getStandardText('Thời gian sấy'),
              onChanged: (v) => _updateInputStatus('tgSayCaiDat', v, paramNameInStandard: 'Thời gian sấy'),
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Tốc độ gió (Hz)', controller: _tocDoGioCtrl, keyboardType: TextInputType.number)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Áp suất túi lọc (Pa)', controller: _apSuatTuiLocCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Tần số sấy (Hz)', controller: _tanSoSayCtrl, keyboardType: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhase3() {
    return _buildCenteredStatus(Icons.hourglass_empty, Colors.orange, 'ĐANG ĐỢI QC XÁC NHẬN', 'Số liệu đã được khóa. Mời QC kiểm tra và ký xác nhận.');
  }

  Widget _buildPhase4() {
    return _buildCenteredStatus(Icons.play_circle_fill, Colors.green, 'ĐANG THỰC HIỆN SẤY', 'Máy đang vận hành. Nhấn KẾT THÚC sau khi sấy xong.');
  }

  Widget _buildPhase5() {
    return _buildCenteredStatus(Icons.check_circle, Colors.blue, 'ĐÃ HOÀN THÀNH', 'Công đoạn sấy đã kết thúc thành công.');
  }

  Widget _buildCenteredStatus(IconData icon, Color color, String title, String desc) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
