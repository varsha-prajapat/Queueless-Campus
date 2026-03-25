// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/userui_model.dart';
import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';

class UserService {
  final String baseUrl = Api_Config.users_admin;

  // 🔐 Get a valid token
  Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }
    return token;
  }

  // ================= FETCH ALL USERS =================
  Future<List<Userui>> getUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users');

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      if (jsonBody['success'] == true) {
        final List<dynamic> data = jsonBody['data'];
        return data.map((e) => Userui.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load users: ${jsonBody['message']}');
      }
    } else if (response.statusCode == 401) {
      // Retry once with refreshed token
      final newToken = await _getToken();
      final retryResponse = await http.get(
        url,
        headers: {"Authorization": "Bearer $newToken"},
      );

      if (retryResponse.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(retryResponse.body);
        if (jsonBody['success'] == true) {
          final List<dynamic> data = jsonBody['data'];
          return data.map((e) => Userui.fromJson(e)).toList();
        } else {
          throw Exception('Failed to load users: ${jsonBody['message']}');
        }
      }
      throw Exception(
          'Unauthorized. Status code: ${retryResponse.statusCode}, Body: ${retryResponse.body}');
    } else {
      throw Exception(
          'Failed to load users. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // ================= UPDATE USER =================
  Future<void> updateUser(Userui user) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users/${user.id}');

    // Convert to JSON and send departmentId
    final Map<String, dynamic> jsonBody = user.toJson();

    if (user.departmentId != null) {
      jsonBody['departmentId'] = user.departmentId;
    }

    // Remove old department name field if exists
    jsonBody.remove('department');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(jsonBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update user. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // ================= BLOCK/UNBLOCK USER =================
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final token = await _getToken();
    final url = isActive
        ? '$baseUrl/users/$userId/unblock'
        : '$baseUrl/users/$userId/block';

    final response = await http.patch(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update user status. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // ================= DELETE USER =================
  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete user. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
