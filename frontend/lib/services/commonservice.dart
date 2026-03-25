import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/department_model.dart';
import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';

class DepartmentService {
  static const String baseUrl = Api_Config.commondepartment;

  // 🔐 Get VALID Token (Auto Refresh if Expired)
  Future<String?> _getToken() async {
    return await AuthStorage.getValidAccessToken();
  }

  // ================= GET ALL ACTIVE DEPARTMENTS =================
  Future<List<Department>> getDepartments() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        // no Authorization header needed
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body["data"] ?? [];
      final List<Department> allDepartments =
          data.map((e) => Department.fromJson(e)).toList();

      // Filter only ACTIVE departments
      return allDepartments
          .where((dept) => (dept.status ?? "").toLowerCase() == "active")
          .toList();
    } else {
      throw Exception(
        "Failed to load departments: ${response.statusCode}",
      );
    }
  }

  // ================= GET DEPARTMENT BY ID =================
  Future<Department?> getDepartmentById(String id) async {
    final token = await AuthStorage.getValidAccessToken(); // 🔑 get token
    if (token == null) throw Exception("No access token available");

    final response = await http.get(
      Uri.parse('${Api_Config.department_infor}/$id'),
      headers: {
        'Authorization': 'Bearer $token', // <-- send token
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Department.fromJson(data['data']); // adjust per your API
    } else {
      throw Exception(
          'Failed to fetch department by ID: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
