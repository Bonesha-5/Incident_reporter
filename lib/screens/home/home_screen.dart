import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_colors.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/primary_button.dart';
import '../reports/report_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onReport,
  });

  /// Switches the bottom-navigation tab (1 = Reports, 2 = My reports, 3 = Profile)
  final ValueChanged<int> onOpenTab;
  final VoidCallback onReport;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    final mine = incidents.myIncidents;
    int count(bool Function(Incident) test) => mine.where(test).length;
    final recent = incidents.allIncidents.take(5).toList();
    final firstName = user.fullName.trim().split(' ').first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ---------- Navy header + overlapping report card ----------
            Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkHeader : AppColors.navy,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(),
                                    style: const TextStyle(
                                      color: Color(0xFFC9D3E6),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const NotificationBell(),
                            const SizedBox(width: 10),
                            Semantics(
                              button: true,
                              label: 'Open profile',
                              child: GestureDetector(
                                onTap: () => onOpenTab(3),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.navyLight,
                                  child: Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'See something broken?',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Report it in under a minute and track the fix.',
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Report an issue',
                              icon: Icons.add_rounded,
                              onPressed: onReport,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ---------- My reports summary ----------
            _SectionHeader(title: 'My reports', onSeeAll: () => onOpenTab(2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _StatTile(count: mine.length, label: 'Total'),
                  const SizedBox(width: 8),
                  _StatTile(
                    count: count((i) => i.status == 'submitted'),
                    label: 'Submitted',
                    status: 'submitted',
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    count: count(
                      (i) =>
                          i.status == 'in_review' || i.status == 'in_progress',
                    ),
                    label: 'Ongoing',
                    status: 'in_progress',
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    count: count((i) => i.status == 'resolved'),
                    label: 'Resolved',
                    status: 'resolved',
                  ),
                ],
              ),
            ),

            // ---------- Happening on campus ----------
            _SectionHeader(
              title: 'Happening on campus',
              onSeeAll: () => onOpenTab(1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Builder(
                builder: (context) {
                  if (incidents.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (incidents.loadError != null) {
                    return InfoBanner(
                      message: incidents.loadError!,
                      type: InfoBannerType.error,
                    );
                  }
                  if (recent.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No reports yet. Be the first to report an issue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return Column(
                    children: recent
                        .map(
                          (incident) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: IncidentCard(
                              incident: incident,
                              onTap: () =>
                                  openReportDetails(context, incident.id),
                            ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.count, required this.label, this.status});

  final int count;
  final String label;
  final String? status; // null = neutral "Total" tile

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color foreground;
    final Color background;
    if (status == null) {
      foreground = scheme.onPrimaryContainer;
      background = scheme.surface;
    } else {
      (foreground, background) = StatusColors.of(
        status!,
        Theme.of(context).brightness,
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
