import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Component [MaterialCard] đại diện cho một thẻ nguyên liệu trong danh sách yêu cầu.
/// Có logic tự động kiểm tra (validation): nếu `Thực cân` khớp với `Khối lượng YC`,
/// thẻ sẽ chuyển viền xanh báo hiệu thành công.
class MaterialCard extends StatefulWidget {
  final String materialName;
  final String requiredWeightKg;
  final String initialActualWeight;
  final ValueChanged<String>? onWeightChanged;
  
  const MaterialCard({
    super.key,
    required this.materialName,
    required this.requiredWeightKg,
    this.initialActualWeight = '',
    this.onWeightChanged,
  });

  @override
  State<MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<MaterialCard> {
  late TextEditingController _controller;
  late TextEditingController _phieuKNController;
  bool _isMatched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialActualWeight);
    _phieuKNController = TextEditingController();
    _checkMatch(widget.initialActualWeight);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _phieuKNController.dispose();
    super.dispose();
  }

  void _checkMatch(String value) {
    // tryParse cố gắng dịch chuỗi String sang số thập phân (double).
    // Nếu giá trị đầu vào rỗng hoặc là chữ cái, hàm trả về null thay vì tung ra Exception (gây sập ứng dụng).
    final act = double.tryParse(value);
    final req = double.tryParse(widget.requiredWeightKg);
    
    // setState() báo hiệu cho Flutter framework biết rằng trạng thái (State) đã thay đổi
    // và cần vẽ lại (re-build) các Widget bị ảnh hưởng trên màn hình theo dữ liệu mới.
    setState(() {
      // _isMatched chỉ bằng True khi cả act và req đều hợp lệ (khác null) VÀ giá trị bằng nhau tuyệt đối
      _isMatched = (act != null && req != null && act == req);
    });
    
    // Nếu Widget mẹ có truyền hàm callback thông qua property onWeightChanged
    if (widget.onWeightChanged != null) {
      widget.onWeightChanged!(value); // Thực thi và đẩy tham số chuỗi giá trị ngược lên cây Widget
    }
  }

  @override
  Widget build(BuildContext context) {
    // Card tạo khối chữ nhật nổi bật với hiệu ứng đổ bóng tĩnh chuẩn Material Design
    return Card(
      margin: const EdgeInsets.only(bottom: 16), // Tạo rãnh lề rỗng 16px cách li với các thẻ MaterialCard kế phía dưới
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Xác định viền thẻ Bo tròn 4 góc 12px
        // BorderSide đóng vai trò là cây cọ vẽ đường viền bao quanh Card
        // Nếu cân nặng khớp hoàn toàn (_isMatched = true), viền chuyển màu Xanh lá (Success) với độ trong suốt 0.5. Ngược lại viền vô hình (transparent).
        side: BorderSide(
          color: _isMatched ? AppTheme.success.withValues(alpha: 0.5) : Colors.transparent,
          width: 2, // Bề dày của đường nét vẽ viền lên tới 2 pixels khi nó phát sáng
        ),
      ),
      // Padding ôm trọn nội dung bên trong, bắt chúng cách đều vỏ lưng Card 16px mọi bề
      child: Padding(
        padding: const EdgeInsets.all(16),
        // Column tổ chức các widget con xếp lớp theo chiều dọc
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Neo toàn bộ con nằm sát mí bên trái
          children: [
            // Row này chia bố cục ngang chứa Tên nguyên liệu và Dấu Tích Xanh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Phân phối các con xa nhau hết mức đẩy chúng trôi dạt ra 2 lề ngang
              children: [
                // Expanded nhường toàn bộ diện tích không bị chiếm chỗ cho nhãn Tên Nguyên liệU (Chấm dứt lỗi tràn dòng)
                Expanded(
                  child: Text(
                    widget.materialName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor, // Kế thừa màu xanh Teal quy định trong AppTheme
                    ),
                  ),
                ),
                // Cú pháp if-collection nội tuyến của Dart: Chỉ vẽ dòng Icon khi logic _isMatched trả True
                if (_isMatched)
                  const Icon(Icons.check_circle, color: AppTheme.success),
              ],
            ),
            const Divider(height: 24), // Thanh kẻ ngang đường phân cách dầy 24px lót trước khi vào Form
            // Row này tạo không gian 2 cột để chứa Ô Nhập khối lượng Yêu Cầu (Bên trái) và Thực Cân (Bên Phải)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Neo đỉnh Row, tránh lệch chữ nếu bên kia lấn dòng cao
              children: [
                // Cột bên Trái (sử dụng Flex = 1 để đảm bảo 2 mặt cân đối đối xứng ngang)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số phiếu KN:',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _phieuKNController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập số',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Khối lượng YC (kg):',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.requiredWeightKg,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thực cân (kg):',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _checkMatch,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _isMatched ? AppTheme.success : Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _isMatched ? AppTheme.success : Colors.grey.shade300,
                              width: _isMatched ? 2 : 1,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isMatched ? AppTheme.success : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
