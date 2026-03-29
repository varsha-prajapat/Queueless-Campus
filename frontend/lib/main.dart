import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';

import './provider/profile_provider.dart';
import './provider/TokenProvider.dart';
import './provider/notification_provider.dart'; // ✅ ADDED FIX

import "./services/socket_service.dart";
import 'routes/app_routes.dart';
import "./utils/auth_role_helper.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch user info
  final userId = await AuthRoleHelper.getUserId();
  final rolesString = await AuthRoleHelper.getRole();
  final roles =
      rolesString.contains(',') ? rolesString.split(',') : [rolesString];

  print("🚀 App starting with userId: $userId, roles: $roles");

  // Initialize global socket service
  final socketService = SocketService();
  socketService.init(userId: userId, roles: roles);

  // Connect once globally
  await socketService.connect();
  print("✅ Socket connected globally");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      _handleUri(initialUri);

      _linkSub = _appLinks.uriLinkStream.listen(
        (Uri uri) => _handleUri(uri),
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );
      print("✅ Deep link listener initialized");
    } catch (e) {
      debugPrint('Failed to init deep links: $e');
    }
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;

    debugPrint('🔗 Deep link received: $uri');

    if (uri.scheme == 'queueless' &&
        uri.host == 'app' &&
        uri.path == '/login') {
      AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
      print("➡ Navigated to login via deep link");
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
    print("🛑 App disposed, deep link subscription cancelled");
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => TokenProvider(),
        ),

        // ✅ FIXED: NotificationProvider added
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: AppRoutes.navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
