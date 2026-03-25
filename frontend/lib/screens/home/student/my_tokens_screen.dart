import 'package:flutter/material.dart';
import '../../../services/student_service/token_service.dart';
import '../../../services/socket_service.dart';
import '../../../models/token_model.dart';
import '../../../shared/widgets/bottom_message.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});

  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen> {
  List<TokenModel> tokens = [];
  List<TokenModel> filteredTokens = [];
  Map<String, String> serviceNames = {}; // serviceId -> serviceName

  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchTokens();

    // Realtime updates
    SocketService().on("token:update", (_) {
      fetchTokens();
    });
  }

  Future<void> fetchTokens() async {
    setState(() => isLoading = true);

    try {
      final data = await TokenService.getMyTokens();

      // Fetch unique service names
      Set<String> uniqueServiceIds = data
          .map((t) => t.serviceId ?? "")
          .where((id) => id.isNotEmpty)
          .toSet();

      Map<String, String> tempServiceNames = Map.from(serviceNames);

      await Future.wait(uniqueServiceIds.map((id) async {
        if (!tempServiceNames.containsKey(id)) {
          tempServiceNames[id] = await TokenService.getServiceName(id);
        }
      }));

      setState(() {
        tokens = data;
        serviceNames = tempServiceNames;
        applySearchFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showBottomMessage(context, "Error fetching tokens: $e", isError: true);
    }
  }

  void applySearchFilter() {
    if (searchQuery.isEmpty) {
      filteredTokens = tokens;
    } else {
      filteredTokens = tokens.where((t) {
        final name = serviceNames[t.serviceId] ?? "";
        return name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "waiting":
        return Colors.orange;
      case "serving":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      case "waiting_payment":
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Widget buildTokenCard(TokenModel token) {
    final serviceName = serviceNames[token.serviceId] ?? "Loading...";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text("Token ${token.displayToken()}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Service: $serviceName"),
            const SizedBox(height: 2),
            Text("Status: ${token.status}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: getStatusColor(token.status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            token.status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tokens"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Service...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  applySearchFilter();
                });
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTokens.isEmpty
              ? const Center(child: Text("No Tokens Found"))
              : RefreshIndicator(
                  onRefresh: fetchTokens,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredTokens.length,
                    itemBuilder: (context, index) {
                      return buildTokenCard(filteredTokens[index]);
                    },
                  ),
                ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
