import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [AuthService] — Quản lý trạng thái đăng nhập (persistent).
/// Lưu token và thông tin user cục bộ qua flutter_secure_storage.
class AuthService {
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;

  /// Gọi khi app vừa khởi động
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    _token = await _storage.read(key: 'auth_token');
    final userStr = await _storage.read(key: 'auth_user');
    if (userStr != null) {
      try {
        _currentUser = jsonDecode(userStr);
      } catch (_) {
        _currentUser = null;
        _token = null;
      }
    } else {
      _token = null;
    }
  }

  /// Gọi sau khi login thành công để lưu token + user
  static Future<void> setSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _currentUser = user;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'auth_user', value: jsonEncode(user));
  }

  /// Xóa phiên đăng nhập
  static Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'auth_user');
  }

  /// Xác thực PIN chữ ký cá nhân (GMP Electronic Signature)
  /// Trong thực tế sẽ gọi API verify, hiện tại dùng mẫu test.
  static bool verifyPin(String pin) {
    if (pin.isEmpty) return false;
    // Chấp nhận admin123 cho quyền admin/QC, và 123456 cho nhân viên sản xuất
    return pin == 'admin123' || pin == '123456';
  }
}
