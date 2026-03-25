import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import "../../core/config/api_config.dart";

class AuthStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = "accessToken";
  static const String _refreshTokenKey = "refreshToken";

  // 🔥 CHANGE THIS TO YOUR REFRESH API
  static const String _refreshUrl = Api_Config.refresh;

  // ================= SAVE =================

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  // ================= GET =================

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // ================= LOGIN CHECK =================

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      // ✅ If not expired → user is logged in
      if (!JwtDecoder.isExpired(token)) {
        return true;
      }

      // 🔥 If expired → try refresh
      final refreshed = await _refreshAccessToken();

      return refreshed;
    } catch (e) {
      await clear();
      return false;
    }
  }

  // ================= REFRESH TOKEN =================
  static Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        await clear();
        return false;
      }

      final response = await http.post(
        Uri.parse(_refreshUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $refreshToken", // ✅ YEH IMPORTANT HAI
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data["accessToken"];

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await saveAccessToken(newAccessToken);
          return true;
        }
      }

      await clear();
      return false;
    } catch (e) {
      await clear();
      return false;
    }
  }
  // ================= CLEAR =================

  static Future<void> clear() async {
    await _storage.deleteAll();
  }

  // ================= GET VALID TOKEN =================
  static Future<String?> getValidAccessToken() async {
    final token = await getAccessToken();

    if (token == null) return null;

    if (!JwtDecoder.isExpired(token)) {
      return token;
    }

    // 🔥 If expired → refresh
    final refreshed = await _refreshAccessToken();

    if (refreshed) {
      return await getAccessToken();
    }

    return null;
  }
}
