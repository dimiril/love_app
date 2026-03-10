import 'package:flutter/material.dart';

class AppColors {
  // ===== الألوان الأساسية (ثابتة في الوضعين) =====
  static const Color primary = Color(0xFF0091ea);
  static const Color secondary = Color(0xFF00C897);
  static const Color accent = Color(0xFFf8c460);
  static const Color like = Colors.redAccent;

  // ===== ألوان الوضع الفاتح (Light Mode) =====
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color bgLight2 = Colors.white;
  static const Color appBarLight = Color(0xffeef0f4);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // ===== ألوان الوضع الداكن (Dark Mode) =====
  static const Color bgDark = Color(0xFF121212);
  static const Color appBarDark = Color(0xFF252525);
  static const Color cardDark = Color(0xFF242424);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // ===== ألوان مساعدة =====
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Colors.red;
  static const Color success = Colors.green;
}
