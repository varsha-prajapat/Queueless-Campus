import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../shared/screens/settings_screen.dart';
import '../shared/screens/notification_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;
  int unreadCount = 3;

  static const Color primary = Color(0xFF1F5F5B);
  static const Color bgLight = Color(0xFFF6FAF9);

  final List<Widget> screens = const [
    HomeScreen(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            setState(() {
              index = i;
              if (i == 1) unreadCount = 0;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            _navItem(
              label: "Home",
              icon: Icons.dashboard_outlined,
              active: index == 0,
            ),
            _notificationItem(
              active: index == 1,
              count: unreadCount,
            ),
            _navItem(
              label: "Settings",
              icon: Icons.settings_outlined,
              active: index == 2,
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Standard nav item
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

  // 🔔 Notification item with badge
  BottomNavigationBarItem _notificationItem({
    required bool active,
    required int count,
  }) {
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
                  count.toString(),
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
