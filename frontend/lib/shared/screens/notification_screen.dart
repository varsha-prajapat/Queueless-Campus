import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../utils/auth_role_helper.dart';
import '../../provider/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Map<String, Timer> _expiryTimers = {};

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

    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // ✅ ONLY FETCH DATA
    await provider.refresh();

    // ❌ REMOVED:
    // await provider.markAllAsRead();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void _setupExpiryTimers(List<NotificationModel> notifications) {
    for (var t in _expiryTimers.values) {
      t.cancel();
    }
    _expiryTimers.clear();

    final now = DateTime.now();

    for (var notif in notifications.toList()) {
      if (notif.expiresAt == null) continue;

      if (notif.expiresAt!.isBefore(now)) continue;

      final diff = notif.expiresAt!.difference(now);

      _expiryTimers[notif.id] = Timer(diff, () {
        if (!mounted) return;

        final provider =
            Provider.of<NotificationProvider>(context, listen: false);

        provider.refresh(); // only expiry update
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    await provider.deleteNotification(id, "SKIPPED");
  }

  Future<void> _deleteAllNotifications() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    await provider.deleteAll();
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final bool isRead = notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notif.id),
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
                  Text(
                    notif.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
    for (var t in _expiryTimers.values) {
      t.cancel();
    }
    _expiryTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;

        _setupExpiryTimers(notifications);

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
      },
    );
  }
}
