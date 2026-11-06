import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Shows how urgent a report is. High and Emergency stand out in red.
class UrgencyChip extends StatelessWidget {
  const UrgencyChip({super.key, required this.urgency, this.showSuffix = true});

  final String urgency;
  final bool showSuffix; // "High urgency" vs "High"

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = AppConstants.urgencyLevels[urgency] ?? urgency;
    final label = showSuffix ? '$name urgency' : name;

    if (urgency == 'low' || urgency == 'medium') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
    }

    final isEmergency = urgency == 'emergency';
    final background = isEmergency
        ? const Color(0xFFC8261F)
        : (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFDECEB));
    final foreground = isEmergency
        ? Colors.white
        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8261F));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmergency) ...[
            Icon(Icons.warning_amber_rounded, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
