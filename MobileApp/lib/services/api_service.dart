import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use localhost for local dev/web-server, or 10.0.2.2 for Android emulator
  // If deployed via Docker/Tailscale, this could be the proxy URL.
  // For Docker Compose, the backend is typically exposed on 5001.
  static const String baseUrl = 'http://localhost:5001/api';

  /// Gửi dữ liệu Batch Process Log lên Backend
  static Future<bool> submitStepData(int batchId, int stepId, String operatorId, Map<String, dynamic> parametersData) async {
    final url = Uri.parse('$baseUrl/BatchProcessLogs');
    
    // Construct the payload matching the .NET DTO / Entity expected structure
    final Map<String, dynamic> payload = {
      "batchId": batchId,
      "stepId": stepId,
      "operatorId": operatorId,
      "startTime": DateTime.now().toUtc().toIso8601String(),
      "endTime": DateTime.now().toUtc().toIso8601String(),
      "resultStatus": "Completed",
      "parametersData": jsonEncode(parametersData),
      "notes": "Submitted from Mobile App eBMR",
      "qcPassed": true
    };

    try {
      print('Sending POST request to $url with payload: $payload');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error calling API: $e');
      return false;
    }
  }
}
