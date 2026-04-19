import 'package:flutter/material.dart';
import '../../../services/student_service/token_service.dart';
import '../../../services/socket_service.dart';
import '../../../models/token_model.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  TokenStats? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();

    // Listen for realtime queue updates
    SocketService().on("queue:update", (data) {
      fetchStats();
    });
  }

  /// Fetch Queue Stats
  Future<void> fetchStats() async {
    setState(() {
      loading = true;
    });

    try {
      final data = await TokenService.getTokenStats();

      print(
        "DEBUG: currentToken='${data.currentToken}', nextToken='${data.nextToken}', waiting='${data.waiting}'",
      );

      setState(() {
        stats = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        stats = null;
        loading = false;
      });
    }
  }

  /// Build a row for display
  Widget buildRow(String title, String? value, {bool isYourToken = false}) {
    String displayValue;

    if (isYourToken) {
      displayValue = (value != null && value.trim().isNotEmpty)
          ? value.trim()
          : "No token booked yet";
    } else {
      displayValue =
          (value != null && value.trim().isNotEmpty) ? value.trim() : "-";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "$title : $displayValue",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Safe parse token (FIXED)
  int parseToken(String? token) {
    if (token == null) return 0;

    final cleaned = token.trim();

    // remove extra text like "12 (Urgent)"
    final numeric = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    return int.tryParse(numeric) ?? 0;
  }

  /// FIXED People Ahead Logic (IMPORTANT FIX)
  int calculatePeopleAhead(String? current, String? your) {
    final currentInt = parseToken(current);
    final yourInt = parseToken(your);

    if (currentInt == 0 || yourInt == 0) return 0;

    final ahead = yourInt - currentInt;

    return ahead > 0 ? ahead : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Queue Status"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchStats,
              child: stats == null
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        Center(
                          child: Text(
                            "No data available yet!",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        buildRow(
                          "Current Token",
                          parseToken(stats!.currentToken) > 0
                              ? stats!.currentToken
                              : "-",
                        ),
                        buildRow(
                          "Your Token",
                          parseToken(stats!.nextToken) > 0
                              ? stats!.nextToken
                              : "",
                          isYourToken: true,
                        ),
                        buildRow(
                          "People Ahead",
                          calculatePeopleAhead(
                            stats!.currentToken,
                            stats!.nextToken,
                          ).toString(),
                        ),
                        buildRow(
                          "Waiting",
                          stats!.waiting.toString(),
                        ),
                        buildRow(
                          "Served Today",
                          stats!.servedToday.toString(),
                        ),
                        buildRow(
                          "Completed",
                          stats!.completed.toString(),
                        ),
                        buildRow(
                          "Cancelled",
                          stats!.cancelled.toString(),
                        ),
                        buildRow(
                          "Skipped",
                          stats!.skipped.toString(),
                        ),
                      ],
                    ),
            ),
    );
  }
}
