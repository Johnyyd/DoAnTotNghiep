import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// [ApiService] — Lớp trung gian kết nối giao tiếp HTTP với Backend GMP System.
/// Mọi request đều tự động gắn JWT token từ [AuthService].
class ApiService {
  // Khi chạy trong Docker Compose (Nginx proxy), baseUrl nên là đường dẫn tương đối '/api'
  // Khi chạy dev local Windows thì dùng 'http://localhost:5001/api' hoặc IP máy chủ
  static String? _manualBaseUrl;
  static void setManualBaseUrl(String url) => _manualBaseUrl = url;

  static String get baseUrl {
    if (_manualBaseUrl != null) return _manualBaseUrl!;
    if (kIsWeb) {
      // Trên Web, dùng origin hiện tại (vd http://localhost:8081) + /api
      final origin = Uri.base.origin;
      return '$origin/api';
    }
    // QUAN TRỌNG: Thay 'localhost' thành địa chỉ IP máy tính của bạn (vd: 192.168.1.10) để kết nối từ điện thoại thật.
    return 'http://192.168.100.152:5001/api'; // <--- HÃY THAY IP NÀY BẰNG IP MÁY TÍNH CỦA BẠN
  }

  /// Tiện ích log lỗi cho dev
  static void _logError(String context, dynamic error) {
    debugPrint('[ApiService Error] $context: $error');
  }

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
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
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

  // ─── PRODUCTION ORDERS (LỆNH SẢN XUẤT) ─────────────────────

  /// Lấy danh sách các lệnh sản xuất hiện tại từ CSDL
  static Future<List<Map<String, dynamic>>> getProductionOrders() async {
    final url = Uri.parse('$baseUrl/production-orders');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data.map((e) {
          final order = e as Map<String, dynamic>;
          final batches = order['productionBatches'] as List<dynamic>? ?? [];
          final totalBatches = batches.length;
          final completedBatches =
              batches.where((b) => b['status'] == 'Completed').length;
          final progress =
              totalBatches == 0 ? 0.0 : completedBatches / totalBatches;

          final measureUnit = order['recipe']?['material']?['unitOfMeasure']
                  ?['uomName'] ??
              'kg';

          return {
            'orderId': order['orderId'],
            'orderCode': order['orderCode'] ?? '-',
            'productName':
                order['recipe']?['material']?['materialName'] ?? 'Sản phẩm',
            'sdk': 'N/A', // Tạm để N/A vì Backend không trả SDK ở Order
            'batchSize': '${order['plannedQuantity'] ?? 0} $measureUnit',
            'sizing': '-', // N/A
            'startDate': order['startDate'] != null
                ? _formatDate(order['startDate'])
                : '-',
            'endDate':
                order['endDate'] != null ? _formatDate(order['endDate']) : '-',
            'progress': progress,
            'totalBatches': totalBatches,
            'completedBatches': completedBatches,
            'status': order['status'] ?? 'Draft',
            'productionBatches': batches, // Include batches for status tracking
            'recipe':
                order['recipe'], // Keep full recipe for BOM access in pre-check
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Cập nhật trạng thái của Order
  static Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final url = Uri.parse('$baseUrl/production-orders/$orderId/status');
    try {
      final response = await http.patch(
        url,
        headers: await _headers(),
        body: jsonEncode(newStatus),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // ─── PRODUCTION BATCHES ────────────────────────────────────

  /// Lấy danh sách tất cả mẻ sản xuất từ CSDL
  static Future<List<Map<String, dynamic>>> getBatches({int? orderId}) async {
    final url = orderId != null
        ? Uri.parse('$baseUrl/production-orders/$orderId/batches')
        : Uri.parse('$baseUrl/production-batches');
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

  /// Lấy nhật ký công đoạn của một mẻ (Virtual Workflow: Routing + Logs)
  static Future<List<Map<String, dynamic>>> getProcessLogs(int batchId) async {
    try {
      final url = Uri.parse(
          '$baseUrl/batch-process-logs/batch/$batchId?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(url, headers: await _headers());

      debugPrint('ApiService.getProcessLogs status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> workflow = data['data'] ?? [];
        return workflow.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService.getProcessLogs error: $e');
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
    final url = Uri.parse('$baseUrl/batch-process-logs');
    final payload = {
      'batchId': batchId,
      'routingId': stepId,
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
      debugPrint('ApiService.submitStepData error: $e');
      return false;
    }
  }

  /// QC Phê duyệt công đoạn
  static Future<bool> verifyStepData({
    required int logId,
    required int verifierId,
    required String status, // "Passed", "Failed", "Approved"
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/batch-process-logs/verify');
    final payload = {
      'logId': logId,
      'verifierId': verifierId,
      'status': status,
      if (notes != null) 'notes': notes,
    };

    try {
      final response = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      debugPrint('ApiService.verifyStepData status: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('ApiService.verifyStepData error: $e');
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
