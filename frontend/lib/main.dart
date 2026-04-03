import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';

import './provider/profile_provider.dart';
import './provider/TokenProvider.dart';
import './provider/notification_provider.dart';

import "./services/socket_service.dart";
import 'routes/app_routes.dart';
import "./utils/auth_role_helper.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------- USER DATA -----------------
  final userId = await AuthRoleHelper.getUserId();
  final rolesString = await AuthRoleHelper.getRole();

  final roles =
      rolesString.contains(',') ? rolesString.split(',') : [rolesString];

  // ----------------- SOCKET INIT (GLOBAL ONLY) -----------------
  final socketService = SocketService();

  socketService.init(
    userId: userId,
    roles: roles.map((e) => e.toUpperCase()).toList(),
  );

  await socketService.connect();

  runApp(const MyApp());
}

// =======================================================
// APP ROOT
// =======================================================
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

  // ----------------- DEEP LINKS -----------------
  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      _handleUri(initialUri);

      _linkSub = _appLinks.uriLinkStream.listen(
        (Uri uri) => _handleUri(uri),
        onError: (err) {},
      );
    } catch (e) {}
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;

    if (uri.scheme == 'queueless' &&
        uri.host == 'app' &&
        uri.path == '/login') {
      AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // =======================================================
  // BUILD
  // =======================================================
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

        // ----------------- NOTIFICATION PROVIDER -----------------
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..init(), // 🔥 IMPORTANT FIX
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
