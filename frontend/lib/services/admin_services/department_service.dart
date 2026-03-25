import 'dart:convert';
import 'package:http/http.dart' as http;
import "../../auth/services/auth_storage.dart";
import '../../models/department_model.dart';
import "../../core/config/api_config.dart";

class DepartmentService {
  static const String baseUrl = Api_Config.department;

  // 🔐 Get VALID Token
  Future<String?> _getToken() async {
    return await AuthStorage.getValidAccessToken();
  }

  // ==============================
  // ✅ GET ALL DEPARTMENTS
  // ==============================
  Future<List<Department>> getDepartments() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    print("GET URL: $baseUrl");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("GET Status: ${response.statusCode}");
    print("GET Body: ${response.body}");

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      final List data = body["data"] ?? [];

      return data.map((e) => Department.fromJson(e)).toList();
    } else {
      throw Exception(
        "Failed to load departments: ${response.statusCode}",
      );
    }
  }

  // ==============================
  // ✅ CREATE DEPARTMENT
  // ==============================
  Future<void> createDepartment(String name, String status) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    print("POST URL: $baseUrl");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "status": status,
      }),
    );

    print("POST Status: ${response.statusCode}");
    print("POST Body: ${response.body}");

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        "Failed to create department: ${response.statusCode}",
      );
    }
  }

  // ==============================
  // ✅ UPDATE DEPARTMENT
  // ==============================
  Future<void> updateDepartment(
    String id,
    String name,
    String status,
  ) async {
    print("Updating ID: $id");
    final token = await _getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    if (id.isEmpty) {
      throw Exception("Department ID is missing");
    }

    final updateUrl = "$baseUrl/$id";

    print("PUT URL: $updateUrl");
    print("Updating ID: $id");

    final response = await http.put(
      Uri.parse(updateUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "status": status,
      }),
    );

    print("PUT Status: ${response.statusCode}");
    print("PUT Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to update department: ${response.statusCode}",
      );
    }
  }

  // ==============================
  // ✅ DELETE DEPARTMENT
  // ==============================
  Future<void> deleteDepartment(String id) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    if (id.isEmpty) {
      throw Exception("Department ID is missing");
    }

    final deleteUrl = "$baseUrl/$id";

    print("DELETE URL: $deleteUrl");

    final response = await http.delete(
      Uri.parse(deleteUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete department: ${response.statusCode}",
      );
    }
  }
}
