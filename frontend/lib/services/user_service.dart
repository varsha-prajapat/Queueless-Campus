import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../auth/services/auth_storage.dart';
import '../core/config/api_config.dart';

class UserService {
  static Future<UserModel> getMe() async {
    // 🔐 Get valid token (auto refresh if expired)
    String? token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    http.Response response = await http.get(
      Uri.parse(Api_Config.getMyProfile),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // 🔁 If backend still returns 401 → retry once
    if (response.statusCode == 401) {
      token = await AuthStorage.getValidAccessToken();

      if (token == null) {
        throw Exception("Session expired. Please login again.");
      }

      response = await http.get(
        Uri.parse(Api_Config.getMyProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    }

    if (response.statusCode != 200) {
      throw Exception("User fetch failed: ${response.body}");
    }

    final json = jsonDecode(response.body);

    // 🔥 Handle wrapped & unwrapped response
    if (json is Map<String, dynamic>) {
      if (json.containsKey('data')) {
        return UserModel.fromJson(json['data']);
      } else {
        return UserModel.fromJson(json);
      }
    }

    throw Exception("Invalid response format");
  }
}
