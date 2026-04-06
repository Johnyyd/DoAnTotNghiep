import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/execution_phase.dart';

/// Màn hình [DryingStepScreen] quản lý công đoạn sấy nguyên liệu.
class DryingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;
  final int? orderId;
  final String stepName;
  final bool isPrecheck;
  final bool isViewer;

  const DryingStepScreen({
    super.key, 
    this.batchId,
    this.stepId,
    this.orderId,
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
  final _inputMoistureCtrl = TextEditingController();

  // Checklist states
  bool _tuiLoc = false;
  bool _lapRap = false;
  bool _raiNhe = false;
  bool _khoaBang = false;
  bool _dayThung = false;
  bool _dongGoiPE = false;
  bool _cotChat = false;
  bool _danNhan = false;
  bool _baoQuanKho = false;

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

  Timer? _timer;
  Timer? _pollTimer; 
  int _secondsRemaining = 15;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timer?.cancel();
    _ngayCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Tự động khởi tạo ngày và người thực hiện nếu không phải mode xem lại
    if (!widget.isViewer) {
      final now = DateTime.now();
      _ngayCtrl.text = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      _timeCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      _nguoiCtrl.text = AuthService.currentUser?['fullName'] ?? '';
    }
    
    if (widget.batchId != null) {
      _loadDataFromDB().then((_) {
        if (_currentPhase == ExecutionPhase.verification) {
          _startPolling();
        }
      });
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
            _inputMoistureCtrl.text = params['doAmDauVao'] ?? '';

            // Checklists
            _tuiLoc = params['checkTuiLoc'] ?? false;
            _lapRap = params['checkLapRap'] ?? false;
            _raiNhe = params['checkRaiNhe'] ?? false;
            _khoaBang = params['checkKhoaBang'] ?? false;
            _dayThung = params['checkDayThung'] ?? false;
            _dongGoiPE = params['checkDongGoiPE'] ?? false;
            _cotChat = params['checkCotChat'] ?? false;
            _danNhan = params['checkDanNhan'] ?? false;
            _baoQuanKho = params['checkBaoQuanKho'] ?? false;

            // Xác định phase hiện tại dựa trên dữ liệu từ DB (Chuẩn hóa so sánh)
            final rawStatus = _currentLog['resultStatus']?.toString().replaceAll(' ', '').toUpperCase() ?? '';
            
            if (rawStatus == 'PENDINGQC' || rawStatus == 'PENDING_QC') {
              _currentPhase = ExecutionPhase.verification;
            } else if (rawStatus == 'APPROVED' || rawStatus == 'PASSED') {
              _currentPhase = ExecutionPhase.execution;
              // TỰ ĐỘNG BẮT ĐẦU ĐẾM NGƯỢC NẾU VỪA ĐƯỢC DUYỆT TRÊN DB
              if (_secondsRemaining == 15 && _timer == null) {
                Future.delayed(const Duration(milliseconds: 500), () => _startTimer());
              }
            } else if (rawStatus == 'PASSED') {
              _currentPhase = ExecutionPhase.completed;
            } else if (rawStatus == 'RUNNING' || rawParams != null) {
              _currentPhase = ExecutionPhase.input;
            }
          });
          
          // QUẢN LÝ AUTO-POLLING KHI ĐANG ĐỢI QC
          if (_currentPhase == ExecutionPhase.verification) {
            _startPolling();
          } else {
            _stopPolling();
          }

          _updateAllInputStatuses();
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    debugPrint("--- START AUTO-POLLING FOR QC STATUS ---");
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadDataFromDB());
  }

  void _stopPolling() {
    if (_pollTimer != null) {
      debugPrint("--- STOP AUTO-POLLING ---");
      _pollTimer!.cancel();
      _pollTimer = null;
    }
  }

  bool get _isPhase1Locked => widget.isViewer || _currentPhase.index > 0;
  bool get _isPhase2Locked => widget.isViewer || _currentPhase.index > 1;
  bool get _isPhase4Locked => widget.isViewer || (_currentPhase.index > 3) || (_currentPhase == ExecutionPhase.execution && _secondsRemaining > 0);

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 15;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _setCurrentTime(TextEditingController ctrl) {
    if (widget.isViewer) return;
    final now = DateTime.now();
    setState(() {
      ctrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
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
    if (pin == null || pin.isEmpty) {
      return;
    }
    if (mounted && pin != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN xác nhận không đúng!')));
      return;
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }
    final verifierId = AuthService.currentUser?['userId'] ?? 0;
    
    final success = await ApiService.verifyStepData(
      logId: _currentLog['logId'],
      verifierId: verifierId,
      status: status,
      notes: status == 'Failed' ? 'QC Rejected' : 'Approved via Mobile',
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Nếu duyệt trực tiếp trên máy công nhân, cũng cần update trạng thái Lệnh
        if (status == 'Approved' && widget.orderId != null) {
          await ApiService.updateOrderStatus(widget.orderId!, 'In-Process');
        }

        if (mounted) {
          setState(() {
            if (status == 'Approved') {
              _currentPhase = ExecutionPhase.execution;
            }
          });
          if (status != 'Approved') {
            Navigator.pop(context, true);
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✔ QC đã xác nhận: $status')));
        }
      }
    }
  }

  Future<void> _verifyAndSubmit() async {
    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) {
      return;
    }

    if (mounted && pin != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN không đúng!')));
      return;
    }

    await _submit('PendingQC', null);
    
    // Đảm bảo update Order status thành công rồi mới báo refresh
    if (widget.orderId != null) {
      await ApiService.updateOrderStatus(widget.orderId!, 'Pending QC');
    }

    if (mounted) {
      setState(() => _currentPhase = ExecutionPhase.verification);
      // Quay về dashboard để mẻ sấy hiện ra ở tab QC ngay
      Navigator.of(context).pop(true);
    }
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
      final now = DateTime.now();
      if (_timeStartCtrl.text.isEmpty) {
        _timeStartCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      }
      setState(() => _currentPhase = ExecutionPhase.input);
      // Giữ status Running khi nhập liệu
      await _submit('Running', null, isInternal: true);
    } else if (_currentPhase == ExecutionPhase.input) {
      // Chuyển sang giai đoạn Đợi QC (PendingQC)
      await _verifyAndSubmit(); 
    } else if (_currentPhase == ExecutionPhase.execution) {
       // Kết thúc mẻ sấy (Passed)
       if (_secondsRemaining > 0) return; // Bảo vệ nếu timer chưa xong
       
       final now = DateTime.now();
       if (_timeEndCtrl.text.isEmpty) {
         _timeEndCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
       }
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✔ Đã hoàn thành mẻ sấy và lưu kết quả!')));
         Navigator.of(context).pop(true);
       }
    }
  }

  Future<void> _prevPhase() async {
    if (_currentPhase == ExecutionPhase.completed || _currentPhase == ExecutionPhase.precheck) {
      return;
    }
    
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

  Future<void> _submit(String resultStatus, String? signature, {bool isInternal = false}) async {
    if (widget.batchId == null || widget.stepId == null) return;
    
    setState(() => _isSaving = true);
    final now = DateTime.now();
    
    // Gói dữ liệu vào 'rawInputs' để màn hình QC đọc được
    final payload = {
      'rawInputs': {
        'ngay': _ngayCtrl.text,
        'nguoiThucHien': _nguoiCtrl.text,
        'checkPhong': _phongSach,
        'checkMay': _maySay,
        'checkDungCu': _dungCuSay,
        'nhietDo': _tempCtrl.text,
        'doAm': _humidCtrl.text,
        'thoiGianCheck': _timeCtrl.text,
        'apLuc': _pressCtrl.text,
        'checkKhongTai': _mayKhongTai,
        'batDauSay': _timeStartCtrl.text,
        'ketThucSay': _timeEndCtrl.text,
        'nhietDoKhiVao': _tempInCtrl.text,
        'nhietDoKhiRa': _tempOutCtrl.text,
        'tgSayCaiDat': _tgSayCaiDatCtrl.text,
        'tocDoGio': _tocDoGioCtrl.text,
        'apSuatTuiLoc': _apSuatTuiLocCtrl.text,
        'tanSoSay': _tanSoSayCtrl.text,
        'slTruocSay': _slTruocCtrl.text,
        'slSauSay': _slSauCtrl.text,
        'mauKiemTra': _mauKiemTra,
        'viTriCuaGio': _cuaGioCtrl.text,
        'doAmDauVao': _inputMoistureCtrl.text,
        'doAmSauSay': _humidAfterCtrl.text,
        'checkTuiLoc': _tuiLoc,
        'checkLapRap': _lapRap,
        'checkRaiNhe': _raiNhe,
        'checkKhoaBang': _khoaBang,
        'checkDayThung': _dayThung,
        'checkDongGoiPE': _dongGoiPE,
        'checkCotChat': _cotChat,
        'checkDanNhan': _danNhan,
        'checkBaoQuanKho': _baoQuanKho,
      },
      'signature': signature,
      'timestamp': now.toIso8601String(),
    };

    final success = await ApiService.submitStepData(
      batchId: widget.batchId!,
      stepId: widget.stepId!,
      resultStatus: resultStatus,
      parametersData: payload,
      notes: isInternal ? null : (signature ?? 'Worker Confirm'),
    );

    setState(() => _isSaving = false);
    
    if (success && mounted) {
      if (resultStatus == 'PendingQC') {
        setState(() => _currentPhase = ExecutionPhase.verification);
      } else if (resultStatus == 'Passed') {
        setState(() => _currentPhase = ExecutionPhase.completed);
        Navigator.pop(context, true);
      }
    }
    
    if (!isInternal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '✔ Cập nhật dữ liệu thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SẤY ${_currentLog['order']?['orderCode'] ?? ''}: ${_currentPhase.label}'),
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
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
        if (widget.stepName.contains('NLC 3')) ...[
          const FormSectionHeader('2.1 KIỂM TRA ĐẦU VÀO NGUYÊN LIỆU'),
          StandardInputField(
            label: 'Độ ẩm NLC 3 (%)', 
            controller: _inputMoistureCtrl,
            keyboardType: TextInputType.number,
            readOnly: _isPhase1Locked,
            hint: 'Tiêu chuẩn: > 5%',
            standardText: _getStandardText('Độ ẩm NLC 3 (Input)'),
          ),
          const Divider(),
        ],
        const FormSectionHeader('1. THÔNG TIN CHUNG'),
        const StandardInputField(label: 'Phòng thực hiện', hint: 'Phòng Pha chế', readOnly: true),
        StandardInputField(label: 'Ngày thực hiện', controller: _ngayCtrl, readOnly: _isPhase1Locked, suffixIcon: const Icon(Icons.calendar_today)),
        StandardInputField(label: 'Người thực hiện', controller: _nguoiCtrl, readOnly: _isPhase1Locked, hint: 'Tên nhân viên', suffixIcon: const Icon(Icons.person)),
        
        const FormSectionHeader('2.2 TÌNH TRẠNG VỆ SINH'),
        SegmentedToggle(label: 'Phòng pha chế', optionA: 'Sạch', optionB: 'Không sạch', disabled: _isPhase1Locked, onChanged: (v) => _phongSach = v),
        SegmentedToggle(label: 'Máy sấy tầng sôi KBC-TS-50', optionA: 'Sạch', optionB: 'Không sạch', disabled: _isPhase1Locked, onChanged: (v) => _maySay = v),
        SegmentedToggle(label: 'Dụng cụ sấy', optionA: 'Sạch', optionB: 'Không sạch', disabled: _isPhase1Locked, onChanged: (v) => _dungCuSay = v),

        const FormSectionHeader('2.3 ĐIỀU KIỆN MÔI TRƯỜNG'),
        StandardInputField(
          label: 'Thời gian kiểm tra', 
          controller: _timeCtrl, 
          hint: 'HH:mm', 
          readOnly: _isPhase1Locked,
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: !_isPhase1Locked ? () => _setCurrentTime(_timeCtrl) : null,
          ),
        ),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'Nhiệt độ (°C)', 
              controller: _tempCtrl, 
              keyboardType: TextInputType.number,
              readOnly: _isPhase1Locked,
              status: _inputStatus['nhietDo'] ?? 'none',
              standardText: 'Chuẩn: 21 - 25 °C',
              onChanged: (v) => _updateInputStatus('nhietDo', v, paramNameInStandard: 'Nhiệt độ phòng'),
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(
              label: 'Độ ẩm (%)', 
              controller: _humidCtrl, 
              keyboardType: TextInputType.number,
              readOnly: _isPhase1Locked,
              status: _inputStatus['doAm'] ?? 'none',
              standardText: 'Chuẩn: 45 - 70 %',
              onChanged: (v) => _updateInputStatus('doAm', v, paramNameInStandard: 'Độ ẩm phòng'),
            )),
          ],
        ),
        StandardInputField(
          label: 'Áp lực phòng (Pa)', 
          controller: _pressCtrl, 
          keyboardType: TextInputType.number,
          readOnly: _isPhase1Locked,
          status: _inputStatus['apLuc'] ?? 'none',
          standardText: 'Chuẩn: >= 10 Pa',
          onChanged: (v) => _updateInputStatus('apLuc', v, paramNameInStandard: 'Áp lực phòng'),
        ),
        
        const FormSectionHeader('3.1 CHUẨN BỊ THIẾT BỊ'),
        CheckboxListTile(
          title: const Text('Kiểm tra tính nguyên vẹn túi lọc (số 4, 5)'),
          subtitle: const Text('Đảm bảo túi sạch và không rách'),
          value: _tuiLoc,
          onChanged: !_isPhase1Locked ? (v) => setState(() => _tuiLoc = v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Lắp ráp máy theo SOP'),
          value: _lapRap,
          onChanged: !_isPhase1Locked ? (v) => setState(() => _lapRap = v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        SegmentedToggle(
          label: 'Kiểm tra tình trạng làm việc không tải', 
          optionA: 'Ổn định', 
          optionB: 'Không ổn định', 
          disabled: _isPhase1Locked,
          onChanged: (v) => _mayKhongTai = v
        ),
        const Divider(),
        const FormSectionHeader('3.2 NẠP LIỆU'),
        CheckboxListTile(
          title: const Text('Rải nhẹ nhàng nguyên liệu vào thùng sấy'),
          subtitle: const Text('Một mẻ sấy tối đa 50 kg'),
          value: _raiNhe,
          onChanged: !_isPhase1Locked ? (v) => setState(() => _raiNhe = v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Khỏa bằng mặt nguyên liệu trong thùng'),
          value: _khoaBang,
          onChanged: !_isPhase1Locked ? (v) => setState(() => _khoaBang = v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Đẩy thùng sấy vào máy, sấy theo SOP'),
          value: _dayThung,
          onChanged: !_isPhase1Locked ? (v) => setState(() => _dayThung = v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        StandardInputField(
          label: 'KL trước sấy (kg)', 
          controller: _slTruocCtrl, 
          keyboardType: TextInputType.number,
          readOnly: _isPhase1Locked,
          hint: 'Nhập khối lượng TD 8 / NLC 3',
        ),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionHeader('PHASE 2: THÔNG SỐ VẬN HÀNH BẮT ĐẦU'),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'Giờ bắt đầu', 
              controller: _timeStartCtrl, 
              suffixIcon: const Icon(Icons.access_time),
              readOnly: true, // Auto-populated and locked
              hint: 'Nhập HH:mm',
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(
              label: 'Nhiệt độ khí vào (°C)', 
              controller: _tempInCtrl, 
              keyboardType: TextInputType.number,
              readOnly: _isPhase2Locked,
              standardText: _getStandardText('Nhiệt độ sấy'),
            )),
          ],
        ),
        const FormSectionHeader('THÔNG SỐ VẬN HÀNH CHI TIẾT'),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'TG sấy cài đặt (phút)', 
              controller: _tgSayCaiDatCtrl, 
              keyboardType: TextInputType.number,
              readOnly: _isPhase2Locked,
              status: _inputStatus['tgSayCaiDat'] ?? 'none',
              standardText: _getStandardText('Thời gian sấy'),
              onChanged: (v) => _updateInputStatus('tgSayCaiDat', v, paramNameInStandard: 'Thời gian sấy'),
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(
              label: 'Vị trí cửa gió', 
              controller: _cuaGioCtrl, 
              readOnly: true,
              standardText: _getStandardText('Vị trí cửa gió'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPhase3() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60),
        Icon(Icons.hourglass_bottom, size: 80, color: Colors.orange),
        SizedBox(height: 24),
        Text(
          'ĐANG ĐỢI QC XÁC NHẬN',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Lô hàng đã được gửi duyệt. Vui lòng chờ QC kiểm tra hồ sơ và ký xác nhận điện tử trước khi bắt đầu sấy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
        SizedBox(height: 40),
        CircularProgressIndicator(color: Colors.orange),
      ],
    );
  }

  Widget _buildPhase4() {
    double progress = (15 - _secondsRemaining) / 15;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_secondsRemaining > 0) ...[
          _buildCenteredStatus(
            Icons.settings_input_component, 
            Colors.blue, 
            'ĐANG TRONG QUÁ TRÌNH SẤY', 
            'Vui lòng chờ máy sấy hoàn thành. Thời gian còn lại: $_secondsRemaining giây'
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 40),
        ] else ...[
          _buildCenteredStatus(
            Icons.check_circle, 
            Colors.green, 
            'CÔNG ĐOẠN SẤY ĐÃ XONG', 
            'Mời nhập kết quả vận hành thực tế và gửi hồ sơ hoàn kỹ.'
          ),
          const Divider(height: 40),
        ],
        
        const FormSectionHeader('KẾT QUẢ VẬN HÀNH THỰC TẾ (CHẾ ĐỘ SẤY)'),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'Giờ kết thúc', 
              controller: _timeEndCtrl, 
              readOnly: _isPhase4Locked || _secondsRemaining > 0, 
              suffixIcon: const Icon(Icons.access_time_filled), 
              hint: 'HH:mm'
            )),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(
              label: 'Nhiệt độ khí ra (°C)', 
              controller: _tempOutCtrl, 
              readOnly: _isPhase4Locked || _secondsRemaining > 0, 
              keyboardType: TextInputType.number
            )),
          ],
        ),
        const Divider(),
        const FormSectionHeader('4.1 KIỂM SOÁT CHẤT LƯỢNG (IN-PROCESS QC)'),
        StandardInputField(
          label: 'Độ ẩm sau sấy (%)', 
          controller: _humidAfterCtrl, 
          keyboardType: TextInputType.number,
          readOnly: _isPhase4Locked || _secondsRemaining > 0,
          status: _inputStatus['doAmSauSay'] ?? 'none',
          standardText: _getStandardText('Độ ẩm thực tế'),
          onChanged: (v) => _updateInputStatus('doAmSauSay', v, paramNameInStandard: 'Độ ẩm'),
        ),
        DryingSampleField(
          onResultChanged: (v) => _mauKiemTra = v, 
          readOnly: _isPhase4Locked || _secondsRemaining > 0
        ),
        const Divider(),
        const FormSectionHeader('4.2 CÂN ĐỐI SẢN LƯỢNG'),
        StandardInputField(
          label: 'Số lượng sau sấy (kg)', 
          controller: _slSauCtrl, 
          keyboardType: TextInputType.number,
          readOnly: _isPhase4Locked || _secondsRemaining > 0,
          hint: 'Cân khối lượng thực tế sau sấy',
        ),
        const SizedBox(height: 20),
        if (_secondsRemaining == 0)
          ElevatedButton.icon(
            onPressed: () => _submit('Passed', 'Operation Completed Successfully'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('XÁC NHẬN HOÀN THÀNH LOG'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
      ],
    );
  }

  Widget _buildPhase5() {
    return Column(
      children: [
        _buildCenteredStatus(Icons.check_circle, Colors.blue, 'ĐÃ HOÀN THÀNH', 'Công đoạn sấy đã kết thúc thành công.'),
        const Divider(height: 40),
        const FormSectionHeader('4.3 ĐÓNG GÓI & BẢO QUẢN'),
        CheckboxListTile(
          title: const Text('Đóng gói túi PE 2 lớp, cột chặt miệng túi'),
          value: _dongGoiPE,
          onChanged: (v) => setState(() => _dongGoiPE = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Dán nhãn công đoạn & nhãn tình trạng'),
          value: _danNhan,
          onChanged: (v) => setState(() => _danNhan = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Bảo quản trong kho cốm'),
          value: _baoQuanKho,
          onChanged: (v) => setState(() => _baoQuanKho = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _submit('Passed', 'Final Packaging Confirmation'),
          icon: const Icon(Icons.save),
          label: const Text('LƯU XÁC NHẬN ĐÓNG GÓI'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        )
      ],
    );
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
