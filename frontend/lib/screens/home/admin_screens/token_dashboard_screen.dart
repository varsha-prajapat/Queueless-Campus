import 'package:flutter/material.dart';
import '../../../services/admin_services/token_dashboard_service.dart';
import '../../../services/socket_service.dart';
import 'dart:async';

class TokenDashboardScreen extends StatefulWidget {
  const TokenDashboardScreen({super.key});

  @override
  State<TokenDashboardScreen> createState() => _TokenDashboardScreenState();
}

class _TokenDashboardScreenState extends State<TokenDashboardScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  final SocketService socketService = SocketService();

  StreamSubscription? _adminSub;

  @override
  void initState() {
    super.initState();

    fetchData();

    socketService.init(
      userId: "ADMIN_ID",
      roles: ["ADMIN"],
    );

    socketService.connect();

    // ✅ FIXED: wrap socket data like API
    _adminSub = socketService.adminStream.listen((socketData) {
      debugPrint("📡 LIVE DASHBOARD DATA: $socketData");

      if (!mounted) return;

      setState(() {
        data = {
          "data": socketData, // 🔥 IMPORTANT FIX
        };
        isLoading = false;
      });
    });
  }

  Future<void> fetchData() async {
    try {
      final result = await TokenDashboardService.fetchDashboard();

      debugPrint("✅ API DATA RECEIVED: $result");

      if (!mounted) return;

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ API ERROR: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget buildStatCard(String title, int value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCounterCard(Map<String, dynamic> counter) {
    final summary = counter["summary"] ?? {};
    final current = counter["currentToken"];
    final queue = counter["queue"] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(counter["counterName"] ?? "Counter"),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text("W: ${summary["waiting"] ?? 0}"),
                Text("S: ${summary["serving"] ?? 0}"),
                Text("C: ${summary["completed"] ?? 0}"),
                Text("X: ${summary["cancelled"] ?? 0}"),
                Text("Skip: ${summary["skipped"] ?? 0}"),
                Text("Unpaid: ${summary["unpaid"] ?? 0}"),
                Text("₹: ${summary["totalPayment"] ?? 0}"),
              ],
            ),
          ),
          if (current != null)
            ListTile(
              title: Text(
                "Now Serving: ${current["tokenNumber"] ?? "-"}",
              ),
              subtitle: Text(
                "Student: ${current["student"]?["name"] ?? "-"}",
              ),
              trailing: Text(
                "₹${current["payment"] ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ...List<Widget>.from(
            queue.map((token) {
              return ListTile(
                title: Text("Token: ${token["tokenNumber"] ?? "-"}"),
                subtitle: Text(token["studentId"]?["name"] ?? "-"),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(token["status"] ?? "-"),
                    Text(
                      "₹${token["payment"] ?? 0}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = data?["data"]?["globalStats"] ?? {};
    final counters = data?["data"]?["counters"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Token Dashboard"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                buildStatCard("Waiting", stats["totalWaiting"] ?? 0),
                buildStatCard("Serving", stats["totalServing"] ?? 0),
              ],
            ),
            Row(
              children: [
                buildStatCard("Completed", stats["totalCompleted"] ?? 0),
                buildStatCard("Cancelled", stats["totalCancelled"] ?? 0),
              ],
            ),
            Row(
              children: [
                buildStatCard("Skipped", stats["totalSkipped"] ?? 0),
                buildStatCard("Unpaid", stats["totalUnpaid"] ?? 0),
              ],
            ),
            Row(
              children: [
                buildStatCard("Total ₹", stats["totalPayment"] ?? 0),
                buildStatCard("Tokens", stats["totalTokens"] ?? 0),
              ],
            ),
            const SizedBox(height: 10),
            ...List<Widget>.from(
              counters.map((c) => buildCounterCard(c)),
            ),
          ],
        ),
      ),
    );
  }
}
