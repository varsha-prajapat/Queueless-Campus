import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterService {
  /// Registers a new user
  ///
  /// [name], [email], and [password] are required.
  /// [phone] and [departmentId] are optional.
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? departmentId,
  }) async {
    // Build request body
    final Map<String, dynamic> body = {
      "name": name,
      "email": email,
      "password": password,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      body["phone"] = phone.trim();
    }

    if (departmentId != null && departmentId.trim().isNotEmpty) {
      body["departmentId"] = departmentId.trim(); // backend key
    }

    // Make POST request
    final response = await http.post(
      Uri.parse("http://localhost:3005/api/v1/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    // Handle empty response
    if (response.body.isEmpty) {
      throw Exception("Server error. Please try again.");
    }

    // Decode response
    final data = jsonDecode(response.body);

    // Handle backend errors
    if (data["success"] == false) {
      throw Exception(data["message"] ?? "Registration failed.");
    }
  }
}
