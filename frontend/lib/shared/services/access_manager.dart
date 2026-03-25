import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_storage.dart';

class AccessManager {
  static Future<dynamic> execute(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = await AuthStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final response = await request(headers);

    // ✅ SUCCESS
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // ❌ UNAUTHORIZED (DO NOT CLEAR TOKEN HERE)
    if (response.statusCode == 401) {
      throw Exception("Session expired. Please login again.");
    }

    // ❌ OTHER ERRORS
    String message = "Something went wrong";

    try {
      final body = jsonDecode(response.body);
      message = body["message"] ?? message;
    } catch (_) {}

    throw Exception(message);
  }
}
