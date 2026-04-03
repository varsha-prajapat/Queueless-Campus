import 'package:flutter/material.dart';
import '../../../models/token_model.dart';
import '../../../services/staff_service/token_service.dart';

class TokenActionButtons extends StatefulWidget {
  final String staffId;
  final List<TokenModel> tokens;
  final TokenModel? currentToken;

  final Function(TokenModel? token)? onTokenChanged;

  const TokenActionButtons({
    super.key,
    required this.staffId,
    required this.tokens,
    this.currentToken,
    this.onTokenChanged,
  });

  @override
  State<TokenActionButtons> createState() => _TokenActionButtonsState();
}

class _TokenActionButtonsState extends State<TokenActionButtons> {
  bool _loading = false;

  TokenModel? _localCurrentToken;

  @override
  void initState() {
    super.initState();
    _localCurrentToken = widget.currentToken;
  }

  @override
  void didUpdateWidget(covariant TokenActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localCurrentToken = widget.currentToken;
  }

  // ✅ WAITING only
  TokenModel? get _waitingToken {
    final list = widget.tokens.where((t) {
      final status = (t.status ?? "").toLowerCase().trim();
      return status == "waiting";
    }).toList();

    return list.isNotEmpty ? list.first : null;
  }

  // ❌ FIXED (ONLY CHANGE HERE)
  bool get _hasServing =>
      _localCurrentToken != null &&
      (_localCurrentToken!.status ?? "").toLowerCase().trim() == "serving";

  bool get _hasWaiting => _waitingToken != null;

  bool get _canCall => !_hasServing && _hasWaiting;

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callNext() async {
    if (_loading || !_canCall) return;

    setState(() => _loading = true);

    try {
      final res = await TokenService.callNextToken(widget.staffId);

      if (res['success'] == true) {
        final next = _waitingToken;

        _localCurrentToken = next;

        _showSuccess("Token ${next?.tokenNumber ?? ''} called");

        widget.onTokenChanged?.call(next);
      }
    } catch (e) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _complete() async {
    if (_loading || _localCurrentToken == null) return;

    setState(() => _loading = true);

    try {
      final res = await TokenService.completeToken(_localCurrentToken!.id);

      if (res['success'] == true) {
        _showSuccess("Token completed");

        _localCurrentToken = null;

        widget.onTokenChanged?.call(null);
      }
    } catch (e) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _skip() async {
    if (_loading || _localCurrentToken == null) return;

    setState(() => _loading = true);

    try {
      final res = await TokenService.skipToken(_localCurrentToken!.id);

      if (res['success'] == true) {
        _showSuccess("Token skipped");

        _localCurrentToken = null;

        widget.onTokenChanged?.call(null);
      }
    } catch (e) {}

    if (mounted) setState(() => _loading = false);
  }

  Widget _btn(String text, VoidCallback? onTap, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(color: Colors.white), // ✅ ALL TEXT WHITE
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_hasServing) ...[
          _btn("Complete Token", _complete, const Color(0xFF2E7D32)),
          _btn("Skip Token", _skip, const Color(0xFFF57C00)),
        ],
        if (_canCall)
          _btn(
            "Call ${_waitingToken!.tokenNumber}",
            _callNext,
            const Color(0xFF0D47A1), // ✅ DARK BLUE
          ),
        if (!_hasServing && !_hasWaiting)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "No tokens available",
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
