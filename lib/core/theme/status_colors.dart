import 'package:flutter/material.dart';

/// Text and background colour for each status, in light and dark mode.
class StatusColors {
  StatusColors._();

  /// Returns (text colour, background colour).
  static (Color, Color) of(String status, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (status) {
      case 'submitted':
        return dark
            ? (const Color(0xFFFCD34D), const Color(0xFF3A2C0B))
            : (const Color(0xFF92400E), const Color(0xFFFEF3C7));
      case 'in_review':
        return dark
            ? (const Color(0xFF93C5FD), const Color(0xFF172A55))
            : (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE));
      case 'in_progress':
        return dark
            ? (const Color(0xFFC4B5FD), const Color(0xFF2A1F52))
            : (const Color(0xFF6D28D9), const Color(0xFFEDE9FE));
      case 'resolved':
        return dark
            ? (const Color(0xFF6EE7B7), const Color(0xFF0E3A2D))
            : (const Color(0xFF047857), const Color(0xFFD1FAE5));
      default: // rejected
        return dark
            ? (const Color(0xFFCBD5E1), const Color(0xFF2A2F3A))
            : (const Color(0xFF4B5563), const Color(0xFFF3F4F6));
    }
  }
}
