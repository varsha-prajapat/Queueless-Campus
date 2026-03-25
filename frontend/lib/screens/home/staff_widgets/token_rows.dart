import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/token_model.dart';
import '../../../services/staff_service/token_service.dart';

class TokenRows extends StatefulWidget {
  const TokenRows({super.key});

  @override
  State<TokenRows> createState() => _TokenRowsState();
}

class _TokenRowsState extends State<TokenRows> {
  TokenStats? _stats;
  List<TokenModel> _tokens = [];
  bool _loading = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initLoad();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// 🔥 Initial Load
  Future<void> _initLoad() async {
    try {
      final stats = await TokenService.getTokenStats();
      final tokens = await TokenService.getAllTokensOfStaffDetail();

      if (mounted) {
        setState(() {
          _stats = stats;
          _tokens = tokens;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// 🔥 Silent refresh
  Future<void> _silentRefresh() async {
    try {
      final tokens = await TokenService.getAllTokensOfStaffDetail();

      if (mounted) {
        setState(() {
          _tokens = tokens;
        });
      }
    } catch (_) {}
  }

  void _startAutoRefresh() {
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _silentRefresh());
  }

  /// ✅ ONLY SERVING TOKEN
  TokenModel? _getServingToken() {
    try {
      return _tokens.firstWhere((t) => t.status == "serving");
    } catch (_) {
      return null;
    }
  }

  String _getServingLabel() {
    final token = _getServingToken();
    return token == null ? "No Active Token" : "Token #${token.tokenNumber}";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        /// ---------------- STATS ----------------
        if (_stats != null)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TokenCard(
                      title: "Current",
                      value: _stats!.currentToken,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TokenCard(
                      title: "Next",
                      value: _stats!.nextToken,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TokenCard(
                      title: "Waiting",
                      value: _stats!.waiting.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TokenCard(
                      title: "Served",
                      value: _stats!.servedToday.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

/// ---------------- TOKEN CARD ----------------
class TokenCard extends StatelessWidget {
  final String title;
  final String value;

  const TokenCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value.isEmpty || value == "-") ? "No Token" : value;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
