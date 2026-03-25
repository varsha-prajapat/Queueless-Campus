import '../auth/services/auth_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRoleHelper {
  /// 🔐 Get decoded payload safely (auto refresh support)
  static Future<Map<String, dynamic>?> _payload() async {
    try {
      final token = await AuthStorage.getValidAccessToken();

      if (token == null || token.isEmpty) return null;

      return JwtDecoder.decode(token);
    } catch (_) {
      return null;
    }
  }

  /// 👤 Get User Role
  static Future<String> getRole() async {
    final data = await _payload();
    print("Role${data?["role"]}");
    return data?['role'] ?? 'GUEST';
  }

  /// 👤 Get User Name
  static Future<String> getName() async {
    final data = await _payload();
    return data?['name'] ?? 'User';
  }

  /// 🆔 Get User ID
  static Future<String> getUserId() async {
    final data = await _payload();
    return data?['userId'] ?? "";
  }

  /// 🛡 Check Admin
  static Future<bool> isAdmin() async {
    return (await getRole()) == "ADMIN";
  }
}
