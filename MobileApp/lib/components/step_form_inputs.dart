import 'package:flutter/material.dart';

/// Component [FormSectionHeader] hiển thị tiêu đề cho một phần (section) của biểu mẫu.
/// Tiêu đề được viết hoa, in đậm và dùng màu nhận diện thương hiệu.
class FormSectionHeader extends StatelessWidget {
  final String title;

  const FormSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Component [SegmentedToggle] là một Toggle dạng Segmented Button 
/// thay thế cho Checkbox truyền thống, tối ưu cho thao tác chạm trên mobile.
/// Thường dùng cho lựa chọn nhị phân: [Đạt] / [Không đạt], [Sạch] / [Không sạch].
class SegmentedToggle extends StatefulWidget {
  final String label;
  final String optionA;
  final String optionB;
  final ValueChanged<String>? onChanged;

  const SegmentedToggle({
    super.key,
    required this.label,
    required this.optionA,
    required this.optionB,
    this.onChanged,
  });

  @override
  State<SegmentedToggle> createState() => _SegmentedToggleState();
}

class _SegmentedToggleState extends State<SegmentedToggle> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.optionA;
  }

  @override
  Widget build(BuildContext context) {
    // Padding bao bọc ngoài cùng để tạo biên giới đẩy các component form cách nhau ra
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      // Column dùng để xếp các Widget hình trụ xếp dọc chồng lên nhau (Từ trên xuống dưới)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Căn lề về bên trái trục dọc (start của Row)
        children: [
          // Text tạo nhãn định danh cho câu hỏi
          Text(
            widget.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8), // Chặn một khối rỗng cao 8px làm vách ngăn thị giác
          
          // Container làm lớp vỏ chứa cái rãnh xám nhạt đằng sau nút chuyển đổi (Toggle background)
          Container(
            width: double.infinity, // Ra lệnh cho bộ khung này kéo dài hết chiều ngang cho phép
            padding: const EdgeInsets.all(4), // Thụt vào 4px từ viền để chứa "miếng lót" nút bên trong không bị kịch viền
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Đổ màu xám nhạt giả lập độ lõm (Sunken Layout)
              borderRadius: BorderRadius.circular(10), // Bo tròn toàn bộ trục chữ nhật 
            ),
            // Tổ chức các lựa chọn bên trong rãnh thành một hàng ngang (Row)
            child: Row(
              children: [
                // Option A 
                // Expanded buộc widget con chia đôi chiều ngang (vì có 2 Option, mỗi thằng sẽ lấy 50% flex space)
                Expanded(
                  // GestureDetector phủ lên widget con diện tích bắt sự kiện Tap của ngón tay
                  child: GestureDetector(
                    onTap: () {
                      // SetState yêu cầu Flutter Redraw (vẽ lại UI Component này) ngay khi update Data
                      setState(() => _selected = widget.optionA);
                      // Gọi callback function do Cha (Parent component) cung cấp nếu không null
                      if (widget.onChanged != null) widget.onChanged!(widget.optionA);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10), // Độ dày của nút nhấn
                      decoration: BoxDecoration(
                        // Logic đảo màu Nền Nút: Nếu được chọn => Thành màu Trắng tinh. Nếu nhả => Trong suốt tiệp màu rãnh
                        color: _selected == widget.optionA ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8), // Bo góc để mảng màu trắng nằm gọn lọt tròng
                        // Phục hồi hiệu ứng mảng nổi bật bằng chiếc đổ bóng lợt (Drop Shadow) dưới đáy
                        boxShadow: _selected == widget.optionA
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                            : null, // Bỏ đổ bóng nếu ẩn
                      ),
                      alignment: Alignment.center, // Bắt buộc Text nằm chính xác tâm miếng cắt
                      child: Text(
                        widget.optionA,
                        style: TextStyle(
                          fontSize: 13,
                          // Nếu được focus, chữ sẽ Đậm lên (Bold) và Đen hơn (black87)
                          fontWeight: _selected == widget.optionA ? FontWeight.bold : FontWeight.normal,
                          color: _selected == widget.optionA ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                // Option B (Tương tự hệt logic Option A nhưng bind giá trị B)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = widget.optionB);
                      if (widget.onChanged != null) widget.onChanged!(widget.optionB);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selected == widget.optionB ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selected == widget.optionB
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.optionB,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selected == widget.optionB ? FontWeight.bold : FontWeight.normal,
                          color: _selected == widget.optionB ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String? comparisonValue;

  const ReadOnlyField({super.key, required this.label, required this.value, this.comparisonValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
         const SizedBox(height: 4),
         Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
           decoration: BoxDecoration(
             color: Colors.grey.shade200,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.grey.shade300)
           ),
           child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
         ),
      ],
    );
  }
}

/// Component [StandardInputField] hỗ trợ nhập text chuẩn hóa.
/// Nếu truyền vào `keyboardType: TextInputType.number`, nó sẽ tự động gọi
/// bàn phím số (Numeric Keypad) của hệ điều hành di động.
class StandardInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? standardText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const StandardInputField({
    super.key,
    required this.label,
    this.hint,
    this.standardText,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          if (standardText != null) ...[
            const SizedBox(height: 2),
            Text(standardText!, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class ESignatureButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const ESignatureButton({super.key, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.history_edu),
        label: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Component [DryingSampleField] dùng đễ nhập "Lấy mẫu kiểm tra" (g/túi x túi = g)
class DryingSampleField extends StatefulWidget {
  final ValueChanged<String>? onResultChanged;
  const DryingSampleField({super.key, this.onResultChanged});

  @override
  State<DryingSampleField> createState() => _DryingSampleFieldState();
}

class _DryingSampleFieldState extends State<DryingSampleField> {
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _tuiController = TextEditingController();
  String _total = '0';

  void _calculate() {
    final g = double.tryParse(_gController.text) ?? 0;
    final tui = int.tryParse(_tuiController.text) ?? 0;
    setState(() {
      _total = (g * tui).toStringAsFixed(1).replaceAll('.0', '');
    });
    if (widget.onResultChanged != null) {
      widget.onResultChanged!(_total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lấy mẫu kiểm tra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: TextField(controller: _gController, keyboardType: TextInputType.number, onChanged: (_) => _calculate(), decoration: const InputDecoration(hintText: 'g/túi', contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: TextField(controller: _tuiController, keyboardType: TextInputType.number, onChanged: (_) => _calculate(), decoration: const InputDecoration(hintText: 'số túi', contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('=', style: TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Text('$_total g', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Component [MixingPackagingField] dùng đề nhập "Số lượng đóng gói" ((túi x 10kg) + kg lẻ = kg)
class MixingPackagingField extends StatefulWidget {
  final ValueChanged<String>? onResultChanged;
  const MixingPackagingField({super.key, this.onResultChanged});

  @override
  State<MixingPackagingField> createState() => _MixingPackagingFieldState();
}

class _MixingPackagingFieldState extends State<MixingPackagingField> {
  final TextEditingController _tuiController = TextEditingController();
  final TextEditingController _kgLeController = TextEditingController();
  String _total = '0';

  void _calculate() {
    final tui = int.tryParse(_tuiController.text) ?? 0;
    final kgLe = double.tryParse(_kgLeController.text) ?? 0;
    setState(() {
      _total = ((tui * 10) + kgLe).toStringAsFixed(1).replaceAll('.0', '');
    });
    if (widget.onResultChanged != null) {
      widget.onResultChanged!(_total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Số lượng đóng gói', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('(', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
            Expanded(flex: 2, child: TextField(controller: _tuiController, keyboardType: TextInputType.number, onChanged: (_) => _calculate(), decoration: const InputDecoration(hintText: 'số túi', contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x 10kg) +', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(flex: 2, child: TextField(controller: _kgLeController, keyboardType: TextInputType.number, onChanged: (_) => _calculate(), decoration: const InputDecoration(hintText: 'kg lẻ/túi', contentPadding: EdgeInsets.symmetric(horizontal: 8)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('=', style: TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Text('$_total kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
