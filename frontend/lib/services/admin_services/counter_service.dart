import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';
import '../../models/counter_model.dart';

class CounterService {
  // ================= GET TOKEN =================
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  // ================= GET COUNTERS =================
  static Future<List<CounterModel>> getCounters() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse(Api_Config.counter),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch counters: ${res.body}");
    }

    final data = jsonDecode(res.body);

    return (data['data'] ?? [])
        .map<CounterModel>((e) => CounterModel.fromJson(e))
        .toList();
  }

  // ================= FETCH ACTIVE SERVICES =================
  static Future<List<Map<String, dynamic>>> fetchActiveServices() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse(Api_Config.service_active),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch active services");
    }

    final data = jsonDecode(res.body);

    return (data['data'] ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ================= FETCH ALL SERVICES =================
  static Future<List<Map<String, dynamic>>> fetchAllServices() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse(Api_Config.service),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch services");
    }

    final data = jsonDecode(res.body);

    return (data['data'] ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ================= FETCH STAFF BY DEPARTMENT =================
  static Future<List<Map<String, dynamic>>> fetchStaffByDepartment(
      String departmentId) async {
    if (departmentId.isEmpty) return [];

    final token = await _getToken();

    final res = await http.get(
      Uri.parse("${Api_Config.staff_department}/$departmentId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch staff");
    }

    final decoded = jsonDecode(res.body);

    return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
  }

  // ================= VALIDATE STAFF =================
  static Future<void> _validateStaff({
    required String serviceId,
    required List<String> staffIds,
    String? currentCounterId,
  }) async {
    final counters = await getCounters();
    final services = await fetchAllServices(); // 👈 ALL SERVICES

    final service = services.firstWhere(
      (s) => s['_id'].toString() == serviceId,
      orElse: () => {},
    );

    if (service.isEmpty) {
      throw Exception("Service not found");
    }

    /// CHECK SERVICE PAUSED
    if (service['isPaused'] == true) {
      throw Exception("Service is paused. Cannot assign counter.");
    }

    final serviceDepartment = service['departmentId'] is Map
        ? service['departmentId']['_id'].toString()
        : service['departmentId']?.toString();

    if (serviceDepartment == null) {
      throw Exception("Service department not found");
    }

    final staffList = await fetchStaffByDepartment(serviceDepartment);

    for (String staffId in staffIds) {
      final staff = staffList.firstWhere(
        (s) => s['_id'].toString() == staffId,
        orElse: () => {},
      );

      if (staff.isEmpty) {
        throw Exception("Staff not found");
      }

      final staffDepartment = staff['departmentId'] is Map
          ? staff['departmentId']['_id'].toString()
          : staff['departmentId']?.toString();

      if (staffDepartment != serviceDepartment) {
        throw Exception("${staff['name'] ?? 'Staff'} department mismatch");
      }

      /// STAFF ALREADY ASSIGNED
      for (var counter in counters) {
        if (currentCounterId != null && counter.id == currentCounterId) {
          continue;
        }

        if (counter.staffIds.contains(staffId)) {
          throw Exception(
              "${staff['name'] ?? 'Staff'} already assigned to another counter");
        }
      }
    }
  }

  // ================= CREATE COUNTER =================
  static Future<void> createCounter({
    required String name,
    required String serviceId,
    required List<String> staffIds,
    required bool isActive,
  }) async {
    await _validateStaff(
      serviceId: serviceId,
      staffIds: staffIds,
    );

    final token = await _getToken();

    final res = await http.post(
      Uri.parse(Api_Config.counter),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name.trim(),
        "serviceId": serviceId,
        "staffIds": staffIds,
        "isActive": isActive,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to create counter");
    }
  }

  // ================= UPDATE COUNTER =================
  static Future<void> updateCounter({
    required String id,
    required String name,
    required String serviceId,
    required List<String> staffIds,
    required bool isActive,
  }) async {
    await _validateStaff(
      serviceId: serviceId,
      staffIds: staffIds,
      currentCounterId: id,
    );

    final token = await _getToken();

    final res = await http.put(
      Uri.parse("${Api_Config.counter}/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name.trim(),
        "serviceId": serviceId,
        "staffIds": staffIds,
        "isActive": isActive,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update counter");
    }
  }

  // ================= DELETE COUNTER =================
  static Future<void> deleteCounter(String id) async {
    final token = await _getToken();

    final res = await http.delete(
      Uri.parse("${Api_Config.counter}/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to delete counter");
    }
  }
}
