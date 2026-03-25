import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';

class HomeService {
  static const int _timeoutSeconds = 15;

  /// 🔐 AUTH HEADERS (AUTO REFRESH SUPPORT)
  static Future<Map<String, String>> _authHeaders({
    bool isMultipart = false,
  }) async {
    final headers = <String, String>{};

    if (!isMultipart) {
      headers["Content-Type"] = "application/json";
    }

    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired");
    }

    headers["Authorization"] = "Bearer $token";
    return headers;
  }

  /// 🧠 COMMON JSON REQUEST HANDLER (AUTO RETRY ON 401)
  static Future<dynamic> _executeRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _authHeaders();
    var res = await request(headers).timeout(
      const Duration(seconds: _timeoutSeconds),
    );

    // If somehow backend still returns 401
    if (res.statusCode == 401) {
      final refreshed = await AuthStorage.getValidAccessToken();
      if (refreshed == null) {
        throw Exception("Session expired");
      }

      headers = await _authHeaders();
      res = await request(headers).timeout(
        const Duration(seconds: _timeoutSeconds),
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isNotEmpty ? jsonDecode(res.body) : {};
    }

    throw Exception(
      res.body.isNotEmpty
          ? jsonDecode(res.body)["message"] ?? "Request failed"
          : "Request failed",
    );
  }

  /// 👤 GET MY PROFILE
  static Future<Map<String, dynamic>> getMyProfile() async {
    return await _executeRequest((headers) {
      return http.get(
        Uri.parse(Api_Config.getMyProfile),
        headers: headers,
      );
    });
  }

  /// ✏️ UPDATE PROFILE (MULTIPART SUPPORT + AUTO RETRY)
  static Future<Map<String, dynamic>> updateProfile({
    required Map<String, String> updateData,
    File? imageFile,
  }) async {
    try {
      return await _sendMultipart(updateData, imageFile);
    } catch (e) {
      // retry once if unauthorized
      final refreshed = await AuthStorage.getValidAccessToken();
      if (refreshed == null) {
        throw Exception("Session expired");
      }

      return await _sendMultipart(updateData, imageFile);
    }
  }

  /// 📤 MULTIPART PUT REQUEST
  static Future<Map<String, dynamic>> _sendMultipart(
    Map<String, String> updateData,
    File? imageFile,
  ) async {
    final headers = await _authHeaders(isMultipart: true);

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse(Api_Config.updateMyProfile),
    );

    request.headers.addAll(headers);
    request.fields.addAll(updateData);

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profileImage",
          imageFile.path,
        ),
      );
    }

    final streamed = await request.send().timeout(
          const Duration(seconds: _timeoutSeconds),
        );

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = response.body.isNotEmpty
          ? jsonDecode(response.body)["message"] ?? "Profile update failed"
          : "Profile update failed";
      throw Exception(msg);
    }

    return response.body.isNotEmpty ? jsonDecode(response.body) : {};
  }

  /// 📩 INVITE USER
  static Future<bool> inviteUser({
    required String email,
    required String role,
    required String department,
  }) async {
    await _executeRequest((headers) {
      return http.post(
        Uri.parse(Api_Config.inviteUser),
        headers: headers,
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "role": role,
          "department": department,
        }),
      );
    });

    return true;
  }
}
