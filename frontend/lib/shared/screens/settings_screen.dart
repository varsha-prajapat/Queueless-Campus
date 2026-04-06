import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/access_manager_screen.dart';
import '../../shared/screens/edit_profile_screen.dart';
import '../../utils/auth_role_helper.dart';
import '../../auth/services/auth_storage.dart';
import '../../auth/screens/login_screen.dart';
import '../../provider/profile_provider.dart';
import '../../services/socket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final admin = await AuthRoleHelper.isAdmin();
    if (!mounted) return;
    setState(() => isAdmin = admin);
  }

  Future<void> _logout() async {
    try {
      /// 🔥 SOCKET DISCONNECT (IMPORTANT)
      SocketService().dispose();
    } catch (_) {}

    /// 🔑 Clear tokens
    await AuthStorage.clear();

    if (!mounted) return;

    /// 🔥 Clear profile provider data
    context.read<ProfileProvider>().clearProfile();

    /// Navigate to login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          /// 👤 Profile Avatar
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFEDE9FE),
            child: Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF5B21B6),
            ),
          ),

          const SizedBox(height: 32),

          /// ✏️ Edit Profile
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text("Edit Profile"),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),

          /// 🔐 Admin-only
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text("Access Manager"),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccessManagerScreen(),
                  ),
                );
              },
            ),

          const Spacer(),

          /// 🚪 Logout
          ListTile(
            leading: const Icon(
              Icons.logout_outlined,
              color: Color(0xFF6B7280),
            ),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _logout,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
