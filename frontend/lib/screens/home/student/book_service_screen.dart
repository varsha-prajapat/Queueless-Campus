import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../services/student_service/token_service.dart';
import '../../../services/socket_service.dart';
import '../../../models/token_model.dart';
import '../../../shared/widgets/bottom_message.dart';

class BookServiceScreen extends StatefulWidget {
  final String departmentId;
  final String studentId;

  const BookServiceScreen({
    super.key,
    required this.departmentId,
    required this.studentId,
  });

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  List<TokenModel> myTokens = [];

  final Map<String, TokenModel> _latestTokenMap = {};
  StreamSubscription? _tokenSub;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchAllData();

    _tokenSub = SocketService().tokenStream.listen((data) async {
      if (!mounted) return;
      await fetchAllData();
    });
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    super.dispose();
  }

  TokenModel? getLatestToken(String serviceId) => _latestTokenMap[serviceId];

  void _mapTokens(List<TokenModel> tokens) {
    _latestTokenMap.clear();

    for (var token in tokens) {
      final sid = token.serviceId;
      if (sid == null) continue;

      final existing = _latestTokenMap[sid];
      final current = token.createdAt ?? DateTime.now();
      final old = existing?.createdAt ?? DateTime(2000);

      if (existing == null || current.isAfter(old)) {
        _latestTokenMap[sid] = token;
      }
    }
  }

  Future<void> fetchAllData() async {
    try {
      final serviceRes = await TokenService.getWithAuth(
        "${Api_Config.service_student}/${widget.departmentId}",
      );

      List<Map<String, dynamic>> serviceList = [];

      if (serviceRes.statusCode == 200) {
        final decoded = jsonDecode(serviceRes.body);

        if (decoded is Map && decoded["data"] is List) {
          serviceList = (decoded["data"] as List)
              .map((e) => Map<String, dynamic>.from(e ?? {}))
              .toList();
        }
      }

      final tokens = await TokenService.getMyTokens();
      _mapTokens(tokens);

      if (!mounted) return;

      setState(() {
        services = serviceList;
        filteredServices = serviceList;
        myTokens = tokens;
      });
    } catch (e) {
      if (mounted) {
        showBottomMessage(context, "Error: $e", isError: true);
      }
    }
  }

  void applySearch(String query) {
    if (!mounted) return;

    setState(() {
      searchQuery = query;

      filteredServices = services.where((service) {
        final name = service["name"]?.toString().toLowerCase() ?? "";
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> handleServiceTap(Map<String, dynamic> service) async {
    final serviceId = service["_id"]?.toString();
    if (serviceId == null) return;

    final booked = await TokenService.bookToken(
      serviceId: serviceId,
      isUrgent: false,
    );

    if (booked == null) {
      showBottomMessage(context, "Booking failed", isError: true);
      return;
    }

    myTokens.add(booked);
    _latestTokenMap[serviceId] = booked;

    showBottomMessage(context, "Token booked");
    setState(() {});
  }

  Future<void> handleCancel(TokenModel token) async {
    try {
      final success = await TokenService.cancelToken(tokenId: token.id);

      if (!success) {
        showBottomMessage(context, "Cancel failed", isError: true);
        return;
      }

      showBottomMessage(context, "Cancelled successfully");
      await fetchAllData();
    } catch (e) {
      showBottomMessage(context, "Error: $e", isError: true);
    }
  }

  // ✅ PAYMENT CONFIRM
  Future<void> handlePayment(TokenModel token) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: const Text("Do you want to proceed with payment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await TokenService.confirmPayment(tokenId: token.id);

      if (!success) {
        showBottomMessage(context, "Payment failed", isError: true);
        return;
      }

      showBottomMessage(context, "Payment successful");
      await fetchAllData();
    } catch (e) {
      showBottomMessage(context, "Error: $e", isError: true);
    }
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service["_id"]?.toString();
    final token = serviceId != null ? getLatestToken(serviceId) : null;

    final status = (token?.status ?? "").toLowerCase().trim();

    final List counters =
        (service["counters"] is List) ? service["counters"] : [];

    final bool noCounter = counters.isEmpty;
    final bool isDisabled = noCounter;

    String statusLabel = "Book";

    if (status == "waiting" || status == "serving") {
      statusLabel = "Cancel";
    } else if (status == "waiting_payment") {
      statusLabel = "Pay Now";
    }

    final fee = service["hasFee"] == true ? service["fee"] ?? 0 : "Free";

    // ✅ BUTTON COLOR FIX
    Color bgColor = Colors.blue.shade100;
    Color textColor = Colors.blue;

    if (status == "waiting" || status == "serving") {
      bgColor = Colors.red.shade100;
      textColor = Colors.red;
    } else if (status == "waiting_payment") {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange;
    }

    return AbsorbPointer(
      absorbing: isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service["name"] ?? "Service",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Fee: $fee"),
                    if (token != null)
                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: const TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.w500),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          noCounter ? "NO COUNTER" : "AVAILABLE",
                          style: TextStyle(
                            color: noCounter ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: isDisabled
                    ? null
                    : () async {
                        if (status == "waiting" || status == "serving") {
                          if (token != null) {
                            await handleCancel(token);
                          }
                        } else if (status == "waiting_payment") {
                          if (token != null) {
                            await handlePayment(token);
                          }
                        } else {
                          await handleServiceTap(service);
                        }
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.grey.shade300 : bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDisabled ? "No Counter" : statusLabel,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Service")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: applySearch,
              decoration: InputDecoration(
                hintText: "Search Service...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredServices.length,
              itemBuilder: (context, index) =>
                  buildServiceCard(filteredServices[index]),
            ),
          ),
        ],
      ),
    );
  }
}
