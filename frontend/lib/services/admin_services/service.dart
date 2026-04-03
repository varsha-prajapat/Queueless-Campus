import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';

class ServiceApi {
  // 🔐 Get Valid Token (Auto Refresh)
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  // ================= FETCH SERVICES =================
  static Future<List<Map<String, dynamic>>> fetchServices() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(Api_Config.service),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 401) {
      final newToken = await _getToken();
      final retryResponse = await http.get(
        Uri.parse(Api_Config.service),
        headers: {"Authorization": "Bearer $newToken"},
      );

      if (retryResponse.statusCode != 200) {
        throw Exception("Failed to load services");
      }

      final decoded = jsonDecode(retryResponse.body);
      final List data = decoded is List ? decoded : decoded["data"] ?? [];

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded is List ? decoded : decoded["data"] ?? [];

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception("Failed to load services");
  }

  // ================= FETCH ACTIVE DEPARTMENTS =================
  static Future<List<Map<String, dynamic>>> fetchActiveDepartments() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(Api_Config.department),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load departments");
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded is List ? decoded : decoded["data"] ?? [];

    return data
        .where((d) => d["status"] == "active")
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ================= CREATE SERVICE =================
  static Future<void> createService({
    required String name,
    required String departmentId,
    required String serviceType,
    required bool allowUrgent,
    required bool isPaused,
    required int fee,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(Api_Config.service),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "name": name.trim(),
        "departmentId": departmentId, // MUST be real ObjectId
        "serviceType": serviceType, // MUST be "Documents" or "Fees"
        "hasFee": serviceType == "Fees",
        "fee": serviceType == "Fees" ? fee : 0,
        "isPaused": isPaused,
        "allowUrgent": allowUrgent,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create service");
    }
  }

  // ================= UPDATE SERVICE =================
  static Future<void> updateService({
    required String id,
    required String name,
    required String departmentId,
    required String serviceType, // ✅ ADDED
    required bool allowUrgent,
    required bool isPaused,
    required int fee,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse("${Api_Config.service}/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "name": name,
        "departmentId": departmentId,
        "serviceType": serviceType, // ✅ ADDED
        "allowUrgent": allowUrgent,
        "isPaused": isPaused,
        "fee": fee,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update service");
    }
  }

  // ================= DELETE SERVICE =================
  static Future<void> deleteService(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("${Api_Config.service}/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete service");
    }
  }
}
