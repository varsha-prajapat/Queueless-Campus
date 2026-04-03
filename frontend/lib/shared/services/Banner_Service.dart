import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../models/banner_model.dart';
import '../../core/config/api_config.dart';
import '../../auth/services/auth_storage.dart';

class BannerService {
  static const String baseUrl = Api_Config.banner_all;

  // ================= GET TOKEN =================
  static Future<String> _getToken() async {
    final token = await AuthStorage.getValidAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return token;
  }

  // ================= GET BANNERS =================
  static Future<List<BannerModel>> getUserBanners({
    required String role,
    String? departmentId,
  }) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to load banners. Status code: ${response.statusCode}");
      }

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      final List<dynamic> dataList =
          decoded is List ? decoded : (decoded["data"] as List? ?? []);

      List<BannerModel> banners = dataList
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // ================= FILTER =================
      List<BannerModel> filtered = banners.where((banner) {
        // ✅ ACTIVE CHECK
        if (banner.isActive != true) {
          return false;
        }

        // ================= ROLE MATCH =================
        final String userRole = role.toUpperCase();
        final String bannerRole = banner.targetRole.trim().toUpperCase();

        final bool roleMatch = bannerRole == "ALL" || bannerRole == userRole;

        // ================= DEPARTMENT CLEAN =================
        final String? userDept = (departmentId == null ||
                departmentId.trim().isEmpty ||
                departmentId.trim().toLowerCase() == "null")
            ? null
            : departmentId.trim();

        final String? bannerDept =
            (banner.departmentId == null || banner.departmentId!.trim().isEmpty)
                ? null
                : banner.departmentId!.trim();

        // ================= DEPARTMENT MATCH =================
        bool departmentMatch;

        if (bannerDept == null) {
          // ✅ GLOBAL BANNER
          departmentMatch = true;
        } else if (userDept == null) {
          // ❌ user has no department
          departmentMatch = false;
        } else {
          departmentMatch = bannerDept == userDept;
        }

        final bool finalMatch = roleMatch && departmentMatch;

        return finalMatch;
      }).toList();

      return filtered;
    } catch (e) {
      throw Exception("Error loading banners: $e");
    }
  }

  // ================= HELPERS =================
  static Future<List<BannerModel>> getStaffBanners(String departmentId) async {
    return getUserBanners(role: "STAFF", departmentId: departmentId);
  }

  static Future<List<BannerModel>> getStudentBanners(
      String departmentId) async {
    return getUserBanners(role: "STUDENT", departmentId: departmentId);
  }
}
