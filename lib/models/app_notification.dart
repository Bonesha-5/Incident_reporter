import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One alert in the "notifications" collection.
class AppNotification {
  final String id;
  final String userId;
  final String incidentId;
  final String incidentTitle;
  final String status;
  final String message;
  final String reason; // "reporter" or "me_too"
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.incidentId,
    required this.incidentTitle,
    required this.status,
    required this.message,
    required this.reason,
    required this.isRead,
    required this.createdAt,
  });

  /// "Your report is resolved", "Now in progress", …
  String get headline => switch (status) {
    'in_review' => 'Now in review',
    'in_progress' => 'Now in progress',
    'resolved' =>
      reason == 'reporter'
          ? 'Your report is resolved'
          : 'A report you follow is resolved',
    'rejected' => 'Report closed',
    _ => 'Status updated',
  };

  String get reasonLabel =>
      reason == 'reporter' ? 'Your report' : 'You tapped Me too';

  IconData get icon => switch (status) {
    'in_review' => Icons.manage_search_rounded,
    'in_progress' => Icons.build_outlined,
    'resolved' => Icons.check_rounded,
    'rejected' => Icons.block_rounded,
    _ => Icons.info_outline_rounded,
  };

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      incidentId: data['incidentId'] as String? ?? '',
      incidentTitle: data['incidentTitle'] as String? ?? '',
      status: data['status'] as String? ?? '',
      message: data['message'] as String? ?? '',
      reason: data['reason'] as String? ?? 'reporter',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
