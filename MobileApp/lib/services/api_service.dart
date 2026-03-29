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

  /// Lấy danh sách các lệnh sản xuất hiện tại (Mock data)
  static Future<List<Map<String, dynamic>>> getProductionOrders() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      {
        'orderId': 1001,
        'orderCode': 'ORD-1025',
        'productName': 'VIÊN NANG NLC 3',
        'sdk': 'VD-12345-21',
        'batchSize': '100 kg',
        'sizing': 'Thùng/ 80 chai/ 40 viên',
        'startDate': '18/03/2026',
        'endDate': '25/03/2026',
        'progress': 0.4, // 40% (2/5 mẻ done)
        'totalBatches': 5,
        'completedBatches': 2,
        'status': 'In-Process',
      },
      {
        'orderId': 1002,
        'orderCode': 'ORD-1026',
        'productName': 'SIRO HO THẢO DƯỢC',
        'sdk': 'VD-54321-22',
        'batchSize': '500 Lít',
        'sizing': 'Thùng/ 50 chai/ 100ml',
        'startDate': '20/03/2026',
        'endDate': '30/03/2026',
        'progress': 0.0, // 0%
        'totalBatches': 3,
        'completedBatches': 0,
        'status': 'Draft',
      },
      {
        'orderId': 1003,
        'orderCode': 'ORD-1027',
        'productName': 'PARACETAMOL 500',
        'sdk': 'VD-99999-23',
        'batchSize': '200 kg',
        'sizing': 'Thùng/ 100 vỉ/ 10 viên',
        'startDate': '10/03/2026',
        'endDate': '15/03/2026',
        'progress': 1.0, // 100%
        'totalBatches': 4,
        'completedBatches': 4,
        'status': 'Completed',
      }
    ];
  }

  // ─── PRODUCTION BATCHES ────────────────────────────────────

  /// Lấy danh sách tất cả mẻ sản xuất (Hiển thị mock data để test Progress theo yêu cầu)
  static Future<List<Map<String, dynamic>>> getBatches({int? orderId}) async {
    // Thêm dữ liệu giả lập (mock data) để có thể test chuẩn hơn
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network
    
    // Nếu gọi cho order khác 1001 (VIÊN NANG NLC 3) thì mock dữ liệu riêng
    if (orderId == 1002) {
      return [
        {
          'batchId': 201,
          'batchNumber': 'BATCH-SIRO-001',
          'status': 'Draft',
          'order': {'orderCode': 'ORD-1026', 'productName': 'SIRO HO THẢO DƯỢC (Lô 1)'}
        },
        {
          'batchId': 202,
          'batchNumber': 'BATCH-SIRO-002',
          'status': 'Draft',
          'order': {'orderCode': 'ORD-1026', 'productName': 'SIRO HO THẢO DƯỢC (Lô 2)'}
        },
        {
          'batchId': 203,
          'batchNumber': 'BATCH-SIRO-003',
          'status': 'Draft',
          'order': {'orderCode': 'ORD-1026', 'productName': 'SIRO HO THẢO DƯỢC (Lô 3)'}
        }
      ];
    }
    
    if (orderId == 1003) {
      return List.generate(4, (index) => {
        'batchId': 300 + index,
        'batchNumber': 'BATCH-PARA-00${index+1}',
        'status': 'Completed',
        'order': {'orderCode': 'ORD-1027', 'productName': 'PARACETAMOL 500 (Lô ${index+1})'}
      });
    }

    // Mặc định trả về dữ liệu của VIÊN NANG NLC 3 (orderId = 1001)
    return [
      {
        'batchId': 101,
        'batchNumber': 'BATCH-NLC3-001',
        'status': 'Completed',
        'order': {
          'orderCode': 'ORD-1025',
          'recipe': {
            'material': {
              'materialName': 'Viên Nang NLC 3 (Lô 1)'
            }
          }
        }
      },
      {
        'batchId': 102,
        'batchNumber': 'BATCH-NLC3-002',
        'status': 'Completed',
        'order': {
          'orderCode': 'ORD-1025',
          'recipe': {
            'material': {
              'materialName': 'Viên Nang NLC 3 (Lô 2)'
            }
          }
        }
      },
      {
        'batchId': 103,
        'batchNumber': 'BATCH-NLC3-003',
        'status': 'In-Process',
        'order': {
          'orderCode': 'ORD-1025',
          'recipe': {
            'material': {
              'materialName': 'Viên Nang NLC 3 (Lô 3)'
            }
          }
        }
      },
      {
        'batchId': 104,
        'batchNumber': 'BATCH-NLC3-004',
        'status': 'Draft',
        'order': {
          'orderCode': 'ORD-1025',
          'recipe': {
            'material': {
              'materialName': 'Viên Nang NLC 3 (Lô 4)'
            }
          }
        }
      },
      {
        'batchId': 105,
        'batchNumber': 'BATCH-NLC3-005',
        'status': 'Draft',
        'order': {
          'orderCode': 'ORD-1025',
          'recipe': {
            'material': {
              'materialName': 'Viên Nang NLC 3 (Lô 5)'
            }
          }
        }
      }
    ];
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

  /// Lấy nhật ký công đoạn của một mẻ (Sử dụng Mock Data để hiển thị rõ lộ trình)
  static Future<List<Map<String, dynamic>>> getProcessLogs(int batchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Tạo cấu trúc 3 công đoạn chuẩn (Routing Steps) theo quy trình: Sấy -> Cân -> Trộn
    final stepDrying = {'stepId': 1, 'stepName': 'Công đoạn 1: Sấy NLC 3 / TD 8'};
    final stepWeighing = {'stepId': 2, 'stepName': 'Công đoạn 2: Cân nguyên liệu'};
    final stepMixing = {'stepId': 3, 'stepName': 'Công đoạn 3: Trộn đồng nhất'};

    // Trả về tiến độ khác nhau dựa theo ID của mẻ
    if (batchId == 101 || batchId == 102 || batchId >= 300) {
      // Các mẻ đã Hoàn thành (Completed)
      return [
        {'logId': 1, 'stepId': 1, 'step': stepDrying, 'resultStatus': 'Passed', 'endTime': '2026-03-25T08:30:00Z'},
        {'logId': 2, 'stepId': 2, 'step': stepWeighing, 'resultStatus': 'Passed', 'endTime': '2026-03-25T11:45:00Z'},
        {'logId': 3, 'stepId': 3, 'step': stepMixing, 'resultStatus': 'Passed', 'endTime': '2026-03-25T16:00:00Z'},
      ];
    } else if (batchId == 103) {
      // Mẻ đang Sản xuất (In-Process)
      return [
        {'logId': 4, 'stepId': 1, 'step': stepDrying, 'resultStatus': 'Passed', 'endTime': '2026-03-29T09:15:00Z'},
        {'logId': 5, 'stepId': 2, 'step': stepWeighing, 'resultStatus': 'PendingQC', 'endTime': '2026-03-29T13:00:00Z'},
        {'logId': 6, 'stepId': 3, 'step': stepMixing, 'resultStatus': null, 'endTime': null},
      ];
    } else {
      // Mẻ chưa thực hiện (Draft)
      return [
         {'logId': 7, 'stepId': 1, 'step': stepDrying, 'resultStatus': null, 'endTime': null},
         {'logId': 8, 'stepId': 2, 'step': stepWeighing, 'resultStatus': null, 'endTime': null},
         {'logId': 9, 'stepId': 3, 'step': stepMixing, 'resultStatus': null, 'endTime': null},
      ];
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
