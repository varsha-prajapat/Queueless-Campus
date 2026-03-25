import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';
import '../../models/banner_model.dart';

class BannerService {
  /// ================= GET TOKEN =================
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  /// ================= FETCH BANNERS =================
  Future<List<BannerModel>> getBanners() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(Api_Config.banner),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List data;

      if (decoded is List) {
        data = decoded;
      } else {
        data = decoded["data"] ?? [];
      }

      return data.map((e) => BannerModel.fromJson(e)).toList();
    }

    throw Exception("Failed to load banners");
  }

  /// ================= CREATE BANNER =================
  Future<BannerModel> createBanner({
    required String title,
    required String description,
    required String role,
    String? departmentId,
    required bool isActive,
    required File imageFile,
  }) async {
    final token = await _getToken();

    var request = http.MultipartRequest(
      "POST",
      Uri.parse(Api_Config.banner),
    );

    request.headers['Authorization'] = "Bearer $token";

    request.fields['title'] = title.trim();
    request.fields['description'] = description.trim();
    request.fields['targetRole'] = role;
    request.fields['isActive'] = isActive.toString();

    /// ✅ SEND ALL DEPARTMENT
    if (departmentId == null || departmentId.isEmpty) {
      request.fields['departmentId'] = "ALL";
    } else {
      request.fields['departmentId'] = departmentId;
    }

    /// IMAGE
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final response = await request.send();

    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return BannerModel.fromJson(decoded['data']);
    }

    throw Exception(decoded['message'] ?? "Failed to create banner");
  }

  /// ================= UPDATE BANNER =================
  Future<BannerModel> updateBanner({
    required String id,
    required String title,
    required String description,
    required String role,
    String? departmentId,
    required bool isActive,
    File? imageFile,
  }) async {
    final token = await _getToken();

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("${Api_Config.banner}/$id"),
    );

    request.headers['Authorization'] = "Bearer $token";

    request.fields['title'] = title.trim();
    request.fields['description'] = description.trim();
    request.fields['targetRole'] = role;
    request.fields['isActive'] = isActive.toString();

    /// ✅ SEND ALL DEPARTMENT
    if (departmentId == null || departmentId.isEmpty) {
      request.fields['departmentId'] = "ALL";
    } else {
      request.fields['departmentId'] = departmentId;
    }

    /// IMAGE OPTIONAL
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
    }

    final response = await request.send();

    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body);

    if (response.statusCode == 200) {
      return BannerModel.fromJson(decoded['data']);
    }

    throw Exception(decoded['message'] ?? "Failed to update banner");
  }

  /// ================= DELETE BANNER =================
  Future<void> deleteBanner(String id) async {
    final token = await _getToken();

    final url = "${Api_Config.banner}/$id";

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    final decoded = jsonDecode(response.body);

    throw Exception(decoded['message'] ?? "Failed to delete banner");
  }
}
