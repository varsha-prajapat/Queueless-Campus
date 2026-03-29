import 'package:flutter/material.dart';
import '../shared/services/notification_service.dart';
import '../services/socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  final SocketService _socket = SocketService();

  int unreadCount = 0;
  bool _socketInitialized = false;

  List<dynamic> notifications = [];

  // ----------------- CONSTRUCTOR -----------------
  NotificationProvider() {
    _init(); // 🔥 AUTO START EVERYTHING
  }

  // ----------------- INIT -----------------
  Future<void> _init() async {
    await fetchUnread(); // 🔥 load badge first
    await fetchNotifications(); // optional list load
    _initSocket(); // 🔥 real-time updates
  }

  // ----------------- SOCKET LISTENER -----------------
  void _initSocket() {
    if (_socketInitialized) return;
    _socketInitialized = true;

    _socket.notifStream.listen((data) {
      print("📡 SOCKET NOTIF: $data");

      // add new notification
      notifications.insert(0, data);

      // increase unread badge
      unreadCount++;

      notifyListeners();
    });
  }

  // ----------------- FETCH ALL NOTIFICATIONS -----------------
  Future<void> fetchNotifications() async {
    try {
      final data = await _service.fetchNotifications();

      notifications = data;
      notifyListeners();
    } catch (e) {
      print("❌ fetchNotifications error: $e");
    }
  }

  // ----------------- FETCH UNREAD COUNT -----------------
  Future<void> fetchUnread() async {
    try {
      unreadCount = await _service.getUnreadCount();

      print("📥 Unread loaded: $unreadCount");

      notifyListeners();
    } catch (e) {
      print("❌ fetchUnread error: $e");
    }
  }

  // ----------------- MARK ALL READ -----------------
  Future<void> markAllRead() async {
    final success = await _service.markAsReadALL();

    if (success) {
      unreadCount = 0;

      // mark all local as read
      for (var n in notifications) {
        n['read'] = true;
      }

      notifyListeners();
    }
  }

  // ----------------- MANUAL INCREASE (DEBUG) -----------------
  void increase() {
    unreadCount++;
    notifyListeners();
  }

  // ----------------- RESET -----------------
  void reset() {
    unreadCount = 0;
    notifyListeners();
  }
}
