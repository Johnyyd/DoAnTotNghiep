import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/gmp_step_mixin.dart';
import '../models/execution_phase.dart';
import '../components/step_form_inputs.dart';

/// [DynamicStepScreen] — Màn hình công đoạn "thông minh" tự động hiển thị form theo tham số từ DB.
/// Thích hợp cho các loại thuốc mới/phức tạp mà không cần tạo file code màn hình riêng.
class DynamicStepScreen extends StatefulWidget {
  final int batchId;
  final int stepId;
  final int? orderId;
  final String? stepName;
  final bool isViewer;

  const DynamicStepScreen({
    super.key,
    required this.batchId,
    required this.stepId,
    this.orderId,
    this.stepName,
    this.isViewer = false,
  });

  @override
  State<DynamicStepScreen> createState() => _DynamicStepScreenState();
}

class _DynamicStepScreenState extends State<DynamicStepScreen>
    with GmpStepMixin<DynamicStepScreen> {
  ExecutionPhase _currentPhase = ExecutionPhase.precheck;
  Map<String, dynamic>? _stepData;
  List<dynamic> _parameters = [];
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    if (!widget.isViewer) {
      startPolling(_fetchData);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    final workflow = await ApiService.getProcessLogs(widget.batchId);
    final log = workflow.firstWhere((l) => l['stepId'] == widget.stepId, orElse: () => {});

    if (log.isNotEmpty) {
      final String rawStatus = normalizeStatus(log['resultStatus']);
      final pList = log['routing']?['stepParameters'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _stepData = log;
          _parameters = pList;
          _isLoading = false;

          // Cập nhật Phase dựa trên status
          if (rawStatus == 'PENDINGQC' || rawStatus == 'PENDING_QC') {
            _currentPhase = ExecutionPhase.verification;
          } else if (rawStatus == 'APPROVED' || rawStatus == 'PASSED') {
            _currentPhase = ExecutionPhase.execution;
          } else if (rawStatus == 'RUNNING') {
            _currentPhase = ExecutionPhase.input;
          } else {
            _currentPhase = ExecutionPhase.precheck;
          }

          // Real-time time updates for dynamic parameters
          if (!widget.isViewer) {
            final List<TextEditingController> timeCtrls = [];
            for (var p in _parameters) {
              final String name = (p['parameterName'] ?? '').toString().toLowerCase();
              final pid = p['parameterId'] as int;
              if (name.contains('thời gian') || name.contains('time')) {
                if (!_controllers.containsKey(pid)) {
                  _controllers[pid] = TextEditingController();
                }
                timeCtrls.add(_controllers[pid]!);
              }
            }
            if (timeCtrls.isNotEmpty) {
              startTimeUpdates(timeCtrls);
            }
          }
        });
      }
    }
  }

  Future<bool> _submitPhase(String status) async {
    final Map<String, dynamic> dataMap = {};
    for (var p in _parameters) {
      final pid = p['parameterId'];
      final ctrl = _controllers[pid];
      if (ctrl != null) {
        dataMap[p['parameterName']] = ctrl.text;
      }
    }

    setState(() => isSaving = true);
    final success = await ApiService.submitStepData(
      batchId: widget.batchId,
      stepId: widget.stepId,
      resultStatus: status,
      parametersData: dataMap,
    );
    setState(() => isSaving = false);

    if (success) {
      _fetchData();
    }
    return success;
  }

  void _nextPhase() {
    if (_currentPhase == ExecutionPhase.precheck) {
      _submitPhase('Running');
    } else if (_currentPhase == ExecutionPhase.input) {
      _submitPhase('PendingQC');
    } else if (_currentPhase == ExecutionPhase.execution) {
      _finishStep();
    }
  }

  Future<void> _finishStep() async {
    final pin = await showPinDialog();
    if (pin == null) return;

    setState(() => isSaving = true);
    final ok = await _submitPhase('Passed');
    if (ok) {
        // Success logic handled by _fetchData
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.stepName ?? 'CÔNG ĐOẠN ĐỘNG', style: const TextStyle(fontSize: 16)),
            Text('Giai đoạn: ${_currentPhase.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _currentPhase.indexNumber / 5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildForm(),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isViewer ? null : _buildFab(),
    );
  }

  Widget _buildForm() {
    if (_currentPhase == ExecutionPhase.verification) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Đang đợi QC xét duyệt chữ ký điện tử...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Bước: ${widget.stepName}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('THÔNG TIN CHUNG'),
        const SizedBox(height: 16),
        _readOnlyField('Ngày thực hiện', '17/04/2026'),
        _readOnlyField('Người thực hiện', AuthService.currentUser?['username'] ?? 'Công nhân'),
        
        const SizedBox(height: 24),
        _sectionHeader('THÔNG SỐ KỸ THUẬT'),
        const SizedBox(height: 16),
        ..._parameters.map((p) => _buildParameterInput(p)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 1));
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildParameterInput(Map<String, dynamic> p) {
    final pid = p['parameterId'] as int;
    final name = p['parameterName'] as String;
    final unit = p['unit'] as String? ?? '';
    final min = p['minValue'];
    final max = p['maxValue'];

    if (!_controllers.containsKey(pid)) {
      _controllers[pid] = TextEditingController();
    }

    final isReadOnly = widget.isViewer || _currentPhase != ExecutionPhase.input;
    final fieldKey = 'dynamic_$pid';

    return StandardInputField(
      label: name,
      controller: _controllers[pid],
      readOnly: isReadOnly,
      keyboardType: TextInputType.number,
      hint: 'Nhập giá trị...',
      suffixIcon: unit.isNotEmpty ? Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(unit, style: const TextStyle(color: Colors.grey)),
      ) : null,
      standardText: 'Tiêu chuẩn: ${min ?? 'N/A'} - ${max ?? 'N/A'} $unit',
      status: inputStatuses[fieldKey] ?? 'none',
      onChanged: (v) => validateInput(fieldKey, v, _parameters, matchName: name),
    );
  }

  Widget? _buildFab() {
    if (_currentPhase == ExecutionPhase.verification || _currentPhase == ExecutionPhase.completed) {
      return null;
    }

    String label = 'TIẾP TỤC';
    if (_currentPhase == ExecutionPhase.input) label = 'GỬI DUYỆT QC';
    if (_currentPhase == ExecutionPhase.execution) label = 'HOÀN THÀNH';

    return FloatingActionButton.extended(
      onPressed: isSaving ? null : _nextPhase,
      label: Text(label),
      icon: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.arrow_forward),
    );
  }
}
