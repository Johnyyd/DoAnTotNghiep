import 'dart:convert';
import 'package:flutter/material.dart';
import '../components/step_form_inputs.dart';
import '../services/api_service.dart';

/// Màn hình [MixingStepScreen] dành cho công đoạn trộn khô nguyên liệu.
class MixingStepScreen extends StatefulWidget {
  final int? batchId;
  final int? stepId;
  final bool isPrecheck;
  final bool isViewer;

  const MixingStepScreen({
    super.key,
    this.batchId,
    this.stepId,
    this.isPrecheck = false,
    this.isViewer = false,
  });

  @override
  State<MixingStepScreen> createState() => _MixingStepScreenState();
}

class _MixingStepScreenState extends State<MixingStepScreen> {
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

  String _phongSach = 'Sạch';
  String _mayTron = 'Sạch';
  String _dungCu = 'Sạch';
  String _slDongGoi = '0'; 
  
  final Map<String, String> _actualMaterials = {};
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _bom = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.batchId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final batch = await ApiService.getBatchById(widget.batchId!);
    List<dynamic> newBom = batch?['order']?['recipe']?['recipeBoms'] ?? [];
    
    if (widget.isViewer && widget.stepId != null) {
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

          if (params['khoiLuongThucTe'] != null) {
            final Map<dynamic, dynamic> parsedMats = params['khoiLuongThucTe'];
            parsedMats.forEach((k, v) {
              if (k is String && v is String) {
                _actualMaterials[k] = v;
              }
            });
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _bom = newBom;
        _isLoading = false;
      });
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
        final double diffPercent = ((actualQty - requiredQty).abs() / requiredQty) * 100;
        if (diffPercent > 5.0) {
          hasDeviation = true;
          deviationMsg += '- $name: Y/c ${requiredQty}kg, Thực tế ${actualQty}kg (Lệch ${diffPercent.toStringAsFixed(1)}%)\n';
        }
      }
    }

    if (hasDeviation) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('CẢNH BÁO DEVIATION (>5%)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('Phát hiện sai số khối lượng quá mức cho phép:\n\n$deviationMsg\nBạn có chắc chắn muốn tiếp tục và ghi nhận sự cố (Failed)?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy & Sửa đổi')),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xác nhận Lỗi', style: TextStyle(color: Colors.white))
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

    await _submit(hasDeviation ? 'Failed' : 'Passed', hasDeviation ? deviationMsg : null);
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
    };
    
    final finalNotes = devNotes != null 
      ? 'DEVIATION REPORT:\n$devNotes\nGhi chú người dùng: ${_noteCtrl.text}'
      : _noteCtrl.text;

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
    
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✔ Lưu công đoạn trộn thành công!' : '❌ Lỗi khi lưu dữ liệu!'))
    );
  }

  Widget _buildComparisonRow(String key, String label, String expected) {
    String initialValue = _actualMaterials[key] ?? '';
    if (widget.isViewer && initialValue.isEmpty) {
      // Create a temporary controller so that empty doesn't look undefined when parsed
      initialValue = ''; 
    }
    
    // We must rebuild controller once if data is fetched since we are creating it inline,
    // actually StandardInputField accepts external controllers only, so we can just use `initialValue`
    // Wait, StandardInputField uses controller. I will pass the controller logic internally or just use a local controller
    // let's create a temporary controller:
    TextEditingController ctrl = TextEditingController(text: initialValue);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: ReadOnlyField(label: '', value: expected)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(color: Colors.grey))),
          Expanded(child: StandardInputField(
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
      return widget.isPrecheck 
        ? const Center(child: CircularProgressIndicator()) 
        : const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.isPrecheck) 
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('ĐIỀN CHECKLIST KIỂM TRA MÔI TRƯỜNG & THIẾT BỊ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        else
          const Text('CÔNG ĐOẠN TRỘN KHÔ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        
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
        
        const FormSectionHeader('6.1 MÔI TRƯỜNG & THIẾT BỊ'),
        const ReadOnlyField(label: 'Phòng thực hiện', value: 'Trộn khô'),
        SegmentedToggle(label: 'Phòng trộn khô', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _phongSach = v, disabled: widget.isViewer),
        SegmentedToggle(label: 'Máy trộn lập phương AD-LP-200', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _mayTron = v, disabled: widget.isViewer),
        SegmentedToggle(label: 'Dụng cụ sản xuất', optionA: 'Sạch', optionB: 'Không sạch', onChanged: (v) => _dungCu = v, disabled: widget.isViewer),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: StandardInputField(label: 'Nhiệt độ (°C)', controller: _tempCtrl, hint: '23.0', standardText: 'Standard: 21 - 25', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Độ ẩm (%)', controller: _humidCtrl, hint: '60.0', standardText: 'Standard: 45 - 70', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
          ],
        ),
        StandardInputField(label: 'Thời gian kiểm tra', controller: _timeCtrl, hint: '08:00 AM', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer),
        StandardInputField(label: 'Áp lực phòng (Pa)', controller: _pressCtrl, hint: '15', standardText: 'Standard: >= 10', keyboardType: TextInputType.number, readOnly: widget.isViewer),
  
        const FormSectionHeader('6.2 THÔNG SỐ VẬN HÀNH'),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'Từ', controller: _timeStartCtrl, hint: '09:00', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Đến', controller: _timeEndCtrl, hint: '09:15', suffixIcon: const Icon(Icons.access_time), readOnly: widget.isViewer)),
          ],
        ),
        Row(
          children: [
            Expanded(child: StandardInputField(label: 'TG cài đặt (phút)', controller: _tgCaiDatCtrl, hint: '15', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
            const SizedBox(width: 16),
            Expanded(child: StandardInputField(label: 'Tốc độ cài đặt (v/p)', controller: _tocDoCaiDatCtrl, hint: '15', keyboardType: TextInputType.number, readOnly: widget.isViewer)),
          ],
        ),
        StandardInputField(label: 'Thời gian trộn thực tế (phút)', controller: _tgThucTeCtrl, hint: '15', standardText: 'Standard: 15 phút', keyboardType: TextInputType.number, readOnly: widget.isViewer),
        StandardInputField(label: 'Tốc độ quay (vòng/phút)', controller: _tocDoThucTeCtrl, hint: '15', standardText: 'Standard: 15 vòng/phút', keyboardType: TextInputType.number, readOnly: widget.isViewer),

        const FormSectionHeader('6.3 ĐỐI CHIẾU NGUYÊN LIỆU'),
        const Text('Lý thuyết vs Thực sử dụng', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
        const SizedBox(height: 8),
        
        if (_bom.isEmpty)
          const Text('Không có dữ liệu BOM.', style: TextStyle(color: Colors.red))
        else
          ..._bom.map((item) {
              final materialName = item['material']?['materialName'] ?? 'N/A';
              final requiredQty = item['quantity']?.toString() ?? '0.00';
              return _buildComparisonRow(materialName, '$materialName (kg)', requiredQty);
          }),

        const SizedBox(height: 12),
        StandardInputField(label: 'Dư phẩm lô số', controller: _duPhamCtrl, hint: 'Nhập số lô dư phẩm', readOnly: widget.isViewer),

        const FormSectionHeader('6.4 KẾT QUẢ HẠT KHÔ'),
        StandardInputField(label: 'Tỷ trọng gõ', controller: _tyTrongCtrl, hint: '0.8', keyboardType: TextInputType.number, readOnly: widget.isViewer),
        MixingPackagingField(onResultChanged: (v) => _slDongGoi = v, readOnly: widget.isViewer),
        const SizedBox(height: 12),
        const Text('Nhận xét', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          readOnly: widget.isViewer,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú hoặc nhận xét...',
            filled: widget.isViewer,
            fillColor: widget.isViewer ? Colors.grey.shade100 : null,
          ),
        ),
        
        if (!widget.isPrecheck && !widget.isViewer) ...[
          const SizedBox(height: 24),
          _isSaving
            ? const Center(child: CircularProgressIndicator())
            : ESignatureButton(title: 'HOÀN THÀNH CÔNG ĐOẠN TRỘN', onPressed: _verifyAndSubmit),
          const SizedBox(height: 32),
        ]
      ],
    );

    if (widget.isPrecheck) return content;
    
    return Scaffold(
      appBar: AppBar(title: const Text('CÔNG ĐOẠN TRỘN')),
      body: content,
    );
  }
}
