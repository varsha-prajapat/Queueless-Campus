import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../shared/screens/settings_screen.dart';
import '../shared/screens/notification_screen.dart';
import '../../provider/notification_provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;

  static const Color primary = Color(0xFF1F5F5B);
  static const Color bgLight = Color(0xFFF6FAF9);

  bool _initialized = false;

  final List<Widget> screens = const [
    HomeScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.initSocketListener();

    _initialized = true;
  }

  void _handleTabChange(int newIndex) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    final previousIndex = index;

    setState(() {
      index = newIndex;
    });

    // ✅ FIX: CALL WHEN LEAVING NOTIFICATION SCREEN
    if (previousIndex == 1 && newIndex != 1) {
      await Future.delayed(const Duration(milliseconds: 200));
      provider.markAllAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unread = provider.unreadCount;

        return Scaffold(
          backgroundColor: bgLight,
          body: IndexedStack(
            index: index,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: _handleTabChange,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 10,
            selectedItemColor: primary,
            unselectedItemColor: Colors.grey.shade400,
            items: [
              _navItem(
                label: "Home",
                icon: Icons.dashboard_outlined,
                active: index == 0,
              ),
              _notificationItem(
                active: index == 1,
                count: unread,
              ),
              _navItem(
                label: "Settings",
                icon: Icons.settings_outlined,
                active: index == 2,
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _navItem({
    required String label,
    required IconData icon,
    required bool active,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
    );
  }

  BottomNavigationBarItem _notificationItem({
    required bool active,
    required int count,
  }) {
    String badgeText = "";

    if (count > 0 && count <= 5) {
      badgeText = count.toString();
    } else if (count > 5) {
      badgeText = "5+";
    }

    return BottomNavigationBarItem(
      label: "Alerts",
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active ? primary.withOpacity(0.12) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
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
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
