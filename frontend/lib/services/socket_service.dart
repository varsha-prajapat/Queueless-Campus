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

  final StreamController<Map<String, dynamic>> _adminController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get adminStream => _adminController.stream;

  Timer? _notifDebounce;

  // ----------------- USER INFO -----------------
  String? userId;
  List<String>? roles;
  List<String>? counters;

  bool _initialized = false;

  // ----------------- SERVER URL -----------------
  String get _serverUrl {
    if (Platform.isAndroid) return 'http://localhost:3005'; // emulator
    return 'http://192.168.1.100:3005'; // 🔁 change to your PC IP
  }

  bool get isConnected => socket?.connected ?? false;

  // ----------------- INIT -----------------
  void init({
    required String userId,
    required List<String> roles,
    List<String>? counters,
  }) {
    // 🔥 USER CHANGE → CLEAN OLD SOCKET
    if (this.userId != null && this.userId != userId) {
      _forceDisposeSocket();
    }

    this.userId = userId;
    this.roles = roles;
    this.counters = counters;
  }

  // ----------------- CONNECT -----------------
  Future<void> connect() async {
    if (userId == null || roles == null) return;

    // 🔥 Prevent duplicate connection
    if (isConnected) {
      print("⚠️ Socket already connected");
      return;
    }

    // 🔥 Clean old socket
    _forceDisposeSocket();

    _initialized = true;

    socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setQuery({
            'userId': userId!,
            'roles': roles!.join(','),
          })
          .build(),
    );

    socket!.connect();

    // ----------------- CONNECT -----------------
    socket!.onConnect((_) {
      print("✅ Socket Connected: $userId");

      // 👤 user room
      socket?.emit('joinRoom', 'user_$userId');

      // 👥 role rooms
      for (var role in roles!) {
        socket?.emit('joinRoom', 'role_$role');
      }

      // 🧑‍💼 staff counters
      if (roles!.contains('STAFF') && counters != null) {
        for (var counterId in counters!) {
          socket?.emit('joinRoom', 'counter_$counterId');
        }
      }

      // listeners
      _registerNotificationListeners();
      _registerTokenListeners();
      _registerAdminListeners();
    });

    socket!.onDisconnect((reason) {
      print("❌ Socket Disconnected: $reason");
    });

    socket!.onError((err) {
      print("⚠️ Socket Error: $err");
    });

    socket!.on('ping', (_) => socket?.emit('pong'));
  }

  // ----------------- NOTIFICATION -----------------
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
          if (!_notifController.isClosed) {
            _notifController.add(notif);
          }
        } catch (_) {}
      });
    }
  }

  // ----------------- TOKEN -----------------
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
          if (!_tokenController.isClosed) {
            _tokenController.add(normalized);
          }
        } catch (_) {}
      });
    }
  }

  // ----------------- ADMIN -----------------
  void _registerAdminListeners() {
    const event = 'admin:queue:update';

    socket?.off(event);

    socket?.on(event, (data) {
      if (data == null) return;

      try {
        final adminData = Map<String, dynamic>.from(data);
        if (!_adminController.isClosed) {
          _adminController.add(adminData);
        }
      } catch (_) {}
    });
  }

  // ----------------- HELPERS -----------------
  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    socket?.off(event);
    socket?.on(event, callback);
  }

  void off(String event) {
    socket?.off(event);
  }

  // ----------------- FORCE CLEAN -----------------
  void _forceDisposeSocket() {
    if (socket != null) {
      socket!.clearListeners();
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
  }

  // ----------------- LOGOUT -----------------
  void dispose() {
    _notifDebounce?.cancel();

    _forceDisposeSocket();

    // 🔥 IMPORTANT RESET (fixes role bug)
    userId = null;
    roles = null;
    counters = null;

    _initialized = false;
  }
}
