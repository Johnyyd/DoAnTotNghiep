import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../components/material_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/execution_phase.dart';

/// Màn hình [WeighingStepScreen] hiển thị giao diện cho công đoạn cân nguyên liệu.
class WeighingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;
  final int? orderId;
  final bool isPrecheck;
  final bool isViewer;
  final List<dynamic>? initialBom;

  const WeighingStepScreen({
    super.key,
    this.batchId,
    this.stepId,
    this.orderId,
    this.isPrecheck = false,
    this.isViewer = false,
    this.initialBom,
  });

  @override
  State<WeighingStepScreen> createState() => _WeighingStepScreenState();
}

class _WeighingStepScreenState extends State<WeighingStepScreen> {
  final _tempCtrl = TextEditingController();
  final _humidCtrl = TextEditingController();
  final _pressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _hieuChuanCanCtrl = TextEditingController();
  
  // Dynamic BMR Logic
  final _lotWeightACtrl = TextEditingController();
  final _purityCCtrl = TextEditingController();
  double? _targetYieldQ;
  final Map<String, double> _dynamicTargets = {};
  bool _isCalculated = false;

  String _canIW2 = 'Tốt';
  String _canPMA = 'Tốt';
  String _dungCuCan = 'Sạch';

  final Map<String, Map<String, String>> _materialsData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _bom = [];

  // GMP EBR Additions
  final Map<String, String> _inputStatus = {};
  List<dynamic> _standardParams = [];
  Map<String, dynamic> _currentLog = {};
  ExecutionPhase _currentPhase = ExecutionPhase.precheck;
  Timer? _pollTimer; 

  @override
  void initState() {
    super.initState();
    if (widget.batchId != null) {
      _loadDataFromDB().then((_) {
        if (_currentPhase == ExecutionPhase.verification) {
          _startPolling();
        }
      });
    } else {
      setState(() {
        _bom = widget.initialBom ?? [];
        _isLoading = false;
      });
    }
  }

  String? _getStandardText(String paramName) {
    if (_standardParams.isEmpty) {
      return null;
    }
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
    final batch = await ApiService.getBatchById(widget.batchId!);
    List<dynamic> newBom = batch?['order']?['recipe']?['recipeBoms'] ?? widget.initialBom ?? [];
    
    if (widget.stepId != null) {
      try {
        final logs = await ApiService.getProcessLogs(widget.batchId!);
        final log = logs.firstWhere((l) => l['stepId'] == widget.stepId, orElse: () => <String, dynamic>{});
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
            _tempCtrl.text = params['temperature'] ?? '';
            _humidCtrl.text = params['humidity'] ?? '';
            _pressCtrl.text = params['pressure'] ?? '';
            if (params['canIW2'] != null) _canIW2 = params['canIW2'];
            if (params['canPMA'] != null) _canPMA = params['canPMA'];
            if (params['dungCuCan'] != null) _dungCuCan = params['dungCuCan'];
            _hieuChuanCanCtrl.text = params['hieuChuanCan'] ?? '';
            
            if (params['materials'] != null) {
              final Map<dynamic, dynamic> parsedMats = params['materials'];
              parsedMats.forEach((k, v) {
                if (k is String && v is Map) {
                  _materialsData[k] = Map<String, String>.from(v);
                }
              });
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _bom = newBom;
        _isLoading = false;
        
        if (_currentLog.isNotEmpty) {
          final rawStatus = _currentLog['resultStatus']?.toString().replaceAll(' ', '').toUpperCase() ?? '';
          final rawParams = _currentLog['parametersData'];
          
          if (rawStatus == 'PENDINGQC' || rawStatus == 'PENDING_QC') {
            _currentPhase = ExecutionPhase.verification;
          } else if (rawStatus == 'APPROVED' || rawStatus == 'PASSED') {
            _currentPhase = ExecutionPhase.execution;
          } else if (rawStatus == 'RUNNING' || rawParams != null) {
            _currentPhase = ExecutionPhase.input;
          } else {
            _currentPhase = ExecutionPhase.precheck;
          }

          if (_currentPhase == ExecutionPhase.verification) {
            _startPolling();
          } else {
            _stopPolling();
          }
        }
      });
      _updateAllInputStatuses();
    }
  }

