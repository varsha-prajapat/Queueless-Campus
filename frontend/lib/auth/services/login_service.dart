import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class LoginService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? invitationToken,
  }) async {
    final url = Uri.parse(Api_Config.login);

    final Map<String, dynamic> body = {
      "email": email.trim().toLowerCase(),
      "password": password.trim(),
      if (invitationToken != null) "invitationToken": invitationToken,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    // ⛔ Empty response safety
    if (response.body.isEmpty) {
      throw Exception("Server error. Please try again.");
    }

    final data = jsonDecode(response.body);

    // ⛔ Backend-defined failure
    if (data["success"] == false) {
      throw Exception(data["message"]);
    }

    // ⛔ HTTP-level failure
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data["message"] ?? "Login failed");
    }

    // ✅ Success
    return data;
  }
}
