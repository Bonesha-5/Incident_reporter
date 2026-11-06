import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';

/// Opens the staff "Update status" sheet. Returns true if saved.
Future<bool?> showUpdateStatusSheet(BuildContext context, Incident incident) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => UpdateStatusSheet(incident: incident),
  );
}

class UpdateStatusSheet extends StatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String? _selected;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String get _noteHint => switch (_selected) {
    'in_review' => 'e.g. We are checking the water tank.',
    'in_progress' => 'e.g. Plumber assigned. Expected fix by tomorrow.',
    'resolved' => 'e.g. Water supply restored.',
    'rejected' => "Explain why this can't be handled by campus staff.",
    _ => 'Write a short message for the students',
  };

  Future<void> _save() async {
    if (_selected == null) {
      setState(() => _error = 'Choose the new status first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<IncidentProvider>().updateStatus(
      widget.incident,
      _selected!,
      _noteController.text,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to ${AppConstants.statuses[_selected]}'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incident = widget.incident;
    final followers = incident.meTooCount;
    final options = AppConstants.statuses.keys
        .where((s) => s != 'submitted')
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Update status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${incident.refCode} · ${incident.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // ---------- Status options ----------
              ...options.map((status) {
                final isCurrent = status == incident.status;
                final isSelected = status == _selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    child: Material(
                      color: isSelected
                          ? scheme.primaryContainer
                          : scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? scheme.onPrimaryContainer
                              : scheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isCurrent
                            ? null
                            : () => setState(() {
                                _selected = status;
                                _error = null;
                              }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              StatusChip(status: status),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isCurrent
                                    ? scheme.outline
                                    : isSelected
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),

              // ---------- Message ----------
              AppTextField(
                label: 'Message to students',
                controller: _noteController,
                hint: _noteHint,
                maxLines: 3,
                maxLength: 300,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please write a short message';
                  if (text.length < 5) return 'Message is too short';
                  return null;
                },
              ),
              Text(
                followers == 0
                    ? 'The reporter will see this on the timeline and get a notification.'
                    : 'The reporter and $followers ${followers == 1 ? 'student' : 'students'} who tapped Me too will get a notification.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                InfoBanner(message: _error!, type: InfoBannerType.error),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save update',
                      onPressed: _save,
                      isLoading: _busy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
