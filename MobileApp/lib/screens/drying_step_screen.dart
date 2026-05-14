import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/execution_phase.dart';
import '../utils/gmp_step_mixin.dart';

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

class _DryingStepScreenState extends State<DryingStepScreen>
    with GmpStepMixin<DryingStepScreen> {
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
  final _tgSayCaiDatCtrl = TextEditingController(text: '180');
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
  // Map lưu trữ trạng thái hiển thị được kế thừa từ GmpStepMixin

  List<dynamic> _standardParams = [];
  List<dynamic> _bom = [];
  Map<String, dynamic> _currentLog = {};
  Map<String, dynamic>? _batchInfo;
  ExecutionPhase _currentPhase = ExecutionPhase.precheck;

  String _phongSach = 'Sạch';
  String _maySay = 'Sạch';
  String _dungCuSay = 'Sạch';
  String _mayKhongTai = 'Ổn định';
  String _mauKiemTra = '0';

  Timer? _timer;
  int _secondsRemaining = 20;

  @override
  void dispose() {
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
      _ngayCtrl.text =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      _timeCtrl.text =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      _nguoiCtrl.text = AuthService.currentUser?['fullName'] ?? '';
    }

    if (widget.batchId != null) {
      _loadDataFromDB().then((_) {
        // Tự động cập nhật thời gian real-time nếu đang ở phase cần thiết
        if (!widget.isViewer) {
          final List<TextEditingController> toUpdate = [];
          if (!_isPhase1Locked) toUpdate.add(_timeCtrl);
          if (!_isPhase2Locked) toUpdate.add(_timeStartCtrl);

          if (toUpdate.isNotEmpty) {
            startTimeUpdates(toUpdate);
            // Lắng nghe thay đổi giờ bắt đầu để tính giờ kết thúc
            _timeStartCtrl.addListener(_autoCalcTimeEnd);
          }
        }

        if (_currentPhase == ExecutionPhase.verification) {
          startPolling(_loadDataFromDB);
        }
      });
    }
  }

  String _normalize(String s) {
    return s.replaceAll(RegExp(r'[\s\-]'), '').toLowerCase();
  }

  String _getRequiredDryingInfo() {
    if (_bom.isEmpty) return 'Chưa có dữ liệu nguyên liệu';
    final unit = _batchInfo?['order']?['unit'] ?? 'kg';
    List<String> items = [];
    final stepNameNorm = _normalize(widget.stepName);

    for (var item in _bom) {
      final mat = item['material'] ?? {};
      final name = mat['materialName']?.toString() ?? '';
      final code = mat['materialCode']?.toString() ?? '';

      bool isMatch = false;
      if (name.isNotEmpty && stepNameNorm.contains(_normalize(name))) {
        isMatch = true;
      }
      if (code.isNotEmpty && stepNameNorm.contains(_normalize(code))) {
        isMatch = true;
      }

      if (isMatch) {
        final qtyStr = item['quantity']?.toString() ?? '0';
        final qty = double.tryParse(qtyStr.replaceAll(',', '.')) ?? 0;
        if (qty > 0) {
          final displayName = name.isNotEmpty ? name : code;
          if (qty > 50) {
            int numSubBatches = (qty / 50).ceil();
            double qtyPerSubBatch = qty / numSubBatches;
            items.add(
                '$displayName: $qtyStr (Chia $numSubBatches mẻ sấy, ~${qtyPerSubBatch.toStringAsFixed(2)} $unit/mẻ)');
          } else {
            items.add('$displayName: $qtyStr');
          }
        }
      }
    }

    if (items.isEmpty) return 'Tham chiếu BOM để biết khối lượng cần sấy';
    return 'Cần sấy: ${items.join(' + ')}';
  }

  Future<void> _loadDataFromDB() async {
    try {
      final batch = await ApiService.getBatchById(widget.batchId!);
      if (batch != null && mounted) {
        setState(() {
          _batchInfo = batch;
          _bom = batch['order']?['recipe']?['recipeBoms'] ?? [];
        });
      }

      final logs = await ApiService.getProcessLogs(widget.batchId!);
      debugPrint(
          "DEBUG: [Drying] widget.stepId=${widget.stepId} (${widget.stepId.runtimeType})");

      final log = logs.firstWhere(
        (l) {
          final sid = l['stepId'];
          return sid.toString() == widget.stepId.toString();
        },
        orElse: () {
          debugPrint(
              "DEBUG: [Drying] StepId ${widget.stepId} NOT FOUND in logs list!");
          if (logs.isNotEmpty) {
            debugPrint(
                "DEBUG: [Drying] Available IDs: ${logs.map((l) => l['stepId']).toList()}");
          }
          return <String, dynamic>{};
        },
      );

      if (log.isNotEmpty) {
        _currentLog = log;

        // Try multiple nested paths for parameters (backward compatibility/robustness)
        final routing = log['routing'] ?? log['step'] ?? {};
        _standardParams = routing['stepParameters'] ?? [];

        // Inject root-level routing standards for UI consistency
        if (routing['standardTemperature'] != null) {
          _standardParams.add({
            'parameterName': 'Nhiệt độ phòng',
            'unit': '°C',
            'minValue': null,
            'maxValue': null,
            'standardValue': routing['standardTemperature']
          });
        }
        if (routing['standardHumidity'] != null) {
          _standardParams.add({
            'parameterName': 'Độ ẩm phòng',
            'unit': '%',
            'minValue': null,
            'maxValue': null,
            'standardValue': routing['standardHumidity']
          });
        }
        if (routing['standardPressure'] != null) {
          _standardParams.add({
            'parameterName': 'Áp lực phòng',
            'unit': 'Pa',
            'minValue': null,
            'maxValue': null,
            'standardValue': routing['standardPressure']
          });
        }

        debugPrint(
            "DEBUG: [Drying] _standardParams count: ${_standardParams.length}");
        final rawParams = _currentLog['parametersData'];

        Map<String, dynamic> params = {};
        if (rawParams is Map<String, dynamic>) {
          params = rawParams;
        } else if (rawParams is String && rawParams.isNotEmpty) {
          try {
            params = Map<String, dynamic>.from(jsonDecode(rawParams) ?? {});
          } catch (_) {}
        }

        // Bổ sung drilling vào rawInputs nếu có (do logic _submit đóng gói vào đây)
        if (params['rawInputs'] != null && params['rawInputs'] is Map) {
          params = Map<String, dynamic>.from(params['rawInputs']);
        }

        if (mounted) {
          setState(() {
            // Chỉ ghi đè nếu trong DB có dữ liệu, nếu không giữ giá trị mặc định đã init ở initState
            if (params['ngay'] != null &&
                params['ngay'].toString().isNotEmpty) {
              _ngayCtrl.text = params['ngay'];
            }
            if (params['nguoiThucHien'] != null &&
                params['nguoiThucHien'].toString().isNotEmpty) {
              _nguoiCtrl.text = params['nguoiThucHien'];
            }

            if (params['veSinhPhong'] != null) {
              _phongSach = params['veSinhPhong'];
            }
            if (params['veSinhMay'] != null) _maySay = params['veSinhMay'];
            if (params['veSinhDungCu'] != null) {
              _dungCuSay = params['veSinhDungCu'];
            }
            _tempCtrl.text = params['nhietDo'] ?? '';
            _humidCtrl.text = params['doAm'] ?? '';
            _timeCtrl.text = params['thoiGianKiemTra'] ?? '';
            _pressCtrl.text = params['apLuc'] ?? '';
            if (params['mayKhongTai'] != null) {
              _mayKhongTai = params['mayKhongTai'];
            }
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
            final rawStatus = normalizeStatus(_currentLog['resultStatus']);

            if (rawStatus == 'PENDINGQC' || rawStatus == 'PENDING_QC') {
              _currentPhase = ExecutionPhase.verification;
            } else if (rawStatus == 'PASSED') {
              // Đã sấy xong toàn bộ -> Chuyển sang giai đoạn Đóng gói (Phase 5)
              _currentPhase = ExecutionPhase.completed;
              _secondsRemaining = 0;
              _timer?.cancel();
            } else if (rawStatus == 'APPROVED') {
              // APPROVED -> Chuyển qua giai đoạn EXECUTION (Sấy) và bắt đầu bộ đếm ngược 20s
              _currentPhase = ExecutionPhase.execution;
              if (_secondsRemaining == 20 && _timer == null) {
                Future.delayed(
                    const Duration(milliseconds: 500), () => _startTimer());
              }
            } else if (rawStatus == 'RUNNING' || rawStatus == 'PENDING') {
              _currentPhase = ExecutionPhase.input;
            } else {
              // Mặc định cho status NONE, null hoặc bất kỳ gì khác -> Kiểm tra ban đầu
              _currentPhase = ExecutionPhase.precheck;
            }
          });

          // QUẢN LÝ AUTO-POLLING KHI ĐANG ĐỢI QC
          if (_currentPhase == ExecutionPhase.verification) {
            startPolling(_loadDataFromDB);
          } else {
            stopPolling();
          }

          _updateAllInputStatuses();
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  bool get _isPhase1Locked =>
      _currentPhase.index > ExecutionPhase.precheck.index || widget.isViewer;
  bool get _isMoistureMet =>
      widget.stepName.contains('NLC 3') &&
      (double.tryParse(_inputMoistureCtrl.text.replaceAll(',', '.')) ?? 0) > 0 &&
      (double.tryParse(_inputMoistureCtrl.text.replaceAll(',', '.')) ?? 0) <= 5.0;

  bool get _isPhase2Locked =>
      _currentPhase.index > ExecutionPhase.input.index || widget.isViewer;
  bool get _isPhase4Locked =>
      widget.isViewer ||
      (_currentPhase.index > 3) ||
      (_currentPhase == ExecutionPhase.execution && _secondsRemaining > 0);

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 20;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (mounted && !widget.isViewer) {
          setState(() {
            _autoCalcTimeEnd();
          });
          // Lưu trạng thái Running và giờ kết thúc dự kiến nhưng không chốt Log
          _submit('Running', null, isInternal: true);
        }
      }
    });
  }

  void _setCurrentTime(TextEditingController ctrl) {
    if (widget.isViewer) return;
    final now = DateTime.now();
    setState(() {
      ctrl.text =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (ctrl == _timeStartCtrl) {
        _autoCalcTimeEnd();
      }
    });
  }

  void _autoCalcTimeEnd() {
    if (_timeStartCtrl.text.isNotEmpty && _tgSayCaiDatCtrl.text.isNotEmpty) {
      try {
        final parts = _timeStartCtrl.text.split(':');
        if (parts.length == 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final minutesToAdd = int.tryParse(_tgSayCaiDatCtrl.text) ?? 180;
          final now = DateTime.now();
          final timeStart = DateTime(now.year, now.month, now.day, h, m);
          final timeEnd = timeStart.add(Duration(minutes: minutesToAdd));
          _timeEndCtrl.text =
              "${timeEnd.hour.toString().padLeft(2, '0')}:${timeEnd.minute.toString().padLeft(2, '0')}";
        }
      } catch (_) {}
    }
  }

  void _updateAllInputStatuses() {
    validateInput('nhietDo', _tempCtrl.text, _standardParams,
        matchName: 'Nhiệt độ phòng');
    validateInput('doAm', _humidCtrl.text, _standardParams,
        matchName: 'Độ ẩm phòng');
    validateInput('apLuc', _pressCtrl.text, _standardParams,
        matchName: 'Áp lực phòng');
    validateInput('nhietDoKhiVao', _tempInCtrl.text, _standardParams,
        matchName: 'Nhiệt độ sấy');
    validateInput('tgSayCaiDat', _tgSayCaiDatCtrl.text, _standardParams,
        matchName: 'Thời gian sấy');
    validateInput('doAmSauSay', _humidAfterCtrl.text, _standardParams,
        matchName: 'Độ ẩm');
    validateInput('tocDoGio', _tocDoGioCtrl.text, _standardParams,
        matchName: 'Tốc độ gió');
    validateInput('apSuatTuiLoc', _apSuatTuiLocCtrl.text, _standardParams,
        matchName: 'Áp suất túi lọc');

    // Ràng buộc kiểm tra Khối lượng trước và sau sấy
    _validateWeightStatus();
  }

  void _validateWeightStatus() {
    final truocStr = _slTruocCtrl.text;
    final sauStr = _slSauCtrl.text;

    if (truocStr.isEmpty) {
      if (mounted) setState(() => inputStatuses['slTruocSay'] = 'none');
    } else {
      final val = double.tryParse(truocStr.replaceAll(',', '.')) ?? 0;
      bool isValid = val > 0;

      if (mounted) {
        setState(
            () => inputStatuses['slTruocSay'] = isValid ? 'valid' : 'invalid');
      }
    }

    if (sauStr.isEmpty) {
      if (mounted) setState(() => inputStatuses['slSauSay'] = 'none');
    } else {
      final truocVal = double.tryParse(truocStr.replaceAll(',', '.')) ?? 0;
      final sauVal = double.tryParse(sauStr.replaceAll(',', '.')) ?? 0;
      if (sauVal <= 0) {
        if (mounted) setState(() => inputStatuses['slSauSay'] = 'invalid');
      } else if (truocVal > 0) {
        if (sauVal > truocVal) {
          if (mounted) setState(() => inputStatuses['slSauSay'] = 'invalid');
        } else {
          // Tính hao hụt (%)
          final lossPercent = ((truocVal - sauVal) / truocVal) * 100;
          if (lossPercent > 9.0) {
            if (mounted) setState(() => inputStatuses['slSauSay'] = 'warning');
          } else {
            if (mounted) setState(() => inputStatuses['slSauSay'] = 'valid');
          }
        }
      } else {
        if (mounted) setState(() => inputStatuses['slSauSay'] = 'valid');
      }
    }
  }

  bool _isFormValid() {
    if (_currentPhase == ExecutionPhase.precheck && _isMoistureMet) {
      return _inputMoistureCtrl.text.isNotEmpty && _slTruocCtrl.text.isNotEmpty;
    }

    // Check individual status for invalid/error globally
    if (inputStatuses.values.contains('invalid') ||
        inputStatuses.values.contains('error')) return false;

    // Check mandatory fields based on current phase
    if (_currentPhase == ExecutionPhase.precheck) {
      // Trường hợp bình thường: Phải nhập đầy đủ toàn bộ thông số
      if (_tempCtrl.text.isEmpty ||
          _humidCtrl.text.isEmpty ||
          _pressCtrl.text.isEmpty) return false;
      if (_slTruocCtrl.text.isEmpty) return false;
      if (widget.stepName.contains('NLC 3') && _inputMoistureCtrl.text.isEmpty)
        return false;

      // Bổ sung các ràng buộc vệ sinh và máy móc để đảm bảo "đầy đủ"
      if (!_lapRap || !_raiNhe || !_khoaBang || !_dayThung) return false;
      if (!_phongSach.contains('Sạch') ||
          !_maySay.contains('Sạch') ||
          !_dungCuSay.contains('Sạch')) return false;
    } else if (_currentPhase == ExecutionPhase.input) {
      if (_tempInCtrl.text.isEmpty || _tgSayCaiDatCtrl.text.isEmpty)
        return false;
    } else if (_currentPhase == ExecutionPhase.execution) {
      if (_tempOutCtrl.text.isEmpty ||
          _slSauCtrl.text.isEmpty ||
          _humidAfterCtrl.text.isEmpty) return false;
    }

    return true;
  }

  Future<void> _approveByQC(String status) async {
    final pin = await showPinDialog();
    if (pin == null) return;

    if (mounted) {
      setState(() => isSaving = true);
    }
    final verifierId = AuthService.currentUser?['userId'] ?? 0;

    final success = await ApiService.verifyStepData(
      logId: _currentLog['logId'],
      verifierId: verifierId,
      status: status,
      notes: status == 'Failed' ? 'QC Rejected' : 'Approved via Mobile',
    );

    if (mounted) {
      setState(() => isSaving = false);
      if (success) {
        // Nếu duyệt trực tiếp trên máy công nhân, cũng cần update trạng thái Lệnh
        if (status == 'Approved' && widget.orderId != null) {
          await ApiService.updateOrderStatus(widget.orderId!, 'In-Process');
        }

        if (mounted) {
          setState(() {
            if (status == 'Approved') {
              // Kiểm tra nếu là trường hợp bỏ qua sấy (NLC 3 và độ ẩm <= 5%)
              if (_isMoistureMet) {
                _currentPhase = ExecutionPhase.completed;
                // Gửi bản chốt Passed lên server
                _submit('Passed', 'QC xác nhận đạt chuẩn, bỏ qua sấy.');
              } else {
                _currentPhase = ExecutionPhase.execution;
                _startTimer();
              }
            }
          });
          if (status != 'Approved') {
            Navigator.pop(context, true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✔ QC đã xác nhận: $status')));
        }
      }
    }
  }

  Future<void> _verifyAndSubmit() async {
    final slTruoc = double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 0;
    final slSau = double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0;
    if (slSau >= slTruoc && slSau > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                '❌ Lỗi: Khối lượng sau sấy phải nhỏ hơn khối lượng trước sấy!')));
      }
      return;
    }

    final pin = await showPinDialog();
    if (pin == null) return;

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

  Future<void> _nextPhase() async {
    // Ưu tiên kiểm tra logic Skip nếu độ ẩm NLC 3 đạt chuẩn (<= 5%)
    if (_currentPhase == ExecutionPhase.precheck && _isMoistureMet) {
      final shouldSkip = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('ĐỘ ẨM ĐẠT CHUẨN (SKIP)',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                content: Text(
                    'Độ ẩm NLC 3 hiện tại là ${_inputMoistureCtrl.text}%, đạt tiêu chuẩn (<= 5%). Bạn có muốn BỎ QUA công đoạn sấy này không?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('KHÔNG, VẪN SẤY')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('BỎ QUA & GỬI DUYỆT QC')),
                ],
              ));

      if (shouldSkip == true) {
        await _submit('PendingQC',
            'Yêu cầu bỏ qua sấy do độ ẩm đạt chuẩn (${_inputMoistureCtrl.text}%)');
        if (mounted) {
          setState(() => _currentPhase = ExecutionPhase.verification);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✔ Đã gửi yêu cầu bỏ qua sấy lên QC duyệt.')));
        }
        return;
      }
    }

    // Standard GMP validation for all other cases
    if (inputStatuses.values.contains('error')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              '❌ Vui lòng điều chỉnh các thông số đang báo đỏ (ngoài khoảng cho phép) trước khi tiếp tục!'),
          backgroundColor: Colors.red));
      return;
    }

    if (_currentPhase == ExecutionPhase.precheck) {
      final now = DateTime.now();
      if (_timeStartCtrl.text.isEmpty) {
        _timeStartCtrl.text =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        _autoCalcTimeEnd();
      }
      setState(() => _currentPhase = ExecutionPhase.input);
      // Giữ status Running khi nhập liệu
      await _submit('Running', null, isInternal: true);
    } else if (_currentPhase == ExecutionPhase.input) {
      // Chuyển sang giai đoạn Đợi QC (PendingQC)
      await _verifyAndSubmit();
    } else if (_currentPhase == ExecutionPhase.execution) {
      // Kết thúc mẻ sấy (Passed) - Chốt dữ liệu thủ công
      if (_secondsRemaining > 0) return; // Bảo vệ nếu timer chưa xong

      setState(() => isSaving = true);
      // Gửi bản chốt cuối cùng lên server
      bool ok = await _submit('Passed', null);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✔ Đã hoàn thành mẻ sấy và lưu kết quả!')));
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _prevPhase() async {
    if (_currentPhase == ExecutionPhase.completed ||
        _currentPhase == ExecutionPhase.precheck) {
      return;
    }

    // Logic lùi trạng thái dựa trên phase mới
    String newStatus = 'Running';
    final targetPhase = ExecutionPhase.values[_currentPhase.index - 1];

    if (targetPhase == ExecutionPhase.verification) {
      newStatus = 'PendingQC';
    } else if (targetPhase == ExecutionPhase.execution) {
      newStatus = 'Approved';
    } else if (targetPhase == ExecutionPhase.input ||
        targetPhase == ExecutionPhase.precheck) {
      newStatus = 'Running';
    }

    setState(() {
      _currentPhase = targetPhase;
    });

    // Cập nhật trạng thái lên server để đồng bộ và khóa/mở khóa dữ liệu
    await _submit(newStatus, null, isInternal: true);
  }

  Future<bool> _submit(String resultStatus, String? signature,
      {bool isInternal = false}) async {
    if (widget.batchId == null || widget.stepId == null) return false;

    setState(() => isSaving = true);
    final now = DateTime.now();

    // Ràng buộc kiểm tra Khối lượng trước và sau sấy
    if (resultStatus == 'Passed' && _currentPhase == ExecutionPhase.execution) {
      final truocVal = double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 0;
      final sauVal = double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0;

      if (truocVal <= 0 || sauVal <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('⚠ Vui lòng nhập đầy đủ Khối lượng trước và sau sấy!')));
        }
        setState(() => isSaving = false);
        return false;
      }

      if (sauVal > truocVal) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  '⚠ Khối lượng sau sấy không thể lớn hơn khối lượng trước sấy!')));
        }
        setState(() => isSaving = false);
        return false;
      }

      // Kiểm tra hao hụt 9%
      final lossPercent = ((truocVal - sauVal) / truocVal) * 100;
      if (lossPercent > 9.0) {
        final proceed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('CẢNH BÁO HAO HỤT (>9%)',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  content: Text(
                      'Phát hiện hao hụt sau sấy là ${lossPercent.toStringAsFixed(2)}%, vượt quá giới hạn SOP (9%).\nBạn có chắc chắn muốn tiếp tục?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Hủy & Kiểm tra lại')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Tiếp tục',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ));
        if (proceed != true) {
          setState(() => isSaving = false);
          return false;
        }
      }
    }

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
        'netWeight': (double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0) -
            ((double.tryParse(_mauKiemTra.replaceAll(',', '.')) ?? 0) / 1000.0),
        'yieldLoss': _slTruocCtrl.text.isNotEmpty
            ? (((double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 0) -
                    (double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0)) /
                (double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 1) *
                100)
            : 0,
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

    setState(() => isSaving = false);

    if (success && mounted) {
      if (resultStatus == 'PendingQC') {
        setState(() => _currentPhase = ExecutionPhase.verification);
      } else if (resultStatus == 'Passed') {
        if (widget.orderId != null) {
          await ApiService.updateOrderStatus(widget.orderId!, 'Pending Worker');
        }
        setState(() => _currentPhase = ExecutionPhase.completed);
        Navigator.pop(context, true);
      }
    }

    if (!isInternal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '✔ Cập nhật dữ liệu thành công!'
              : '❌ Lỗi khi lưu dữ liệu!')));
    }

    if (success && mounted && !isInternal) {
      // Chỉ tải lại dữ liệu từ DB khi không phải là lưu nội bộ (giúp tránh nhảy Phase khi bấm Quay lại/Tiếp tục)
      await _loadDataFromDB();
    }
    return success;
  }

  void _resetOperationalData() {
    setState(() {
      _timeStartCtrl.clear();
      _timeEndCtrl.clear();
      _tempOutCtrl.clear();
      _tempInCtrl.clear();
      _humidAfterCtrl.clear();
      _slSauCtrl.clear();
      _secondsRemaining = 20;
      _timer?.cancel();
      _timer = null;
      _currentPhase = ExecutionPhase.precheck;
    });
  }

  Future<void> _handleRetryDrying(double currentHumid, double maxHumid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('CHỈ TIÊU KHÔNG ĐẠT'),
          ],
        ),
        content: Text(
            'Độ ẩm hiện tại là $currentHumid%, vượt ngưỡng cho phép (<= $maxHumid%).\n\nHệ thống yêu cầu bạn thực hiện SẤY LẠI mẻ này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KIỂM TRA LẠI SỐ LIỆU'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('BẮT ĐẦU SẤY LẠI'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Gửi kết quả thất bại lên server để lưu Audit Trail
      await _submit(
          'Failed', 'Humidity out of range ($currentHumid%). Rework required.');

      // 2. Làm sạch dữ liệu và quay lại Phase 1 để bắt đầu lượt sấy mới (Attempt X)
      _resetOperationalData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('♻ Đã chuẩn bị sẵn sàng cho lượt sấy tiếp theo.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SẤY - ${_currentPhase.label}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
                'Công đoạn: ${widget.stepName} | Mẻ: ${_batchInfo?['batchNumber'] ?? "---"} | Lệnh: ${_batchInfo?['order']?['orderCode'] ?? "---"}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
            Text(
                'Thuốc: ${_batchInfo?['order']?['recipe']?['material']?['materialName'] ?? "---"}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
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
                if (_currentPhase == ExecutionPhase.verification)
                  _buildPhase3(),
                if (_currentPhase == ExecutionPhase.execution) _buildPhase4(),
                if (_currentPhase == ExecutionPhase.completed) _buildPhase5(),
                const SizedBox(height: 150),
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
          Text('Bước ${_currentPhase.indexNumber}/5',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          Text(_currentPhase.label.toUpperCase(),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget? _buildContextualFAB() {
    if (widget.isViewer && _currentPhase != ExecutionPhase.verification) {
      return null;
    }

    if (_currentPhase == ExecutionPhase.verification) {
      if (AuthService.currentUser?['role'] == 'QA_QC') {
        return FloatingActionButton.extended(
          heroTag: 'btnApprove',
          onPressed: () => _approveByQC('Approved'),
          label: const Text('QC KÝ XÁC NHẬN'),
          icon: const Icon(Icons.verified_user),
          backgroundColor: Colors.green,
        );
      }
      // Khách (Worker) đang đợi QC: Cho phép quay lại Phase 2 để sửa
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton.extended(
          heroTag: 'btnBackWait',
          onPressed: isSaving ? null : _prevPhase,
          label: const Text('QUAY LẠI SỬA'),
          icon: const Icon(Icons.arrow_back),
          backgroundColor: Colors.grey.shade700,
        ),
      );
    }

    if (_currentPhase == ExecutionPhase.completed) return null;

    if (_currentPhase == ExecutionPhase.execution) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPhase != ExecutionPhase.precheck &&
              _currentPhase != ExecutionPhase.completed)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FloatingActionButton.extended(
                heroTag: 'btnBack',
                onPressed: isSaving ? null : _prevPhase,
                label: const Text('QUAY LẠI'),
                icon: const Icon(Icons.arrow_back),
                backgroundColor: Colors.grey.shade700,
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'btnNext',
            onPressed: (isSaving || !_isFormValid()) ? null : _nextPhase,
            label: Text(_currentPhase == ExecutionPhase.input
                ? 'GỬI DUYỆT QC'
                : 'TIẾP TỤC'),
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.arrow_forward),
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
          const FormSectionHeader('PHẦN 1: KIỂM TRA GIÁ TRỊ ĐẦU VÀO'),
          StandardInputField(
            label: 'Độ ẩm NLC 3 (%)',
            controller: _inputMoistureCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
            ],
            readOnly: _isPhase1Locked,
            hint: 'Tiêu chuẩn: > 5%',
            standardText:
                getStandardText('Độ ẩm NLC 3 (Input)', _standardParams),
          ),
          const Divider(),
        ],
        const FormSectionHeader('1. THÔNG TIN CHUNG'),
        const StandardInputField(
            label: 'Phòng thực hiện', hint: 'Phòng Pha chế', readOnly: true),
        StandardInputField(
            label: 'Ngày thực hiện',
            controller: _ngayCtrl,
            readOnly: _isPhase1Locked,
            suffixIcon: const Icon(Icons.calendar_today)),
        StandardInputField(
            label: 'Người thực hiện',
            controller: _nguoiCtrl,
            readOnly: _isPhase1Locked,
            hint: 'Tên nhân viên',
            suffixIcon: const Icon(Icons.person)),
        const FormSectionHeader('2.2 TÌNH TRẠNG VỆ SINH'),
        SegmentedToggle(
            label: 'Phòng pha chế',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            value: _phongSach,
            disabled: _isPhase1Locked || _isMoistureMet,
            onChanged: (v) => setState(() => _phongSach = v)),
        SegmentedToggle(
            label: 'Máy sấy tầng sôi KBC-TS-50',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            value: _maySay,
            disabled: _isPhase1Locked || _isMoistureMet,
            onChanged: (v) => setState(() => _maySay = v)),
        SegmentedToggle(
            label: 'Dụng cụ sấy',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            value: _dungCuSay,
            disabled: _isPhase1Locked || _isMoistureMet,
            onChanged: (v) => setState(() => _dungCuSay = v)),
        const FormSectionHeader('2.3 ĐIỀU KIỆN MÔI TRƯỜNG'),
        StandardInputField(
          label: 'Thời gian kiểm tra',
          controller: _timeCtrl,
          hint: 'HH:mm',
          readOnly: _isPhase1Locked || _isMoistureMet,
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: !(_isPhase1Locked || _isMoistureMet)
                ? () => _setCurrentTime(_timeCtrl)
                : null,
          ),
        ),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
              label: 'Nhiệt độ (°C)',
              controller: _tempCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
              ],
              readOnly: _isPhase1Locked || _isMoistureMet,
              status: inputStatuses['nhietDo'] ?? 'none',
              standardText: getStandardText('Nhiệt độ phòng', _standardParams),
              onChanged: (v) => validateInput('nhietDo', v, _standardParams,
                  matchName: 'Nhiệt độ phòng'),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
              label: 'Độ ẩm (%)',
              controller: _humidCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
              ],
              readOnly: _isPhase1Locked || _isMoistureMet,
              status: inputStatuses['doAm'] ?? 'none',
              standardText: getStandardText('Độ ẩm phòng', _standardParams),
              onChanged: (v) => validateInput('doAm', v, _standardParams,
                  matchName: 'Độ ẩm phòng'),
            )),
          ],
        ),
        StandardInputField(
          label: 'Áp lực phòng (Pa)',
          controller: _pressCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
          ],
          readOnly: _isPhase1Locked || _isMoistureMet,
          status: inputStatuses['apLuc'] ?? 'none',
          standardText: getStandardText('Áp lực phòng', _standardParams),
          onChanged: (v) => validateInput('apLuc', v, _standardParams,
              matchName: 'Áp lực phòng'),
        ),
        const FormSectionHeader('3.1 CHUẨN BỊ THIẾT BỊ'),
        CheckboxListTile(
          title: const Text('Kiểm tra tính nguyên vẹn túi lọc (số 4, 5)'),
          subtitle: const Text('Đảm bảo túi sạch và không rách'),
          value: _tuiLoc,
          onChanged: (!_isPhase1Locked && !_isMoistureMet)
              ? (v) => setState(() => _tuiLoc = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Lắp ráp máy theo SOP'),
          value: _lapRap,
          onChanged: (!_isPhase1Locked && !_isMoistureMet)
              ? (v) => setState(() => _lapRap = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        SegmentedToggle(
            label: 'Kiểm tra tình trạng làm việc không tải',
            optionA: 'Ổn định',
            optionB: 'Không ổn định',
            disabled: _isPhase1Locked || _isMoistureMet,
            onChanged: (v) => _mayKhongTai = v),
        const Divider(),
        const FormSectionHeader('3.2 NẠP LIỆU'),
        CheckboxListTile(
          title: const Text('Rải nhẹ nhàng nguyên liệu vào thùng sấy'),
          subtitle: const Text('Một mẻ sấy tối đa 50 kg'),
          value: _raiNhe,
          onChanged: !_isPhase1Locked
              ? (v) => setState(() => _raiNhe = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Khỏa bằng mặt nguyên liệu trong thùng'),
          value: _khoaBang,
          onChanged: !_isPhase1Locked
              ? (v) => setState(() => _khoaBang = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Đẩy thùng sấy vào máy, sấy theo SOP'),
          value: _dayThung,
          onChanged: !_isPhase1Locked
              ? (v) => setState(() => _dayThung = v ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        StandardInputField(
          label:
              'Khối lượng trước sấy (${_batchInfo?['order']?['unit'] ?? 'kg'})',
          controller: _slTruocCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
          ],
          readOnly: _isPhase1Locked,
          hint: 'Nhập khối lượng thực tế',
          status: inputStatuses['slTruocSay'] ?? 'none',
          standardText: _getRequiredDryingInfo(),
          onChanged: (v) => _validateWeightStatus(),
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
            Expanded(
                child: StandardInputField(
              label: 'Giờ bắt đầu',
              controller: _timeStartCtrl,
              suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: widget.isViewer
                      ? null
                      : () => _setCurrentTime(_timeStartCtrl)),
              readOnly: true, // Auto-populated and locked
              hint: 'Nhập HH:mm',
            )),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
              label: 'Nhiệt độ khí vào (°C)',
              controller: _tempInCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
              ],
              readOnly: _isPhase2Locked,
              status: inputStatuses['nhietDoKhiVao'] ?? 'none',
              standardText: getStandardText('Nhiệt độ sấy', _standardParams),
              onChanged: (v) => validateInput(
                  'nhietDoKhiVao', v, _standardParams,
                  matchName: 'Nhiệt độ sấy'),
            )),
          ],
        ),
        const FormSectionHeader('THÔNG SỐ VẬN HÀNH CHI TIẾT'),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
              label: 'TG sấy cài đặt (phút)',
              controller: _tgSayCaiDatCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
              ],
              readOnly: _isPhase2Locked,
              status: inputStatuses['tgSayCaiDat'] ?? 'none',
              standardText: getStandardText('Thời gian sấy', _standardParams),
              onChanged: (v) {
                validateInput('tgSayCaiDat', v, _standardParams,
                    matchName: 'Thời gian sấy');
                _autoCalcTimeEnd();
              },
            )),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
              label: 'Vị trí cửa gió',
              controller: _cuaGioCtrl,
              readOnly: true,
              standardText: getStandardText('Vị trí cửa gió', _standardParams),
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
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
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
    double progress = (20 - _secondsRemaining) / 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_secondsRemaining > 0) ...[
          _buildCenteredStatus(
              Icons.settings_input_component,
              Colors.blue,
              'ĐANG TRONG QUÁ TRÌNH SẤY',
              'Vui lòng chờ máy sấy hoàn thành. Thời gian còn lại: $_secondsRemaining giây'),
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
              'Mời nhập kết quả vận hành thực tế và gửi hồ sơ hoàn kỹ.'),
          const Divider(height: 40),
        ],
        const FormSectionHeader('KẾT QUẢ VẬN HÀNH THỰC TẾ (CHẾ ĐỘ SẤY)'),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
                    label: 'Giờ kết thúc',
                    controller: _timeEndCtrl,
                    readOnly: _isPhase4Locked || _secondsRemaining > 0,
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.access_time_filled),
                        onPressed: (widget.isViewer || _secondsRemaining > 0)
                            ? null
                            : () => _setCurrentTime(_timeEndCtrl)),
                    hint: 'HH:mm')),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
              label: 'Nhiệt độ khí ra (°C)',
              controller: _tempOutCtrl,
              readOnly: _isPhase4Locked || _secondsRemaining > 0,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
              ],
              onChanged: (v) => setState(() {}),
            )),
          ],
        ),
        const Divider(),
        const FormSectionHeader('4.1 KIỂM SOÁT CHẤT LƯỢNG (IN-PROCESS QC)'),
        StandardInputField(
          label: 'Độ ẩm sau sấy (%)',
          controller: _humidAfterCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
          ],
          readOnly: _isPhase4Locked || _secondsRemaining > 0,
          status: inputStatuses['doAmSauSay'] ?? 'none',
          standardText: getStandardText('Độ ẩm sau sấy', _standardParams),
          onChanged: (v) => validateInput('doAmSauSay', v, _standardParams,
              matchName: 'Độ ẩm sau sấy'),
        ),
        DryingSampleField(
            onResultChanged: (v) => _mauKiemTra = v,
            readOnly: _isPhase4Locked || _secondsRemaining > 0),
        const Divider(),
        const FormSectionHeader('4.2 KIỂM TRA SẢN LƯỢNG'),
        StandardInputField(
          label:
              'Khối lượng sau khi sấy (${_batchInfo?['order']?['unit'] ?? 'kg'})',
          controller: _slSauCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
          ],
          readOnly: _isPhase4Locked || _secondsRemaining > 0,
          hint: 'Cân khối lượng thực tế sau sấy',
          status: inputStatuses['slSauSay'] ?? 'none',
          onChanged: (v) => _validateWeightStatus(),
        ),
        if (_slSauCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Khối lượng tịnh (sau trừ mẫu):',
                          style: TextStyle(fontSize: 13)),
                      Text(
                          '${((double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0) - ((double.tryParse(_mauKiemTra.replaceAll(',', '.')) ?? 0) / 1000.0)).toStringAsFixed(3)} kg',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hao hụt sau sấy:',
                          style: TextStyle(fontSize: 13)),
                      Text(
                          '${_slTruocCtrl.text.isNotEmpty ? (((double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 0) - (double.tryParse(_slSauCtrl.text.replaceAll(',', '.')) ?? 0)) / (double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ?? 1) * 100).toStringAsFixed(2) : 0}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _slTruocCtrl.text.isNotEmpty &&
                                      (((double.tryParse(_slTruocCtrl.text.replaceAll(',', '.')) ??
                                                      0) -
                                                  (double.tryParse(
                                                          _slSauCtrl.text.replaceAll(',', '.')) ??
                                                      0)) /
                                              (double.tryParse(
                                                      _slTruocCtrl.text.replaceAll(',', '.')) ??
                                                  1) *
                                              100) >
                                          9.0
                                  ? Colors.red
                                  : Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (_secondsRemaining == 0)
          ElevatedButton.icon(
            onPressed: () async {
              // Kiểm tra độ ẩm trước khi cho phép Hoàn tất
              final humidVal = double.tryParse(_humidAfterCtrl.text.replaceAll(',', '.')) ?? 0;

              // Lấy tiêu chuẩn từ standardParams (nếu có)
              double maxAllowed = 5.0; // Mặc định 5% cho NLC
              try {
                final sp = _standardParams.firstWhere((p) {
                  final name =
                      (p['parameterName'] as String? ?? '').toLowerCase();
                  return name.contains('độ ẩm') && !name.contains('phòng');
                }, orElse: () => null);
                if (sp != null && sp['maxValue'] != null) {
                  maxAllowed = (sp['maxValue'] as num).toDouble();
                }
              } catch (_) {}

              if (humidVal > maxAllowed) {
                await _handleRetryDrying(humidVal, maxAllowed);
              } else {
                final ok =
                    await _submit('Passed', 'Operation Completed Successfully');
                if (ok && mounted) {
                  setState(() => _currentPhase = ExecutionPhase.completed);
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('XÁC NHẬN HOÀN TẤT CÔNG ĐOẠN'),
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
        _buildCenteredStatus(Icons.check_circle, Colors.blue, 'ĐÃ HOÀN TẤT',
            'Công đoạn sấy đã kết thúc thành công.'),
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
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50)),
        )
      ],
    );
  }

  Widget _buildCenteredStatus(
      IconData icon, Color color, String title, String desc) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 20),
          Text(title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
