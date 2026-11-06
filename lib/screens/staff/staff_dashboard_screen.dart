import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/urgency_chip.dart';
import '../reports/report_actions.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  static const _urgencyRank = {
    'emergency': 3,
    'high': 2,
    'medium': 1,
    'low': 0,
  };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<IncidentProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    final all = provider.allIncidents;
    int count(String status) => all.where((i) => i.status == status).length;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final resolvedThisWeek = all
        .where((i) => i.status == 'resolved' && i.updatedAt.isAfter(weekAgo))
        .length;

    // Open reports: most urgent first, then most affected, then newest
    final needsAttention =
        all
            .where((i) => i.status != 'resolved' && i.status != 'rejected')
            .toList()
          ..sort((a, b) {
            final byUrgency = (_urgencyRank[b.urgency] ?? 0).compareTo(
              _urgencyRank[a.urgency] ?? 0,
            );
            if (byUrgency != 0) return byUrgency;
            final byAffected = b.affectedCount.compareTo(a.affectedCount);
            if (byAffected != 0) return byAffected;
            return b.createdAt.compareTo(a.createdAt);
          });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ---------- Header with counts ----------
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.paddingOf(context).top + 20,
                24,
                24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkHeader : AppColors.navy,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFC9D3E6),
                              ),
                            ),
                            const Text(
                              'Staff dashboard',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8261F),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'STAFF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _CountTile(
                        count: count('submitted'),
                        label: 'New reports',
                        status: 'submitted',
                      ),
                      const SizedBox(width: 10),
                      _CountTile(
                        count: count('in_review'),
                        label: 'In review',
                        status: 'in_review',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CountTile(
                        count: count('in_progress'),
                        label: 'In progress',
                        status: 'in_progress',
                      ),
                      const SizedBox(width: 10),
                      _CountTile(
                        count: resolvedThisWeek,
                        label: 'Resolved this week',
                        status: 'resolved',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------- Needs attention ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Needs attention',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onOpenTab(1),
                    child: const Text('All reports'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Most urgent first, then most students affected',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.loadError != null) {
                    return InfoBanner(
                      message: provider.loadError!,
                      type: InfoBannerType.error,
                    );
                  }
                  if (needsAttention.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.task_alt_rounded,
                            size: 48,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All caught up. No open reports.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: needsAttention
                        .take(10)
                        .map(
                          (incident) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StaffIncidentCard(incident: incident),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.label,
    required this.status,
  });

  final int count;
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, _) = StatusColors.of(status, Theme.of(context).brightness);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffIncidentCard extends StatelessWidget {
  const _StaffIncidentCard({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmergency = incident.urgency == 'emergency';
    final affected = incident.affectedCount;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEmergency
            ? BorderSide(
                color: isDark
                    ? const Color(0xFFF87171)
                    : const Color(0xFFC8261F),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openReportDetails(context, incident.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UrgencyChip(urgency: incident.urgency, showSuffix: false),
                  const Spacer(),
                  StatusChip(status: incident.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                incident.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${incident.location} · ${Formatters.timeAgo(incident.createdAt)} · $affected affected',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
