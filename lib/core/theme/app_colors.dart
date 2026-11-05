import 'package:flutter/material.dart';

/// Every colour in the app lives here, so we never type hex codes in screens.
class AppColors {
  AppColors._();

  // Brand
  static const Color navy = Color(0xFF0F2A5C);
  static const Color navyLight = Color(0xFFE8EDF6);
  static const Color red = Color(0xFFE4312B);
  static const Color blue = Color(0xFF1D4ED8);

  // Light mode
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1D29);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightError = Color(0xFFB91C1C);

  // Dark mode
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF151D2E);
  static const Color darkHeader = Color(0xFF13254A);
  static const Color darkTextPrimary = Color(0xFFE8ECF5);
  static const Color darkTextSecondary = Color(0xFF9AA4B8);
  static const Color darkBorder = Color(0xFF263048);
  static const Color darkAccent = Color(0xFFA9C1F5);
  static const Color darkTile = Color(0xFF1E2A44);
  static const Color darkError = Color(0xFFFCA5A5);
}
