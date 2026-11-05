import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Navy header used on the login, register and password screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status-bar icons
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          24,
          topPadding + (showBack ? 8 : 40),
          24,
          32,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkHeader : AppColors.navy,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.navy, size: 28),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFC9D3E6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
