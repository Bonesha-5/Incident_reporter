import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/primary_button.dart';
import 'report_actions.dart';

/// The student's own reports, with Edit and Delete while still "Submitted".
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key, required this.onReport});

  final VoidCallback onReport;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _filter = 'all';

  static bool _inGroup(Incident i, String group) => switch (group) {
    'submitted' => i.status == 'submitted',
    'ongoing' => i.status == 'in_review' || i.status == 'in_progress',
    'resolved' => i.status == 'resolved',
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final scheme = Theme.of(context).colorScheme;
    final mine = provider.myIncidents;
    final shown = mine.where((i) => _inGroup(i, _filter)).toList();

    const groups = {
      'all': 'All',
      'submitted': 'Submitted',
      'ongoing': 'Ongoing',
      'resolved': 'Resolved',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (mine.isEmpty) {
            return _NoReportsYet(onReport: widget.onReport);
          }
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                  children: groups.entries.map((g) {
                    final selected = _filter == g.key;
                    final count = mine.where((i) => _inGroup(i, g.key)).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${g.value} · $count'),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = g.key),
                        showCheckmark: false,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surface,
                        side: BorderSide(
                          color: selected ? scheme.primary : scheme.outline,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected ? scheme.onPrimary : scheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                          'No reports in this group.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _MyReportCard(incident: shown[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      side: BorderSide(color: scheme.outline),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IncidentCard(
            incident: incident,
            onTap: () => openReportDetails(context, incident.id),
          ),
          if (incident.canBeEdited)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: compact,
                          onPressed: () => openEditReport(context, incident),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: compact.copyWith(
                            foregroundColor: WidgetStatePropertyAll(
                              scheme.error,
                            ),
                          ),
                          onPressed: () =>
                              confirmAndDeleteReport(context, incident),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can edit or delete until staff start reviewing it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoReportsYet extends StatelessWidget {
  const _NoReportsYet({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reports yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'When you report a problem on campus, you can follow its progress here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Report an issue', onPressed: onReport),
          ],
        ),
      ),
    );
  }
}
