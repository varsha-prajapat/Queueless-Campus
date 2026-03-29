import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';
import '../../services/socket_service.dart';
import '../services/notification_service.dart';
import '../../utils/auth_role_helper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();

  final List<NotificationModel> notifications = [];
  final Map<String, Timer> _expiryTimers = {};

  StreamSubscription<Map<String, dynamic>>? _notifSub;

  bool loading = true;
  String? userId;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    userId = await AuthRoleHelper.getUserId();
    userRole = await AuthRoleHelper.getRole();

    await _fetchNotifications();

    // ✅ SAFE SOCKET CONNECT
    if (!SocketService().isConnected) {
      await SocketService().connect();
    }

    // ✅ FIX: avoid multiple listeners
    await _notifSub?.cancel();

    _notifSub = SocketService().notifStream.listen((data) {
      if (!mounted) return;

      try {
        final notif = NotificationModel.fromJson(data);

        // ---------------- FILTER ----------------
        if (notif.hiddenFor?.contains(userId) ?? false) return;

        if (notif.roles != null && notif.roles!.isNotEmpty) {
          if (!notif.roles!.contains("ALL")) {
            if (userRole == null || !notif.roles!.contains(userRole)) {
              return;
            }
          }
        }

        // ---------------- UPDATE LIST ----------------
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notif.id);

          if (index >= 0) {
            notifications[index] = notif;
          } else {
            notifications.insert(0, notif);
          }
        });

        _setupExpiryTimers();
      } catch (e) {
        debugPrint("❌ Socket parse error: $e");
      }
    });
  }

  Future<void> _fetchNotifications() async {
    setState(() => loading = true);

    try {
      final fetched = await _service.fetchNotifications();

      if (!mounted) return;

      final filtered = fetched.where((n) {
        if (n.hiddenFor?.contains(userId) ?? false) return false;

        if (n.roles == null || n.roles!.isEmpty) return true;
        if (n.roles!.contains("ALL")) return true;
        if (userRole != null && n.roles!.contains(userRole)) return true;

        return false;
      }).toList();

      setState(() {
        notifications
          ..clear()
          ..addAll(filtered);
      });

      _setupExpiryTimers();
    } catch (e) {
      debugPrint("❌ Notification fetch error: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void _setupExpiryTimers() {
    for (var t in _expiryTimers.values) {
      t.cancel();
    }
    _expiryTimers.clear();

    final now = DateTime.now();

    for (var notif in notifications.toList()) {
      if (notif.expiresAt == null) continue;

      if (notif.expiresAt!.isBefore(now)) {
        notifications.removeWhere((n) => n.id == notif.id);
        continue;
      }

      final diff = notif.expiresAt!.difference(now);

      _expiryTimers[notif.id] = Timer(diff, () {
        if (!mounted) return;

        setState(() {
          notifications.removeWhere((n) => n.id == notif.id);
        });

        _expiryTimers.remove(notif.id);
      });
    }
  }

  Future<void> _deleteNotification(String id, {String type = "SKIPPED"}) async {
    final success = await _service.deleteNotification(id, type);

    if (success && mounted) {
      setState(() {
        notifications.removeWhere((n) => n.id == id);
      });

      _expiryTimers[id]?.cancel();
      _expiryTimers.remove(id);
    }
  }

  Future<void> _deleteAllNotifications() async {
    final success = await _service.deleteAllNotifications();

    if (success && mounted) {
      setState(() => notifications.clear());

      for (var t in _expiryTimers.values) {
        t.cancel();
      }
      _expiryTimers.clear();
    }
  }

  // ================= UI (UNCHANGED) =================

  Widget _buildNotificationCard(NotificationModel notif) {
    final bool isRead = notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notif.id, type: "SKIPPED"),
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(notif.message),
                  if (notif.expiresAt != null)
                    Text(
                      "Expires: ${DateFormat('MMM d, HH:mm').format(notif.expiresAt!)}",
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              size: 18,
              color: isRead ? Colors.blue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel();

    for (var t in _expiryTimers.values) {
      t.cancel();
    }

    _expiryTimers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteAllNotifications,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _buildNotificationCard(notifications[i]),
                ),
    );
  }
}
