import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/token_model.dart';
import '../../auth/services/auth_storage.dart';
import '../../core/config/api_config.dart';

class TokenService {
  static const String baseUrl = Api_Config.token_staff;
  static const String skip_token = Api_Config.skip_token;
  static const String call_token = Api_Config.call_token;

  /// ================= HEADERS =================
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// ================= TOKEN STATS =================
  static Future<TokenStats> getTokenStats() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(Uri.parse(baseUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded["data"] is Map) {
          final data = decoded["data"];

          return TokenStats(
            currentToken: data["currentToken"]?.toString() ?? "-",
            nextToken: data["nextToken"]?.toString() ?? "-",
            waiting: data["waiting"] ?? 0,
            servedToday: data["servedToday"] ?? 0,
            urgentWaiting: data["urgentWaiting"] ?? 0,
          );
        }
      }

      return TokenStats.empty();
    } catch (_) {
      return TokenStats.empty();
    }
  }

  /// ================= STAFF QUEUE =================
  static Future<List<TokenModel>> getStaffQueue() async {
    try {
      final headers = await _getHeaders();

      final response =
          await http.get(Uri.parse("$baseUrl/queue"), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded["data"] is List) {
          return (decoded["data"] as List)
              .map((e) => TokenModel.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  /// ================= COMPLETE TOKEN =================
  static Future<Map<String, dynamic>> completeToken(String tokenId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(Api_Config.change_token_status_completed),
        headers: headers,
        body: jsonEncode({
          "tokenId": tokenId, // 🔥 IMPORTANT FIX
        }),
      );

      print("COMPLETE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {"success": false, "message": "Failed to complete token"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= SKIP TOKEN =================
  static Future<Map<String, dynamic>> skipToken(String tokenId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(skip_token),
        headers: headers,
        body: jsonEncode({"tokenId": tokenId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {"success": false, "message": "Failed to skip token"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= CALL NEXT TOKEN =================
  static Future<Map<String, dynamic>> callNextToken(String staffId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(call_token),
        headers: headers,
        body: jsonEncode({"staffId": staffId}),
      );

      print("CALL NEXT RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {"success": false, "message": "Failed to call next token"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= ALL TOKENS =================
  static Future<List<TokenModel>> getAllTokensOfStaffDetail() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(Api_Config.all_tokens_details),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded["data"] is Map) {
          final data = decoded["data"];

          if (data["tokens"] is List) {
            final tokensList = data["tokens"] as List;

            return tokensList.map((e) {
              return TokenModel(
                /// 🔥 FIXED ID
                id: e["_id"] ?? e["tokenId"] ?? "",

                tokenNumber: e["tokenNumber"] ?? 0,

                /// 🔥 normalize status
                status: (e["status"] ?? "").toString().toLowerCase(),

                serviceId: "",
                isUrgent: e["isUrgent"] ?? false,

                createdAt: e["createdAt"] != null
                    ? DateTime.tryParse(e["createdAt"])
                    : null,
                updatedAt: e["updatedAt"] != null
                    ? DateTime.tryParse(e["updatedAt"])
                    : null,
              );
            }).toList();
          }
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  /// ================= SERVING TOKEN =================
  static TokenModel? getServingToken(List<TokenModel> tokens) {
    try {
      return tokens.firstWhere(
        (t) => t.status == "serving",
      );
    } catch (e) {
      return null;
    }
  }

  static Future<TokenModel?> fetchServingToken() async {
    final tokens = await getAllTokensOfStaffDetail();
    return getServingToken(tokens);
  }

  /// ================= FIFO WAITING =================
  static List<TokenModel> getWaitingTokensFIFO(List<TokenModel> tokens) {
    return tokens.where((t) => t.status == "waiting").toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
  }

  /// ================= NEXT TOKEN =================
  static TokenModel? getNextTokenFIFO(List<TokenModel> tokens) {
    final waiting = tokens.where((t) => t.status == "waiting").toList();

    if (waiting.isEmpty) return null;

    final urgent = waiting.where((t) => t.isUrgent).toList();

    final target = urgent.isNotEmpty ? urgent : waiting;

    target.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.now();
      final bTime = b.createdAt ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    return target.first;
  }

  /// ================= NEXT TOKEN NUMBER =================
  static Future<int?> getNextTokenNumber() async {
    final tokens = await getAllTokensOfStaffDetail();
    final next = getNextTokenFIFO(tokens);
    return next?.tokenNumber;
  }

  /// ================= ACCESS TOKEN =================
  static Future<String> get accessToken async =>
      (await AuthStorage.getValidAccessToken()) ?? "";
}
