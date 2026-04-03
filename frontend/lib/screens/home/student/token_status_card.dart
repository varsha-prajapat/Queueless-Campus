import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/TokenProvider.dart';
import '../../../services/socket_service.dart';

class TokenStatusCard extends StatefulWidget {
  const TokenStatusCard({super.key});

  @override
  State<TokenStatusCard> createState() => _TokenStatusCardState();
}

class _TokenStatusCardState extends State<TokenStatusCard> {
  late final SocketService _socket;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();

    // Initialize SocketService
    _socket = SocketService();
    _socket.connect();

    // Listen for all relevant token events
    _notifSub = _socket.notifStream.listen((data) async {
      await _refreshTokenStats();
    });

    // Optional direct binding
    _socket.socket?.on('token:created', (_) => _refreshTokenStats());
    _socket.socket?.on('token:called', (_) => _refreshTokenStats());
    _socket.socket?.on('token:completed', (_) => _refreshTokenStats());
    _socket.socket?.on('token:paymentConfirmed', (_) => _refreshTokenStats());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  /// Refresh token stats via Provider
  Future<void> _refreshTokenStats() async {
    if (!mounted) return;
    final provider = Provider.of<TokenProvider>(context, listen: false);
    await provider.refresh();
  }

  /// People ahead
  int peopleAhead(TokenProvider provider) {
    final stats = provider.stats;
    if (stats == null || stats.currentToken == "-" || stats.nextToken == "-") {
      return 0;
    }
    try {
      final diff = int.parse(stats.nextToken) - int.parse(stats.currentToken);
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  /// Progress for LinearProgressIndicator
  double progress(TokenProvider provider) {
    final stats = provider.stats;
    if (stats == null || stats.currentToken == "-" || stats.nextToken == "-") {
      return 0.0;
    }
    try {
      final current = int.parse(stats.currentToken);
      final next = int.parse(stats.nextToken);
      final total = next - current;
      if (total <= 0) return 1.0;
      final ahead = peopleAhead(provider);
      return (1 - (ahead / total)).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Determine token status text and color
  Map<String, dynamic> tokenStatus(TokenProvider provider) {
    final stats = provider.stats;
    if (stats == null) return {"text": "No Token Booked", "color": Colors.grey};

    if (stats.currentToken != "-" &&
        stats.nextToken != "-" &&
        stats.waiting > 0) {
      // Currently serving
      return {"text": "Serving", "color": Colors.green};
    } else if (stats.nextToken != "-" &&
        stats.waiting == 0 &&
        stats.currentToken == "-") {
      // Payment pending / not started
      return {"text": "Payment Pending", "color": Colors.red};
    } else if (stats.currentToken == "-" && stats.nextToken == "-") {
      // No token
      return {"text": "No Token Booked", "color": Colors.grey};
    } else {
      // Waiting
      return {"text": "Waiting", "color": Colors.orange};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TokenProvider>(
      builder: (context, provider, _) {
        if (provider.loading) return const SizedBox();

        final stats = provider.stats;
        if (stats == null) return const SizedBox();

        final status = tokenStatus(provider);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xffE3E9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffC7D2FE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Token Status",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tokenBox(
                    title: "Current Token",
                    token: stats.currentToken,
                    color: Colors.orange,
                  ),
                  _tokenBox(
                    title: "Your Token",
                    token: stats.nextToken,
                    color: status["color"] as Color,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (status["color"] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status["text"] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: status["color"] as Color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress(provider),
                      minHeight: 7,
                      backgroundColor: const Color(0xffCBD5F5),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "People Ahead: ${peopleAhead(provider)}",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _tokenBox({
    required String title,
    required String token,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF1F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffD6DEFF)),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(token,
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
