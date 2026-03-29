import 'package:flutter/material.dart';
import '../../../models/token_model.dart';

/// ---------------- TOKEN ROWS ----------------
class TokenRows extends StatefulWidget {
  final TokenStats? stats;
  final TokenModel? currentToken;
  final List<TokenModel> allTokens;
  final String? counterId;

  const TokenRows({
    super.key,
    this.stats,
    this.currentToken,
    required this.allTokens,
    this.counterId,
  });

  @override
  State<TokenRows> createState() => _TokenRowsState();
}

class _TokenRowsState extends State<TokenRows> {
  TokenStats _stats = TokenStats.empty();

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  @override
  void didUpdateWidget(covariant TokenRows oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.allTokens != oldWidget.allTokens ||
        widget.currentToken?.id != oldWidget.currentToken?.id ||
        widget.counterId != oldWidget.counterId) {
      _calculateStats();
    }
  }

  /// ---------------- NORMALIZE ----------------
  String _normalize(String? s) => (s ?? "").toLowerCase().trim();

  bool _isWaiting(String s) => s == "waiting";
  bool _isServing(String s) => s == "serving" || s == "called";

  /// ---------------- CALCULATE ----------------
  void _calculateStats() {
    final tokens = (widget.counterId != null)
        ? widget.allTokens
            .where((t) => t.counterId == widget.counterId)
            .toList()
        : widget.allTokens;

    if (tokens.isEmpty) {
      if (!mounted) return;
      setState(() => _stats = TokenStats.empty());
      return;
    }

    /// ---------------- SORT FIFO ----------------
    final sortedTokens = [...tokens]
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));

    /// ---------------- CURRENT TOKEN ----------------
    final current = widget.currentToken ??
        sortedTokens.firstWhere(
          (t) => _isServing(_normalize(t.status)),
          orElse: () => TokenModel(id: "", tokenNumber: 0, status: "waiting"),
        );

    /// ---------------- WAITING LIST ----------------
    final waitingTokens =
        sortedTokens.where((t) => _isWaiting(_normalize(t.status))).toList();

    /// ---------------- URGENT + NORMAL SPLIT ----------------
    final urgentWaiting =
        waitingTokens.where((t) => t.isUrgent == true).toList();

    final normalWaiting =
        waitingTokens.where((t) => t.isUrgent != true).toList();

    /// ---------------- NEXT TOKEN (FIXED) ----------------
    final next = urgentWaiting.isNotEmpty
        ? urgentWaiting.first
        : normalWaiting.isNotEmpty
            ? normalWaiting.first
            : TokenModel(id: "", tokenNumber: 0, status: "waiting");

    /// ---------------- COUNTS ----------------
    final waitingCount = waitingTokens.length;

    final completedCount =
        tokens.where((t) => _normalize(t.status) == "completed").length;

    final cancelledCount =
        tokens.where((t) => _normalize(t.status) == "cancelled").length;

    final skippedCount =
        tokens.where((t) => _normalize(t.status) == "skipped").length;

    final urgentWaitingCount = urgentWaiting.length;

    final newStats = TokenStats(
      currentToken:
          current.tokenNumber == 0 ? "-" : current.tokenNumber.toString(),
      nextToken: next.tokenNumber == 0 ? "-" : next.tokenNumber.toString(),
      waiting: waitingCount,
      servedToday: completedCount,
      urgentWaiting: urgentWaitingCount,
      completed: completedCount,
      cancelled: cancelledCount,
      skipped: skippedCount,
    );

    if (!mounted) return;

    setState(() {
      _stats = newStats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TokenCard(
                title: "Current",
                value: _stats.currentToken,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Next",
                value: _stats.nextToken,
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
                value: _stats.waiting.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Urgent Waiting",
                value: _stats.urgentWaiting.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TokenCard(
                title: "Served",
                value: _stats.completed.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Cancelled",
                value: _stats.cancelled.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Skipped",
                value: _stats.skipped.toString(),
              ),
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
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
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
