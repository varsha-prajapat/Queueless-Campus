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
    _tokenSub = SocketService().notifStream.listen((_) async {
      await _updateTokensFromSocket();
    });
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    super.dispose();
  }

  TokenModel? getLatestToken(String serviceId) => _latestTokenMap[serviceId];

  // ================= SOCKET =================
  Future<void> _updateTokensFromSocket() async {
    final tokens = await TokenService.getMyTokens();

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

    if (!mounted) return;

    setState(() {
      myTokens = tokens;
    });
  }

  // ================= FETCH =================
  Future<void> fetchAllData() async {
    try {
      final serviceRes = await TokenService.getWithAuth(
          "${Api_Config.service_student}/${widget.departmentId}");

      List<Map<String, dynamic>> serviceList = [];

      if (serviceRes.statusCode == 200) {
        final decoded = jsonDecode(serviceRes.body);

        if (decoded is Map && decoded["data"] is List) {
          serviceList = (decoded["data"] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      final tokens = await TokenService.getMyTokens();

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

      setState(() {
        services = serviceList;
        filteredServices = serviceList;
        myTokens = tokens;
      });
    } catch (e) {
      showBottomMessage(context, "Error: $e", isError: true);
    }
  }

  // ================= SEARCH =================
  void applySearch(String query) {
    setState(() {
      searchQuery = query;
      filteredServices = services.where((service) {
        final name = service["name"]?.toString().toLowerCase() ?? "";
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  // ================= PAYMENT =================
  Future<void> showPaymentDialog(TokenModel token, dynamic fee) async {
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Payment"),
          content: Text("Pay ₹$fee to confirm your token?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setStateDialog(() => loading = true);

                      bool success = await TokenService.confirmPayment(
                        tokenId: token.id,
                        paymentId:
                            DateTime.now().millisecondsSinceEpoch.toString(),
                      );

                      if (success) {
                        Navigator.pop(ctx);
                        showBottomMessage(context, "Payment Successful ✅");
                        await fetchAllData();
                      } else {
                        showBottomMessage(context, "Payment Failed ❌",
                            isError: true);
                      }

                      setStateDialog(() => loading = false);
                    },
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Yes"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CANCEL =================
  Future<void> cancelToken(TokenModel token) async {
    bool success = await TokenService.cancelToken(tokenId: token.id);

    if (success) {
      _latestTokenMap.remove(token.serviceId);
      myTokens.removeWhere((t) => t.id == token.id);

      setState(() {});
      showBottomMessage(context, "Token cancelled");

      await fetchAllData();
    } else {
      showBottomMessage(context, "Cancel failed ❌", isError: true);
    }
  }

  // ================= URGENT CONFIRMATION =================
  Future<bool> askUrgentConfirmation() async {
    bool urgent = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Urgent Token"),
        content: const Text("Do you want to make this token urgent?"),
        actions: [
          TextButton(
            onPressed: () {
              urgent = false;
              Navigator.pop(ctx);
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              urgent = true;
              Navigator.pop(ctx);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    return urgent;
  }

  // ================= BOOK =================
  Future<void> handleServiceTap(Map<String, dynamic> service) async {
    final serviceId = service["_id"]?.toString();
    if (serviceId == null) return;

    bool isUrgent = false;

    // Ask urgent only if service allows urgent
    if (service["allowUrgent"] == true) {
      isUrgent = await askUrgentConfirmation();
    }

    final booked = await TokenService.bookToken(
      serviceId: serviceId,
      isUrgent: isUrgent,
    );

    if (booked == null) {
      showBottomMessage(context, "Booking failed", isError: true);
      return;
    }

    TokenModel updatedToken = booked;

    // For paid services → set status to waiting_payment
    if (service["hasFee"] == true) {
      updatedToken = TokenModel(
        id: booked.id,
        tokenNumber: booked.tokenNumber,
        status: "waiting_payment",
        serviceId: booked.serviceId,
        isUrgent: booked.isUrgent,
        createdAt: booked.createdAt,
      );
    }

    myTokens.add(updatedToken);
    _latestTokenMap[serviceId] = updatedToken;

    // Only show bottom message if free
    if (service["hasFee"] != true) {
      showBottomMessage(context, "Token booked");
    }

    setState(() {});
  }

  // ================= UI =================
  Widget buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service["_id"]?.toString();
    final token = serviceId != null ? getLatestToken(serviceId) : null;

    final status = (token?.status ?? "").toLowerCase().trim();

    String statusLabel = "Book";

    if (status == "waiting" || status == "serving") {
      statusLabel = "Cancel";
    } else if (status == "waiting_payment") {
      statusLabel = "Pay Now";
    }

    final fee = service["hasFee"] == true ? service["fee"] ?? 0 : "Free";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
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
                if (status == "waiting" || status == "serving")
                  Text(
                    "Status: ${status.toUpperCase()}",
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (status == "waiting" || status == "serving") {
                if (token != null) await cancelToken(token);
              } else if (status == "waiting_payment") {
                if (token != null) await showPaymentDialog(token, fee);
              } else {
                await handleServiceTap(service);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (status == "waiting" || status == "serving")
                    ? Colors.red.shade100
                    : status == "waiting_payment"
                        ? Colors.orange.shade100
                        : const Color(0xffD0E8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: (status == "waiting" || status == "serving")
                      ? Colors.red
                      : status == "waiting_payment"
                          ? Colors.orange
                          : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
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
                    borderSide: BorderSide.none),
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
