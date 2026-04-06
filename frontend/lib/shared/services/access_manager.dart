import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_storage.dart';

class AccessManager {
  static Future<dynamic> execute(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    try {
      /* ================= 🔐 GET TOKEN ================= */

      final token = await AuthStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      /* ================= 📡 HEADERS ================= */

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      /* ================= 🚀 API CALL ================= */

      final response = await request(headers);

      /* ================= ✅ SUCCESS ================= */

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;

        try {
          return jsonDecode(response.body);
        } catch (_) {
          // अगर response JSON नहीं है
          return response.body;
        }
      }

      /* ================= ❌ UNAUTHORIZED ================= */

      if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      }

      /* ================= ❌ OTHER ERRORS ================= */

      String message = "Something went wrong";

      if (response.body.isNotEmpty) {
        try {
          final body = jsonDecode(response.body);

          // ✅ flexible message handling
          if (body is Map && body.containsKey("message")) {
            message = body["message"].toString();
          }
        } catch (_) {
          // अगर JSON parse fail हो जाए तो raw body दिखा सकते हैं
          message = response.body;
        }
      }

      throw Exception(message);
    } catch (e) {
      /* ================= ⚠️ NETWORK / UNKNOWN ERROR ================= */

      throw Exception(
        e.toString().replaceAll("Exception:", "").trim(),
      );
    }
  }
}
