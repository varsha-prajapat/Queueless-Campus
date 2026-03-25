import 'package:flutter/material.dart';
import '../../../services/socket_service.dart';
import 'dart:async';

class TokenCard extends StatefulWidget {
  final String title;
  final String tokenKey; // token field to display, e.g., "tokenNumber"
  final bool isStaff; // true for staff, false for student

  const TokenCard({
    super.key,
    required this.title,
    required this.tokenKey,
    this.isStaff = false,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> {
  late final SocketService _socket;
  String _displayValue = "-";

  @override
  void initState() {
    super.initState();
    _socket = SocketService();

    // Ensure socket is connected
    if (!_socket.isConnected) {
      _socket.connect();
    }

    // Listen to real-time notifications
    _socketSub = _socket.notifStream.listen((events) {
      _updateToken(events);
    });
  }

  StreamSubscription? _socketSub;

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  /// Updates the display value based on socket events
  void _updateToken(List<dynamic> events) {
    String newValue = "-";

    for (var notif in events) {
      if (notif is Map<String, dynamic>) {
        if (widget.isStaff && notif['servingStaffId'] == _socket.userId) {
          newValue = notif[widget.tokenKey]?.toString() ?? "-";

          // If token cancelled, show no token
          if (notif['status'] == 'cancelled') newValue = "No Token";
          break;
        } else if (!widget.isStaff && notif['studentId'] == _socket.userId) {
          newValue = notif[widget.tokenKey]?.toString() ?? "-";

          if (notif['status'] == 'cancelled') newValue = "No Token";
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _displayValue =
            (newValue.isEmpty || newValue == "-") ? "No Token" : newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _displayValue,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
