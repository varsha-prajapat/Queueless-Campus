// services/admin_contact_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../auth/services/auth_storage.dart';
import '../../core/config/api_config.dart';

class AdminContactService {
  static const String baseUrl = Api_Config.admin_contact;

  /// 🔐 Get a valid access token (refresh if needed)
  static Future<String?> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    return token;
  }

  /// ================= GET ADMIN CONTACT =================
  /// Returns a UserModel representing the admin
  static Future<UserModel?> getAdminContact({required String role}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No access token available");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/${role.toLowerCase()}/contact"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          final admin = UserModel.fromJson(body['data']);
          print(
              "DEBUG: Parsed admin data: ${admin.name}, ${admin.email}, ${admin.phone}");
          return admin;
        } else {
          return null;
        }
      } else {
        throw Exception(
          "Failed to fetch admin contact: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      return null;
    }
  }
}
