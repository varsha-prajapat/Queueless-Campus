import 'package:flutter/material.dart';
import '../screens/home/widgets/sections/admin_section.dart';
import '../shared/widgets/home_header.dart';
import '../shared/widgets/role_welcome.dart';
import '../../services/user_service.dart';
import '../../services/socket_service.dart';
import '../../auth/services/auth_storage.dart';
import '../../models/user_model.dart';
import '../screens/home/widgets/sections/staff_section.dart';
import '../screens/home/widgets/sections/student_section.dart';
import "../provider/notification_provider.dart";
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<UserModel> _future;
  @override
  void initState() {
    super.initState();
    _future = _init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).init();
    });
  }

  Future<UserModel> _init() async {
    final token = await AuthStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final user = await UserService.getMe();

    final socket = SocketService();

    // ✅ MOST IMPORTANT LINE
    socket.init(
      userId: user.id,
      roles: [user.role.toUpperCase()], // MUST BE UPPERCASE
    );

    // ✅ then connect
    if (!socket.isConnected) {
      await socket.connect();
    }

    return user;
  }

  // 🔁 Called from BottomNav if needed
  void loadProfile() {
    setState(() {
      _future = _init();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Role based section
  Widget _buildRoleSection(UserModel user) {
    switch (user.role) {
      case 'ADMIN':
        return const AdminSection();

      case 'STAFF':
        return StaffSection(
          departmentId: user.departmentId ?? "",
          staffId: user.id,
        );

      case 'STUDENT':
        return StudentSection(
          departmentId: user.departmentId ?? "",
        );

      default:
        return const Center(child: Text("Invalid role"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _future,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            final user = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: RoleWelcome(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildRoleSection(user),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
