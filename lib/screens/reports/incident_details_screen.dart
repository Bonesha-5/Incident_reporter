import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/incident.dart';
import '../../models/incident_update.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/urgency_chip.dart';
import '../staff/update_status_sheet.dart';
import 'report_actions.dart';

class IncidentDetailsScreen extends StatefulWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  late final Stream<List<IncidentUpdate>> _updates = context
      .read<IncidentProvider>()
      .updatesFor(widget.incidentId);
  Future<String?>? _hiddenNameFuture; // staff only

  void _openPhoto(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Center(child: Image.network(url)),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final user = context.watch<AuthProvider>().user;
    final incident = provider.incidentById(widget.incidentId);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report details')),
        body: Center(
          child: provider.isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'This report was deleted or is no longer available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
        ),
      );
    }

    final isStaff = user?.isStaff ?? false;
    final isMine = user != null && incident.isReportedBy(user.uid);
    final canEdit = isMine && incident.canBeEdited;

    // ---------- Who reported it ----------
    final Widget reporterRow;
    if (incident.isAnonymous && isStaff && !isMine) {
      _hiddenNameFuture ??= provider.reporterNameFor(incident.reporterId);
      reporterRow = FutureBuilder<String?>(
        future: _hiddenNameFuture,
        builder: (context, snapshot) => _MetaRow(
          icon: Icons.person_outline_rounded,
          text: snapshot.connectionState != ConnectionState.done
              ? 'Loading reporter…'
              : '${snapshot.data ?? 'Unknown student'} (anonymous to students)',
        ),
      );
    } else {
      final String text;
      if (incident.isAnonymous) {
        text = isMine
            ? 'You (hidden from other students)'
            : 'Anonymous student';
      } else {
        text = isMine ? 'You' : (incident.reporterName ?? 'Student');
      }
      reporterRow = _MetaRow(icon: Icons.person_outline_rounded, text: text);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                incident.refCode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (value) async {
                if (value == 'edit') {
                  openEditReport(context, incident);
                } else {
                  final deleted = await confirmAndDeleteReport(
                    context,
                    incident,
                  );
                  if (deleted && context.mounted) Navigator.of(context).pop();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Edit report'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete report',
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 12),
        ],
      ),

      // ---------- Staff action at the bottom ----------
      bottomNavigationBar: isStaff
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outline)),
                ),
                child: PrimaryButton(
                  label: 'Update status',
                  icon: Icons.edit_note_rounded,
                  onPressed: () => showUpdateStatusSheet(context, incident),
                ),
              ),
            )
          : null,

      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // ---------- Photo ----------
          if (incident.photoUrl != null) ...[
            Semantics(
              button: true,
              label: 'Open photo full screen',
              child: GestureDetector(
                onTap: () => _openPhoto(incident.photoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    incident.photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(
                            height: 200,
                            color: scheme.primaryContainer,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                    errorBuilder: (context, error, stack) => Container(
                      height: 120,
                      color: scheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Text(
                        "Photo couldn't load",
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ---------- Title, chips, details ----------
          Text(
            incident.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(status: incident.status),
              UrgencyChip(urgency: incident.urgency),
              _OutlineChip(text: incident.categoryLabel),
            ],
          ),
          const SizedBox(height: 14),
          _MetaRow(icon: Icons.place_outlined, text: incident.fullLocation),
          _MetaRow(
            icon: Icons.schedule_rounded,
            text: 'Reported ${Formatters.dateTime(incident.createdAt)}',
          ),
          reporterRow,
          const SizedBox(height: 18),

          // ---------- Me too ----------
          _MeTooCard(
            incident: incident,
            isMine: isMine,
            isStaff: isStaff,
            hasMeToo: user != null && incident.hasMeTooFrom(user.uid),
          ),
          const SizedBox(height: 22),

          // ---------- Description ----------
          Text(
            'Description',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(incident.description, style: const TextStyle(height: 1.55)),
          const SizedBox(height: 24),

          // ---------- Timeline ----------
          Text(
            'Progress',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<IncidentUpdate>>(
            stream: _updates,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  "Couldn't load the progress.",
                  style: TextStyle(color: scheme.error),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _Timeline(
                updates: snapshot.data!,
                currentStatus: incident.status,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------- Small widgets for this screen ----------

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _MeTooCard extends StatefulWidget {
  const _MeTooCard({
    required this.incident,
    required this.isMine,
    required this.isStaff,
    required this.hasMeToo,
  });

  final Incident incident;
  final bool isMine;
  final bool isStaff;
  final bool hasMeToo;

  @override
  State<_MeTooCard> createState() => _MeTooCardState();
}

class _MeTooCardState extends State<_MeTooCard> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final error = await context.read<IncidentProvider>().toggleMeToo(
      widget.incident,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.incident.affectedCount;
    final canTap = !widget.isMine && !widget.isStaff;

    final String subtitle;
    if (widget.isMine) {
      subtitle = 'You reported this';
    } else if (widget.isStaff) {
      subtitle = 'Reporter + students who tapped Me too';
    } else if (widget.hasMeToo) {
      subtitle = "You'll get updates on this report";
    } else {
      subtitle = 'Affects you too? Add yourself.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 22,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'student' : 'students'} affected',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: scheme.onSurface),
                ),
              ],
            ),
          ),
          if (canTap)
            widget.hasMeToo
                ? OutlinedButton.icon(
                    onPressed: _busy ? null : _toggle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Me too'),
                  )
                : ElevatedButton(
                    onPressed: _busy ? null : _toggle,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Me too'),
                  ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.updates, required this.currentStatus});

  final List<IncidentUpdate> updates;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final isFinished =
        currentStatus == 'resolved' || currentStatus == 'rejected';
    final steps = <Widget>[];

    for (var i = 0; i < updates.length; i++) {
      final update = updates[i];
      final isNewest = i == updates.length - 1;
      steps.add(
        _TimelineStep(
          title: AppConstants.statuses[update.status] ?? update.status,
          subtitle: Formatters.dateTime(update.createdAt),
          note: update.note,
          staffName: update.staffName,
          status: update.status,
          state: isNewest ? _StepState.current : _StepState.done,
          isLast: isNewest && isFinished,
        ),
      );
    }
    if (!isFinished) {
      steps.add(
        const _TimelineStep(
          title: 'Resolved',
          subtitle: 'Waiting',
          status: 'resolved',
          state: _StepState.pending,
          isLast: true,
        ),
      );
    }
    return Column(children: steps);
  }
}

enum _StepState { done, current, pending }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.state,
    required this.isLast,
    this.note,
    this.staffName,
  });

  final String title;
  final String subtitle;
  final String status;
  final _StepState state;
  final bool isLast;
  final String? note;
  final String? staffName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusColor, statusBackground) = StatusColors.of(
      status,
      Theme.of(context).brightness,
    );

    final Widget dot = switch (state) {
      _StepState.done => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: scheme.onPrimaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 14, color: scheme.surface),
      ),
      _StepState.current => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          border: Border.all(color: statusBackground, width: 4),
        ),
      ),
      _StepState.pending => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline, width: 2),
        ),
      ),
    };

    final hasNote = (note ?? '').isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == _StepState.done
                          ? scheme.onPrimaryContainer
                          : scheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state == _StepState.current ? '$title · now' : title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: switch (state) {
                        _StepState.current => statusColor,
                        _StepState.pending => scheme.onSurfaceVariant,
                        _StepState.done => scheme.onSurface,
                      },
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        border: Border.all(color: scheme.outline),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: note),
                            if (staffName != null)
                              TextSpan(
                                text: '  — $staffName',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