  void _startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadDataFromDB());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tempCtrl.dispose();
    _humidCtrl.dispose();
    _pressCtrl.dispose();
    _noteCtrl.dispose();
    _hieuChuanCanCtrl.dispose();
    _lotWeightACtrl.dispose();
    _purityCCtrl.dispose();
    super.dispose();
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
    _updateInputStatus('temperature', _tempCtrl.text, paramNameInStandard: 'Nhiệt độ phòng');
    _updateInputStatus('humidity', _humidCtrl.text, paramNameInStandard: 'Độ ẩm phòng');
    _updateInputStatus('pressure', _pressCtrl.text, paramNameInStandard: 'Áp lực phòng');
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
      notes: status == 'Failed' ? 'QC Rejected Weighing' : 'Approved via Mobile',
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      if (status == 'Approved' && widget.orderId != null) {
        await ApiService.updateOrderStatus(widget.orderId!, 'In-Process');
      }
      if (!mounted) return;
      setState(() {
        _currentPhase = (status == 'Approved') ? ExecutionPhase.execution : _currentPhase;
      });
      if (status != 'Approved') Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✔ QC đã xác nhận: $status')));
    }
  }

  void _updateMaterial(String name, String field, String value) {
    if (!_materialsData.containsKey(name)) _materialsData[name] = {};
    _materialsData[name]![field] = value;
  }

  void _calculateDynamicBOM() {
    double? A = double.tryParse(_lotWeightACtrl.text);
    double? C = double.tryParse(_purityCCtrl.text);

    if (A == null || C == null || C < 0.4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Dữ liệu đầu vào không hợp lệ (C yêu cầu >= 0.4%)')));
      return;
    }

    setState(() {
      double X = (A * C) / 100;
      double Y = (A * 1.250) / (X * 1000);
      double Q = A / Y;

      _targetYieldQ = Q;
      _isCalculated = true;
      _dynamicTargets.clear();

      _dynamicTargets['MAT-NLC3'] = A; 
      _dynamicTargets['MAT-TD1'] = (0.00162 * Q);
      _dynamicTargets['MAT-TD3'] = (0.02970 * Q);
      _dynamicTargets['MAT-TD4'] = (0.00405 * Q);
      _dynamicTargets['MAT-TD5'] = (0.00405 * Q);
      
      double yMg = Y * 1000;
      double fixedTDsMg = 1.62 + 29.70 + 4.05 + 4.05;
      double td8Mg = 540 - yMg - fixedTDsMg;
      _dynamicTargets['MAT-TD8'] = (td8Mg * Q) / 1000;
      _dynamicTargets['MAT-NLP6'] = Q; 
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✔ Đã tính toán: ${Q.toStringAsFixed(0)} viên.')));
    });
  }

  Future<void> _verifyAndSubmit() async {
    bool hasDeviation = false;
    String deviationMsg = '';

    for (var item in _bom) {
      final name = item['material']?['materialName'] ?? 'N/A';
      final code = item['material']?['materialCode'] ?? '';
      double requiredQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      if (_isCalculated && _dynamicTargets.containsKey(code)) requiredQty = _dynamicTargets[code]!;
      
      final actualStr = _materialsData[name]?['actual'] ?? '0';
      final actualQty = double.tryParse(actualStr) ?? 0.0;
      
      if (requiredQty > 0) {
        final double diffPercent = ((actualQty - requiredQty).abs() / requiredQty) * 100;
        if (diffPercent > 2.0) {
          hasDeviation = true;
          deviationMsg += '- $name: Y/c ${requiredQty.toStringAsFixed(2)}, Cân $actualQty (Lệch ${diffPercent.toStringAsFixed(1)}%)\n';
        }
      }
    }

    if (hasDeviation) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('CẢNH BÁO SAI SỐ BMR (>2%)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('Phát hiện sai số khối lượng vượt quá giới hạn BMR:\n\n$deviationMsg\nBạn có chắc chắn muốn tiếp tục?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy & Cân lại')),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cứ tiếp tục', style: TextStyle(color: Colors.white))
            ),
          ],
        )
      );
      if (proceed != true) return;
    }

    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return;
    if (pin != '123456') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mã PIN không đúng!')));
      return;
    }

    await _submit(hasDeviation ? 'Failed' : 'PendingQC', hasDeviation ? deviationMsg : null);
  }

  Future<String?> _showPinDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('XÁC NHẬN CHỮ KÝ ĐIỆN TỬ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Mã PIN cá nhân (123456)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Ký tên')),
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
    String newStatus = 'Running';
    final targetPhase = ExecutionPhase.values[_currentPhase.index - 1];
    if (targetPhase == ExecutionPhase.verification) newStatus = 'PendingQC';
    else if (targetPhase == ExecutionPhase.execution) newStatus = 'Approved';
    
    setState(() => _currentPhase = targetPhase);
    await _submit(newStatus, null, isInternal: true);
  }

  Future<void> _submit(String resultStatus, String? devNotes, {bool isInternal = false}) async {
    setState(() => _isSaving = true);
    final params = {
      "temperature": _tempCtrl.text,
      "humidity": _humidCtrl.text,
      "pressure": _pressCtrl.text,
      "canIW2": _canIW2,
      "canPMA": _canPMA,
      "dungCuCan": _dungCuCan,
      "hieuChuanCan": _hieuChuanCanCtrl.text,
      "materials": _materialsData,
      "dynamicYield": _targetYieldQ,
      "isCalculated": _isCalculated
    };
    
    final finalNotes = devNotes != null ? 'DEVIATION:\n$devNotes\nNote: ${_noteCtrl.text}' : _noteCtrl.text;
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
    
    if (success && mounted) {
      if (resultStatus == 'PendingQC') setState(() => _currentPhase = ExecutionPhase.verification);
      else if (resultStatus == 'Passed') {
        setState(() => _currentPhase = ExecutionPhase.completed);
        Navigator.pop(context, true);
      }
    }
    if (!isInternal && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? '✔ Thành công!' : '❌ Thất bại!')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('CÂN: ${_currentPhase.label}'),
        actions: [
          IconButton(
            onPressed: () {
               debugPrint("--- MANUAL REFRESH ---");
               _loadDataFromDB();
            }, 
            icon: const Icon(Icons.refresh)
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tự động cập nhật mỗi 5 giây khi chờ QC.'))
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _currentPhase.indexNumber / 5.0),
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
    if (widget.isViewer && _currentPhase != ExecutionPhase.verification) {
      return null;
    }
    if (_currentPhase == ExecutionPhase.verification) {
      if (AuthService.currentUser?['role'] == 'QA_QC') {
        return FloatingActionButton.extended(onPressed: () => _approveByQC('Approved'), label: const Text('XÁC NHẬN QC'), icon: const Icon(Icons.verified_user), backgroundColor: Colors.green);
      }
      return FloatingActionButton.extended(onPressed: _isSaving ? null : _prevPhase, label: const Text('QUAY LẠI SỬA'), icon: const Icon(Icons.arrow_back), backgroundColor: Colors.grey);
    }
    if (_currentPhase == ExecutionPhase.completed) {
      return null;
    }
    String label = 'TIẾP TỤC';
    if (_currentPhase == ExecutionPhase.input) {
      label = 'GỬI DUYỆT QC';
    }
    if (_currentPhase == ExecutionPhase.execution) {
      label = 'KẾT THÚC';
    }
    return FloatingActionButton.extended(onPressed: _isSaving ? null : _nextPhase, label: Text(label), icon: const Icon(Icons.arrow_forward));
  }

  Widget _buildPhase1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FormSectionHeader('PHASE 1: KIỂM TRA MÔI TRƯỜNG & THIẾT BỊ'),
        Row(
          children: [
            Expanded(child: StandardInputField(
              label: 'Nhiệt độ (°C)', 
              controller: _tempCtrl, 
              status: _inputStatus['temperature'] ?? 'none',
              standardText: _getStandardText('Nhiệt độ phòng'),
              keyboardType: TextInputType.number, 
              onChanged: (v) => _updateInputStatus('temperature', v, paramNameInStandard: 'Nhiệt độ phòng'),
            )),
            const SizedBox(width: 16), 
            Expanded(child: StandardInputField(
              label: 'Độ ẩm (%)', 
              controller: _humidCtrl, 
              status: _inputStatus['humidity'] ?? 'none',
              standardText: _getStandardText('Độ ẩm phòng'),
              keyboardType: TextInputType.number, 
              onChanged: (v) => _updateInputStatus('humidity', v, paramNameInStandard: 'Độ ẩm phòng'),
            )),
          ],
        ),
        StandardInputField(
          label: 'Áp lực (Pa)', 
          controller: _pressCtrl, 
          status: _inputStatus['pressure'] ?? 'none',
          standardText: _getStandardText('Áp lực phòng'),
          keyboardType: TextInputType.number,
          onChanged: (v) => _updateInputStatus('pressure', v, paramNameInStandard: 'Áp lực phòng'),
        ),
        StandardInputField(label: 'Mã hiệu chuẩn cân (MT/QC)', controller: _hieuChuanCanCtrl, hint: 'MT-XXXX'),
        SegmentedToggle(label: 'Cân IW2-60', optionA: 'Tốt', optionB: 'Không ổn định', onChanged: (v) => _canIW2 = v),
        SegmentedToggle(label: 'Cân PMA-5000', optionA: 'Tốt', optionB: 'Không ổn định', onChanged: (v) => _canPMA = v),
        SegmentedToggle(label: 'Dụng cụ cân', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCuCan = v),
    ]);
  }

  Widget _buildPhase2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FormSectionHeader('PHASE 2: NHẬP LIỆU KHỐI LƯỢNG THỰC TẾ'),
        ExpansionTile(
          title: const Text('TÍNH TOÁN ĐỊNH MỨC ĐỘNG (BMR SECTION 4)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          subtitle: Text(_isCalculated ? 'Sản lượng: ${_targetYieldQ?.toStringAsFixed(0)} viên' : 'Nhập thông số lô NLC 3 để điều chỉnh'),
          childrenPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.indigo.shade50,
          children: [
            StandardInputField(label: 'Khối lượng lô NLC 3 (A - gam)', controller: _lotWeightACtrl, keyboardType: TextInputType.number),
            StandardInputField(label: 'Hàm lượng Alkaloid (C - %)', controller: _purityCCtrl, keyboardType: TextInputType.number),
            ElevatedButton.icon(onPressed: _calculateDynamicBOM, icon: const Icon(Icons.calculate), label: const Text('TÍNH ĐỊNH MỨC')),
          ],
        ),
        const SizedBox(height: 16),
        ..._bom.map((item) {
          final name = item['material']?['materialName'] ?? 'N/A';
          final code = item['material']?['materialCode'] ?? '';
          double target = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          if (_isCalculated && _dynamicTargets.containsKey(code)) target = _dynamicTargets[code]!;
          return MaterialCard(
            materialName: '$name ($code)', requiredWeightKg: target.toStringAsFixed(2), initialActualWeight: _materialsData[name]?['actual'] ?? '', initialPhieuKN: _materialsData[name]?['phieuKN'] ?? '',
            onWeightChanged: (v) => _updateMaterial(name, 'actual', v), onPhieuKNChanged: (v) => _updateMaterial(name, 'phieuKN', v)
          );
        }),
        const FormSectionHeader('GHI CHÚ'),
        TextField(controller: _noteCtrl, maxLines: 2),
    ]);
  }

  Widget _buildPhase3() => const Center(child: Column(children: [SizedBox(height: 40), Icon(Icons.hourglass_empty, size: 80, color: Colors.orange), SizedBox(height: 24), Text('ĐANG ĐỢI QC XÁC NHẬN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange))]));
  Widget _buildPhase4() => const Column(children: [SizedBox(height: 20), Icon(Icons.play_circle_fill, size: 80, color: Colors.green), SizedBox(height: 20), Text('GIAI ĐOẠN THỰC THI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);
  Widget _buildPhase5() => const Center(child: Column(children: [SizedBox(height: 40), Icon(Icons.check_circle, size: 80, color: Colors.blue), SizedBox(height: 20), Text('HOÀN THÀNH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]));
}
