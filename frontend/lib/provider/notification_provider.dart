import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/socket_service.dart';
import '../models/notification_model.dart';
import '../shared/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  final NotificationService _api = NotificationService();

  List<NotificationModel> notifications = [];
  int unreadCount = 0;

  StreamSubscription? _notifSub;

  // ✅ INTERNAL SAFE FLAG
  bool _isInitialized = false;

  // ----------------- INIT (ADD THIS) -----------------
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await refresh(); // 🔥 load old unread + notifications first

    initSocketListener(); // 🔥 then start socket listener
  }

  // ----------------- SOCKET LISTENER -----------------
  void initSocketListener() {
    _notifSub ??= _socketService.notifStream.listen((data) async {
      if (data == null) return;

      print("📩 SOCKET EVENT: $data");

      final type = data['type'];

      if (type == null) {
        await refresh();
        return;
      }

      switch (type) {
        // ---------------- NEW NOTIFICATION ----------------
        case 'notification:new':
          unreadCount++;
          notifyListeners();
          break;

        // ---------------- SINGLE READ ----------------
        case 'notification:read':
          unreadCount = (unreadCount > 0) ? unreadCount - 1 : 0;
          notifyListeners();
          break;

        // ---------------- MARK ALL READ ----------------
        case 'notification:read_all':
          unreadCount = 0;
          notifyListeners();
          break;

        // ---------------- DELETE ----------------
        case 'notification:delete':
        case 'notification:delete_all':
          await refresh();
          break;

        default:
          await refresh();
          break;
      }
    });
  }

  // ----------------- REFRESH -----------------
  Future<void> refresh() async {
    try {
      await Future.wait([
        fetchNotifications(),
        fetchUnreadCount(),
      ]);

      notifyListeners();
    } catch (e) {
      print("⚠️ refresh error: $e");
    }
  }

  // ----------------- FETCH NOTIFICATIONS -----------------
  Future<void> fetchNotifications() async {
    try {
      final res = await _api.fetchNotifications();
      notifications = res;
    } catch (e) {
      print("⚠️ fetchNotifications error: $e");
    }
  }

  // ----------------- FETCH UNREAD -----------------
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      unreadCount = count;

      print("📊 Unread Count: $unreadCount");
    } catch (e) {
      print("⚠️ fetchUnreadCount error: $e");
    }
  }

  // ----------------- MARK ALL READ -----------------
  Future<void> markAllAsRead() async {
    try {
      await _api.markAsReadALL();

      // 🔥 just refresh everything properly
      await refresh();
    } catch (e) {
      print("⚠️ markAllAsRead error: $e");
    }
  }

  // ----------------- DELETE ONE -----------------
  Future<void> deleteNotification(String id, String type) async {
    try {
      await _api.deleteNotification(id, type);
      await refresh();
    } catch (e) {
      print("⚠️ deleteNotification error: $e");
    }
  }

  // ----------------- DELETE ALL -----------------
  Future<void> deleteAll() async {
    try {
      await _api.deleteAllNotifications();

      unreadCount = 0;
      notifyListeners();

      await refresh();
    } catch (e) {
      print("⚠️ deleteAll error: $e");
    }
  }

  // ----------------- DISPOSE -----------------
  @override
  void dispose() {
    _notifSub?.cancel();
    _isInitialized = false;
    super.dispose();
  }
}
