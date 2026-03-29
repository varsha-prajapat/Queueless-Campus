import 'package:flutter/material.dart';
import '../../../models/token_model.dart';

/// ---------------- TOKEN STATS ----------------
class TokenStats {
  final String currentToken;
  final String nextToken;
  final int waiting;
  final int servedToday;
  final int urgentWaiting;
  final int completed;
  final int cancelled;
  final int skipped;

  const TokenStats({
    required this.currentToken,
    required this.nextToken,
    required this.waiting,
    required this.servedToday,
    this.urgentWaiting = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.skipped = 0,
  });

  factory TokenStats.empty() {
    return const TokenStats(
      currentToken: "-",
      nextToken: "-",
      waiting: 0,
      servedToday: 0,
      urgentWaiting: 0,
      completed: 0,
      cancelled: 0,
      skipped: 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenStats &&
          currentToken == other.currentToken &&
          nextToken == other.nextToken &&
          waiting == other.waiting &&
          servedToday == other.servedToday &&
          urgentWaiting == other.urgentWaiting &&
          completed == other.completed &&
          cancelled == other.cancelled &&
          skipped == other.skipped;

  @override
  int get hashCode =>
      currentToken.hashCode ^
      nextToken.hashCode ^
      waiting.hashCode ^
      servedToday.hashCode ^
      urgentWaiting.hashCode ^
      completed.hashCode ^
      cancelled.hashCode ^
      skipped.hashCode;
}

/// ---------------- TOKEN ROWS ----------------
class TokenRows extends StatelessWidget {
  final TokenModel? currentToken;
  final List<TokenModel> allTokens;
  final String? counterId;

  const TokenRows({
    super.key,
    this.currentToken,
    required this.allTokens,
    this.counterId,
  });

  TokenStats _calculateStats() {
    final tokens = (counterId != null)
        ? allTokens.where((t) => t.counterId == counterId).toList()
        : allTokens;

    if (tokens.isEmpty) {
      return TokenStats.empty();
    }

    String normalize(String s) => s.toLowerCase();

    // ---------------- WAITING (FIXED) ----------------
    final waitingTokens = tokens.where((t) {
      final status = normalize(t.status);
      return status == "waiting" || status == "waiting_payment";
    }).toList();

    // ---------------- COMPLETED ----------------
    final completedTokens = tokens.where((t) {
      return normalize(t.status) == "completed";
    }).toList();

    // ---------------- CANCELLED ----------------
    final cancelledTokens = tokens.where((t) {
      return normalize(t.status) == "cancelled";
    }).toList();

    // ---------------- SKIPPED ----------------
    final skippedTokens = tokens.where((t) {
      return normalize(t.status) == "skipped";
    }).toList();

    // ---------------- URGENT WAITING (FIXED) ----------------
    final urgentWaitingTokens =
        waitingTokens.where((t) => t.isUrgent == true).toList();

    // ---------------- CURRENT TOKEN ----------------
    final current = currentToken ??
        tokens.firstWhere(
          (t) =>
              normalize(t.status) == "serving" ||
              normalize(t.status) == "called",
          orElse: () => TokenModel(id: "", tokenNumber: 0, status: "waiting"),
        );

    // ---------------- NEXT TOKEN (FIXED) ----------------
    TokenModel nextTokenModel = TokenModel(
      id: "",
      tokenNumber: 0,
      status: "waiting",
    );

    if (waitingTokens.isNotEmpty) {
      final urgent = waitingTokens.where((t) => t.isUrgent == true).toList();
      nextTokenModel = urgent.isNotEmpty ? urgent.first : waitingTokens.first;
    }

    return TokenStats(
      currentToken:
          current.tokenNumber == 0 ? "-" : current.tokenNumber.toString(),
      nextToken: nextTokenModel.tokenNumber == 0
          ? "-"
          : nextTokenModel.tokenNumber.toString(),
      waiting: waitingTokens.length,
      servedToday: completedTokens.length,
      urgentWaiting: urgentWaitingTokens.length,
      completed: completedTokens.length,
      cancelled: cancelledTokens.length,
      skipped: skippedTokens.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TokenCard(title: "Current", value: stats.currentToken),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(title: "Next", value: stats.nextToken),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TokenCard(
                title: "Waiting",
                value: stats.waiting.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Urgent Waiting",
                value: stats.urgentWaiting.toString(),
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
                value: stats.completed.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Cancelled",
                value: stats.cancelled.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TokenCard(
                title: "Skipped",
                value: stats.skipped.toString(),
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
