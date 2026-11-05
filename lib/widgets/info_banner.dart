import 'package:flutter/material.dart';

enum InfoBannerType { info, error, success }

/// Coloured message box: info (blue), error (red) or success (green).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.type = InfoBannerType.info,
    this.icon,
  });

  final String message;
  final InfoBannerType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color background;
    late final Color foreground;
    late final IconData defaultIcon;

    switch (type) {
      case InfoBannerType.info:
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
        defaultIcon = Icons.info_outline_rounded;
      case InfoBannerType.error:
        background = isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFDECEB);
        foreground = scheme.error;
        defaultIcon = Icons.error_outline_rounded;
      case InfoBannerType.success:
        background = isDark ? const Color(0xFF0E3A2D) : const Color(0xFFD1FAE5);
        foreground = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
        defaultIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: type == InfoBannerType.info
                    ? scheme.onSurface
                    : foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
