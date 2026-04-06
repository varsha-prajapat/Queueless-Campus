import 'package:flutter/material.dart';
import '../../../models/counter_model.dart';

class CounterCard extends StatelessWidget {
  final CounterModel counter;
  final String serviceName;

  const CounterCard({
    super.key,
    required this.counter,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5E48EC);

    final String counterName =
        (counter.name.isNotEmpty) ? counter.name : "Unnamed Counter";

    final String service =
        (serviceName.isNotEmpty) ? serviceName : "No Service";

    final bool isActive = counter.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE9FF),
            Color(0xFFDCD6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD6D1FF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            /// 🔵 ICON
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            /// 🧾 TEXT INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Counter Name
                  Text(
                    counterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// Service Name
                  Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            /// 🟢 STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDFF5E4)
                    : const Color(0xFFFFE3E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.circle : Icons.circle,
                    size: 10,
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? "Active" : "Inactive",
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
