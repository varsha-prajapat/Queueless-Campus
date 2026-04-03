import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/socket_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;
  SocketService._();

  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      return; // ✅ Prevent duplicate connection
    }

    _socket = IO.io(
      SocketConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {});

    _socket!.onDisconnect((_) {});
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
