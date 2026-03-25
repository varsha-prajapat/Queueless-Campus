import 'package:flutter/material.dart';

/// ===============================
/// 🎨 COLORS
/// ===============================
class AppColors {
  // Brand (green logo like image)
  static const Color primary = Color(0xFF1F5F5B); // Deep teal green
  static const Color primaryLight = Color(0xFFDFF3F4); // Light mint

  // Splash / Background (exact image vibe)
  static const Color bgTop = Color(0xFFDFF3F4); // Mint blue top
  static const Color bgBottom = Color(0xFFF7FCFC); // Soft white-blue

  // Cards & Inputs
  static const Color card = Colors.white;
  static const Color inputFill = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF1F5F5B); // Same as logo
  static const Color textSecondary = Color(0xFF6B7280); // Soft gray

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
}

/// ===============================
/// ✍️ TEXT STYLES
/// ===============================
class AppTextStyles {
  // App title (matches image)
  static const TextStyle appTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // Subtitle / helper text
  static const TextStyle linkBase = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Action links
  static const TextStyle linkAction = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Buttons (light green buttons)
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Error banner text
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Success banner text
  static const TextStyle successText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}
