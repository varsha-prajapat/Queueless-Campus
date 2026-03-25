import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../utils/auth_role_helper.dart';
import '../../../services/socket_service.dart';
import '../../../provider/profile_provider.dart';

class RoleWelcome extends StatefulWidget {
  const RoleWelcome({super.key});

  @override
  State<RoleWelcome> createState() => _RoleWelcomeState();
}

class _RoleWelcomeState extends State<RoleWelcome> {
  String role = "";

  @override
  void initState() {
    super.initState();
    _loadRole();

    // Fetch profile on widget init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });

    _initSocketListener();
  }

  Future<void> _loadRole() async {
    final r = await AuthRoleHelper.getRole();
    if (!mounted) return;
    setState(() {
      role = r;
    });
  }

  void _initSocketListener() async {
    if (!SocketService().isConnected) {
      await SocketService().connect();
    }

    SocketService().socket?.off('userUpdated');

    SocketService().socket?.on('userUpdated', (_) {
      _loadRole(); // refresh role
      context.read<ProfileProvider>().fetchProfile(); // refresh profile
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'STAFF':
        return 'Staff Member';
      case 'STUDENT':
        return 'Student';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final name = profile.name;
        final department = profile.department;

        // Show loading until role and name are ready
        if (role.isEmpty || name.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $name",
              style: AppTextStyles.appTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _roleLabel(role),
              style: AppTextStyles.linkAction.copyWith(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (department.isNotEmpty &&
                department.toLowerCase() != "no department") ...[
              const SizedBox(height: 2),
              Text(
                department,
                style: AppTextStyles.linkAction.copyWith(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
