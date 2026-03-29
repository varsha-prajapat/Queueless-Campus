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

  Widget buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service["_id"]?.toString();
    getLatestToken(serviceId ?? "");

    return Container(
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
                Text(
                  service["name"]?.toString() ?? "Service",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  service["serviceType"]?.toString() ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  service["hasFee"] == true
                      ? "₹${service["fee"] ?? 0}"
                      : "Free",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
