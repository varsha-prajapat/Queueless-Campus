import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ Left Side
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.primary,
                  size: 24, // 🔹 slightly smaller
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "QueueLess Campus",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // ✅ Prevent overflow
                    style: AppTextStyles.appTitle.copyWith(
                      fontSize: 16, // 🔹 Smaller text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Right Side
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
