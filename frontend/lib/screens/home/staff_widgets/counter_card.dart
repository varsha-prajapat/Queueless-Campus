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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD6D1FF),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Service Icon
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Counter Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Counter Name
                  Text(
                    counter.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Service Name
                  Text(
                    serviceName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: counter.isActive
                    ? const Color(0xFFDFF5E4)
                    : const Color(0xFFFFE3E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                counter.isActive ? "Active" : "Inactive",
                style: TextStyle(
                  color: counter.isActive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
