import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_storage.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(String url) async {
    // 🔐 Get valid token (auto refresh if expired)
    String? token = await AuthStorage.getValidAccessToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    // 🔁 Retry once if backend returns 401
    if (response.statusCode == 401) {
      token = await AuthStorage.getValidAccessToken();

      if (token == null) {
        throw Exception("Session expired. Please login again.");
      }

      final retryResponse = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
        return retryResponse.body.isNotEmpty
            ? jsonDecode(retryResponse.body)
            : {};
      }

      throw Exception("API Error ${retryResponse.statusCode}");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }

    throw Exception("API Error ${response.statusCode}");
  }
}
