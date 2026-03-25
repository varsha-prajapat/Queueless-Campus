import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/socket_service.dart';
import '../../../services/student_service/token_service.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/widgets/bottom_message.dart';
import '../../../models/token_model.dart';

class ServiceList extends StatefulWidget {
  final String departmentId;
  final String studentId;

  const ServiceList({
    super.key,
    required this.departmentId,
    required this.studentId,
  });

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  List<Map<String, dynamic>> services = [];
  List<TokenModel> myTokens = [];
  final Map<String, TokenModel> _latestTokenMap = {};
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    fetchAllData();

    _notifSub = SocketService().notifStream.listen((_) async {
      await fetchAllData();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    if (widget.departmentId.isEmpty) return;

    try {
      final serviceRes = await TokenService.getWithAuth(
          "${Api_Config.service_student}/${widget.departmentId}");

      final tokens = await TokenService.getMyTokens();

      List<Map<String, dynamic>> serviceList = [];
      if (serviceRes.statusCode == 200) {
        final decoded =
            serviceRes.body.isNotEmpty ? jsonDecode(serviceRes.body) : {};

        if (decoded is Map && decoded.containsKey("data")) {
          final data = decoded["data"];
          if (data is List) {
            serviceList = data
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } else if (decoded is List) {
          serviceList = decoded
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      serviceList =
          serviceList.where((s) => s["isPaused"] != true).take(2).toList();

      List<TokenModel> tokenList = [];
      if (tokens.isNotEmpty) {
        tokenList =
            tokens.where((t) => t.studentId == widget.studentId).toList();
      }

      final newTokenMap = <String, TokenModel>{};
      for (var token in tokenList) {
        final serviceId = token.serviceId;
        if (serviceId == null) continue;

        final existing = newTokenMap[serviceId];
        if (existing == null ||
            (token.createdAt ?? DateTime(2000))
                .isAfter(existing.createdAt ?? DateTime(2000))) {
          newTokenMap[serviceId] = token;
        }
      }

      if (!mounted) return;
      setState(() {
        services = serviceList;
        myTokens = tokenList;
        _latestTokenMap
          ..clear()
          ..addAll(newTokenMap);
      });
    } catch (e) {
      if (!mounted) return;
      showBottomMessage(context, "Error: $e", isError: true);
    }
  }

  TokenModel? getLatestToken(String serviceId) => _latestTokenMap[serviceId];

  Future<void> handleServiceTap(Map<String, dynamic> service) async {
    final serviceId = service["_id"]?.toString();
    if (serviceId == null || serviceId.isEmpty) {
      showBottomMessage(context, "Invalid service", isError: true);
      return;
    }

    bool isUrgent = false;
    if (service["allowUrgent"] == true) {
      final urgency = await askUrgency();
      if (urgency == null) return;
      isUrgent = urgency;
    }

    try {
      final booked = await TokenService.bookToken(
        serviceId: serviceId,
        isUrgent: isUrgent,
      );

      if (booked == null) {
        showBottomMessage(context, "Booking failed", isError: true);
        return;
      }

      showBottomMessage(context, "Token booked successfully");

      await fetchAllData();
    } catch (e) {
      showBottomMessage(context, "Error: $e", isError: true);
    }
  }

  Future<bool?> askUrgency() async {
    bool? urgent;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Urgent Token?"),
        content: const Text("Do you want to mark this token as urgent?"),
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
          TextButton(
            onPressed: () {
              urgent = null;
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    return urgent;
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service["_id"]?.toString();
    final token = getLatestToken(serviceId ?? "");
    final status = (token?.status ?? "").toLowerCase();

    bool isCompleted = status == "completed";
    bool isPaymentPending = status == "waiting_payment";
    bool isBooked = status == "waiting" ||
        (status == "completed" && service["hasFee"] != true);

    return GestureDetector(
      onTap: () => handleServiceTap(service),
      child: Container(
        key: ValueKey(serviceId),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service["name"]?.toString() ?? "Service",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(service["serviceType"]?.toString() ?? "",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(
                      service["hasFee"] == true
                          ? "₹${service["fee"] ?? 0}"
                          : "Free",
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (isPaymentPending)
              const Chip(
                label: Text("Payment Pending"),
                backgroundColor: Colors.orangeAccent,
              ),
            if (isBooked)
              const Chip(
                label: Text("Booked"),
                backgroundColor: Colors.greenAccent,
              ),
            if (isCompleted)
              const Chip(
                label: Text("Completed"),
                backgroundColor: Colors.blueAccent,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return services.isEmpty
        ? const Center(child: Text("No Services Available"))
        : ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return buildServiceCard(services[index]);
            },
          );
  }
}
