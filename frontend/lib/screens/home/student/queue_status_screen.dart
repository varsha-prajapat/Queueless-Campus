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
          "DEBUG: currentToken='${data.currentToken}', nextToken='${data.nextToken}', waiting='${data.waiting}'");

      setState(() {
        stats = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        stats = null;
        loading = false;
      });
      print("Queue fetch error: $e");
    }
  }

  /// Build a row for display
  Widget buildRow(String title, String? value, {bool isYourToken = false}) {
    String displayValue;

    if (isYourToken) {
      // Show a friendly message if user hasn't booked a token
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

  /// Parse token safely as integer
  int parseToken(String? token) {
    if (token == null) return 0;
    final t = token.trim();
    final val = int.tryParse(t) ?? 0;
    return val > 0 ? val : 0;
  }

  /// Calculate people ahead
  int calculatePeopleAhead(String? current, String? your) {
    final currentInt = parseToken(current);
    final yourInt = parseToken(your);
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
                                  stats!.currentToken, stats!.nextToken)
                              .toString(),
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
                          stats!.completed?.toString() ?? "0",
                        ),
                        buildRow(
                          "Cancelled",
                          stats!.cancelled?.toString() ?? "0",
                        ),
                        buildRow(
                          "Skipped",
                          stats!.skipped?.toString() ?? "0",
                        ),
                      ],
                    ),
            ),
    );
  }
}
