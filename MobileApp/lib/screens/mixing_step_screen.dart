import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/execution_phase.dart';
import '../utils/gmp_step_mixin.dart';

/// Màn hình [MixingStepScreen] dành cho công đoạn trộn khô nguyên liệu.
class MixingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;
  final int? orderId;
  final bool isPrecheck;
  final bool isViewer;
  final List<dynamic>? initialBom;

  const MixingStepScreen({
    super.key,
    this.batchId,
    this.stepId,
    this.orderId,
    this.isPrecheck = false,
    this.isViewer = false,
    this.initialBom,
  });

  @override
  State<MixingStepScreen> createState() => _MixingStepScreenState();
}

class _MixingStepScreenState extends State<MixingStepScreen> with GmpStepMixin<MixingStepScreen> {
  final _tempCtrl = TextEditingController();
  final _humidCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _pressCtrl = TextEditingController();

  final _timeStartCtrl = TextEditingController();
  final _timeEndCtrl = TextEditingController();
  final _tgCaiDatCtrl = TextEditingController();
  final _tocDoCaiDatCtrl = TextEditingController();
  final _tgThucTeCtrl = TextEditingController();
  final _tocDoThucTeCtrl = TextEditingController();

  final _duPhamCtrl = TextEditingController();
  final _tyTrongCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Expanded GMP Parameters
  final _tgGiaiDoan1Ctrl = TextEditingController();
  final _tgGiaiDoan2Ctrl = TextEditingController();
  final _tieuChuanRSDCtrl = TextEditingController();
  final _rsdThucTeCtrl = TextEditingController();

  String _phongSach = 'Sạch';
  String _mayTron = 'Sạch';
  String _dungCu = 'Sạch';
  String _slDongGoi = '0';

  final Map<String, String> _actualMaterials = {};
  bool _isLoading = true;
  List<dynamic> _bom = [];

  // GMP EBR Additions
  final Map<String, String> _inputStatus = {};
  List<dynamic> _standardParams = [];
  Map<String, dynamic> _currentLog = {};
  Map<String, dynamic>? _batchInfo;
  ExecutionPhase _currentPhase = ExecutionPhase.precheck;

  @override
  void initState() {
    super.initState();
    _loadDataFromDB();
  }

