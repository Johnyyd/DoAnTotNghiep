import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// [AuthService] — Quản lý trạng thái đăng nhập (persistent).
/// Lưu token và thông tin user cục bộ qua shared_preferences.
class AuthService {
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;

  /// Gọi khi app vừa khởi động
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user));
  }

  /// Xóa phiên đăng nhập
  static Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}
