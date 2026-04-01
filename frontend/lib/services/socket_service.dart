import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // ----------------- Singleton -----------------
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // ----------------- STREAMS -----------------
  final StreamController<Map<String, dynamic>> _notifController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notifStream => _notifController.stream;

  final StreamController<Map<String, dynamic>> _tokenController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tokenStream => _tokenController.stream;

  Timer? _notifDebounce;

  // ----------------- USER INFO -----------------
  String? userId;
  List<String>? roles;
  List<String>? counters;

  bool _initialized = false;

  // ----------------- SERVER URL -----------------
  String get _serverUrl {
    // ❗ FIXED: localhost is WRONG for Android emulator
    if (Platform.isAndroid) return 'http://localhost:3005';
    if (Platform.isIOS) return 'http://localhost:3005';
    return 'http://localhost:3005';
  }

  bool get isConnected => socket?.connected ?? false;

  // ----------------- INIT -----------------
  void init({
    required String userId,
    required List<String> roles,
    List<String>? counters,
  }) {
    this.userId = userId;
    this.roles = roles;
    this.counters = counters;
  }

  // ----------------- CONNECT -----------------
  Future<void> connect() async {
    if (_initialized && socket?.connected == true) return;
    _initialized = true;

    if (userId == null || roles == null) {
      print('⚠️ SocketService: init() not called');
      return;
    }

    socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setQuery({
            'userId': userId!,
            'roles': roles!.join(','),
          })
          .build(),
    );

    // ----------------- CONNECT EVENT -----------------
    socket!.onConnect((_) {
      print("✅ Socket connected: ${socket!.id}");

      socket?.emit('joinRoom', userId);

      if (roles!.contains('staff') && counters != null) {
        for (var counterId in counters!) {
          socket?.emit('joinRoom', 'role_COUNTER_$counterId');
        }
      }

      // ❗ FIX: register ALL listeners here (important)
      _registerNotificationListeners();
      _registerTokenListeners();
    });

    socket!.onDisconnect((reason) {
      print("❌ Disconnected: $reason");
    });

    socket!.onError((err) {
      print("⚠️ Socket error: $err");
    });

    socket!.on('ping', (_) => socket?.emit('pong'));
  }

  // ----------------- NOTIFICATION EVENTS FIXED -----------------
  void _registerNotificationListeners() {
    final events = [
      'notification:new',
      'notification:read',
      'notification:read_all',
      'notification:delete',
      'notification:delete_all',
    ];

    for (var event in events) {
      socket?.off(event);

      socket?.on(event, (data) {
        if (data == null) return;

        try {
          final notif = Map<String, dynamic>.from(data);

          print("🔔 $event => $notif");

          if (!_notifController.isClosed) {
            _notifController.add(notif);
          }
        } catch (e) {
          print("⚠️ Notification parse error ($event): $e");
        }
      });
    }
  }

  // ----------------- TOKEN EVENTS -----------------
  void _registerTokenListeners() {
    final tokenEvents = [
      'token:update',
      'token:created',
      'token:paymentConfirmed',
      'token:cancelled',
      'token:called',
      'token:completed',
      'token:skipped',
    ];

    for (var event in tokenEvents) {
      socket?.off(event);

      socket?.on(event, (data) {
        if (data == null) return;

        try {
          final normalized = Map<String, dynamic>.from(data);

          print("📡 $event => $normalized");

          if (!_tokenController.isClosed) {
            _tokenController.add(normalized);
          }
        } catch (e) {
          print("⚠️ Token parse error ($event): $e");
        }
      });
    }
  }

  // ----------------- HELPERS -----------------
  void on(String event, Function(dynamic) callback) {
    socket?.off(event);
    socket?.on(event, callback);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void off(String event) {
    socket?.off(event);
  }

  // ----------------- DISPOSE -----------------
  void dispose() {
    _notifDebounce?.cancel();

    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;

    _initialized = false;

    if (!_notifController.isClosed) _notifController.close();
    if (!_tokenController.isClosed) _tokenController.close();
  }
}
