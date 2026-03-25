import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/counter_model.dart';
import "../../core/config/api_config.dart";
import '../../auth/services/auth_storage.dart';

class CounterService {
  static const String baseUrl = Api_Config.getcounter_staff;

  // ================= GET TOKEN =================
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  // ================= GET USER COUNTERS =================
  static Future<List<CounterModel>> getUserCounters({
    required String staffId,
  }) async {
    try {
      final token = await _getToken();

      final url = "$baseUrl/$staffId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Failed to load counters");
      }

      final decoded = jsonDecode(response.body);

      List dataList = [];

      if (decoded is Map && decoded.containsKey("data")) {
        dataList = decoded["data"];
      } else if (decoded is List) {
        dataList = decoded;
      }

      print("dataList: $dataList");

      List<CounterModel> counters =
          dataList.map((e) => CounterModel.fromJson(e)).toList();

      return counters.where((counter) => counter.isActive == true).toList();
    } catch (e) {
      print("CounterService Error: $e");
      throw Exception("Error loading counters: $e");
    }
  }

  // ================= GET SERVICE NAME =================
  static Future<String> getServiceName(String serviceId) async {
    try {
      if (serviceId.isEmpty) {
        return "Unknown Service";
      }

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(Api_Config.getservice_name),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch services");
      }

      final decoded = jsonDecode(response.body);

      List services = [];

      if (decoded is Map && decoded.containsKey("data")) {
        services = decoded["data"];
      }

      final service = services.firstWhere(
        (s) => s["_id"] == serviceId,
        orElse: () => null,
      );

      if (service != null) {
        return service["name"] ?? "Unknown Service";
      }

      return "Unknown Service";
    } catch (e) {
      print("ServiceName Error: $e");
      return "Unknown Service";
    }
  }
}
