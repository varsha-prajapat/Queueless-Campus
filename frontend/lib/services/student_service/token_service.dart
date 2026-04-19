import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/token_model.dart';
import '../../auth/services/auth_storage.dart';
import '../../core/config/api_config.dart';

class TokenService {
  /// ================= COMMON HEADER =================
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getValidAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// ================= PRIVATE REQUEST METHODS =================
  static Future<http.Response> _get(String url) async {
    final headers = await _getHeaders();
    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 401) {
      final retryHeaders = await _getHeaders();
      response = await http.get(Uri.parse(url), headers: retryHeaders);
    }
    return response;
  }

  static Future<http.Response> _post(
      String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    var response = await http.post(Uri.parse(url),
        headers: headers, body: jsonEncode(body));

    if (response.statusCode == 401) {
      final retryHeaders = await _getHeaders();
      response = await http.post(Uri.parse(url),
          headers: retryHeaders, body: jsonEncode(body));
    }
    return response;
  }

  /// ================= PUBLIC GET WITH AUTH =================
  /// Helper: GET request with authentication
  static Future<http.Response> getWithAuth(String url) => _get(url);

  /// Get token stats from backend
  /// ============================== GET TOKEN STATS ==============================
  static Future<TokenStats> getTokenStats() async {
    try {
      final response = await _get(Api_Config.token_stats);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);

        // Extract the stats key (not "data")
        final data = decoded["stats"];
        if (data is Map<String, dynamic>) {
          return TokenStats.fromJson({
            "currentToken": data["currentToken"]?.toString() ?? "-",
            "nextToken": data["nextToken"]?.toString() ?? "-",
            "peopleAhead": data["peopleAhead"] is int ? data["peopleAhead"] : 0,
            "waiting": data["waiting"] is int ? data["waiting"] : 0,
            "servedToday": data["servedToday"] is int ? data["servedToday"] : 0,
            "urgentWaiting":
                data["urgentWaiting"] is int ? data["urgentWaiting"] : 0,
            "completed": data["completed"] is int ? data["completed"] : 0,
            "cancelled": data["cancelled"] is int ? data["cancelled"] : 0,
            "skipped": data["skipped"] is int ? data["skipped"] : 0,
          });
        }
      }

      // Fallback to empty if body or stats is invalid
      return TokenStats.empty();
    } catch (e, st) {
      return TokenStats.empty();
    }
  }

  /// ============================== My Tokens ==============================
  static Future<List<TokenModel>> getMyTokens() async {
    try {
      final response = await _get(Api_Config.my_tokens);
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final decoded = jsonDecode(response.body);

      List<Map<String, dynamic>> tokenList = [];

      if (decoded is Map<String, dynamic> && decoded["tokens"] != null) {
        final tokensField = decoded["tokens"];

        // tokensField is a Map with 'summary' and 'tokens' array
        if (tokensField is Map<String, dynamic> &&
            tokensField["tokens"] is List) {
          tokenList = (tokensField["tokens"] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        // fallback if tokensField is already a List (rare)
        else if (tokensField is List) {
          tokenList =
              tokensField.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      // fallback if decoded itself is a List (old response format)
      else if (decoded is List) {
        tokenList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Map each token JSON into TokenModel
      return tokenList.map((e) => TokenModel.fromJson(e)).toList();
    } catch (e, st) {
      return [];
    }
  }

  /// ============================== Book Token ==============================
  static Future<TokenModel?> bookToken({
    required String serviceId,
    bool isUrgent = false,
  }) async {
    try {
      final response = await _post(Api_Config.book_token, {
        "serviceId": serviceId,
        "isUrgent": isUrgent,
      });

      if (response.statusCode != 200 && response.statusCode != 201) return null;

      final body = response.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(response.body))
          : {};

      if (body['success'] == true && body['token'] != null) {
        return TokenModel.fromJson(Map<String, dynamic>.from(body['token']));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ============================== Confirm Payment ==============================
  static Future<bool> confirmPayment({
    required String tokenId,
    String? paymentId,
  }) async {
    try {
      final payload = {
        "tokenId": tokenId,
        if (paymentId != null) "paymentId": paymentId,
      };

      final response = await _post(Api_Config.token_payment, payload);

      if (response.statusCode < 200 || response.statusCode >= 300) return false;

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body.containsKey('success')) return body['success'] == true;
        if (body.containsKey('status')) return body['status'] == 'paid';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// ============================== Cancel Token ==============================
  static Future<bool> cancelToken({
    required String tokenId, // ✅ REQUIRED (IMPORTANT FIX)
  }) async {
    try {
      final response = await _post(
        Api_Config.cancel_token,
        {
          "tokenId": tokenId, // ✅ goes in req.body
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body.containsKey('success')) {
          return body['success'] == true;
        }

        // fallback if backend only returns message
        if (body.containsKey('message')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
