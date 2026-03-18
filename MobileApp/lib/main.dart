import 'package:flutter/material.dart';

void main() {
  runApp(const GmpMobileApp());
}

class GmpMobileApp extends StatelessWidget {
  const GmpMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eBMR - Nhật ký sản xuất điện tử',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo.shade900,
          primary: Colors.indigo.shade900,
          secondary: Colors.amber.shade800,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isHeaderExpanded = false;
  String _selectedBatch = 'BATCH-NLC3-001';
  String _status = 'ĐANG THỰC HIỆN';

  void _showSignDialog(String stepName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ký xác nhận: $stepName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập Mã định danh kỹ thuật số / PIN để xác nhận nhật ký này.'),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mã PIN', hintText: '****'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY BỎ')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_selectedIndex == 4) _status = 'HOÀN THÀNH';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã ký xác nhận thành công: $stepName')));
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
       DryingOperationScreen(onSign: () => _showSignDialog('Công đoạn Sấy')),
       WeighingOperationScreen(onSign: () => _showSignDialog('Cân nguyên liệu')),
       MixingOperationScreen(onSign: () => _showSignDialog('Công đoạn Trộn')),
       FillingOperationScreen(onSign: () => _showSignDialog('Đóng nang')),
       PackagingOperationScreen(onSign: () => _showSignDialog('Đóng gói')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('eBMR - Nhật ký sản xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade900,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20)),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildStickyHeader(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Sấy'),
          NavigationDestination(icon: Icon(Icons.scale_outlined), label: 'Cân'),
          NavigationDestination(icon: Icon(Icons.cyclone), label: 'Trộn'),
          NavigationDestination(icon: Icon(Icons.input), label: 'Đóng nang'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Đóng gói'),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return GestureDetector(
      onTap: () => setState(() => _isHeaderExpanded = !_isHeaderExpanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Viên nang NLC 3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                      Row(
                        children: [
                          Text('Lô: $_selectedBatch', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(width: 12),
                          _buildStatusBadge(_status),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(_isHeaderExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.indigo),
              ],
            ),
            if (_isHeaderExpanded) ...[
              const Divider(),
              _buildHeaderDetailRow('Cỡ lô:', '100 kg'),
              _buildHeaderDetailRow('Quy cách:', '80 chai/ 40 viên'),
              _buildHeaderDetailRow('Số ĐK:', 'VD-12345-21'),
              _buildHeaderDetailRow('Hạn dùng:', '18/03/2028'),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'HOÀN THÀNH' ? Colors.green : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeaderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// --- 1. CÔNG ĐOẠN SẤY ---
class DryingOperationScreen extends StatefulWidget {
  final VoidCallback onSign;
  const DryingOperationScreen({super.key, required this.onSign});

  @override
  State<DryingOperationScreen> createState() => _DryingOperationScreenState();
}

class _DryingOperationScreenState extends State<DryingOperationScreen> {
  final TextEditingController _gBagController = TextEditingController(text: '10');
  final TextEditingController _bagsController = TextEditingController(text: '5');
  double _totalSample = 50.0;

  void _calculate() {
    double g = double.tryParse(_gBagController.text) ?? 0;
    double b = double.tryParse(_bagsController.text) ?? 0;
    setState(() => _totalSample = g * b);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Thông tin chung'),
        Row(
          children: [
            Expanded(child: _Helper.buildDropdown('Phòng thực hiện:', 'Pha chế')),
            const SizedBox(width: 12),
            Expanded(child: _Helper.buildDatePicker('Ngày thực hiện:', '18/03/2026')),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Kiểm tra điều kiện'),
        _Helper.buildToggleRow('Vệ sinh phòng sạch', true),
        _Helper.buildToggleRow('Máy sấy KBC-TS-50 sạch', true),
        const SizedBox(height: 16),
        const _SectionHeader('Môi trường (Thời điểm kiểm tra)'),
        _Helper.buildInputField('Nhiệt độ phòng (°C)', '23.5', suffix: 'TC: 21-25'),
        _Helper.buildInputField('Độ ẩm phòng (%)', '52', suffix: 'TC: 45-70'),
        const Divider(),
        const Text('Tính toán lấy mẫu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Row(
          children: [
            Expanded(child: _Helper.buildInputField('g/túi', '10', controller: _gBagController, onChanged: (v) => _calculate())),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x')),
            Expanded(child: _Helper.buildInputField('Số túi', '5', controller: _bagsController, onChanged: (v) => _calculate())),
            const SizedBox(width: 12),
            Text('Tổng cộng: ${_totalSample}g', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        _Helper.buildEsignatureButton(widget.onSign),
        const SizedBox(height: 32),
      ],
    );
  }
}

// --- 2. CÂN NGUYÊN LIỆU ---
class WeighingOperationScreen extends StatefulWidget {
  final VoidCallback onSign;
  const WeighingOperationScreen({super.key, required this.onSign});

  @override
  State<WeighingOperationScreen> createState() => _WeighingOperationScreenState();
}

class _WeighingOperationScreenState extends State<WeighingOperationScreen> {
  final Map<String, String> _actuals = {'NLC 3': '50.00', 'TD 1': '10.05', 'TD 3': '0'};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('DANH SÁCH NGUYÊN LIỆU CẦN CÂN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 12),
        _buildMatCard('NLC 3 (Hoạt chất)', 'Phiếu KN: X01', '50.00', _actuals['NLC 3']!),
        _buildMatCard('TD 1 (Tá dược độn)', 'Phiếu KN: B12', '10.00', _actuals['TD 1']!),
        _buildMatCard('TD 3 (Tá dược rã)', 'Phiếu KN: R05', '0.50', _actuals['TD 3']!),
        const SizedBox(height: 24),
        _Helper.buildEsignatureButton(widget.onSign),
      ],
    );
  }

  Widget _buildMatCard(String name, String lot, String req, String act) {
    bool isMatch = double.tryParse(act) == double.tryParse(req) && act != '0';
    bool isPartial = double.tryParse(act) != 0;
    Color color = isMatch ? Colors.green.shade50 : (isPartial ? Colors.red.shade50 : Colors.grey.shade50);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), if (isMatch) const Icon(Icons.check, color: Colors.green)]),
            const Divider(),
            Row(
              children: [
                Expanded(child: _Helper.buildSmallInfo(lot, 'Yêu cầu: $req kg')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _actuals[name.split(' ')[0]] = v),
                    decoration: InputDecoration(fillColor: color, labelText: 'Thực cân', suffixText: 'kg'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- 3. CÔNG ĐOẠN TRỘN ---
class MixingOperationScreen extends StatefulWidget {
  final VoidCallback onSign;
  const MixingOperationScreen({super.key, required this.onSign});

  @override
  State<MixingOperationScreen> createState() => _MixingOperationScreenState();
}

class _MixingOperationScreenState extends State<MixingOperationScreen> {
  final TextEditingController _bags = TextEditingController(text: '5');
  final TextEditingController _kgBag = TextEditingController(text: '15');
  final TextEditingController _loose = TextEditingController(text: '2.5');
  double _yield = 77.5;

  void _calculate() {
    setState(() => _yield = (double.tryParse(_bags.text) ?? 0) * (double.tryParse(_kgBag.text) ?? 0) + (double.tryParse(_loose.text) ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Thông số máy trộn (AD-LP-200)'),
        _Helper.buildInputField('Số vòng/phút thực tế', '15', suffix: 'TC: 15'),
        _Helper.buildInputField('Thời gian trộn (phút)', '30', suffix: 'TC: 30'),
        const SizedBox(height: 16),
        const _SectionHeader('Tính toán hiệu suất thành phẩm'),
        Row(
          children: [
            Expanded(child: _Helper.buildInputField('Số bao', '5', controller: _bags, onChanged: (v) => _calculate())),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x')),
            Expanded(child: _Helper.buildInputField('kg/bao', '15', controller: _kgBag, onChanged: (v) => _calculate())),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('+')),
            Expanded(child: _Helper.buildInputField('Số lẻ', '2.5', controller: _loose, onChanged: (v) => _calculate())),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('TỔNG KHỐI LƯỢNG:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('${_yield} kg', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))],
          ),
        ),
        const SizedBox(height: 24),
        _Helper.buildEsignatureButton(widget.onSign),
      ],
    );
  }
}

// --- 4. CÔNG ĐOẠN ĐÓNG NANG ---
class FillingOperationScreen extends StatelessWidget {
  final VoidCallback onSign;
  const FillingOperationScreen({super.key, required this.onSign});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Máy đóng nang (NJP-1200 D)'),
        _Helper.buildInputField('Tốc độ đóng thực tế', '72,000 viên/h'),
        const Divider(),
        const Text('Kiểm tra khối lượng (Trung bình 20 viên)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _Helper.buildInputField('Khối lượng mẫu 1 (mg)', '502', suffix: 'TC: 500±5%'),
        _Helper.buildInputField('Khối lượng mẫu 2 (mg)', '498'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Khối lượng trung bình:'), Text('500 mg', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
        ),
        const SizedBox(height: 24),
        _Helper.buildEsignatureButton(onSign),
      ],
    );
  }
}

// --- 5. ĐÓNG GÓI THÀNH PHẨM ---
class PackagingOperationScreen extends StatelessWidget {
  final VoidCallback onSign;
  const PackagingOperationScreen({super.key, required this.onSign});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Đánh bóng & Đóng gói'),
        _Helper.buildToggleRow('Kiểm tra ngoại quan (Đạt)', true),
        _Helper.buildInputField('Thời gian đánh bóng (phút)', '45'),
        const Divider(),
        const _SectionHeader('Kết kết quả đóng gói'),
        _Helper.buildInputField('Số thùng đã đóng', '125'),
        _Helper.buildInputField('Tổng số đơn vị thành phẩm', '10,000'),
        const SizedBox(height: 24),
        _Helper.buildEsignatureButton(onSign),
        const SizedBox(height: 32),
        const Center(child: Text('--- Kết thúc Hồ sơ lô ---', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
      ],
    );
  }
}

// --- HELPERS & SHARED UI ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.1)),
    );
  }
}

class _Helper {
  static Widget buildInputField(String label, String hint, {String? suffix, TextEditingController? controller, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, hintText: hint, suffixText: suffix),
      ),
    );
  }

  static Widget buildToggleRow(String label, bool val) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Switch(value: val, onChanged: (v) {}, activeColor: Colors.green)]);
  }

  static Widget buildDropdown(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.all(8), width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Text(val))]);
  }

  static Widget buildDatePicker(String label, String val) => buildDropdown(label, val);

  static Widget buildSmallInfo(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(val)]);
  }

  static Widget buildEsignatureButton(VoidCallback onPressed) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onPressed, icon: const Icon(Icons.history_edu), label: const Text('KÝ XÁC NHẬN SỐ'), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12))));
  }
}
