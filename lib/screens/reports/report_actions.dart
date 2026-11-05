import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../report/report_form_screen.dart';
import 'incident_details_screen.dart';

/// Actions used from several screens, written once.

void openReportDetails(BuildContext context, String incidentId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => IncidentDetailsScreen(incidentId: incidentId),
    ),
  );
}

void openEditReport(BuildContext context, Incident incident) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ReportFormScreen(existing: incident)),
  );
}

/// Asks for confirmation, then deletes. Returns true if deleted.
Future<bool> confirmAndDeleteReport(
  BuildContext context,
  Incident incident,
) async {
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this report?'),
      content: Text(
        '"${incident.title}" will be removed for everyone. This can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final error = await context.read<IncidentProvider>().deleteIncident(
    incident.id,
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Report deleted')));
  }
  return error == null;
}
