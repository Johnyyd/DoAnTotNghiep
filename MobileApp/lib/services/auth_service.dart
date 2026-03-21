/// [AuthService] — Quản lý trạng thái đăng nhập trong bộ nhớ (in-memory).
/// Lưu token và thông tin user sau khi đăng nhập thành công.
class AuthService {
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;

  /// Gọi sau khi login thành công để lưu token + user
  static void setSession(String token, Map<String, dynamic> user) {
    _token = token;
    _currentUser = user;
  }

  /// Xóa phiên đăng nhập
  static void clearSession() {
    _token = null;
    _currentUser = null;
  }
}
