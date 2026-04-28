/// [ExecutionPhase] — 5 giai đoạn chính của một bước công đoạn theo GMP-WHO.
enum ExecutionPhase {
  /// 1. Kiểm tra ban đầu (Môi trường, thiết bị, vệ sinh).
  precheck,

  /// 2. Nhập liệu (Khối lượng, số lô, thông số kỹ thuật).
  input,

  /// 3. QC Xác nhận (Đợi chữ ký của QC).
  verification,

  /// 4. Thực hiện (Chạy máy, thực hiện quy trình chính).
  execution,

  /// 5. Hoàn thành (Chốt dữ liệu và chuyển công đoạn).
  completed,
}

extension ExecutionPhaseExtension on ExecutionPhase {
  String get label {
    switch (this) {
      case ExecutionPhase.precheck:
        return 'Kiểm tra giá trị đầu vào';
      case ExecutionPhase.input:
        return 'Nhập thông số kỹ thuật';
      case ExecutionPhase.verification:
        return 'Đợi QC xét duyệt';
      case ExecutionPhase.execution:
        return 'Vận hành công đoạn';
      case ExecutionPhase.completed:
        return 'Đã hoàn tất';
    }
  }

  int get indexNumber => index + 1;
}
