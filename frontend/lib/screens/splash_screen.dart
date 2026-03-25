import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../auth/services/auth_storage.dart';
import '../core/constants/app_constants.dart';
import '../provider/profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final loggedIn = await AuthStorage.isLoggedIn();
    if (!mounted) return;

    /// 🔥 If already logged in → fetch profile
    if (loggedIn) {
      await context.read<ProfileProvider>().fetchProfile();
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      loggedIn ? AppRoutes.app : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgTop,
              AppColors.bgBottom,
              Colors.white,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔳 QR LOGO (BUILT-IN ICON)
            Icon(
              Icons.qr_code_rounded,
              size: 88,
              color: AppColors.primary,
            ),

            const SizedBox(height: 26),

            /// 🏷 TITLE
            const Text(
              "Queueless Campus",
              style: AppTextStyles.appTitle,
            ),

            const SizedBox(height: 10),

            /// ✨ SUBTITLE
            const Text(
              "Smart queue management",
              style: AppTextStyles.linkBase,
            ),

            const SizedBox(height: 40),

            /// • DOT LOADER
            Text(
              "•",
              style: TextStyle(
                fontSize: 26,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
