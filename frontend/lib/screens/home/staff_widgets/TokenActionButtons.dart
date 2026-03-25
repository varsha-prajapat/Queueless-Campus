import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/token_model.dart';
import '../../../services/staff_service/token_service.dart';
import '../../../services/socket_service.dart';

class TokenActionButtons extends StatefulWidget {
  final String staffId;
  final VoidCallback onRefresh;

  const TokenActionButtons({
    super.key,
    required this.staffId,
    required this.onRefresh,
  });

  @override
  State<TokenActionButtons> createState() => _TokenActionButtonsState();
}

class _TokenActionButtonsState extends State<TokenActionButtons> {
  TokenModel? _servingToken;
  int? _nextTokenNumber;

  bool _isCalling = false;
  bool _isCompleting = false;
  bool _isSkipping = false;
  bool _isLoadingNext = false;

  StreamSubscription? _socketSub;
  late SocketService _socket;

  @override
  void initState() {
    super.initState();
    _socket = SocketService();
    _initLoad();
    _initSocket();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socket.dispose();
    super.dispose();
  }

  /// ================= INITIAL LOAD =================
  Future<void> _initLoad() async {
    await _loadServingToken();
    await _loadNextTokenPreview();
  }

  /// ================= SOCKET =================
  void _initSocket() {
    _socket.init(userId: widget.staffId, roles: ['staff']);
    _socket.connect();

    _socketSub = _socket.notifStream.listen((event) async {
      await _handleSocketEvent(event);
    });

    _socket.on(
        'token:called', (event) async => await _handleSocketEvent(event));
    _socket.on(
        'token:completed', (event) async => await _handleSocketEvent(event));
    _socket.on(
        'token:cancelled', (event) async => await _handleSocketEvent(event));
  }

  /// ================= HANDLE SOCKET =================
  Future<void> _handleSocketEvent(dynamic event) async {
    debugPrint('🔔 Token Socket Event: $event');

    // Reload serving token & next token
    await _loadServingToken();
    await _loadNextTokenPreview();

    // If the current token got cancelled, disable buttons
    if (_servingToken != null && _servingToken!.status == 'cancelled') {
      setState(() {
        _isCalling = false;
        _isCompleting = false;
        _isSkipping = false;
        _servingToken = null;
      });
    }
  }

  /// ================= SERVING TOKEN =================
  Future<void> _loadServingToken() async {
    try {
      final token = await TokenService.fetchServingToken();
      if (!mounted) return;

      setState(() {
        _servingToken = token;
      });
    } catch (e) {
      debugPrint("Serving fetch error: $e");
    }
  }

  /// ================= NEXT TOKEN =================
  Future<void> _loadNextTokenPreview() async {
    try {
      setState(() => _isLoadingNext = true);

      final nextTokenNumber = await TokenService.getNextTokenNumber();

      if (!mounted) return;
      setState(() {
        _nextTokenNumber = nextTokenNumber;
      });
    } catch (e) {
      debugPrint("Next token error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNext = false);
    }
  }

  /// ================= CALL NEXT =================
  Future<void> _callNext() async {
    if (_isCalling || _servingToken != null) return;

    setState(() => _isCalling = true);

    try {
      final result = await TokenService.callNextToken(widget.staffId);

      if (result['success'] == true) {
        await _loadServingToken();
        widget.onRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Token No ${result['tokenNumber']} called"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isCalling = false);
      await _loadNextTokenPreview();
    }
  }

  /// ================= COMPLETE =================
  Future<void> _completeToken() async {
    if (_servingToken == null || _isCompleting) return;

    // Disable if cancelled
    if (_servingToken!.status == 'cancelled') return;

    setState(() => _isCompleting = true);
    final tokenNumber = _servingToken!.tokenNumber;

    try {
      final result = await TokenService.completeToken(_servingToken!.id);

      if (result['success'] == true) {
        await _loadServingToken();
        widget.onRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Token No $tokenNumber completed"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isCompleting = false);
      await _loadNextTokenPreview();
    }
  }

  /// ================= SKIP =================
  Future<void> _skipToken() async {
    if (_servingToken == null || _isSkipping) return;

    // Disable if cancelled
    if (_servingToken!.status == 'cancelled') return;

    setState(() => _isSkipping = true);
    final tokenNumber = _servingToken!.tokenNumber;

    try {
      final result = await TokenService.skipToken(_servingToken!.id);

      if (result['success'] == true) {
        await _loadServingToken();
        widget.onRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Token No $tokenNumber skipped"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isSkipping = false);
      await _loadNextTokenPreview();
    }
  }

  /// ================= ERROR =================
  void _showError(String? msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg ?? "Something went wrong"),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// ================= BUTTON =================
  Widget _button({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isServing = _servingToken != null;
    final bool tokenCancelled = _servingToken?.status == 'cancelled';

    return Column(
      children: [
        /// COMPLETE
        _button(
          text: _isCompleting
              ? "Completing..."
              : isServing
                  ? "Complete ${_servingToken!.tokenNumber}"
                  : "Complete",
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: (!tokenCancelled && isServing && !_isCompleting)
              ? _completeToken
              : null,
        ),

        /// SKIP
        _button(
          text: _isSkipping
              ? "Skipping..."
              : isServing
                  ? "Skip ${_servingToken!.tokenNumber}"
                  : "Skip",
          icon: Icons.skip_next,
          color: Colors.orange,
          onTap: (!tokenCancelled && isServing && !_isSkipping)
              ? _skipToken
              : null,
        ),

        /// CALL NEXT
        _button(
          text: _isCalling
              ? "Calling..."
              : _isLoadingNext
                  ? "Loading..."
                  : _nextTokenNumber != null
                      ? "Call $_nextTokenNumber"
                      : "No Tokens",
          icon: Icons.campaign,
          color: (!isServing && _nextTokenNumber != null)
              ? Colors.deepPurple
              : Colors.deepPurple.shade200,
          onTap: (!isServing &&
                  !_isCalling &&
                  _nextTokenNumber != null &&
                  !tokenCancelled)
              ? _callNext
              : null,
        ),
      ],
    );
  }
}
