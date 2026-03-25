import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../shared/services/access_manager.dart';
import '../utils/auth_role_helper.dart';

class AdminService {
  static Future<void> inviteUser({
    required String email,
    required String role,
    required String department,
  }) async {
    final isAdmin = await AuthRoleHelper.isAdmin();

    if (!isAdmin) {
      throw Exception("Only admin can invite users");
    }

    await AccessManager.execute((headers) {
      return http.post(
        Uri.parse(Api_Config.inviteUser),
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "role": role,
          "department": department,
        }),
      );
    });
  }
}
