import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AppErrorMessage extends StatelessWidget {
  final String message;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const AppErrorMessage(
    this.message, {
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: borderRadius,
      ),
      child: Text(
        message,
        style: AppTextStyles.errorText,
      ),
    );
  }
}
