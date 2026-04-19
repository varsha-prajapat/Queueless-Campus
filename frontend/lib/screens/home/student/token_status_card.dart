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

  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _socket = SocketService();
    _socket.connect();

    _notifSub = _socket.notifStream.listen((_) {
      _refreshTokenStats();
    });

    _socket.socket?.on('token:created', _handleUpdate);
    _socket.socket?.on('token:called', _handleUpdate);
    _socket.socket?.on('token:completed', _handleUpdate);
    _socket.socket?.on('token:paymentConfirmed', _handleUpdate);
  }

  void _handleUpdate(dynamic _) {
    _refreshTokenStats();
  }

  @override
  void dispose() {
    _notifSub?.cancel();

    _socket.socket?.off('token:created', _handleUpdate);
    _socket.socket?.off('token:called', _handleUpdate);
    _socket.socket?.off('token:completed', _handleUpdate);
    _socket.socket?.off('token:paymentConfirmed', _handleUpdate);

    super.dispose();
  }

  Future<void> _refreshTokenStats() async {
    if (!mounted) return;
    final provider = Provider.of<TokenProvider>(context, listen: false);
    await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TokenProvider>(
      builder: (context, provider, _) {
        if (provider.loading) return const SizedBox();

        final stats = provider.stats;
        if (stats == null) return const SizedBox();

        final status = "";

        Color statusColor;
        String statusText;

        switch (status) {
          case "serving":
            statusColor = Colors.green;
            statusText = "Serving";
            break;

          case "waiting_payment":
            statusColor = Colors.red;
            statusText = "Payment Pending";
            break;

          case "waiting":
            statusColor = Colors.orange;
            statusText = "Waiting";
            break;

          default:
            statusColor = Colors.grey;
            statusText = "Processing";
        }

        final total = stats.waiting + stats.completed;
        final progress =
            total == 0 ? 0.0 : (stats.completed / total).clamp(0.0, 1.0);

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
                    color: statusColor,
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
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _lastProgress, end: progress),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 7,
                          backgroundColor: const Color(0xffCBD5F5),
                          color: Colors.blue,
                        );
                      },
                      onEnd: () {
                        _lastProgress = progress;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 🔥 DIRECT BACKEND VALUE (NO FUNCTION)
              Text(
                "People Ahead: ${stats.peopleAhead}",
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
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            token,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
