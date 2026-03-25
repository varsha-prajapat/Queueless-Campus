import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Singleton
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // Streams
  final StreamController<List<dynamic>> _notifController =
      StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get notifStream => _notifController.stream;

  final StreamController<Map<String, dynamic>> _tokenController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tokenStream => _tokenController.stream;

  Timer? _notifDebounce;

  // User info
  String? userId;
  List<String>? roles;
  List<String>? counters; // staff counter IDs

  // Server URL
  String get _serverUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:3005'; // emulator -> host
    if (Platform.isIOS) return 'http://localhost:3005';
    return 'http://localhost:3005';
  }

  bool get isConnected => socket?.connected ?? false;

  // Initialize user info
  void init({
    required String userId,
    required List<String> roles,
    List<String>? counters,
  }) {
    this.userId = userId;
    this.roles = roles;
    this.counters = counters;
  }

  // Connect to socket
  Future<void> connect() async {
    if (socket != null && socket!.connected) return;
    if (userId == null || roles == null) {
      print('⚠️ SocketService: userId and roles not set. Call init() first.');
      return;
    }

    socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId!, 'roles': roles!.join(',')})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket!.connect();

    // ----------------- Connection -----------------
    socket!.onConnect((_) {
      print("✅ Socket connected: ${socket!.id}");

      // Join personal room (student)
      socket?.emit('joinRoom', userId);

      // Join staff counter rooms
      if (roles!.contains('staff') && counters != null) {
        for (var counterId in counters!) {
          socket?.emit('joinRoom', 'role_COUNTER_$counterId');
          print('✅ Joined staff counter room: role_COUNTER_$counterId');
        }
      }
    });

    socket!.onDisconnect((reason) {
      print("❌ Socket disconnected: $reason");
    });

    socket!.onError((err) {
      print("⚠️ Socket error: $err");
    });

    // Keep alive ping/pong
    socket!.on('ping', (_) => socket?.emit('pong'));

    // ------------------ Notifications ------------------
    socket!.off('notifications:update');
    socket!.on('notifications:update', (data) {
      if (data != null && data is List) {
        _notifDebounce?.cancel();
        _notifDebounce = Timer(const Duration(milliseconds: 200), () {
          if (!_notifController.isClosed) _notifController.add(data);
        });
      }
    });

    // ------------------ Token Events ------------------
    final tokenEvents = [
      'token:created',
      'token:paymentConfirmed',
      'token:cancelled',
      'token:called',
      'token:completed',
      'token:skipped',
    ];

    for (var event in tokenEvents) {
      socket!.off(event);
      socket!.on(event, (data) {
        if (data != null && data is Map<String, dynamic>) {
          print("📡 $event received: $data");
          if (!_tokenController.isClosed) _tokenController.add(data);
        }
      });
    }
  }

  // Generic listeners/emitters
  void on(String event, Function(dynamic) callback) =>
      socket?.on(event, callback);
  void emit(String event, dynamic data) => socket?.emit(event, data);

  // Dispose
  void dispose() {
    _notifDebounce?.cancel();
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _notifController.close();
    _tokenController.close();
  }
}
