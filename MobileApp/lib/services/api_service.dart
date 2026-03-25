import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// [ApiService] — Lớp trung gian kết nối giao tiếp HTTP với Backend GMP System.
/// Mọi request đều tự động gắn JWT token từ [AuthService].
class ApiService {
  // Trong Docker Compose: frontend (8081) gọi backend qua proxy nginx → /api
  // Dev local: gọi thẳng port 5001
  static const String baseUrl = '/api';

  /// Headers mặc định kèm JWT token
  static Future<Map<String, String>> _headers() async {
    final token = AuthService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTHENTICATION ────────────────────────────────────────
  
  /// Đăng nhập: trả về {token, user} nếu thành công
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'platform': 'Mobile',
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── PRODUCTION BATCHES ────────────────────────────────────

  /// Lấy danh sách tất cả mẻ sản xuất
  static Future<List<Map<String, dynamic>>> getBatches() async {
    final url = Uri.parse('$baseUrl/production-batches');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Lấy chi tiết một mẻ sản xuất theo ID (kèm BOM, Routing)
  static Future<Map<String, dynamic>?> getBatchById(int batchId) async {
    final url = Uri.parse('$baseUrl/production-batches/$batchId');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kết thúc một mẻ sản xuất
  static Future<bool> finishBatch(int batchId) async {
    final url = Uri.parse('$baseUrl/production-batches/$batchId/finish');
    try {
      final response = await http.post(url, headers: await _headers());
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // ─── BATCH PROCESS LOGS ────────────────────────────────────

  /// Lấy nhật ký công đoạn của một mẻ
  static Future<List<Map<String, dynamic>>> getProcessLogs(int batchId) async {
    final url = Uri.parse('$baseUrl/batchprocesslogs/batch/$batchId');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Ghi nhận kết quả một bước công đoạn
  static Future<bool> submitStepData({
    required int batchId,
    required int stepId,
    required String resultStatus, // "Passed", "Failed", "PendingQC"
    Map<String, dynamic>? parametersData,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/batchprocesslogs');
    final payload = {
      'batchId': batchId,
      'stepId': stepId,
      'startTime': DateTime.now().toUtc().toIso8601String(),
      'endTime': DateTime.now().toUtc().toIso8601String(),
      'resultStatus': resultStatus,
      if (parametersData != null) 'parametersData': jsonEncode(parametersData),
      if (notes != null) 'notes': notes,
    };

    try {
      final response = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // ─── INVENTORY LOTS ────────────────────────────────────────

  /// Lấy danh sách lô nguyên liệu (đã Released)
  static Future<List<Map<String, dynamic>>> getAvailableLots() async {
    final url = Uri.parse('$baseUrl/inventory-lots/available');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
