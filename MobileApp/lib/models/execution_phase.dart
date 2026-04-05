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
        return 'Kiểm tra (Pre-check)';
      case ExecutionPhase.input:
        return 'Nhập liệu (Input)';
      case ExecutionPhase.verification:
        return 'QC Xác nhận';
      case ExecutionPhase.execution:
        return 'Thực hiện (Execute)';
      case ExecutionPhase.completed:
        return 'Hoàn thành (Done)';
    }
  }

  int get indexNumber => index + 1;
}
