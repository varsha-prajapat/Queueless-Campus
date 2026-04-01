import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../provider/notification_provider.dart';
import '../../shared/screens/notification_screen.dart';
import '../../utils/auth_role_helper.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? role;
  bool _loaded = false;

  final Color darkGreen = const Color(0xFF0B6B3A);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final r = await AuthRoleHelper.getRole();

    if (!mounted) return;

    setState(() {
      role = r;
      _loaded = true;
    });
  }

  String _formatBadge(int count) {
    if (count <= 0) return "";
    if (count > 5) return "5+";
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unread = provider.unreadCount;
        final badgeText = _formatBadge(unread);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT SIDE
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.qr_code_rounded, color: Color(0xFF0B6B3A)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "QueueLess Campus",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF0B6B3A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE (NOTIFICATION)
              if (_loaded && role != "ADMIN")
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        color: darkGreen,
                      ),

                      // ✅ FIXED: mark read AFTER RETURN
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );

                        if (!mounted) return;

                        // 🔥 CALL AFTER COMING BACK
                        final provider = Provider.of<NotificationProvider>(
                          context,
                          listen: false,
                        );

                        await provider.markAllAsRead();
                      },
                    ),

                    // BADGE
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
