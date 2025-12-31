import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A237E); // Deep Indigo
  static const Color secondary = Color(0xFF0D47A1); // Strong Blue
  static const Color accent = Color(0xFF2979FF); // Bright Blue
  
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);

  static const Color divider = Color(0xFFCFD8DC);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
