import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum StatusType { error, success }

class AppStatusMessage extends StatelessWidget {
  final String message;
  final StatusType type;

  const AppStatusMessage({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isError = type == StatusType.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? AppColors.error : AppColors.success,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  isError ? AppTextStyles.errorText : AppTextStyles.successText,
            ),
          ),
        ],
      ),
    );
  }
}