  String? _getStandardText(String paramName) {
    if (_standardParams.isEmpty) return null;
    try {
      final sp = _standardParams.firstWhere(
        (p) => (p['parameterName'] as String)
            .toLowerCase()
            .contains(paramName.toLowerCase()),
        orElse: () => null,
      );
      if (sp != null) {
        final min = sp['minValue'];
        final max = sp['maxValue'];
        final unit = sp['unit'] ?? '';
        if (min != null && max != null) {
          if (min == max) {
            return "Chuẩn: ${min.toString().replaceAll('.0', '')} $unit";
          }
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
    if (widget.batchId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Load Batch for BOM
      final batch = await ApiService.getBatchById(widget.batchId!);
      if (batch != null) {
        _batchInfo = batch;
      }
      if (batch != null && batch['order'] != null) {
        _bom = batch['order']?['recipe']?['recipeBoms'] ?? [];
      } else {
        _bom = widget.initialBom ?? [];
      }

      // Load Logs for Phase Sync
      final logs = await ApiService.getProcessLogs(widget.batchId!);
      final log = logs.firstWhere((l) => l['stepId'] == widget.stepId,
          orElse: () => {});

      if (log.isNotEmpty) {
        _currentLog = log;
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

        if (params.isNotEmpty) {
          if (params['veSinhPhong'] != null) _phongSach = params['veSinhPhong'];
          if (params['veSinhMay'] != null) _mayTron = params['veSinhMay'];
          if (params['veSinhDungCu'] != null) _dungCu = params['veSinhDungCu'];
          _tempCtrl.text = params['nhietDo'] ?? '';
          _humidCtrl.text = params['doAm'] ?? '';
          _timeCtrl.text = params['thoiGianKiemTra'] ?? '';
          _pressCtrl.text = params['apLuc'] ?? '';
          _timeStartCtrl.text = params['tgBatDau'] ?? '';
          _timeEndCtrl.text = params['tgKetThuc'] ?? '';
          _tgCaiDatCtrl.text = params['tgCaiDat'] ?? '';
          _tocDoCaiDatCtrl.text = params['tocDoCaiDat'] ?? '';
          _tgThucTeCtrl.text = params['tgThucTe'] ?? '';
          _tocDoThucTeCtrl.text = params['tocDoThucTe'] ?? '';
          _duPhamCtrl.text = params['duPhamLoSo'] ?? '';
          _tyTrongCtrl.text = params['tyTrongGo'] ?? '';
          _slDongGoi = params['slDongGoiKg'] ?? '0';

          _tgGiaiDoan1Ctrl.text = params['tgGiaiDoan1'] ?? '';
          _tgGiaiDoan2Ctrl.text = params['tgGiaiDoan2'] ?? '';
          _tieuChuanRSDCtrl.text = params['tieuChuanRSD'] ?? '';
          _rsdThucTeCtrl.text = params['rsdThucTe'] ?? '';

          if (params['khoiLuongThucTe'] != null) {
            final Map<String, dynamic> parsedMats =
                Map<String, dynamic>.from(params['khoiLuongThucTe']);
            parsedMats.forEach((k, v) {
              _actualMaterials[k] = v.toString();
            });
          }
        }

        // Phase Logic
        final rawStatus = normalizeStatus(log['resultStatus']);
        if (rawStatus == 'PENDINGQC' || rawStatus == 'PENDING_QC') {
          _currentPhase = ExecutionPhase.verification;
          startPolling(_loadDataFromDB);
        } else if (rawStatus == 'APPROVED' || rawStatus == 'PASSED') {
          _currentPhase = ExecutionPhase.execution;
          stopPolling();
        } else if (rawStatus == 'RUNNING') {
          _currentPhase = ExecutionPhase.input;
          stopPolling();
        } else {
          _currentPhase = ExecutionPhase.precheck;
          stopPolling();
        }
      }

      _updateAllInputStatuses();
    } catch (e) {
      debugPrint("Error loading Mixing data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_timeStartCtrl.text.isNotEmpty && _tgCaiDatCtrl.text.isNotEmpty) {
      try {
        final parts = _timeStartCtrl.text.split(':');
        if (parts.length == 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final minutesToAdd = int.tryParse(_tgCaiDatCtrl.text) ?? 0;
          if (minutesToAdd > 0) {
            final timeStart = DateTime(2026, 1, 1, h, m);
            final timeEnd = timeStart.add(Duration(minutes: minutesToAdd));
            _timeEndCtrl.text =
                "${timeEnd.hour.toString().padLeft(2, '0')}:${timeEnd.minute.toString().padLeft(2, '0')}";
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humidCtrl.dispose();
    _timeCtrl.dispose();
    _pressCtrl.dispose();
    _timeStartCtrl.dispose();
    _timeEndCtrl.dispose();
    _tgCaiDatCtrl.dispose();
    _tocDoCaiDatCtrl.dispose();
    _tgThucTeCtrl.dispose();
    _tocDoThucTeCtrl.dispose();
    _duPhamCtrl.dispose();
    _tyTrongCtrl.dispose();
    _noteCtrl.dispose();
    _tgGiaiDoan1Ctrl.dispose();
    _tgGiaiDoan2Ctrl.dispose();
    _tieuChuanRSDCtrl.dispose();
    _rsdThucTeCtrl.dispose();
    super.dispose();
  }

  void _updateInputStatus(String fieldName, String value,
      {String? paramNameInStandard}) {
    if (_standardParams.isEmpty) return;
    final val = double.tryParse(value);
    if (val == null) {
      setState(() => _inputStatus[fieldName] = 'none');
      return;
    }
    final sp = _standardParams.firstWhere(
      (p) => (p['parameterName'] as String)
          .toLowerCase()
          .contains((paramNameInStandard ?? fieldName).toLowerCase()),
      orElse: () => null,
    );
    if (sp != null) {
      final min =
          sp['minValue'] != null ? (sp['minValue'] as num).toDouble() : null;
      final max =
          sp['maxValue'] != null ? (sp['maxValue'] as num).toDouble() : null;
      String status = 'none';
      if (min != null && val < min) status = 'error';
      if (max != null && val > max) status = 'error';
      setState(() => _inputStatus[fieldName] = status);
    }
  }

  void _updateAllInputStatuses() {
    _updateInputStatus('nhietDo', _tempCtrl.text,
        paramNameInStandard: 'Nhiệt độ phòng');
    _updateInputStatus('doAm', _humidCtrl.text,
        paramNameInStandard: 'Độ ẩm phòng');
    _updateInputStatus('apLuc', _pressCtrl.text,
        paramNameInStandard: 'Áp lực phòng');
    _updateInputStatus('tocDoThucTe', _tocDoThucTeCtrl.text,
        paramNameInStandard: 'Tốc độ trộn');
    _updateInputStatus('tgThucTe', _tgThucTeCtrl.text,
        paramNameInStandard: 'Thời gian trộn');
  }

  Future<void> _approveByQC(String status) async {
    final pin = await showPinDialog();
    if (pin == null) return;

    setState(() => isSaving = true);
    final verifierId = AuthService.currentUser?['userId'] ?? 0;

    final success = await ApiService.verifyStepData(
      logId: _currentLog['logId'] ?? _currentLog['id'],
      verifierId: verifierId,
      status: status,
      notes: status == 'Failed' ? 'QC Rejected Mixing' : 'Approved via Mobile',
    );

    if (mounted) {
      setState(() => isSaving = false);
      if (success) {
        if (status == 'Approved' && widget.orderId != null) {
          await ApiService.updateOrderStatus(widget.orderId!, 'In-Process');
        }
        await _loadDataFromDB();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('✔ QC đã xác nhận: $status')));
      }
    }
  }

  void _updateActualMaterial(String name, String value) {
    _actualMaterials[name] = value;
  }

  Future<void> _verifyAndSubmit() async {
    bool hasDeviation = false;
    String deviationMsg = '';

    for (var item in _bom) {
      final name = item['material']?['materialName'] ?? 'N/A';
      final requiredQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final actualStr = _actualMaterials[name] ?? '0';
      final actualQty = double.tryParse(actualStr) ?? 0.0;

      if (requiredQty > 0) {
        final double diffPercent =
            ((actualQty - requiredQty).abs() / requiredQty) * 100;
        if (diffPercent > 5.0) {
          hasDeviation = true;
          deviationMsg +=
              '- $name: Y/c ${requiredQty}kg, Thực tế ${actualQty}kg (Lệch ${diffPercent.toStringAsFixed(1)}%)\n';
        }
      }
    }

    if (hasDeviation) {
      final proceed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text('CẢNH BÁO DEVIATION (>5%)',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                content: Text(
                    'Phát hiện sai số khối lượng quá mức cho phép:\n\n$deviationMsg\nBạn có chắc chắn muốn tiếp tục và ghi nhận sự cố (Failed)?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Hủy & Sửa đổi')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Xác nhận Lỗi',
                          style: TextStyle(color: Colors.white))),
                ],
              ));
      if (proceed != true) return;
    }

    final pin = await showPinDialog();
    if (pin == null) return;

    await _submit(hasDeviation ? 'Failed' : 'PendingQC',
        hasDeviation ? deviationMsg : null);
  }



  Future<void> _nextPhase() async {
    if (_currentPhase == ExecutionPhase.precheck) {
      if (_timeStartCtrl.text.isEmpty) {
        final now = DateTime.now();
        _timeStartCtrl.text =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        _autoCalcTimeEnd();
      }
      await _submit('Running', null, isInternal: true);
    } else if (_currentPhase == ExecutionPhase.input) {
      await _verifyAndSubmit();
    } else if (_currentPhase == ExecutionPhase.execution) {
      await _submit('Passed', null);
    }
  }

  Future<void> _prevPhase() async {
    if (_currentPhase == ExecutionPhase.completed ||
        _currentPhase == ExecutionPhase.precheck) {
      return;
    }

    final targetPhase = ExecutionPhase.values[_currentPhase.index - 1];
    String newStatus = 'Running';
    if (targetPhase == ExecutionPhase.verification) newStatus = 'PendingQC';
    if (targetPhase == ExecutionPhase.execution) newStatus = 'Approved';

    setState(() => _currentPhase = targetPhase);
    await _submit(newStatus, null, isInternal: true);
  }

  Future<bool> _submit(String resultStatus, String? devNotes,
      {bool isInternal = false}) async {
    setState(() => isSaving = true);
    final params = {
      "veSinhPhong": _phongSach,
      "veSinhMay": _mayTron,
      "veSinhDungCu": _dungCu,
      "nhietDo": _tempCtrl.text,
      "doAm": _humidCtrl.text,
      "thoiGianKiemTra": _timeCtrl.text,
      "apLuc": _pressCtrl.text,
      "tgBatDau": _timeStartCtrl.text,
      "tgKetThuc": _timeEndCtrl.text,
      "tgCaiDat": _tgCaiDatCtrl.text,
      "tocDoCaiDat": _tocDoCaiDatCtrl.text,
      "tgThucTe": _tgThucTeCtrl.text,
      "tocDoThucTe": _tocDoThucTeCtrl.text,
      "khoiLuongThucTe": _actualMaterials,
      "duPhamLoSo": _duPhamCtrl.text,
      "tyTrongGo": _tyTrongCtrl.text,
      "slDongGoiKg": _slDongGoi,
      "tgGiaiDoan1": _tgGiaiDoan1Ctrl.text,
      "tgGiaiDoan2": _tgGiaiDoan2Ctrl.text,
      "tieuChuanRSD": _tieuChuanRSDCtrl.text,
      "rsdThucTe": _rsdThucTeCtrl.text,
    };

    final finalNotes = devNotes != null
        ? 'DEVIATION REPORT:\n$devNotes\nGhi chú người dùng: ${_noteCtrl.text}'
        : _noteCtrl.text;

    if (widget.batchId == null || widget.stepId == null) {
      setState(() => isSaving = false);
      return false;
    }

    bool success = await ApiService.submitStepData(
      batchId: widget.batchId!,
      stepId: widget.stepId!,
      resultStatus: resultStatus,
      parametersData: params,
      notes: finalNotes.isNotEmpty ? finalNotes : null,
    );

    if (success) {
      await _loadDataFromDB();
      if (resultStatus == 'Passed') Navigator.pop(context, true);
    }

    if (mounted) setState(() => isSaving = false);

    if (!isInternal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '✔ Cập nhật dữ liệu thành công!'
              : '❌ Lỗi khi lưu dữ liệu!')));
    }
    return success;
  }

  Widget _buildComparisonRow(String key, String label, String expected) {
    String initialValue = _actualMaterials[key] ?? '';
    TextEditingController ctrl = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: ReadOnlyField(label: '', value: expected)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('vs', style: TextStyle(color: Colors.grey))),
          Expanded(
              child: StandardInputField(
            label: '',
            hint: 'Thực tế',
            controller: ctrl,
            readOnly: widget.isViewer,
            onChanged: (v) => _updateActualMaterial(key, v),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRỘN - ${_currentPhase.label}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
                'Công đoạn: TRỘN | Mẻ: ${_batchInfo?['batchNumber'] ?? "---"} | Lệnh: ${_batchInfo?['order']?['orderCode'] ?? "---"}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
            Text(
                'Thuốc: ${_batchInfo?['order']?['recipe']?['material']?['materialName'] ?? "---"}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataFromDB,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _currentPhase.indexNumber / 4.0,
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
          heroTag: 'btnApproveW',
          onPressed: () => _approveByQC('Approved'),
          label: const Text('QC KÝ XÁC NHẬN'),
          icon: const Icon(Icons.verified_user),
          backgroundColor: Colors.green,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton.extended(
          heroTag: 'btnBackWaitM',
          onPressed: isSaving ? null : _prevPhase,
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
          if (_currentPhase != ExecutionPhase.precheck &&
              _currentPhase != ExecutionPhase.completed)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FloatingActionButton.extended(
                heroTag: 'btnBackM',
                onPressed: isSaving ? null : _prevPhase,
                label: const Text('QUAY LẠI'),
                icon: const Icon(Icons.arrow_back),
                backgroundColor: Colors.grey.shade700,
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'btnNextM',
            onPressed: isSaving ? null : _nextPhase,
            label: Text(label),
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(icon),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionHeader('GIAN ĐOẠN 1: KIỂM TRA GIÁ TRỊ ĐẦU VÀO'),
        const StandardInputField(
            label: 'Phòng thực hiện', hint: 'Trộn khô', readOnly: true),
        SegmentedToggle(
            label: 'Phòng trộn khô',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            onChanged: (v) => _phongSach = v),
        SegmentedToggle(
            label: 'Máy trộn lập phương',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            onChanged: (v) => _mayTron = v),
        SegmentedToggle(
            label: 'Dụng cụ sản xuất',
            optionA: 'Sạch',
            optionB: 'Không sạch',
            onChanged: (v) => _dungCu = v),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
              label: 'Nhiệt độ (°C)',
              controller: _tempCtrl,
              status: _inputStatus['nhietDo'] ?? 'none',
              standardText: _getStandardText('Nhiệt độ phòng'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _updateInputStatus('nhietDo', v,
                  paramNameInStandard: 'Nhiệt độ phòng'),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
              label: 'Độ ẩm (%)',
              controller: _humidCtrl,
              status: _inputStatus['doAm'] ?? 'none',
              standardText: _getStandardText('Độ ẩm phòng'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _updateInputStatus('doAm', v,
                  paramNameInStandard: 'Độ ẩm phòng'),
            )),
          ],
        ),
        StandardInputField(
          label: 'Áp lực (Pa)',
          controller: _pressCtrl,
          status: _inputStatus['apLuc'] ?? 'none',
          standardText: _getStandardText('Áp lực phòng'),
          keyboardType: TextInputType.number,
          onChanged: (v) => _updateInputStatus('apLuc', v,
              paramNameInStandard: 'Áp lực phòng'),
        ),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionHeader('PHASE 2: THÔNG SỐ VẬN HÀNH & ĐỐI CHIẾU'),
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
                            : () => _setCurrentTime(_timeStartCtrl)))),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
                    label: 'Giờ kết thúc',
                    controller: _timeEndCtrl,
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: widget.isViewer
                            ? null
                            : () => _setCurrentTime(_timeEndCtrl)))),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
                    label: 'TG thực tế (phút)',
                    controller: _tgThucTeCtrl,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
                    label: 'Tốc độ thực tế (v/p)',
                    controller: _tocDoThucTeCtrl,
                    keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 12),
        const Text('ĐỐI CHIẾU NGUYÊN LIỆU (Lý thuyết vs Thực tế)',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        if (_bom.isEmpty)
          const Text('Không có dữ liệu BOM.')
        else
          ..._bom.map((item) {
            final materialName = item['material']?['materialName'] ?? 'N/A';
            final requiredQty = item['quantity']?.toString() ?? '0.00';
            return _buildComparisonRow(materialName, materialName, requiredQty);
          }),
        const FormSectionHeader('THÔNG SỐ TRỘN CHI TIẾT'),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
                    label: 'TG Gđ 1 (phút)',
                    controller: _tgGiaiDoan1Ctrl,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
                    label: 'TG Gđ 2 (phút)',
                    controller: _tgGiaiDoan2Ctrl,
                    keyboardType: TextInputType.number)),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: StandardInputField(
                    label: 'Tiêu chuẩn RSD (%)',
                    controller: _tieuChuanRSDCtrl,
                    hint: '<5%')),
            const SizedBox(width: 16),
            Expanded(
                child: StandardInputField(
                    label: 'RSD thực tế (%)',
                    controller: _rsdThucTeCtrl,
                    keyboardType: TextInputType.number)),
          ],
        ),
        StandardInputField(label: 'Dư phẩm lô số', controller: _duPhamCtrl),
        StandardInputField(
            label: 'Tỷ trọng gõ',
            controller: _tyTrongCtrl,
            keyboardType: TextInputType.number),
        MixingPackagingField(onResultChanged: (v) => _slDongGoi = v),
        const SizedBox(height: 12),
        TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Ghi chú...', border: OutlineInputBorder())),
      ],
    );
  }

  Widget _buildPhase3() {
    return _buildCenteredStatus(
        Icons.hourglass_empty,
        Colors.orange,
        'ĐANG ĐỢI QC XÁC NHẬN',
        'Dữ liệu đã được khóa. Vui lòng báo QC ký xác nhận.');
  }

  Widget _buildPhase4() {
    return _buildCenteredStatus(
        Icons.play_circle_fill,
        Colors.green,
        'ĐANG THỰC HIỆN TRỘN',
        'Máy đang quay. Nhấn KẾT THÚC sau khi hoàn thành.');
  }

  Widget _buildPhase5() {
    return _buildCenteredStatus(Icons.check_circle, Colors.blue,
        'ĐÃ HOÀN THÀNH', 'Công đoạn trộn đã kết thúc và được lưu trữ.');
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
