import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_storage.dart';
import '../../core/config/api_config.dart';
import '../../models/notification_model.dart';

class NotificationService {
  final String baseUrl = Api_Config.notifications;

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await AuthStorage.getValidAccessToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return [];

    final response = await http.get(Uri.parse(baseUrl), headers: headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'] ?? [];
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> deleteNotification(String id) async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final response =
        await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);
    return response.statusCode == 200;
  }

  Future<bool> deleteAllNotifications() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final response = await http.delete(Uri.parse(baseUrl), headers: headers);
    return response.statusCode == 200;
  }

  Future<bool> setAllExpiry(DateTime? expiresAt) async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final body = expiresAt != null
        ? {'expiresAt': expiresAt.toIso8601String()}
        : {'expiresAt': null};

    final response = await http.patch(
      Uri.parse('$baseUrl/expiry/all'),
      headers: headers,
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  Future<bool> markAsRead(String id) async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/$id/read'),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}
