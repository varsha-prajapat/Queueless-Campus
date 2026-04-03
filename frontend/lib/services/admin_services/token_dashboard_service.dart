import 'dart:convert';
import 'package:http/http.dart' as http;

import "../../core/config/api_config.dart";
import "../../auth/services/auth_storage.dart";

class TokenDashboardService {
  static const String baseUrl = Api_Config.token_dashboard_admin;

  // 🔐 Get Valid Token
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  // 🔄 Parse Response Safely
  static Map<String, dynamic> _parseResponse(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {"data": decoded};
  }

  // ================= FETCH DASHBOARD =================
  static Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // 🔁 Retry once if unauthorized
      if (response.statusCode == 401) {
        final newToken = await _getToken();

        final retryResponse = await http.get(
          Uri.parse(baseUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $newToken",
          },
        );

        if (retryResponse.statusCode == 200) {
          return _parseResponse(retryResponse.body);
        }

        throw Exception(
          "Failed after retry: ${retryResponse.statusCode} - ${retryResponse.body}",
        );
      }

      // ✅ Success
      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      }

      // ❌ Other Errors
      throw Exception(
        "Failed: ${response.statusCode} - ${response.body}",
      );
    } catch (e) {
      throw Exception("Dashboard API Error: $e");
    }
  }
}
