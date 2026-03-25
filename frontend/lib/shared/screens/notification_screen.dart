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

  StreamSubscription<List<dynamic>>? _notifSub;

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

    if (!SocketService().isConnected) {
      await SocketService().connect();
    }

    _notifSub?.cancel();

    _notifSub = SocketService().notifStream.listen((data) {
      if (!mounted) return;
      if (data.isEmpty) return;

      final newNotifs =
          data.map((json) => NotificationModel.fromJson(json)).where((n) {
        if (n.hiddenFor?.contains(userId) ?? false) return false;

        if (n.roles == null || n.roles!.isEmpty) return true;

        if (n.roles!.contains("ALL")) return true;

        if (userRole != null && n.roles!.contains(userRole)) return true;

        return false;
      }).toList();

      if (newNotifs.isEmpty) return;

      setState(() {
        for (var notif in newNotifs) {
          final index = notifications.indexWhere((n) => n.id == notif.id);

          if (index >= 0) {
            notifications[index] = notif;
          } else {
            notifications.insert(0, notif);
          }
        }
      });

      _setupExpiryTimers();
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
      debugPrint("Notification fetch error: $e");
    }

    setState(() => loading = false);
  }

  void _setupExpiryTimers() {
    for (var timer in _expiryTimers.values) {
      timer.cancel();
    }

    _expiryTimers.clear();

    final now = DateTime.now();

    for (var notif in notifications.toList()) {
      if (notif.expiresAt != null && notif.expiresAt!.isAfter(now)) {
        final diff = notif.expiresAt!.difference(now);

        _expiryTimers[notif.id] = Timer(diff, () {
          if (!mounted) return;

          setState(() {
            notifications.removeWhere((n) => n.id == notif.id);
          });

          _expiryTimers.remove(notif.id);
        });
      } else if (notif.expiresAt != null && notif.expiresAt!.isBefore(now)) {
        notifications.removeWhere((n) => n.id == notif.id);
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);

    if (success) {
      setState(() {
        notifications.removeWhere((n) => n.id == id);
      });

      _expiryTimers[id]?.cancel();
      _expiryTimers.remove(id);
    }
  }

  Future<void> _deleteAllNotifications() async {
    final success = await _service.deleteAllNotifications();

    if (success) {
      setState(() {
        notifications.clear();
      });

      for (var timer in _expiryTimers.values) {
        timer.cancel();
      }

      _expiryTimers.clear();
    }
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.read) return;

    final success = await _service.markAsRead(notif.id);

    if (success) {
      setState(() {
        notif.read = true;
      });
    }
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notif.id),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: notif.read ? Colors.grey[200] : Colors.white,
        child: ListTile(
          leading: const Icon(Icons.notifications, color: Color(0xFF1F5F5B)),
          title: Text(
            notif.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notif.message),
              if (notif.expiresAt != null)
                Text(
                  "Expires at: ${DateFormat('yyyy-MM-dd HH:mm').format(notif.expiresAt!)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          onTap: () => _markAsRead(notif),
          trailing: notif.read
              ? const Icon(Icons.done_all, color: Colors.green)
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel();

    for (var timer in _expiryTimers.values) {
      timer.cancel();
    }

    _expiryTimers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteAllNotifications,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _buildNotificationCard(notifications[index]),
                  ),
                ),
    );
  }
}
