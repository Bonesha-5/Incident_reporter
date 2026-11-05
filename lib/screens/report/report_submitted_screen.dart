import 'package:flutter/material.dart';

import '../../models/incident.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import 'report_form_screen.dart';

class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          value,
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          children: [
            Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0E3A2D)
                      : const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Report submitted',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thank you. Campus staff can see it now, and you'll see every update on its timeline.",
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    row(
                      'Reference',
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          incident.refCode,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 12),
                    row(
                      'Problem',
                      Text(
                        incident.categoryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    row(
                      'Location',
                      Flexible(
                        child: Text(
                          incident.location,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    row('Status', StatusChip(status: incident.status)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Back to home',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ReportFormScreen()),
              ),
              child: const Text('Report another issue'),
            ),
          ],
        ),
      ),
    );
  }
}
