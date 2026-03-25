import 'package:flutter/material.dart';

// Splash
import 'package:frontend/screens/splash_screen.dart';

// Auth
import 'package:frontend/auth/screens/login_screen.dart';
import 'package:frontend/auth/screens/register_screen.dart';
import 'package:frontend/auth/screens/otp_screen.dart';

// Bottom Nav Shell
import './bottom_nav.dart';

// Inner screens (opened on top of bottom nav)
import 'package:frontend/shared/widgets/access_manager_screen.dart';
import 'package:frontend/shared/screens/edit_profile_screen.dart';

class AppRoutes {
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ROUTE NAMES
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';

  // ✅ ROOT AFTER LOGIN
  static const String app = '/app';

  // inner pages
  static const String accessManager = '/access-manager';
  static const String edit = '/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case otp:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: args['email'],
            purpose: args['purpose'],
          ),
        );

      // ✅ BottomNav ROOT (Home + Settings)
      case app:
        return MaterialPageRoute(
          builder: (_) => const BottomNav(),
        );

      // 🔹 Opened ABOVE bottom nav
      case accessManager:
        return MaterialPageRoute(
          builder: (_) => const AccessManagerScreen(),
        );

      case edit:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}
