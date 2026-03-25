import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import './auth_storage.dart';

const String PURPOSE_LOGIN = "LOGIN_2FA";

class OTPService {
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Api_Config.otp),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "otp": otp.trim(),
          "purpose": purpose.trim(),
        }),
      );

      if (response.body.isEmpty) {
        throw Exception("Server error. Please try again.");
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data["message"] ?? "OTP verification failed");
      }

      if (data["success"] != true) {
        throw Exception(data["message"] ?? "OTP failed");
      }

      // ✅ LOGIN FLOW → SAVE TOKENS
      if (purpose == PURPOSE_LOGIN) {
        final String? accessToken = data["accessToken"];
        final String? refreshToken = data["refreshToken"];

        if (accessToken == null || refreshToken == null) {
          throw Exception("Token missing. Please login again.");
        }

        await AuthStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return {"success": true};
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
