import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../auth/services/auth_storage.dart';
import '../../core/config/api_config.dart';
import '../../models/notification_model.dart';
import '../../services/socket_service.dart';

class NotificationService {
  final SocketService _socket = SocketService();

  /// 📥 Get Auth Headers
  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await AuthStorage.getValidAccessToken();
    if (token == null || token.isEmpty) return null;

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 📥 Get all notifications (API fallback + initial load)
  Future<List<NotificationModel>> fetchNotifications() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return [];

    final response = await http.get(
      Uri.parse(Api_Config.notifications),
      headers: headers,
    );

    print("🔥 STATUS notification: ${response.statusCode}");
    print("🔥 BODY notification: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];

      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }

    return [];
  }

  /// 🔴 Get unread count (badge)
  Future<int> getUnreadCount() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return 0;

    final response = await http.get(
      Uri.parse("${Api_Config.notifications}/unread-count"),
      headers: headers,
    );

    print("🔥 STATUS: ${response.statusCode}");
    print("🔥 BODY: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(response.body) as Map<String, dynamic>;

      print("🔥 PARSED BODY: $body");
      final int count = (body['unreadCount'] ?? 0);

      print("🔥 FINAL COUNT: $count");

      return count;
    }

    return 0;
  }

  /// 👁️ Mark ALL as read (API + SOCKET)
  Future<bool> markAsReadALL() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final response = await http.patch(
      Uri.parse("${Api_Config.notifications}/read-all"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // ✅ SOCKET TRIGGER (instant UI update)
      _socket.emit("notification", {
        "type": "READ_ALL",
      });
      return true;
    }

    return false;
  }

  /// ❌ Delete single notification (API + SOCKET)
  Future<bool> deleteNotification(String id, String type) async {
    if (id.isEmpty) {
      debugPrint("❌ EMPTY ID - BLOCKED DELETE");
      return false;
    }

    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final url = "${Api_Config.notifications}/$id?type=$type";

    debugPrint("🗑 DELETE URL: $url");

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // ✅ SOCKET UPDATE
      _socket.emit("notification", {
        "type": "DELETE_ONE",
        "data": {"notificationId": id}
      });
      return true;
    }

    return false;
  }

  /// ❌ Delete all notifications (API + SOCKET)
  Future<bool> deleteAllNotifications() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return false;

    final response = await http.delete(
      Uri.parse(Api_Config.notifications),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // ✅ SOCKET UPDATE
      _socket.emit("notification", {
        "type": "DELETE_ALL",
      });
      return true;
    }

    return false;
  }
}
