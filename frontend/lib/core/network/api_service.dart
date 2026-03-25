import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<dynamic> get(String url, {String? token}) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );
    return _handle(response);
  }

  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Map<String, String> _headers(String? token) => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception(response.body);
  }
}
